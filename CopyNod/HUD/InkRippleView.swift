import AppKit

/// 잉크 리플: 얇은 링이 중심에서 한 번 퍼지며 소멸하고 (~0.4s),
/// 중앙에 작은 체크 잔상이 그려졌다 링과 함께 사라진다.
/// 배경 재질 없음 — 가장 미니멀한 스타일 (docs/backlog.md HUD 스타일 팩).
final class InkRippleView: NSView {
    static let maxRadius: CGFloat = 48
    /// 링 최대 반경 + 시작 선폭 여유
    static let size = CGSize(width: 104, height: 104)
    static let duration: TimeInterval = 0.4
    private static let checkSize = CGSize(width: 24, height: 24)

    private let ringLayer = CAShapeLayer()
    private let checkLayer = CAShapeLayer()

    init() {
        super.init(frame: NSRect(origin: .zero, size: Self.size))
        wantsLayer = true

        let center = CGPoint(x: Self.size.width / 2, y: Self.size.height / 2)
        // transform.scale이 링 중심을 기준으로 걸리도록 frame을 뷰 전체로 (anchorPoint 0.5 → 중심)
        ringLayer.frame = NSRect(origin: .zero, size: Self.size)
        ringLayer.path = CGPath(ellipseIn: CGRect(x: center.x - Self.maxRadius,
                                                  y: center.y - Self.maxRadius,
                                                  width: Self.maxRadius * 2,
                                                  height: Self.maxRadius * 2), transform: nil)
        ringLayer.fillColor = nil
        ringLayer.opacity = 0

        checkLayer.path = HUDView.checkPath(scaledTo: Self.checkSize)
        checkLayer.fillColor = nil
        checkLayer.lineWidth = 5 * Self.checkSize.width / 64
        checkLayer.lineCap = .round
        checkLayer.lineJoin = .round
        checkLayer.frame = CGRect(origin: CGPoint(x: center.x - Self.checkSize.width / 2,
                                                  y: center.y - Self.checkSize.height / 2),
                                  size: Self.checkSize)
        checkLayer.opacity = 0

        layer?.addSublayer(ringLayer)
        layer?.addSublayer(checkLayer)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) is not supported") }

    override var wantsUpdateLayer: Bool { true }

    override func updateLayer() {
        // semantic color — 다크/라이트 전환 시 재해석
        ringLayer.strokeColor = NSColor.labelColor.cgColor
        checkLayer.strokeColor = NSColor.labelColor.cgColor
    }

    /// 링 확장(스케일 0→1) + 두께 감소(4→1) + 페이드, 체크는 빠르게 그려진 뒤 잔상으로 소멸.
    /// 모든 레이어가 opacity 0으로 끝나므로 패널 알파는 건드리지 않는다.
    func play(completion: @escaping () -> Void) {
        ringLayer.removeAllAnimations()
        checkLayer.removeAllAnimations()

        CATransaction.begin()
        CATransaction.setCompletionBlock(completion)

        let expand = CABasicAnimation(keyPath: "transform.scale")
        expand.fromValue = 0.02
        expand.toValue = 1
        let thin = CABasicAnimation(keyPath: "lineWidth")
        thin.fromValue = 4
        thin.toValue = 1
        let ringFade = CABasicAnimation(keyPath: "opacity")
        ringFade.fromValue = 1
        ringFade.toValue = 0
        ringFade.timingFunction = CAMediaTimingFunction(name: .easeIn)  // 소멸은 끝에 몰리게
        let ring = CAAnimationGroup()
        ring.animations = [expand, thin, ringFade]
        ring.duration = Self.duration
        ring.timingFunction = CAMediaTimingFunction(name: .easeOut)  // 물결처럼 감속하며 퍼짐
        ringLayer.add(ring, forKey: "ripple")

        let draw = CABasicAnimation(keyPath: "strokeEnd")
        draw.fromValue = 0
        draw.toValue = 1
        draw.duration = 0.15
        draw.timingFunction = CAMediaTimingFunction(name: .easeOut)
        let checkFade = CABasicAnimation(keyPath: "opacity")
        checkFade.fromValue = 1
        checkFade.toValue = 0
        checkFade.beginTime = 0.2
        checkFade.duration = Self.duration - 0.2
        checkFade.timingFunction = CAMediaTimingFunction(name: .easeIn)
        // beginTime 전에도 fromValue(1)를 유지하도록 backwards 채움
        checkFade.fillMode = .backwards
        let check = CAAnimationGroup()
        check.animations = [draw, checkFade]
        check.duration = Self.duration
        checkLayer.add(check, forKey: "check")

        CATransaction.commit()
    }
}
