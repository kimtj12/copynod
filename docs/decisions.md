# CopyNod — 결정 기록

> 2026-07-17 그릴링 세션에서 확정한 결정들. 각 항목은 "결정 / 근거 / 기각한 대안" 순.

## D1. 배포 방식: 공개 배포

- **결정**: Developer ID 서명 + notarization으로 공개 배포. App Store는 Accessibility 권한의 샌드박스 제약으로 불가.
- **근거**: 개인용을 넘어 공개할 가치가 있다고 판단.
- **기각**: 개인 사용(개발자 서명만).
- **상태 메모**: Apple Developer 유료 멤버십 보유 확인. 단, 키체인에 Developer ID Application 인증서는 미발급 상태 — 배포 단계(M4)에서 발급 필요.

## D2. 최소 지원 버전: macOS 14+, Liquid Glass는 26+ 분기

- **결정**: macOS 14 (Sonoma) 이상 지원. HUD 배경 재질만 `#available(macOS 26.0, *)` 분기 — 26+는 `NSGlassEffectView`(Liquid Glass), 미만은 `NSVisualEffectView` + `.hudWindow`.
- **근거**: Liquid Glass API는 26 전용이지만 분기 지점이 HUD 배경 뷰 한 곳뿐이라 폴백 비용이 작고, 커버리지 이득이 큼. 기술적 하한은 `SMAppService`의 13이지만, 검증 불가능한 OS를 지원 목록에 올리지 않기 위해 14로.
- **기각**: 13+ (미검증 부담), 26+ 단일 타깃 (커버리지 손실).

## D3. 저장소: 별도 repo `~/github/copynod`

- **결정**: workspace에서 분리해 독립 git 저장소로. 사용자가 직접 생성 예정.
- **근거**: 공개 배포 앱은 git 이력·GitHub Releases·태그 릴리스가 필요 — workspace 규칙("outgrow하면 분리")에 정확히 해당.

## D4. 빌드: XcodeGen + xcodebuild

- **결정**: `project.yml`로 프로젝트 선언, `.xcodeproj`는 생성물.
- **근거**: 프로젝트 설정이 리뷰 가능한 텍스트로 남고, CLI 주도 개발에 적합. XcodeGen이 로컬에 이미 설치돼 있음.
- **기각**: 손으로 만든 .xcodeproj (diff 불가), SwiftPM + 수동 번들 조립 (서명·리소스 스크립트 유지 부담).

## D5. 이름: CopyNod

- **결정**: 앱 이름 CopyNod.
- **근거**: 사용자의 행위("copy")와 일치하고, ClipNod와 달리 클립보드 매니저로 오인될 "Clip" 네임스페이스를 회피. 웹·앱스토어·GitHub 충돌 검증 완료 (2026-07-17 기준 동명 앱·저장소 없음).
- **기각**: ClipNod (Clip* 포화 + 비목표와 충돌하는 인상), CopyWink, Chak(착), Jjan(짠) 등 후보군.

## D6. 번들 ID: `kr.ai.simpool.CopyNod`

- **결정**: simpool.ai.kr 도메인 기반 역DNS.
- **메모**: 번들 ID는 첫 공개 릴리스 후 변경 시 사용자의 Accessibility 권한·로그인 항목이 리셋되는 가장 바꾸기 어려운 값. 릴리스 전까지만 변경 가능.

## D7. 앱 아이콘: 보류

- **결정**: 시안 4종(HUD 미니어처 / 끄덕이는 클립보드 / ⌘C 레터마크 / 끄덕이는 HUD) 제작 후 결정 보류. 개발은 플레이스홀더 아이콘으로 진행.
- **시안**: [icon-concepts.html](icon-concepts.html) (아티팩트: https://claude.ai/code/artifact/f64122a0-6f9e-4dd2-a166-5bb4f280f51d )
- **참고**: 당시 추천은 D안(끄덕이는 HUD) — 배경/패널 2레이어 구조가 Icon Composer의 Liquid Glass 합성과 정합.

## D8. 업데이트: Sparkle 2 내장

- **결정**: 자동 업데이트. appcast는 GitHub 호스팅, EdDSA 키는 M4에서 생성.
- **근거**: "설치하고 잊어버리는 앱"에서 초기 버그 픽스 전달력이 중요. 주기 체크 1일 1회라 유휴 예산에 영향 없음.
- **기각**: 수동 확인만 (핵심 가치와 모순), 업데이트 없음 (공개 배포에서 위험).

## D9. 라이선스·가격: MIT 오픈소스, 무료

- **결정**: 코드 공개(MIT), 무료 배포.
- **근거**: "클립보드를 읽지 않는다"는 프라이버시 주장을 코드로 증명. Accessibility 권한을 요구하는 앱의 신뢰 확보에 결정적. Homebrew cask 등재에도 유리.
- **기각**: 비공개+무료 (신뢰 스토리 약함), 유료 (판매 인프라가 v1 철학 초과 — 추후 Pro 기능 경로는 열려 있음).

## D10. 로컬라이제이션: 영어 기본 + 한국어

- **결정**: String Catalog(`.xcstrings`)로 v1부터 두 언어.
- **근거**: 사용자 노출 문자열이 극히 적어(메뉴·온보딩·설정 라벨, HUD는 텍스트 없음) 추가 비용이 사실상 0. 개발자 본인이 한국어 사용자.

## D11. 메뉴바 아이콘·설정 UI

- **결정**: 메뉴바 아이콘 **기본 표시 + "숨기기" 설정**. 얇은 드롭다운 메뉴 + 작은 SwiftUI 설정 창 1개. 숨김 상태에서는 앱 재실행(`applicationShouldHandleReopen`)으로 설정 창 접근. 권한 회수 경고는 아이콘 배지 + 시스템 알림.
- **근거**: 개발자 본인은 메뉴바 아이콘을 선호하지 않지만, 전역 키 감시 권한을 가진 앱이 완전히 안 보이면 공개 배포에서 신뢰 문제 발생 → 기본은 표시, 원하는 사람만 숨김. 숨김 모드가 존재하므로 설정 창이 필요해짐 (메뉴 단독안 폐기).
- **기각**: 완전 헤드리스 (신뢰 문제), 상태 기반 아이콘 출현 (비표준 UX), 메뉴 드롭다운 단독 (숨김 모드와 양립 불가).

## D12. 텔레메트리: 없음

- **결정**: 분석 SDK·크래시 리포터 미포함. 네트워크 접근은 Sparkle 업데이트 체크가 유일 — README에 명시.
- **근거**: 오픈소스 + "아무것도 안 보냄"이 제품 정체성. 크래시 진단은 macOS 로컬 크래시 리포트 + GitHub 이슈로 충분.

## D13. 구현 범위: 이번엔 M1+M2

- **결정**: 코어 파이프라인(M1)과 HUD(M2)까지 구현 후 실기기 검증에서 멈춤. M3(설정)·M4(마감·배포)는 [backlog.md](backlog.md).
- **근거**: 기술 리스크(권한, 레이스, changeCount)가 M1~M2에 몰려 있고, 검증하려면 어차피 권한 부여로 한 번 멈춰야 함. 그 지점에서 동작+룩을 한 번에 확인.

## D14. 구현 노트 (결정이라기보다 합의된 세부)

- ⌘C/⌘X 판정은 keyCode가 아닌 **문자 기반**(`charactersIgnoringModifiers`) — 비QWERTY 레이아웃 대응.
- 테스트 시임 초안: "트리거 in → HUD 요청 out" 파이프라인 하나 + 순수 함수 `HUDPositioner` (planning.md 3.6, /to-spec에서 확정).

## D15. 감지 baseline: 시점 샘플 → 워터마크 + ⌘-down arm (2026-07-17)

- **결정**: `CopyVerifier`의 기준점을 keyDown 시점 샘플에서 영속 워터마크(`lastAccounted`)로 전환. `flagsChanged`에서 ⌘가 새로 눌릴 때 arm하되 배달 지연 ≥30ms면 스킵(오류를 항상 덜 해로운 FP 쪽으로), 판정 후 남은 창은 조용한 흡수로 정산. 검증 창 300ms→~1s(20회), 체인 소진·arm 스킵·즉시 판정은 os_log(debug) 진단. 상세 분석·잔여 오류 표: [detection-race-solutions.md](detection-race-solutions.md).
- **근거**: 실사용 false negative 체감 ~20% — global monitor 비동기 전달 레이스로 baseline이 이미 "복사 후" 값이 되는 문제. 워터마크 단독은 planning.md 3.2의 금지 우회책(FP 창 무한)이라 기각 유지가 타당하나, ⌘-down arm이 FP 창을 ⌘-hold sub-second로 줄여 금지 사유가 해소됨. `CopyVerifier` 계층의 변경이라 감지 API와 무관 — MAS listen-only 경로에도 그대로 적용.
- **기각**: active CGEventTap 승격 (시스템 전역 키 입력 경로 개입 + 탭 재활성화 운영 부담, 워터마크+arm으로 불필요 — backlog에서 제거), changeCount 상시 폴링 1차 신호 (상시 폴링 회피 원칙·"⌘C에 대한 반응" 정체성과 충돌. 단 Accessibility 권한을 통째로 없앨 수 있다는 전략적 가치는 별도 논의로 보류 — detection-race-solutions.md 6절).
