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
    private var ripplePanel: HUDPanel?
    private var rippleView: InkRippleView?
    private var isRipplePlaying = false

    func show(at cursor: CGPoint, position: HUDPosition, style: HUDStyle) {
        let screens = NSScreen.screens.map(\.visibleFrame)
        guard !screens.isEmpty else { return }

        switch style {
        case .classic: showClassic(at: cursor, position: position, screens: screens)
        case .inkRipple: showRipple(at: cursor, position: position, screens: screens)
        }
    }

    private func showClassic(at cursor: CGPoint, position: HUDPosition, screens: [CGRect]) {
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

    /// 원샷 애니메이션 (~0.4s) — 진행 중 재트리거는 무시한다 (키 반복에 요란하지 않게).
    /// 링·체크가 스스로 opacity 0으로 끝나므로 패널 페이드 없이 완료 시 orderOut만 한다.
    private func showRipple(at cursor: CGPoint, position: HUDPosition, screens: [CGRect]) {
        guard !isRipplePlaying else { return }

        let panel = ensureRipplePanel()
        let center = HUDPositioner.rippleCenter(for: position, badgeSize: Self.hudSize,
                                                cursor: cursor, screens: screens)
        panel.setFrameOrigin(CGPoint(x: center.x - InkRippleView.size.width / 2,
                                     y: center.y - InkRippleView.size.height / 2))
        panel.orderFrontRegardless()
        isRipplePlaying = true
        rippleView?.play { [weak self] in
            self?.isRipplePlaying = false
            self?.ripplePanel?.orderOut(nil)
        }
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

    private func ensureRipplePanel() -> HUDPanel {
        if let ripplePanel { return ripplePanel }
        let view = InkRippleView()
        let newPanel = HUDPanel(contentRect: NSRect(origin: .zero, size: InkRippleView.size))
        newPanel.contentView = view
        ripplePanel = newPanel
        rippleView = view
        return newPanel
    }
}
