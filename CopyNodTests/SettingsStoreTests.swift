import Testing
import Foundation
@testable import CopyNod

// 시임 3 (M3): SettingsStore — UserDefaults 주입으로 기본값·왕복·오염 폴백을 검증.
struct SettingsStoreTests {
    private func makeDefaults() -> UserDefaults {
        let suite = "test.copynod.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defaults.removePersistentDomain(forName: suite)
        return defaults
    }

    @Test("첫 실행 기본값: 커서 근처, 메뉴바 아이콘 표시")
    func firstRunDefaults() {
        let store = SettingsStore(defaults: makeDefaults())
        #expect(store.hudPosition == .nearCursor)
        #expect(store.hideMenuBarIcon == false)
    }

    @Test("설정 왕복: 저장한 값을 새 인스턴스가 그대로 읽는다")
    func settingsRoundTrip() {
        let defaults = makeDefaults()
        let store = SettingsStore(defaults: defaults)
        store.hudPosition = .bottomCenter
        store.hideMenuBarIcon = true
        let reloaded = SettingsStore(defaults: defaults)
        #expect(reloaded.hudPosition == .bottomCenter)
        #expect(reloaded.hideMenuBarIcon == true)
    }

    @Test("오염된 위치 설정값은 기본값(커서 근처)으로 폴백한다")
    func corruptPositionFallsBackToDefault() {
        let defaults = makeDefaults()
        defaults.set("garbage", forKey: SettingsStore.hudPositionKey)
        let store = SettingsStore(defaults: defaults)
        #expect(store.hudPosition == .nearCursor)
    }
}
