import AppKit

// 최상위 코드는 메인 스레드에서 실행된다 — MainActor 격리 명시
MainActor.assumeIsolated {
    let delegate = AppDelegate()
    NSApplication.shared.delegate = delegate
    NSApplication.shared.run()
}
