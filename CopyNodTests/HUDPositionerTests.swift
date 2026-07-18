import Testing
import Foundation
@testable import CopyNod

// 시임 2: HUDPositioner 순수 함수 — (옵션, HUD 크기, 커서, 화면 프레임들) → 패널 원점.
// 기대값은 스펙의 워크드 예제 리터럴 (구현과 독립).
struct HUDPositionerTests {
    let hudSize = CGSize(width: 64, height: 64)
    let screen = CGRect(x: 0, y: 0, width: 1440, height: 900)

    @Test("커서 근처: 커서의 오른쪽 아래 10pt 지점에 뜬다")
    func nearCursorPlacesBelowRightOfCursor() {
        let origin = HUDPositioner.origin(
            for: .nearCursor,
            hudSize: hudSize,
            cursor: CGPoint(x: 500, y: 500),
            screens: [screen]
        )
        // x = 500 + 10, y = 500 - 10 - 64
        #expect(origin == CGPoint(x: 510, y: 426))
    }

    @Test("커서 근처: 화면 우하단 모서리에서는 화면 안쪽으로 클램핑된다 (여백 8pt)")
    func nearCursorClampsToScreenEdges() {
        let origin = HUDPositioner.origin(
            for: .nearCursor,
            hudSize: hudSize,
            cursor: CGPoint(x: 1430, y: 30),
            screens: [screen]
        )
        // 클램핑 전 (1440, -44) → x = 1440 - 64 - 8, y = 8
        #expect(origin == CGPoint(x: 1368, y: 8))
    }

    @Test("멀티 모니터: 커서가 있는 화면 기준으로 클램핑한다")
    func multiMonitorUsesScreenContainingCursor() {
        let second = CGRect(x: 1440, y: 0, width: 1920, height: 1080)
        let origin = HUDPositioner.origin(
            for: .nearCursor,
            hudSize: hudSize,
            cursor: CGPoint(x: 3340, y: 500),
            screens: [screen, second]
        )
        // 클램핑 전 x = 3350 → 두 번째 화면의 maxX 기준 3360 - 64 - 8
        #expect(origin == CGPoint(x: 3288, y: 426))
    }

    @Test("하단 중앙: 커서가 있는 화면의 가로 중앙, 하단에서 100pt 위")
    func bottomCenterOnCursorScreen() {
        let second = CGRect(x: 1440, y: 0, width: 1920, height: 1080)
        let origin = HUDPositioner.origin(
            for: .bottomCenter,
            hudSize: hudSize,
            cursor: CGPoint(x: 2000, y: 500),
            screens: [screen, second]
        )
        // x = 1440 + 960 - 32, y = 0 + 100
        #expect(origin == CGPoint(x: 2368, y: 100))
    }

    @Test("오른쪽 위: 우측 여백 16pt, 상단 여백 80pt (알림 배너 회피)")
    func topRightWithNotificationOffset() {
        let origin = HUDPositioner.origin(
            for: .topRight,
            hudSize: hudSize,
            cursor: CGPoint(x: 500, y: 500),
            screens: [screen]
        )
        // x = 1440 - 64 - 16, y = 900 - 64 - 80
        #expect(origin == CGPoint(x: 1360, y: 756))
    }

    @Test("리플 중심: 커서 근처는 커서 지점 그대로 — 모서리에서도 클램핑하지 않는다")
    func rippleCenterNearCursorIsCursorUnclamped() {
        let center = HUDPositioner.rippleCenter(
            for: .nearCursor,
            badgeSize: hudSize,
            cursor: CGPoint(x: 1435, y: 5),
            screens: [screen]
        )
        #expect(center == CGPoint(x: 1435, y: 5))
    }

    @Test("리플 중심: 하단 중앙은 클래식 배지의 중심과 같은 지점")
    func rippleCenterBottomCenterMatchesBadgeCenter() {
        let center = HUDPositioner.rippleCenter(
            for: .bottomCenter,
            badgeSize: hudSize,
            cursor: CGPoint(x: 500, y: 500),
            screens: [screen]
        )
        // 배지 원점 (720 - 32, 100) + 배지 절반 (32, 32)
        #expect(center == CGPoint(x: 720, y: 132))
    }

    @Test("리플 중심: 오른쪽 위는 클래식 배지의 중심과 같은 지점")
    func rippleCenterTopRightMatchesBadgeCenter() {
        let center = HUDPositioner.rippleCenter(
            for: .topRight,
            badgeSize: hudSize,
            cursor: CGPoint(x: 500, y: 500),
            screens: [screen]
        )
        // 배지 원점 (1360, 756) + 배지 절반 (32, 32)
        #expect(center == CGPoint(x: 1392, y: 788))
    }

    @Test("커서가 어느 화면에도 없으면 첫 화면 기준으로 클램핑한다")
    func cursorOutsideAllScreensFallsBackToFirst() {
        let origin = HUDPositioner.origin(
            for: .nearCursor,
            hudSize: hudSize,
            cursor: CGPoint(x: -5000, y: -5000),
            screens: [screen]
        )
        // 클램핑 전 (-4990, -5074) → 첫 화면 좌하단 여백으로
        #expect(origin == CGPoint(x: 8, y: 8))
    }
}
