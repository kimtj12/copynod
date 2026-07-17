import Foundation

/// 감지 계층 추상화 — MAS용 listen-only CGEventTap 교체 등을 구현체 교체로
/// 대응하기 위한 프로토콜 (docs/detection-api-comparison.md, detection-race-solutions.md 참조).
protocol CopyDetector: AnyObject {
    /// 복사 단축키(⌘C/⌘X) keyDown마다 호출: (키 반복 여부, 그 시점의 커서 위치)
    var onCopyKeyDown: ((_ isRepeat: Bool, _ cursor: CGPoint) -> Void)? { get set }
    /// ⌘가 새로 눌린 순간 호출: (이벤트 발생→핸들러 실행 지연, 초).
    /// 워터마크 arm용 — 지연이 크면 verifier가 arm을 무시한다 (detection-race-solutions.md 4.1).
    var onCommandDown: ((_ lag: TimeInterval) -> Void)? { get set }
    func start()
    func stop()
}
