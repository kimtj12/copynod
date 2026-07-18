# CopyNod

macOS 메뉴바 앱 — ⌘C/⌘X 복사 성공 시 HUD를 띄운다. 설계·결정 기록은 docs/ 참조
(planning.md, decisions.md, detection-race-solutions.md).

## ⚠️ TCC(손쉬운 사용) 권한 꼬임 주의

같은 번들 ID(`kr.ai.simpool.CopyNod`)의 빌드라도 **서명이 다르면**(Apple Development,
ad-hoc 등) 실행하는 순간 TCC가 손쉬운 사용 권한을 조용히 무효화한다. 시스템 설정에는
켜진 것으로 보이지만 키 이벤트가 차단되어 HUD가 안 뜨고 verify 로그도 0건이 된다
(2026-07-17 실제 장애 원인).

- **개발 실행은 반드시 `scripts/run-dev.sh`** — 설치본과 같은 Developer ID 서명으로
  archive → export 후 실행하므로 권한이 안 꼬인다.
- **Xcode에서 직접 Run 금지** (Debug는 Apple Development, Release는 ad-hoc 서명).
  DerivedData에 남은 산출물을 실행해도 같은 문제가 생긴다.
- 평상시 실행은 `/Applications/CopyNod.app` 하나만 (`open -a CopyNod`).
- 이미 꼬였다면: `scripts/reset-accessibility.sh` 또는
  `tccutil reset Accessibility kr.ai.simpool.CopyNod` 후 설치본을 재실행하고 권한 재부여.
- 증상 진단: `/usr/bin/log stream --predicate 'subsystem == "kr.ai.simpool.CopyNod"' --level debug`
  에서 ⌘C를 눌러도 아무 줄이 안 찍히면 이벤트 미도달이다. 원인은 권한 꼬임 외에
  잠자기 복귀 후 모니터 사망도 있다(2026-07-18 장애) — 전체 진단 절차는 docs/debugging.md.
  zsh에서는 `log`가 셸 내장 명령이므로 반드시 `/usr/bin/log`로 실행할 것.

## 빌드 산출물

- `build/`는 gitignore된 로컬 산출물. 릴리스 zip·delta는 GitHub Releases가 원본이므로
  로컬 사본은 지워도 된다.
- 단, `build/CopyNod.xcarchive`(최신 릴리스 아카이브)는 크래시 심볼화용 dSYM이 들어
  있으므로 남겨둔다.
