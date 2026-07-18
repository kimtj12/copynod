import AppKit
import SwiftUI
import Combine
import os

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private static let log = Logger(subsystem: Bundle.main.bundleIdentifier ?? "CopyNod",
                                    category: "lifecycle")
    private let store = SettingsStore()
    private let presenter = HUDPresenter()
    private var statusBar: StatusBarController?
    private var detector: (any CopyDetector)?
    private var verifier: CopyVerifier?
    private var updater: UpdaterController?
    private var permissionWatcher: PermissionWatcher?
    private let revocationNotifier = RevocationNotifier()
    private var onboardingWindow: NSWindow?
    private var settingsWindow: NSWindow?
    private var permissionPollTimer: Timer?
    private var cancellables = Set<AnyCancellable>()

    func applicationDidFinishLaunching(_ notification: Notification) {
        // 테스트 호스트로 실행될 때는 모니터·창을 만들지 않는다.
        if ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil { return }

        updater = UpdaterController()

        let statusBar = StatusBarController(store: store)
        statusBar.openSettings = { [weak self] in self?.showSettings() }
        statusBar.checkForUpdates = { [weak self] in self?.updater?.checkForUpdates() }
        self.statusBar = statusBar
        store.$hideMenuBarIcon
            .sink { [weak statusBar] hidden in statusBar?.isVisible = !hidden }
            .store(in: &cancellables)

        let verifier = CopyVerifier(pasteboard: GeneralPasteboard(),
                                    scheduler: MainScheduler()) { [presenter, store] cursor in
            presenter.show(at: cursor, position: store.hudPosition, style: store.hudStyle)
        }
        self.verifier = verifier

        let detector = KeyEventCopyDetector()
        detector.onCopyKeyDown = { [weak verifier] isRepeat, cursor in
            verifier?.keyDown(isRepeat: isRepeat, cursor: cursor)
        }
        detector.onCommandDown = { [weak verifier] lag in
            verifier?.commandDown(lag: lag)
        }
        self.detector = detector

        if PermissionManager.isTrusted {
            detector.start()
        } else {
            statusBar.showsPermissionWarning = true
            PermissionManager.requestTrust()
            showOnboarding()
        }

        startWatchingPermissionChanges()
        startWatchingWake()
    }

    /// 잠자기 복귀 시 감지기 재등록: 잠자는 동안 TCC 재평가가 미확정으로 끝나면
    /// WindowServer가 이벤트 배달을 끊은 채 방치하고, NSEvent 모니터는 스스로
    /// 재등록하지 않아 완전 무반응이 된다 (2026-07-18 장애, docs/debugging.md).
    /// stop→start로 모니터를 새로 만들어 배달 경로를 복구한다.
    private func startWatchingWake() {
        NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didWakeNotification,
            object: nil, queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated {
                guard let self, PermissionManager.isTrusted else { return }
                Self.log.notice("did wake: re-registering key monitors")
                self.detector?.stop()
                self.detector?.start()
            }
        }
    }

    /// 권한 회수/재부여 감지 (planning.md 2.4): TCC DB 변경의 분산 알림을 받아
    /// PermissionWatcher가 전이를 판정한다 — 상시 폴링 없음.
    private func startWatchingPermissionChanges() {
        let watcher = PermissionWatcher(isTrusted: { PermissionManager.isTrusted },
                                        scheduler: MainScheduler()) { [weak self] trusted in
            guard let self else { return }
            Self.log.notice("accessibility permission changed: trusted=\(trusted)")
            self.statusBar?.showsPermissionWarning = !trusted
            if trusted {
                self.detector?.start()
            } else {
                self.detector?.stop()
                self.revocationNotifier.notifyRevoked()
            }
        }
        permissionWatcher = watcher
        DistributedNotificationCenter.default().addObserver(
            forName: PermissionWatcher.accessibilityAPINotification,
            object: nil, queue: .main
        ) { _ in
            MainActor.assumeIsolated { watcher.accessibilityDatabaseChanged() }
        }
    }

    /// 아이콘 숨김 상태의 설정 접근 경로: Spotlight 등에서 재실행 → 설정 창 (planning.md 2.4).
    /// 권한이 없으면 온보딩이 우선.
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        if PermissionManager.isTrusted {
            showSettings()
        } else {
            showOnboarding()
        }
        return false
    }

    private func showSettings() {
        if settingsWindow == nil {
            let view = SettingsView(store: store) { [weak self] in self?.updater?.checkForUpdates() }
            let window = NSWindow(contentViewController: NSHostingController(rootView: view))
            window.styleMask = [.titled, .closable]
            window.title = String(localized: "CopyNod Settings")
            window.isReleasedWhenClosed = false
            window.center()
            settingsWindow = window
        }
        NSApp.activate(ignoringOtherApps: true)
        settingsWindow?.makeKeyAndOrderFront(nil)
    }

    private func showOnboarding() {
        if onboardingWindow == nil {
            let view = OnboardingView { PermissionManager.openSystemSettings() }
            let window = NSWindow(contentViewController: NSHostingController(rootView: view))
            window.styleMask = [.titled, .closable]
            window.title = "CopyNod"
            window.isReleasedWhenClosed = false
            window.center()
            onboardingWindow = window
        }
        NSApp.activate(ignoringOtherApps: true)
        onboardingWindow?.makeKeyAndOrderFront(nil)
        startPermissionPolling()
    }

    /// 온보딩이 떠 있는 동안만 1초 간격으로 권한 부여를 감지한다 (상시 폴링 금지)
    private func startPermissionPolling() {
        guard permissionPollTimer == nil else { return }
        permissionPollTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            MainActor.assumeIsolated {  // 메인 런루프 타이머는 메인 스레드에서 발화한다
                guard let self else { return }
                if PermissionManager.isTrusted {
                    self.stopPermissionPolling()
                    self.onboardingWindow?.close()
                    self.statusBar?.showsPermissionWarning = false
                    self.detector?.start()
                } else if self.onboardingWindow?.isVisible != true {
                    self.stopPermissionPolling()  // 창을 닫았으면 폴링도 멈춘다
                }
            }
        }
    }

    private func stopPermissionPolling() {
        permissionPollTimer?.invalidate()
        permissionPollTimer = nil
    }
}
