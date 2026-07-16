import Foundation
import Combine

/// UserDefaults 래핑 설정 저장소.
/// 로그인 자동 실행은 여기 저장하지 않는다 — SMAppService.status가 단일 소스 (issue #2).
final class SettingsStore: ObservableObject {
    static let hudPositionKey = "hudPosition"
    static let hideMenuBarIconKey = "hideMenuBarIcon"

    private let defaults: UserDefaults

    @Published var hudPosition: HUDPosition {
        didSet { defaults.set(hudPosition.rawValue, forKey: Self.hudPositionKey) }
    }

    @Published var hideMenuBarIcon: Bool {
        didSet { defaults.set(hideMenuBarIcon, forKey: Self.hideMenuBarIconKey) }
    }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        // 오염된 값은 기본값으로 폴백
        hudPosition = defaults.string(forKey: Self.hudPositionKey)
            .flatMap(HUDPosition.init(rawValue:)) ?? .nearCursor
        hideMenuBarIcon = defaults.bool(forKey: Self.hideMenuBarIconKey)
    }
}
