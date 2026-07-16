import Foundation
import ServiceManagement
import os

/// 로그인 자동 실행 — SMAppService.status가 단일 소스라 별도 저장하지 않는다 (issue #2)
enum LaunchAtLogin {
    static var isEnabled: Bool { SMAppService.mainApp.status == .enabled }

    static func set(_ enabled: Bool) {
        do {
            if enabled {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
        } catch {
            // 실패 시 조용히 실제 상태 유지 — UI는 다음 조회에서 실상을 반영한다
            Logger(subsystem: Bundle.main.bundleIdentifier ?? "CopyNod", category: "LaunchAtLogin")
                .error("register/unregister failed: \(error.localizedDescription)")
        }
    }
}
