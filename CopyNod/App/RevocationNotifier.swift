import Foundation
import UserNotifications

/// 권한 회수 시스템 알림 셸 — 메뉴바 아이콘을 숨긴 상태에서도 회수 사실이 보이도록 (planning.md 2.4).
/// 알림 클릭 시 시스템 설정의 손쉬운 사용 패널을 연다.
final class RevocationNotifier: NSObject, UNUserNotificationCenterDelegate {
    func notifyRevoked() {
        let center = UNUserNotificationCenter.current()
        center.delegate = self
        center.requestAuthorization(options: [.alert]) { granted, _ in
            guard granted else { return }
            let content = UNMutableNotificationContent()
            content.title = String(localized: "Accessibility permission revoked")
            content.body = String(localized: "CopyNod can no longer detect ⌘C. Click to re-enable it in System Settings.")
            center.add(UNNotificationRequest(identifier: "permission-revoked",
                                             content: content, trigger: nil))
        }
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                didReceive response: UNNotificationResponse,
                                withCompletionHandler completionHandler: @escaping () -> Void) {
        DispatchQueue.main.async { PermissionManager.openSystemSettings() }
        completionHandler()
    }
}
