import Testing
import Foundation
@testable import CopyNod

// 시임 2: HUDPositioner 순수 함수 — (옵션, HUD 크기, 커서, 화면 프레임들) → 패널 원점.
// 기대값은 스펙의 워크드 예제 리터럴 (구현과 독립).
struct HUDPositionerTests {
    let hudSize = CGSize(width: 64, height: 64)
    let screen = CGRect(x: 0, y: 0, width: 1440, height: 900)

    @Test("커서 근처: 커서의 오른쪽 아래 16pt 지점에 뜬다")
    func nearCursorPlacesBelowRightOfCursor() {
        let origin = HUDPositioner.origin(
            for: .nearCursor,
            hudSize: hudSize,
            cursor: CGPoint(x: 500, y: 500),
            screens: [screen]
        )
        // x = 500 + 16, y = 500 - 16 - 64
        #expect(origin == CGPoint(x: 516, y: 420))
    }

    @Test("커서 근처: 화면 우하단 모서리에서는 화면 안쪽으로 클램핑된다 (여백 8pt)")
    func nearCursorClampsToScreenEdges() {
        let origin = HUDPositioner.origin(
            for: .nearCursor,
            hudSize: hudSize,
            cursor: CGPoint(x: 1430, y: 30),
            screens: [screen]
        )
        // 클램핑 전 (1446, -50) → x = 1440 - 64 - 8, y = 8
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
        // 클램핑 전 x = 3356 → 두 번째 화면의 maxX 기준 3360 - 64 - 8
        #expect(origin == CGPoint(x: 3288, y: 420))
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

    @Test("커서가 어느 화면에도 없으면 첫 화면 기준으로 클램핑한다")
    func cursorOutsideAllScreensFallsBackToFirst() {
        let origin = HUDPositioner.origin(
            for: .nearCursor,
            hudSize: hudSize,
            cursor: CGPoint(x: -5000, y: -5000),
            screens: [screen]
        )
        // 클램핑 전 (-4984, -5080) → 첫 화면 좌하단 여백으로
        #expect(origin == CGPoint(x: 8, y: 8))
    }
}
