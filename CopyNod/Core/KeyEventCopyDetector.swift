import AppKit

/// NSEvent 모니터 기반 감지. global monitor는 다른 앱의 ⌘C/⌘X를,
/// local monitor는 자기 앱 내부의 것을 잡는다 (global에는 자기 앱이 안 잡힘).
/// flagsChanged는 ⌘-down arm 신호용 — ⇧ 포함 모든 modifier 변화가 배달되므로
/// 이 경로는 비트마스크 비교 후 즉시 리턴하는 수준으로 유지한다.
final class KeyEventCopyDetector: CopyDetector {
    var onCopyKeyDown: ((_ isRepeat: Bool, _ cursor: CGPoint) -> Void)?
    var onCommandDown: ((_ lag: TimeInterval) -> Void)?

    private var globalMonitor: Any?
    private var localMonitor: Any?
    private var wasCommandDown = false

    func start() {
        guard globalMonitor == nil else { return }
        globalMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.keyDown, .flagsChanged]) { [weak self] event in
            self?.handle(event)
        }
        localMonitor = NSEvent.addLocalMonitorForEvents(matching: [.keyDown, .flagsChanged]) { [weak self] event in
            self?.handle(event)
            return event  // 이벤트는 절대 삼키지 않는다
        }
    }

    func stop() {
        if let globalMonitor { NSEvent.removeMonitor(globalMonitor) }
        if let localMonitor { NSEvent.removeMonitor(localMonitor) }
        globalMonitor = nil
        localMonitor = nil
        wasCommandDown = false
    }

    deinit { stop() }

    private func handle(_ event: NSEvent) {
        if event.type == .flagsChanged {
            let isCommandDown = event.modifierFlags.contains(.command)
            if isCommandDown && !wasCommandDown {
                // event.timestamp와 systemUptime은 같은 시간축(부팅 후 경과) — 차가 곧 배달 지연
                onCommandDown?(ProcessInfo.processInfo.systemUptime - event.timestamp)
            }
            wasCommandDown = isCommandDown
            return
        }
        // 키 판정은 keyCode가 아닌 문자 기반 — Dvorak 등 비QWERTY 레이아웃 대응
        let modifiers = event.modifierFlags.intersection([.command, .shift, .option, .control])
        guard modifiers == .command,
              let key = event.charactersIgnoringModifiers?.lowercased(),
              key == "c" || key == "x" else { return }
        // 커서 위치는 이벤트 시점에 1회만 조회 (mouse-moved 구독 금지 — planning.md 3.4)
        onCopyKeyDown?(event.isARepeat, NSEvent.mouseLocation)
    }
}
