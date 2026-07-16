# CopyNod — 백로그

> 이번 구현 범위(M1+M2) 이후의 작업. 2026-07-17 기준.

## M3 — 설정 (완료 — 2026-07-17, 스펙: #2)

- [x] 설정 창 (SwiftUI): HUD 위치 3종, 로그인 자동 실행, 메뉴바 아이콘 숨기기, 업데이트 확인
- [x] 메뉴바 드롭다운 메뉴 완성 (위치 서브메뉴 라디오, 자동 실행 토글, 설정 열기, Check for Updates, 종료)
- [x] 메뉴바 아이콘 숨김 모드 + 앱 재실행(`applicationShouldHandleReopen`) → 설정 창 패턴
- [x] HUD 위치 옵션 2종 추가 구현 (하단 중앙, 우상단 — 멀티 모니터: 커서가 있는 화면 기준)
- [x] `SMAppService.mainApp` 로그인 자동 실행
- [x] 로컬라이제이션 마무리 (String Catalog 영어/한국어 전체 검수)
- 참고: Sparkle 2 통합(SPM, `SPUStandardUpdaterController`, `SUFeedURL`)은 M3에서 선반영 — M4에는 EdDSA 키·appcast 발행만 남음

## M4 — 마감·배포

- [ ] 엣지 케이스 마감: 키 반복 디바운스, 연속 복사, 멀티 모니터 검증
- [ ] 권한 회수 감지 → 아이콘 경고 배지 + 시스템 알림
- [ ] 배터리 예산 검증: Activity Monitor Energy Impact / Idle Wake Ups, `powermetrics`
- [ ] **Developer ID Application 인증서 발급** (계정은 있음, 인증서는 키체인에 없음 — 2026-07-17 확인)
- [ ] notarization 파이프라인 (`notarytool`)
- [ ] Sparkle: EdDSA 키 생성, appcast 호스팅(GitHub Pages 또는 Releases), 업데이트 플로우 테스트
- [ ] GitHub Releases 릴리스 (zip 또는 DMG)
- [ ] README: 기능·설치·프라이버시("네트워크 접근은 업데이트 확인뿐, 클립보드 내용을 읽지 않음") + MIT LICENSE 파일

## 보류된 결정

- [ ] **앱 아이콘 확정** — 시안 4종: [icon-concepts.html](icon-concepts.html) (아티팩트: https://claude.ai/code/artifact/f64122a0-6f9e-4dd2-a166-5bb4f280f51d ). 확정 후: 레이어 분리 → Icon Composer로 26+ Liquid Glass `.icon` 제작 + 14~15용 폴백 에셋(asset catalog) 두 벌.

## v1 이후 아이디어 (약속 아님)

- [ ] 잘라내기(⌘X) 구분 표시 — 가위 아이콘 등 (v1은 복사와 동일한 체크 HUD)
- [ ] Homebrew cask 등재 (오픈소스+notarized면 요건 충족 용이)
- [ ] 감지 계층 CGEventTap(`.defaultTap`) 승격 — 실사용에서 false negative(HUD 안 뜸)가 체감될 때. `CopyDetector` 프로토콜 뒤로 격리해둔 이유 (planning.md 3.2)
- [ ] 추가 언어 (String Catalog 구조라 구조 변경 없이 가능)
- [ ] 랜딩 페이지 / 웹사이트
- [ ] 유료 Pro 기능 검토 (위치 커스텀 등) — v1 검증 이후에만
