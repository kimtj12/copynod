import Foundation

extension HUDPosition {
    /// 설정 창·메뉴바 서브메뉴 공용 표시 이름
    var label: String {
        switch self {
        case .nearCursor: String(localized: "Near Cursor")
        case .bottomCenter: String(localized: "Bottom Center")
        case .topRight: String(localized: "Top Right")
        }
    }
}
