import AppKit

/// 메뉴바 아이콘 + 드롭다운: 상태 / HUD 위치 서브메뉴 / 자동 실행 / 설정 / 업데이트 확인 / 종료.
/// 메뉴 상태는 열릴 때마다 스토어·시스템에서 다시 읽는다.
@MainActor
final class StatusBarController: NSObject, NSMenuDelegate {
    private let statusItem: NSStatusItem
    private let stateItem: NSMenuItem
    private let positionItems: [NSMenuItem]
    private let launchItem: NSMenuItem
    private let store: SettingsStore

    var openSettings: (() -> Void)?
    var checkForUpdates: (() -> Void)?

    var isVisible: Bool {
        get { statusItem.isVisible }
        set { statusItem.isVisible = newValue }
    }

    init(store: SettingsStore) {
        self.store = store
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        stateItem = NSMenuItem()
        positionItems = HUDPosition.allCases.map { position in
            let item = NSMenuItem()
            item.title = position.label
            item.representedObject = position
            return item
        }
        launchItem = NSMenuItem()
        super.init()

        statusItem.button?.image = NSImage(systemSymbolName: "checkmark.circle",
                                           accessibilityDescription: "CopyNod")

        let menu = NSMenu()
        menu.autoenablesItems = false
        menu.delegate = self

        stateItem.isEnabled = false
        menu.addItem(stateItem)
        menu.addItem(.separator())

        let positionMenu = NSMenu()
        positionMenu.autoenablesItems = false
        for item in positionItems {
            item.target = self
            item.action = #selector(selectPosition(_:))
            positionMenu.addItem(item)
        }
        let positionRoot = NSMenuItem(title: String(localized: "HUD Position"), action: nil, keyEquivalent: "")
        positionRoot.submenu = positionMenu
        menu.addItem(positionRoot)

        launchItem.title = String(localized: "Launch at Login")
        launchItem.target = self
        launchItem.action = #selector(toggleLaunchAtLogin)
        menu.addItem(launchItem)
        menu.addItem(.separator())

        let settingsItem = NSMenuItem(title: String(localized: "Settings…"), action: #selector(openSettingsAction), keyEquivalent: ",")
        settingsItem.target = self
        menu.addItem(settingsItem)

        let updatesItem = NSMenuItem(title: String(localized: "Check for Updates…"), action: #selector(checkForUpdatesAction), keyEquivalent: "")
        updatesItem.target = self
        menu.addItem(updatesItem)
        menu.addItem(.separator())

        menu.addItem(NSMenuItem(title: String(localized: "Quit CopyNod"),
                                action: #selector(NSApplication.terminate(_:)),
                                keyEquivalent: "q"))
        statusItem.menu = menu
    }

    func menuWillOpen(_ menu: NSMenu) {
        stateItem.title = PermissionManager.isTrusted
            ? String(localized: "Watching for ⌘C / ⌘X")
            : String(localized: "Accessibility permission required")
        for item in positionItems {
            item.state = (item.representedObject as? HUDPosition) == store.hudPosition ? .on : .off
        }
        launchItem.state = LaunchAtLogin.isEnabled ? .on : .off
    }

    @objc private func selectPosition(_ sender: NSMenuItem) {
        guard let position = sender.representedObject as? HUDPosition else { return }
        store.hudPosition = position
    }

    @objc private func toggleLaunchAtLogin() {
        LaunchAtLogin.set(!LaunchAtLogin.isEnabled)
    }

    @objc private func openSettingsAction() { openSettings?() }
    @objc private func checkForUpdatesAction() { checkForUpdates?() }
}
