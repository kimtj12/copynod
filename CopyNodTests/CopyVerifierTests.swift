import Testing
import Foundation
@testable import CopyNod

// 시임 1: CopyVerifier 파이프라인 — 트리거 in → HUD 표시 요청 out.
// changeCount 제공자와 스케줄러를 주입해 타이밍·세대·워터마크 로직을 결정적으로 검증한다.
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

    /// 예약이 소진될 때까지 실행 (검증·흡수 창 전체 경과에 해당)
    func drain() {
        while !queue.isEmpty { tick() }
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

    @Test("클립보드가 안 변하면 검증 창(20회) 소진 후 조용히 포기한다 (요청 0회)")
    func noChangeGivesUpAfterWindow() {
        let (verifier, requests) = makeVerifier()
        verifier.keyDown(isRepeat: false, cursor: .zero)
        for _ in 0..<CopyVerifier.maxAttempts { scheduler.tick() }
        #expect(requests().isEmpty)
        // 다음 확인은 예약조차 되지 않는다
        #expect(scheduler.scheduledCount == 0)
    }

    @Test("느린 앱: 마지막(20번째) 확인 직전의 변경도 감지한다")
    func lateChangeDetectedOnLastCheck() {
        let (verifier, requests) = makeVerifier()
        verifier.keyDown(isRepeat: false, cursor: .zero)
        for _ in 0..<(CopyVerifier.maxAttempts - 1) { scheduler.tick() }  // 19회 무변경
        pasteboard.changeCount += 1
        scheduler.tick()  // 마지막 확인
        #expect(requests().count == 1)
    }

    @Test("성공 후 추가 요청이 없다 — 남은 창은 조용한 정산(흡수)뿐이며 유한하게 끝난다")
    func successProducesNoFurtherRequests() {
        let (verifier, requests) = makeVerifier()
        verifier.keyDown(isRepeat: false, cursor: .zero)
        pasteboard.changeCount += 1
        scheduler.tick()
        scheduler.drain()  // 흡수 창까지 전부 경과
        #expect(requests().count == 1)
        #expect(scheduler.scheduledCount == 0)
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

    // MARK: - 워터마크 + ⌘-down arm (detection-race-solutions.md)

    @Test("keyDown 시점에 이미 변해 있으면 즉시 감지한다 — 비동기 전달 레이스의 결정적 재현")
    func preKeyDownWriteDetectedImmediately() {
        let (verifier, requests) = makeVerifier()
        pasteboard.changeCount += 1  // 대상 앱이 우리 핸들러보다 먼저 write를 끝냄
        verifier.keyDown(isRepeat: false, cursor: CGPoint(x: 5, y: 6))
        #expect(requests() == [CGPoint(x: 5, y: 6)])  // tick 없이 즉시
    }

    @Test("⌘-down arm 이후의 write도 keyDown에서 즉시 감지된다")
    func writeAfterArmDetectedImmediately() {
        let (verifier, requests) = makeVerifier()
        verifier.commandDown(lag: 0)
        pasteboard.changeCount += 1
        verifier.keyDown(isRepeat: false, cursor: .zero)
        #expect(requests().count == 1)
    }

    @Test("⌘-down arm이 백그라운드 write를 흡수해 빈 ⌘C에 요청이 없다 — planning.md 3.2 금지 우회책의 FP 시나리오")
    func armAbsorbsStaleWriteSoEmptyCopyStaysQuiet() {
        let (verifier, requests) = makeVerifier()
        pasteboard.changeCount += 1  // 패스워드 매니저 등 백그라운드 write
        verifier.commandDown(lag: 0)  // ⌘ 눌림 — 여기서 조용히 정산
        verifier.keyDown(isRepeat: false, cursor: .zero)  // 빈 선택 ⌘C (실제 복사 없음)
        scheduler.drain()
        #expect(requests().isEmpty)
    }

    @Test("배달이 늦은 arm은 무시되고 이전 워터마크로 폴백한다 — 오류는 FN이 아닌 FP 쪽으로")
    func laggedArmIsIgnored() {
        let (verifier, requests) = makeVerifier()
        pasteboard.changeCount += 1
        verifier.commandDown(lag: CopyVerifier.maxArmLag + 0.01)  // 지연 초과 — 흡수하지 않음
        verifier.keyDown(isRepeat: false, cursor: .zero)
        #expect(requests().count == 1)  // 이전 워터마크 기준으론 변경이 있으므로 요청이 나온다
    }

    @Test("즉시 판정 직후 도착한 write는 조용히 정산된다 — 추가 요청 없음, 다음 빈 ⌘C도 조용")
    func absorbAfterImmediateVerify() {
        let (verifier, requests) = makeVerifier()
        pasteboard.changeCount += 1
        verifier.keyDown(isRepeat: false, cursor: .zero)  // 즉시 판정
        pasteboard.changeCount += 1  // 이번 press의 실제 write가 직후 도착
        scheduler.drain()  // 흡수 창 소진
        verifier.keyDown(isRepeat: false, cursor: .zero)  // 빈 선택 ⌘C
        scheduler.drain()
        #expect(requests().count == 1)
    }

    @Test("체인 성공 후의 2차 bump도 정산된다 — 다음 빈 ⌘C에 FP 없음")
    func absorbAfterChainSuccess() {
        let (verifier, requests) = makeVerifier()
        verifier.keyDown(isRepeat: false, cursor: .zero)
        pasteboard.changeCount += 1
        scheduler.tick()  // 감지
        pasteboard.changeCount += 1  // 같은 복사의 2차 bump (clear + write)
        scheduler.drain()
        verifier.keyDown(isRepeat: false, cursor: .zero)  // 빈 선택 ⌘C
        scheduler.drain()
        #expect(requests().count == 1)
    }

    @Test("진행 중 체인 도중의 arm이 늦은 감지를 잃게 하지 않는다 — 체인은 자기 baseline과 비교한다")
    func armDuringPendingChainKeepsLateDetection() {
        let (verifier, requests) = makeVerifier()
        verifier.keyDown(isRepeat: false, cursor: .zero)
        pasteboard.changeCount += 1  // 늦은 write 도착
        verifier.commandDown(lag: 0)  // 다음 복사 준비로 ⌘ 눌림 — 워터마크는 이 write를 정산
        scheduler.tick()
        #expect(requests().count == 1)
    }
}
