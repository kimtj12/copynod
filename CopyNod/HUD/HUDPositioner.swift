import Foundation

/// HUD 위치 옵션. String raw는 UserDefaults 저장용, CaseIterable은 설정 UI 열거용.
enum HUDPosition: String, CaseIterable {
    case nearCursor
    case bottomCenter
    case topRight
}

/// 순수 함수: (옵션, HUD 크기, 커서 좌표, 화면 프레임들) → 패널 원점.
/// 좌표계는 AppKit 전역 좌표 (원점 좌하단, y 위로 증가).
enum HUDPositioner {
    static let cursorOffset: CGFloat = 16
    static let edgePadding: CGFloat = 8
    static let bottomOffset: CGFloat = 100
    static let topRightMargin = CGPoint(x: 16, y: 80)  // 알림 배너 회피용 상단 여백

    static func origin(for position: HUDPosition, hudSize: CGSize, cursor: CGPoint, screens: [CGRect]) -> CGPoint {
        let screen = screens.first(where: { $0.contains(cursor) }) ?? screens[0]
        switch position {
        case .nearCursor:
            let raw = CGPoint(x: cursor.x + cursorOffset,
                              y: cursor.y - cursorOffset - hudSize.height)
            return clamp(raw, hudSize: hudSize, in: screen)
        case .bottomCenter:
            return CGPoint(x: screen.midX - hudSize.width / 2,
                           y: screen.minY + bottomOffset)
        case .topRight:
            return CGPoint(x: screen.maxX - hudSize.width - topRightMargin.x,
                           y: screen.maxY - hudSize.height - topRightMargin.y)
        }
    }

    /// 잉크 리플용 중심점. 커서 근처는 커서 지점 그대로 — 잉크가 떨어진 지점이라는 은유에 맞게
    /// 클램핑 없이 화면 밖 잘림을 허용한다. 고정 위치는 클래식 배지의 중심과 같은 지점.
    static func rippleCenter(for position: HUDPosition, badgeSize: CGSize, cursor: CGPoint, screens: [CGRect]) -> CGPoint {
        guard position != .nearCursor else { return cursor }
        let o = origin(for: position, hudSize: badgeSize, cursor: cursor, screens: screens)
        return CGPoint(x: o.x + badgeSize.width / 2, y: o.y + badgeSize.height / 2)
    }

    private static func clamp(_ origin: CGPoint, hudSize: CGSize, in screen: CGRect) -> CGPoint {
        CGPoint(
            x: min(max(origin.x, screen.minX + edgePadding), screen.maxX - hudSize.width - edgePadding),
            y: min(max(origin.y, screen.minY + edgePadding), screen.maxY - hudSize.height - edgePadding)
        )
    }
}
