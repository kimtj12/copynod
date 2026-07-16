import AppKit

/// HUD 표시 셸: 패널 수명·페이드·디바운스를 관리한다.
/// 위치 계산은 HUDPositioner(순수 함수)에 위임.
@MainActor
final class HUDPresenter {
    static let hudSize = CGSize(width: 64, height: 64)
    private static let fadeInDuration: TimeInterval = 0.1
    private static let visibleDuration: TimeInterval = 0.75
    private static let fadeOutDuration: TimeInterval = 0.25

    private var panel: HUDPanel?
    private var hudView: HUDView?
    private var hideWorkItem: DispatchWorkItem?

    /// v1 UI에서는 nearCursor 고정 (설정 노출은 M3)
    var position: HUDPosition = .nearCursor

    func show(at cursor: CGPoint) {
        let screens = NSScreen.screens.map(\.visibleFrame)
        guard !screens.isEmpty else { return }

        hideWorkItem?.cancel()

        // 표시 중 재트리거: 위치는 유지하고 표시 시간만 연장 (디바운스 — planning.md 5절).
        // 페이드 인/아웃 도중이면 애니메이션 재시작 없이 alpha만 1로 되돌린다.
        if let panel, panel.isVisible {
            if panel.alphaValue < 1 {
                NSAnimationContext.runAnimationGroup { context in
                    context.duration = Self.fadeInDuration
                    panel.animator().alphaValue = 1
                }
            }
            scheduleHide()
            return
        }

        let panel = ensurePanel()
        panel.setFrameOrigin(HUDPositioner.origin(for: position, hudSize: Self.hudSize,
                                                  cursor: cursor, screens: screens))
        panel.alphaValue = 0
        panel.orderFrontRegardless()
        NSAnimationContext.runAnimationGroup { context in
            context.duration = Self.fadeInDuration
            panel.animator().alphaValue = 1
        }
        hudView?.playCheckAnimation()
        scheduleHide()
    }

    private func scheduleHide() {
        let item = DispatchWorkItem { [weak self] in self?.hide() }
        hideWorkItem = item
        DispatchQueue.main.asyncAfter(deadline: .now() + Self.visibleDuration, execute: item)
    }

    private func hide() {
        guard let panel else { return }
        NSAnimationContext.runAnimationGroup({ context in
            context.duration = Self.fadeOutDuration
            panel.animator().alphaValue = 0
        }, completionHandler: {
            // 페이드 아웃 중 재트리거로 다시 밝아졌으면 내리지 않는다
            guard panel.alphaValue == 0 else { return }
            // 투명 상태로 두면 컴포지터가 레이어를 계속 관리하므로 반드시 orderOut (planning.md 3.5)
            panel.orderOut(nil)
        })
    }

    private func ensurePanel() -> HUDPanel {
        if let panel { return panel }
        let view = HUDView(size: Self.hudSize)
        let newPanel = HUDPanel(contentRect: NSRect(origin: .zero, size: Self.hudSize))
        newPanel.contentView = view
        panel = newPanel
        hudView = view
        return newPanel
    }
}
