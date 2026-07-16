import AppKit
import SwiftUI

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusBar: StatusBarController?
    private var detector: (any CopyDetector)?
    private var verifier: CopyVerifier?
    private let presenter = HUDPresenter()
    private var onboardingWindow: NSWindow?
    private var permissionPollTimer: Timer?

    func applicationDidFinishLaunching(_ notification: Notification) {
        // 테스트 호스트로 실행될 때는 모니터·창을 만들지 않는다.
        if ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil { return }

        statusBar = StatusBarController()

        let verifier = CopyVerifier(pasteboard: GeneralPasteboard(),
                                    scheduler: MainScheduler()) { [presenter] cursor in
            presenter.show(at: cursor)
        }
        self.verifier = verifier

        let detector = KeyEventCopyDetector()
        detector.onCopyKeyDown = { [weak verifier] isRepeat, cursor in
            verifier?.keyDown(isRepeat: isRepeat, cursor: cursor)
        }
        self.detector = detector

        if PermissionManager.isTrusted {
            detector.start()
        } else {
            PermissionManager.requestTrust()
            showOnboarding()
        }
    }

    /// 숨김/백그라운드 상태에서 Spotlight 등으로 재실행하면 안내 창을 다시 띄운다
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        if !PermissionManager.isTrusted { showOnboarding() }
        return false
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
