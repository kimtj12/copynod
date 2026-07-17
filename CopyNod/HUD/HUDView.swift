import AppKit

/// 원형 배지 + 체크마크 stroke-drawing 애니메이션.
/// 배경 재질의 버전 분기는 이 이니셜라이저 한 곳뿐이다 (planning.md 2.1).
final class HUDView: NSView {
    private let checkLayer = CAShapeLayer()

    init(size: CGSize) {
        super.init(frame: NSRect(origin: .zero, size: size))
        wantsLayer = true

        let background: NSView
        if #available(macOS 26.0, *) {
            let glass = NSGlassEffectView(frame: bounds)
            glass.cornerRadius = size.width / 2
            background = glass
        } else {
            let visual = NSVisualEffectView(frame: bounds)
            visual.material = .hudWindow
            visual.blendingMode = .behindWindow
            visual.state = .active
            // behind-window 블러는 layer cornerRadius로 잘리지 않는다 — maskImage가 정석
            visual.maskImage = NSImage(size: size, flipped: false) { rect in
                NSBezierPath(ovalIn: rect).fill()
                return true
            }
            background = visual
        }
        background.autoresizingMask = [.width, .height]
        addSubview(background)

        checkLayer.path = Self.checkPath(scaledTo: size)
        checkLayer.fillColor = nil
        checkLayer.lineWidth = 5 * size.width / 64
        checkLayer.lineCap = .round
        checkLayer.lineJoin = .round
        checkLayer.strokeEnd = 0

        // 수동 sublayer를 subview 레이어와 섞으면 z-순서 보장이 없다 — 전용 오버레이 뷰에 담는다
        let checkHost = NSView(frame: bounds)
        checkHost.autoresizingMask = [.width, .height]
        checkHost.wantsLayer = true
        checkHost.layer?.addSublayer(checkLayer)
        addSubview(checkHost, positioned: .above, relativeTo: background)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) is not supported") }

    override var wantsUpdateLayer: Bool { true }

    override func updateLayer() {
        // semantic color — 다크/라이트 전환 시 재해석
        checkLayer.strokeColor = NSColor.labelColor.cgColor
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
