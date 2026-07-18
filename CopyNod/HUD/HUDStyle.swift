import Foundation

/// HUD 스타일 옵션. String raw는 UserDefaults 저장용, CaseIterable은 설정 UI 열거용.
enum HUDStyle: String, CaseIterable {
    case classic
    case liquidGlass
    case inkRipple
}
