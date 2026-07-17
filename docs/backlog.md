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

## M4 — 마감·배포 (코드·문서 완료 — 2026-07-17, 남은 항목은 사용자 수동 단계)

- [x] 엣지 케이스 마감: 키 반복 디바운스, 연속 복사, 멀티 모니터 클램핑 — M1~M2에서 구현·단위 테스트 완료임을 재확인 (실기기 멀티 모니터 확인은 "후속 — HUD 디자인·위치" 항목과 병행)
- [x] 권한 회수 감지 → 아이콘 경고 배지 + 시스템 알림 (`PermissionWatcher` — TCC 분산 알림 기반, 상시 폴링 없음. 알림 클릭 시 시스템 설정 열림)
- [x] 배터리 예산 검증 — 2026-07-17 사용자 실행, 문제 없음 확인 (절차: [release.md](release.md))
- [x] **Developer ID Application 인증서** — 배포 명의를 SIMPOOL Inc. (RC348YTD6U)로 확정, 기존 인증서 사용 (2026-07-17). notarytool 자격 증명(`copynod-notary`)도 저장 완료
- [x] notarization 파이프라인 — `scripts/release.sh` (archive → export → notarize → staple → appcast). 실행은 인증서·자격 증명 설정 후
- [x] Sparkle EdDSA 키 생성 (로그인 키체인, 공개 키는 project.yml — **키체인 백업 필수**). appcast 발행·업데이트 플로우 테스트는 첫 릴리스 때
- [x] GitHub Releases 릴리스 (zip) — v0.1.0 발행 완료 (2026-07-17, notarize·staple·appcast 포함)
- [x] README(기능·설치·프라이버시) + MIT LICENSE

## 후속 — HUD 디자인·위치 세부 조정 (2026-07-17 실사용 피드백에서 등록)

- [ ] HUD 룩 폴리시: 배지 크기(현재 64pt)·체크 선 굵기·애니메이션 타이밍(드로잉 0.25s / 표시 0.75s / 페이드 아웃 0.25s) 실사용 기준 재조정, 26+ Liquid Glass vs 14~15 폴백 룩 비교 검수
- [ ] 위치 상수 튜닝: 커서 오프셋(16pt), 하단 중앙 높이(100pt), 우상단 여백(16/80pt), 가장자리 클램핑 여백(8pt) — `HUDPositioner` 상수라 테스트 기대값과 함께 조정
- [ ] 위치 미리보기: 설정에서 위치를 바꾸면 샘플 HUD를 1회 표시해 즉시 확인

## 후속 — 웹·모니터링 (2026-07-17 등록)

- [ ] GitHub Pages 랜딩 페이지 — 저장소 Pages로 소개·다운로드 페이지 제작. 다운로드 트래킹 포함 (GitHub Releases API의 asset `download_count` 집계 또는 Pages에 경량 애널리틱스 붙이기 — 방식 결정 필요)
- [ ] Sentry 연동 — 크래시·에러 데이터 수집 (sentry-cocoa SPM). 프라이버시 문구(README·랜딩)와 정합 확인 필요

## 보류된 결정

- [x] **앱 아이콘 확정** — 시안 4종: [icon-concepts.html](icon-concepts.html) (아티팩트: https://claude.ai/code/artifact/f64122a0-6f9e-4dd2-a166-5bb4f280f51d ). 확정 후: 레이어 분리 → Icon Composer로 26+ Liquid Glass `.icon` 제작 + 14~15용 폴백 에셋(asset catalog) 두 벌.

## v1 이후 아이디어 (약속 아님)

- [ ] 잘라내기(⌘X) 구분 표시 — 가위 아이콘 등 (v1은 복사와 동일한 체크 HUD)
- [ ] Homebrew cask 등재 (오픈소스+notarized면 요건 충족 용이)
- [ ] 감지 계층 CGEventTap(`.defaultTap`) 승격 — 실사용에서 false negative(HUD 안 뜸)가 체감될 때. `CopyDetector` 프로토콜 뒤로 격리해둔 이유 (planning.md 3.2)
- [ ] 추가 언어 (String Catalog 구조라 구조 변경 없이 가능)
- [ ] 유료 Pro 기능 검토 (위치 커스텀 등) — v1 검증 이후에만
