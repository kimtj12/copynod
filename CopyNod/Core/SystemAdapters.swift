import AppKit

/// 실제 시스템 파스트보드 어댑터 — 내용은 읽지 않고 changeCount 정수만 본다.
final class GeneralPasteboard: PasteboardChangeCounting {
    var changeCount: Int { NSPasteboard.general.changeCount }
}

/// 메인 스레드 스케줄러 어댑터
struct MainScheduler: Scheduling {
    func after(_ delay: TimeInterval, _ action: @escaping () -> Void) {
        DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: action)
    }
}
