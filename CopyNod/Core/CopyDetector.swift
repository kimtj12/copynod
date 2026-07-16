import Foundation

/// 감지 계층 추상화 — 추후 active CGEventTap 승격 또는 MAS용 listen-only 탭 교체를
/// 구현체 교체로 대응하기 위한 프로토콜 (docs/detection-api-comparison.md 참조).
protocol CopyDetector: AnyObject {
    /// 복사 단축키(⌘C/⌘X) keyDown마다 호출: (키 반복 여부, 그 시점의 커서 위치)
    var onCopyKeyDown: ((_ isRepeat: Bool, _ cursor: CGPoint) -> Void)? { get set }
    func start()
    func stop()
}
