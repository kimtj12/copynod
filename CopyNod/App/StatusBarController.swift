import AppKit

/// 메뉴바 아이콘 + 최소 메뉴 (상태 표시, 종료). 드롭다운 완성은 M3.
@MainActor
final class StatusBarController: NSObject, NSMenuDelegate {
    private let statusItem: NSStatusItem
    private let stateItem: NSMenuItem

    override init() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        stateItem = NSMenuItem()
        super.init()

        statusItem.button?.image = NSImage(systemSymbolName: "checkmark.circle",
                                           accessibilityDescription: "CopyNod")

        let menu = NSMenu()
        menu.autoenablesItems = false
        stateItem.isEnabled = false
        menu.addItem(stateItem)
        menu.addItem(.separator())
        menu.addItem(NSMenuItem(title: String(localized: "Quit CopyNod"),
                                action: #selector(NSApplication.terminate(_:)),
                                keyEquivalent: "q"))
        menu.delegate = self
        statusItem.menu = menu
    }

    func menuWillOpen(_ menu: NSMenu) {
        stateItem.title = PermissionManager.isTrusted
            ? String(localized: "Watching for ⌘C / ⌘X")
            : String(localized: "Accessibility permission required")
    }
}
