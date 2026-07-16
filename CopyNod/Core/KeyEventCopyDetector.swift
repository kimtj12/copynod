import AppKit

/// NSEvent 모니터 기반 감지. global monitor는 다른 앱의 ⌘C/⌘X를,
/// local monitor는 자기 앱 내부의 것을 잡는다 (global에는 자기 앱이 안 잡힘).
final class KeyEventCopyDetector: CopyDetector {
    var onCopyKeyDown: ((_ isRepeat: Bool, _ cursor: CGPoint) -> Void)?

    private var globalMonitor: Any?
    private var localMonitor: Any?

    func start() {
        guard globalMonitor == nil else { return }
        globalMonitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { [weak self] event in
            self?.handle(event)
        }
        localMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            self?.handle(event)
            return event  // 이벤트는 절대 삼키지 않는다
        }
    }

    func stop() {
        if let globalMonitor { NSEvent.removeMonitor(globalMonitor) }
        if let localMonitor { NSEvent.removeMonitor(localMonitor) }
        globalMonitor = nil
        localMonitor = nil
    }

    deinit { stop() }

    private func handle(_ event: NSEvent) {
        // 키 판정은 keyCode가 아닌 문자 기반 — Dvorak 등 비QWERTY 레이아웃 대응
        let modifiers = event.modifierFlags.intersection([.command, .shift, .option, .control])
        guard modifiers == .command,
              let key = event.charactersIgnoringModifiers?.lowercased(),
              key == "c" || key == "x" else { return }
        // 커서 위치는 이벤트 시점에 1회만 조회 (mouse-moved 구독 금지 — planning.md 3.4)
        onCopyKeyDown?(event.isARepeat, NSEvent.mouseLocation)
    }
}
