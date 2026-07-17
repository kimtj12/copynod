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

## 후속 — HUD 스타일 팩 (2026-07-17 등록)

> **방향**: 하나의 "정답" HUD를 고르는 대신, 여러 스타일을 구현해 설정에서 사용자가 선택하게 한다.
> 현재의 원형 배지+체크는 "클래식" 스타일로 유지. 모든 스타일은 공통 원칙을 지킨다 —
> 클립보드 내용을 읽지 않음(`changeCount`만), 클릭 스루, 포커스 안 뺏음, 짧고 방해 없음.
> 아키텍처: HUDPresenter/Positioner는 공유하고 스타일별 뷰(HUDView 프로토콜화)만 교체하는 구조가 목표.

- [x] **잉크 리플 (Ink Ripple)** — 배지 없이 커서 지점에서 얇은 링이 물결처럼 한 번 퍼지고 소멸 (~0.4s). 링 반경 0→48pt 확장 + 두께 감소 + 페이드, 중앙에 작은 체크 잔상. 가장 미니멀한 스타일. (2026-07-17 구현 — `InkRippleView`. 커서 근처 모드는 커서 정중앙 센터링·클램핑 없음, 고정 위치는 배지 중심과 동일 지점. 재생 중 재트리거는 무시. 링·체크는 labelColor)
- [ ] **스탬프 (도장)** — 도장이 "쾅" 찍히는 연출: 스케일 1.4→1.0 스프링 + 미세 회전(-4°) + 잉크 번짐. 낙관 도장 감성으로 브랜드 확장 가능. ⌘X는 색/모양을 다르게 해 복사·잘라내기 구분 (v1 이후 아이디어의 "⌘X 구분 표시"와 연계).
- [ ] **노치 캡슐 (Dynamic Island 스타일)** — 맥북 노치 좌우로 캡슐이 확장됐다 접힘 (스프링, 좌우 ~40pt, 체크 아이콘만, 0.6s 후 접힘). 노치 없는 모니터는 상단 중앙 미니 캡슐 폴백. 시선 위치가 항상 일정. 노치 영역 창 배치 구현 난도 조사 필요.
- [ ] **흡수 (Absorb)** — 커서 지점에서 작은 종이 조각이 접히며 메뉴바 CopyNod 아이콘으로 날아가 흡수, 아이콘이 한 번 바운스 (0.5~0.7s). 가장 화려한 "시네마틱" 스타일 — 데모·랜딩 임팩트 최대. 메뉴바 아이콘 숨김 모드일 때의 폴백 동작 결정 필요.
- [ ] **커서 오라 (Cursor Aura)** — 커서를 감싸는 얇은 발광 링(~28pt)이 0.3s 나타났다 소멸. 시선 이동 0. 리플과 결합(오라 발생 → 리플로 퍼지며 소멸)하는 변형도 검토.
- [ ] 스타일 선택 UI: 설정에 스타일 피커 추가 + 선택 시 샘플 HUD 1회 표시 (위치 미리보기 항목과 같은 메커니즘 공유) — 피커(설정 창 라디오, `HUDStyle` enum)는 2026-07-17 잉크 리플과 함께 완료. 샘플 HUD 1회 표시만 남음

## 후속 — 웹·모니터링 (2026-07-17 등록)

- [x] GitHub Pages 랜딩 페이지 — 소개·다운로드 페이지 제작 완료 (2026-07-17)
- [x] 다운로드 추적 — GitHub Actions cron(일 1회)이 Releases API `download_count`를 `data/downloads.csv`에 스냅샷(변화 없으면 커밋 생략) + README 다운로드 배지 (2026-07-17)
- [ ] MAU 근사 추적 — **방향 확정, 착수 보류** (2026-07-17 논의): 앱 내 텔레메트리 없이, Sparkle의 일 1회 appcast 요청을 Cloudflare Worker 프록시로 집계 (요청 수 ≈ DAU). `SUFeedURL` 1줄 변경 + 프라이버시 문구 1줄 추가 필요. README의 "no data collection" 약속과 충돌하는 앱 내 애널리틱스(옵트아웃 MAU 수집)는 하지 않기로 결정
- [ ] Sentry 연동 — 크래시·에러 데이터 수집 (sentry-cocoa SPM). 프라이버시 문구(README·랜딩)와 정합 확인 필요 — "no crash reporting" 약속과 충돌하므로 도입 시 옵트인 여부 등 재논의

## 보류된 결정

- [x] **앱 아이콘 확정** — 시안 4종: [icon-concepts.html](icon-concepts.html) (아티팩트: https://claude.ai/code/artifact/f64122a0-6f9e-4dd2-a166-5bb4f280f51d ). 확정 후: 레이어 분리 → Icon Composer로 26+ Liquid Glass `.icon` 제작 + 14~15용 폴백 에셋(asset catalog) 두 벌.

## v1 이후 아이디어 (약속 아님)

- [ ] 잘라내기(⌘X) 구분 표시 — 가위 아이콘 등 (v1은 복사와 동일한 체크 HUD)
- [ ] Homebrew cask 등재 (오픈소스+notarized면 요건 충족 용이)
- [ ] 감지 계층 CGEventTap(`.defaultTap`) 승격 — 실사용에서 false negative(HUD 안 뜸)가 체감될 때. `CopyDetector` 프로토콜 뒤로 격리해둔 이유 (planning.md 3.2)
- [ ] 추가 언어 (String Catalog 구조라 구조 변경 없이 가능)
- [ ] 유료 Pro 기능 검토 (위치 커스텀 등) — v1 검증 이후에만
