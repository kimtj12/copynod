import Foundation

/// NSPasteboard.changeCount의 주입 가능한 추상화 (테스트 시임)
protocol PasteboardChangeCounting: AnyObject {
    var changeCount: Int { get }
}

/// DispatchQueue.main.asyncAfter의 주입 가능한 추상화 (테스트 시임)
protocol Scheduling {
    func after(_ delay: TimeInterval, _ action: @escaping () -> Void)
}

/// 시임 1: 트리거 이벤트 in → HUD 표시 요청 out.
/// 키 이벤트는 "복사 시도" 신호일 뿐이므로, changeCount가 baseline과 달라졌을 때만
/// 성공으로 판정한다. 전 과정은 메인 스레드에서 돌며 락이 없다.
final class CopyVerifier {
    static let checkInterval: TimeInterval = 0.05
    static let maxAttempts = 6

    private let pasteboard: PasteboardChangeCounting
    private let scheduler: Scheduling
    private let onCopyVerified: (CGPoint) -> Void
    private var generation = 0

    init(pasteboard: PasteboardChangeCounting,
         scheduler: Scheduling,
         onCopyVerified: @escaping (CGPoint) -> Void) {
        self.pasteboard = pasteboard
        self.scheduler = scheduler
        self.onCopyVerified = onCopyVerified
    }

    func keyDown(isRepeat: Bool, cursor: CGPoint) {
        // baseline은 반드시 첫 줄에서 샘플링 — global monitor의 비동기 전달 레이스 완화
        let baseline = pasteboard.changeCount
        if isRepeat { return }  // 꾹 누름은 무시, 진행 중 체인도 건드리지 않음
        generation += 1
        check(gen: generation, baseline: baseline, cursor: cursor, attempt: 0)
    }

    private func check(gen: Int, baseline: Int, cursor: CGPoint, attempt: Int) {
        scheduler.after(Self.checkInterval) { [weak self] in
            guard let self, gen == self.generation else { return }  // 구세대 체인 소멸
            // 비교는 != — "달라졌는가"를 묻는 것이지 "증가했는가"가 아니다
            if self.pasteboard.changeCount != baseline {
                self.onCopyVerified(cursor)
            } else if attempt < Self.maxAttempts - 1 {
                self.check(gen: gen, baseline: baseline, cursor: cursor, attempt: attempt + 1)
            }
        }
    }
}
