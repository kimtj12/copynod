import Foundation

/// 시임: Accessibility 권한의 부여/회수 전이 감지 — 권한 DB 변경 신호 in → 전이 out.
/// 신호 시점에는 DB 반영이 늦을 수 있어 잠시 후 재확인하고,
/// 한 번의 변경에 신호가 여러 번 와도 세대 카운터로 재확인 1회로 코얼레싱한다.
final class PermissionWatcher {
    /// TCC 권한 DB 변경 시 시스템이 쏘는 분산 알림 — 비공개·비문서화 API지만 관례적으로 안정적.
    /// 미전달 대비: 온보딩 폴링(부여)과 메뉴 열림 시 상태 갱신(표시)이 이중 안전망.
    static let accessibilityAPINotification = Notification.Name("com.apple.accessibility.api")
    static let recheckDelay: TimeInterval = 0.5

    private let isTrusted: () -> Bool
    private let scheduler: Scheduling
    private let onChange: (Bool) -> Void
    private var lastKnown: Bool
    private var generation = 0

    init(isTrusted: @escaping () -> Bool,
         scheduler: Scheduling,
         onChange: @escaping (Bool) -> Void) {
        self.isTrusted = isTrusted
        self.scheduler = scheduler
        self.onChange = onChange
        self.lastKnown = isTrusted()
    }

    /// TCC 권한 DB가 변경됐다는 신호 (com.apple.accessibility.api). 얇은 셸이 호출한다.
    func accessibilityDatabaseChanged() {
        generation += 1
        let gen = generation
        scheduler.after(Self.recheckDelay) { [weak self] in
            guard let self, gen == self.generation else { return }  // 구세대 재확인 소멸
            let now = self.isTrusted()
            guard now != self.lastKnown else { return }
            self.lastKnown = now
            self.onChange(now)
        }
    }
}
