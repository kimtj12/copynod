import AppKit

/// 필(pill) 배지: 체크마크 stroke-drawing 애니메이션 + "Copied" 레이블.
/// 배경은 시스템 외형 고정 — 라이트: 흰 필/검정 텍스트, 다크: 검정 필/흰 텍스트.
/// (배경 내용에 따라 톤이 바뀌는 NSGlassEffectView는 재사용 패널에서 이전 톤이 떴다 바뀌는 flip을 만들어 제거)
/// translucent(Liquid Glass 스타일)는 같은 고정 톤에 알파만 주어 반투명 질감을 낸다.
final class HUDView: NSView {
    private static let translucentAlpha: CGFloat = 0.9
    private static let pillHeight: CGFloat = 30
    private static let iconSide: CGFloat = 16
    private static let horizontalPadding: CGFloat = 14
    private static let iconTextGap: CGFloat = 6
    private static let text = Locale.preferredLanguages.first?.hasPrefix("ko") == true ? "복사됨" : "Copied"
    private static let font = NSFont.systemFont(ofSize: 13, weight: .medium)

    /// 텍스트 실측 기반 필 크기 — HUDPresenter.hudSize의 원천
    static let pillSize: CGSize = {
        let textWidth = ceil((text as NSString).size(withAttributes: [.font: font]).width)
        return CGSize(width: horizontalPadding + iconSide + iconTextGap + textWidth + horizontalPadding,
                      height: pillHeight)
    }()

    private let checkLayer = CAShapeLayer()
    let translucent: Bool

    init(size: CGSize, translucent: Bool = false) {
        self.translucent = translucent
        super.init(frame: NSRect(origin: .zero, size: size))
        wantsLayer = true
        layer?.cornerRadius = size.height / 2
        layer?.cornerCurve = .continuous

        let iconFrame = NSRect(x: Self.horizontalPadding,
                               y: (size.height - Self.iconSide) / 2,
                               width: Self.iconSide, height: Self.iconSide)
        checkLayer.path = Self.checkPath(scaledTo: iconFrame.size)
        checkLayer.fillColor = nil
        checkLayer.lineWidth = 2
        checkLayer.lineCap = .round
        checkLayer.lineJoin = .round
        checkLayer.strokeEnd = 0

        // 수동 sublayer를 subview 레이어와 섞으면 z-순서 보장이 없다 — 전용 오버레이 뷰에 담는다
        let checkHost = NSView(frame: iconFrame)
        checkHost.wantsLayer = true
        checkHost.layer?.addSublayer(checkLayer)
        addSubview(checkHost)

        let label = NSTextField(labelWithString: Self.text)
        label.font = Self.font
        label.textColor = .labelColor
        label.sizeToFit()
        label.setFrameOrigin(NSPoint(x: iconFrame.maxX + Self.iconTextGap,
                                     y: (size.height - label.frame.height) / 2))
        addSubview(label)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) is not supported") }

    override var wantsUpdateLayer: Bool { true }

    override func updateLayer() {
        // 시스템 라이트/다크 전환 시 재해석
        let isDark = effectiveAppearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
        let base = isDark ? NSColor.black : NSColor.white
        layer?.backgroundColor = (translucent ? base.withAlphaComponent(Self.translucentAlpha) : base).cgColor
        // Verified Green (docs/DESIGN.md) = Apple systemGreen 그대로
        checkLayer.strokeColor = NSColor.systemGreen.cgColor
    }

    /// strokeEnd 0→1로 체크를 약 0.25초에 걸쳐 그린다
    func playCheckAnimation() {
        checkLayer.removeAnimation(forKey: "draw")
        let draw = CABasicAnimation(keyPath: "strokeEnd")
        draw.fromValue = 0
        draw.toValue = 1
        draw.duration = 0.25
        draw.timingFunction = CAMediaTimingFunction(name: .easeOut)
        checkLayer.strokeEnd = 1
        checkLayer.add(draw, forKey: "draw")
    }

    /// 64pt 기준 체크 좌표를 실제 크기로 스케일 (좌표계 y 위로 증가). InkRippleView의 잔상도 공유.
    static func checkPath(scaledTo size: CGSize) -> CGPath {
        let s = size.width / 64
        let path = CGMutablePath()
        path.move(to: CGPoint(x: 19 * s, y: 33 * s))
        path.addLine(to: CGPoint(x: 28 * s, y: 23 * s))
        path.addLine(to: CGPoint(x: 45 * s, y: 41 * s))
        return path
    }
}
