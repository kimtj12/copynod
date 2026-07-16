import Sparkle

/// Sparkle SPUStandardUpdaterController 래핑.
/// EdDSA 키 생성·appcast 발행은 M4 — 그 전까지 수동 확인은 서버 접근 실패가 정상.
final class UpdaterController {
    private let controller = SPUStandardUpdaterController(startingUpdater: true,
                                                          updaterDelegate: nil,
                                                          userDriverDelegate: nil)

    func checkForUpdates() {
        controller.checkForUpdates(nil)
    }
}
