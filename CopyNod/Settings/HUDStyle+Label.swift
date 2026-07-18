import Foundation

extension HUDStyle {
    /// 설정 창 표시 이름
    var label: String {
        switch self {
        case .classic: String(localized: "Classic")
        case .liquidGlass: String(localized: "Liquid Glass")
        case .inkRipple: String(localized: "Ink Ripple")
        }
    }
}
