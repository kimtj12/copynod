import Testing
import Foundation
@testable import CopyNod

// 시임 1: CopyVerifier 파이프라인 — 트리거 in → HUD 표시 요청 out.
// changeCount 제공자와 스케줄러를 주입해 타이밍·세대 로직을 결정적으로 검증한다.
// 외부 행동(요청 횟수·위치)만 단언하고 내부 상태는 보지 않는다.

final class FakePasteboard: PasteboardChangeCounting {
    var changeCount = 100
}

/// 예약된 작업을 수동 tick으로 실행하는 가짜 스케줄러 (모든 지연이 동일하므로 FIFO = 시간순)
final class FakeScheduler: Scheduling {
    private var queue: [() -> Void] = []
    var scheduledCount: Int { queue.count }

    func after(_ delay: TimeInterval, _ action: @escaping () -> Void) {
        queue.append(action)
    }

    /// 다음 예약 작업 1개 실행 (50ms 경과에 해당)
    func tick() {
        guard !queue.isEmpty else { return }
        queue.removeFirst()()
    }
}

struct CopyVerifierTests {
    let pasteboard = FakePasteboard()
    let scheduler = FakeScheduler()

    private final class Box { var requests: [CGPoint] = [] }

    private func makeVerifier() -> (CopyVerifier, () -> [CGPoint]) {
        let box = Box()
        let verifier = CopyVerifier(pasteboard: pasteboard, scheduler: scheduler) { cursor in
            box.requests.append(cursor)
        }
        return (verifier, { box.requests })
    }

    @Test("클립보드가 변경되면 HUD 요청이 트리거 시점의 커서 위치로 1회 나온다")
    func changeProducesOneRequestAtCursor() {
        let (verifier, requests) = makeVerifier()
        verifier.keyDown(isRepeat: false, cursor: CGPoint(x: 10, y: 20))
        pasteboard.changeCount += 1
        scheduler.tick()
        #expect(requests() == [CGPoint(x: 10, y: 20)])
    }

    @Test("클립보드가 안 변하면 6회 확인 후 조용히 포기한다 (요청 0회)")
    func noChangeGivesUpAfterSixChecks() {
        let (verifier, requests) = makeVerifier()
        verifier.keyDown(isRepeat: false, cursor: .zero)
        for _ in 0..<6 { scheduler.tick() }
        #expect(requests().isEmpty)
        // 7번째 확인은 예약조차 되지 않는다
        #expect(scheduler.scheduledCount == 0)
    }

    @Test("느린 앱: 마지막(6번째) 확인 직전의 변경도 감지한다")
    func lateChangeDetectedOnSixthCheck() {
        let (verifier, requests) = makeVerifier()
        verifier.keyDown(isRepeat: false, cursor: .zero)
        for _ in 0..<5 { scheduler.tick() }  // 5회 무변경
        pasteboard.changeCount += 1
        scheduler.tick()  // 6번째 확인
        #expect(requests().count == 1)
    }

    @Test("성공 후 체인이 멈춘다 — 변경 1건에 요청은 1회뿐")
    func chainStopsAfterSuccess() {
        let (verifier, requests) = makeVerifier()
        verifier.keyDown(isRepeat: false, cursor: .zero)
        pasteboard.changeCount += 1
        scheduler.tick()
        #expect(scheduler.scheduledCount == 0)  // 추가 확인 예약 없음
        #expect(requests().count == 1)
    }

    @Test("⌘C 연타: 구세대 체인이 소멸해 변경 1건당 요청은 최대 1회, 최신 커서 위치로 나온다")
    func rapidRetriggerInvalidatesOlderChain() {
        let (verifier, requests) = makeVerifier()
        verifier.keyDown(isRepeat: false, cursor: CGPoint(x: 1, y: 1))
        verifier.keyDown(isRepeat: false, cursor: CGPoint(x: 2, y: 2))
        pasteboard.changeCount += 1
        scheduler.tick()  // 첫 번째 체인 — 구세대라 스스로 소멸
        scheduler.tick()  // 두 번째 체인 — 감지
        #expect(requests() == [CGPoint(x: 2, y: 2)])
    }

    @Test("changeCount가 감소해도 감지한다 — 비교는 !=이지 >가 아니다")
    func decreaseInChangeCountIsDetected() {
        let (verifier, requests) = makeVerifier()
        verifier.keyDown(isRepeat: false, cursor: .zero)
        pasteboard.changeCount -= 1
        scheduler.tick()
        #expect(requests().count == 1)
    }

    @Test("키 반복(꾹 누름)은 무시된다 — 확인 예약도 하지 않는다")
    func keyRepeatIsIgnored() {
        let (verifier, requests) = makeVerifier()
        verifier.keyDown(isRepeat: true, cursor: .zero)
        pasteboard.changeCount += 1
        scheduler.tick()
        #expect(requests().isEmpty)
        #expect(scheduler.scheduledCount == 0)
    }

    @Test("키 반복이 진행 중인 검증 체인을 죽이지 않는다")
    func keyRepeatDoesNotKillActiveChain() {
        let (verifier, requests) = makeVerifier()
        verifier.keyDown(isRepeat: false, cursor: .zero)
        verifier.keyDown(isRepeat: true, cursor: .zero)  // 반복 이벤트
        pasteboard.changeCount += 1
        scheduler.tick()
        #expect(requests().count == 1)
    }
}
