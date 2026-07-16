import AppKit
import ApplicationServices

/// Accessibility 권한 상태 확인·안내.
/// NSEvent global monitor는 권한이 없으면 조용히 실패하므로 이 확인 흐름이 필수.
enum PermissionManager {
    static var isTrusted: Bool { AXIsProcessTrusted() }

    /// 시스템 권한 프롬프트를 1회 띄운다 (최초 실행 시)
    static func requestTrust() {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
        AXIsProcessTrustedWithOptions(options)
    }

    static func openSystemSettings() {
        let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!
        NSWorkspace.shared.open(url)
    }
}
