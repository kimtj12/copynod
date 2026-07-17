import Foundation
import os

/// NSPasteboard.changeCount의 주입 가능한 추상화 (테스트 시임)
protocol PasteboardChangeCounting: AnyObject {
    var changeCount: Int { get }
}

/// DispatchQueue.main.asyncAfter의 주입 가능한 추상화 (테스트 시임)
protocol Scheduling {
    func after(_ delay: TimeInterval, _ action: @escaping () -> Void)
}

/// 시임 1: 트리거 이벤트 in → HUD 표시 요청 out.
/// 키 이벤트는 "복사 시도" 신호일 뿐이므로, changeCount가 기준점과 달라졌을 때만
/// 성공으로 판정한다. 기준점은 시점 샘플이 아닌 영속 워터마크(lastAccounted) —
/// 대상 앱이 우리 핸들러보다 먼저 write를 끝내도 keyDown 진입 시 워터마크와의
/// 차이로 즉시 잡힌다(구 방식의 false negative 제거). 워터마크는 ⌘-down(arm)에서
/// 갱신해 백그라운드 write를 nod 없이 정산한다 — 상세: docs/detection-race-solutions.md.
/// 전 과정은 메인 스레드에서 돌며 락이 없다.
final class CopyVerifier {
    static let checkInterval: TimeInterval = 0.05
    static let maxAttempts = 20  // ~1s — Office·원격 데스크톱 등 늦은 write 대응 (300ms → 확대)
    static let maxArmLag: TimeInterval = 0.03  // 이보다 늦은 arm은 "복사 후" 값일 수 있어 무시

    private static let log = Logger(subsystem: Bundle.main.bundleIdentifier ?? "CopyNod",
                                    category: "verify")

    private let pasteboard: PasteboardChangeCounting
    private let scheduler: Scheduling
    private let onCopyVerified: (CGPoint) -> Void
    private var generation = 0
    private var lastAccounted: Int

    init(pasteboard: PasteboardChangeCounting,
         scheduler: Scheduling,
         onCopyVerified: @escaping (CGPoint) -> Void) {
        self.pasteboard = pasteboard
        self.scheduler = scheduler
        self.onCopyVerified = onCopyVerified
        lastAccounted = pasteboard.changeCount
    }

    /// ⌘가 새로 눌린 순간(arm): 그 이전의 백그라운드 write를 nod 없이 정산해
    /// false positive 창을 "⌘-hold 동안"으로 줄인다. 늦게 배달된 이벤트는 이미
    /// "복사 후" 값일 수 있으므로 무시하고 이전 워터마크로 폴백 — 오류를 항상
    /// 덜 해로운 FP 쪽으로만 남긴다 (detection-race-solutions.md 4.1).
    func commandDown(lag: TimeInterval) {
        guard lag < Self.maxArmLag else {
            Self.log.debug("arm skipped: lag=\(Int(lag * 1000))ms")  // 메인 스레드 혼잡의 간접 지표
            return
        }
        lastAccounted = pasteboard.changeCount
    }

    func keyDown(isRepeat: Bool, cursor: CGPoint) {
        if isRepeat { return }  // 꾹 누름은 무시, 진행 중 체인도 건드리지 않음
        generation += 1
        let current = pasteboard.changeCount
        if current != lastAccounted {
            // 대상 앱이 우리보다 먼저 write를 끝낸 경우 — 구 방식이 놓치던 레이스
            let previous = lastAccounted
            Self.log.debug("verified immediately: pre-keyDown write (\(previous) -> \(current))")
            lastAccounted = current
            onCopyVerified(cursor)
            absorb(gen: generation, attempt: 0)
        } else {
            check(gen: generation, baseline: current, cursor: cursor, attempt: 0)
        }
    }

    private func check(gen: Int, baseline: Int, cursor: CGPoint, attempt: Int) {
        scheduler.after(Self.checkInterval) { [weak self] in
            guard let self, gen == self.generation else { return }  // 구세대 체인 소멸
            let current = self.pasteboard.changeCount
            // 비교는 != — "달라졌는가"를 묻는 것이지 "증가했는가"가 아니다
            if current != baseline {
                self.lastAccounted = current
                self.onCopyVerified(cursor)
                self.absorb(gen: gen, attempt: attempt + 1)
            } else if attempt < Self.maxAttempts - 1 {
                self.check(gen: gen, baseline: baseline, cursor: cursor, attempt: attempt + 1)
            } else {
                // 진단: 창 내 write 없음 — 진짜 무복사이거나 창(~1s)보다 늦은 write
                let accounted = self.lastAccounted
                Self.log.debug("verify miss: baseline=\(baseline) lastAccounted=\(accounted)")
            }
        }
    }

    /// 조용한 흡수: 판정이 끝난 press의 남은 창 동안 추가 write(같은 복사의 2차 bump,
    /// 즉시 판정 직후 도착하는 이번 press의 실제 write)를 nod 없이 정산해
    /// 다음 ⌘C에서의 false positive를 막는다 (detection-race-solutions.md 5절).
    private func absorb(gen: Int, attempt: Int) {
        guard attempt < Self.maxAttempts else { return }
        scheduler.after(Self.checkInterval) { [weak self] in
            guard let self, gen == self.generation else { return }
            self.lastAccounted = self.pasteboard.changeCount
            self.absorb(gen: gen, attempt: attempt + 1)
        }
    }
}
