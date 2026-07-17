# CopyNod 랜딩 페이지 — 기획 초안 + AI 디자인 에이전트 프롬프트

> 작성일: 2026-07-17 · 상태: 초안 (디자인 에이전트 전달 전)

## 1. 기획 초안

### 1.1 목적과 성공 기준

- **단일 목적**: 방문자가 30초 안에 "이게 뭔지" 이해하고 다운로드 버튼을 누르게 한다.
- 주 CTA: **Download for macOS** → GitHub Releases 최신 zip.
- 보조 CTA: **View on GitHub** (오픈소스·프라이버시 신뢰 근거).
- 전환 방해 요소(가입, 뉴스레터, 가격표)는 전부 없음 — 무료 오픈소스 앱이므로.

### 1.2 타깃과 톤

- 타깃: 맥 파워 유저·개발자. Accessibility 권한 요구에 민감하고, 상주 앱의 리소스 사용을 따지는 사람들.
- 톤: 앱과 동일하게 **조용하고 절제된** 톤. 과장("혁신적인", "생산성 10배") 금지. 사실만 짧게.
- 언어: **영어 + 한국어, v1부터 두 언어 모두 제공.** 영어 기본, 헤더에 EN/KO 토글 (첫 방문 시 브라우저 언어로 자동 선택). 앱이 두 언어를 지원하므로 랜딩도 동일하게.

### 1.3 페이지 구조 (섹션 순서)

| # | 섹션 | 내용 | 비고 |
|---|---|---|---|
| 1 | Hero | 앱 아이콘 + 한 줄 카피 + HUD 데모 + 다운로드 CTA | 데모는 체크마크가 그려지는 애니메이션 (CSS/SVG stroke-drawing 재현) |
| 2 | Problem | "⌘C 눌렀는데… 복사됐나?" — 붙여넣어 봐야만 아는 불안 | 짧게 2~3문장 |
| 3 | How it works | 키 입력은 트리거일 뿐, 클립보드 changeCount가 실제로 바뀌어야만 HUD 표시 → **오탐 없음** | 3단계 다이어그램 (⌘C → verify → ✓) |
| 4 | Privacy | 클립보드 **내용을 절대 읽지 않음** (정수 changeCount만 비교), 분석·수집 제로, 네트워크는 업데이트 확인뿐, MIT 오픈소스 | 신뢰가 이 앱의 핵심 셀링 포인트 |
| 5 | Lightweight | 유휴 CPU ~0%, 이벤트 기반(폴링 없음), 메모리 40MB 이하 | 수치 3개를 스탯 카드로 |
| 6 | Features | HUD 위치 3종 · 전체화면 위 표시 · click-through · 다크/라이트 · Liquid Glass(macOS 26+) · 영어+한국어 · Sparkle 자동 업데이트 | 아이콘 + 한 줄씩 그리드 |
| 7 | Install | 3단계: 다운로드 → Applications로 이동 → Accessibility 권한 허용 | 권한이 왜 필요한지("키 이벤트 관찰만, 수정·차단 없음") 명시 |
| 8 | FAQ | 아래 1.4 | 접이식 |
| 9 | Footer | GitHub · Releases · MIT License · "Made by …" | 최소한으로 |

### 1.4 FAQ 항목

- Why does it need Accessibility permission? — 전역 ⌘C/⌘X 키 관찰용. 키를 수정·차단하지 않으며 코드로 확인 가능.
- Does it read my clipboard? — 아니요. 내용이 아니라 변경 카운터(정수)만 비교.
- Does it work in full-screen apps? — 예, 모든 Space와 전체화면 위에 표시.
- What about battery? — 이벤트 기반. 유휴 시 폴링 0회, ⌘C 직후 최대 300ms만 검증.
- Is it a clipboard manager? — 아니요. 히스토리·저장 기능 없음 (의도적 비목표).
- Which macOS versions? — macOS 14+. 26+에서는 Liquid Glass 재질.

### 1.5 카피 초안 (Hero)

**영어:**

- Headline: **"Did that actually copy?"** 또는 **"Know your ⌘C worked. Instantly."**
- Sub: "A tiny menu bar utility that shows a check mark **only when ⌘C actually copied something** — so you never paste just to find out."
- CTA: `Download for macOS` + 밑에 작은 글씨 "Free · Open source · macOS 14+"

**한국어:**

- Headline: **"방금 그거, 복사됐을까?"** 또는 **"⌘C가 먹었는지, 바로 알 수 있게."**
- Sub: "⌘C로 **실제로 복사됐을 때만** 체크 표시를 띄워주는 작은 메뉴바 유틸리티 — 확인하려고 붙여넣어 볼 필요가 없습니다."
- CTA: `macOS용 다운로드` + "무료 · 오픈소스 · macOS 14+"

### 1.6 디자인 방향

- **macOS 네이티브 감성**: 시스템 폰트(SF Pro 계열), Liquid Glass/frosted-glass 재질감, 절제된 여백 중심 레이아웃. Apple 제품 페이지 결의 미니멀리즘.
- 다크 모드 기본(HUD 데모가 돋보임) + 라이트 모드 대응.
- 액센트 컬러는 체크마크 그린 계열 하나만. 나머지는 무채색.
- 히어로의 HUD 데모가 페이지의 유일한 모션 — 체크 stroke-drawing 애니메이션을 반복 재생. 그 외 과한 스크롤 애니메이션 금지.
- 반응형이되 모바일에선 다운로드 CTA 대신 "Send link to your Mac" 성격의 안내도 고려 (v1은 단순히 동일 페이지).

### 1.7 기술 메모 (구현 시)

- 정적 페이지 1장. GitHub Pages 호스팅 상정 (appcast와 같은 채널).
- **i18n**: 빌드 도구 없는 정적 페이지이므로 문자열을 JS 사전(en/ko) 하나로 관리하고 토글 시 교체하는 단순 방식. 선택 언어는 `localStorage`에 저장, 최초 방문은 `navigator.language`로 결정. `<html lang>` 속성도 함께 갱신.
- 다운로드 버튼은 `https://github.com/kimtj12/copynod/releases/latest` 링크로 시작 (버전 하드코딩 회피).
- 에셋: 앱 아이콘(확정본), HUD 스크린샷/녹화, 메뉴바 드롭다운 스크린샷.

## 2. AI 디자인 에이전트 프롬프트

아래를 그대로 붙여넣어 사용. (디자인 도구 호환성을 위해 영어로 작성.)

---

Design a single-page landing site for **CopyNod**, a free, open-source macOS menu bar utility.

**What the app does:** When you press ⌘C or ⌘X on a Mac, there's no visual feedback that the copy actually worked — people paste just to check. CopyNod shows a small, elegant check-mark HUD near your cursor **only when the clipboard actually changed**. No false positives. It never reads clipboard contents (it only compares an integer change counter), collects zero analytics, uses ~0% idle CPU, and is MIT-licensed open source.

**Audience:** Mac power users and developers — skeptical, privacy-conscious people who scrutinize apps that ask for Accessibility permission.

**Tone:** Quiet, precise, understated — like the app itself. No hype words, no exclamation marks. Short factual sentences.

**Visual direction:**
- Apple-product-page minimalism: generous whitespace, large type, system font stack (SF Pro feel).
- Dark mode as the default look (with a light variant), monochrome palette with a single green accent used only for the check mark.
- Frosted-glass / "Liquid Glass" material touches echoing macOS 26 — e.g., the HUD badge and cards use translucent blur.
- The hero centerpiece is a looping demo of the HUD: a circular translucent badge in which a check mark **draws itself** (SVG stroke animation, ~0.25s draw, hold, fade out — total ~1s, then loop with a pause). This is the only significant motion on the page; no scroll-triggered animation elsewhere.

**Page structure (in order):**
1. **Hero** — app icon, headline "Did that actually copy?", subline "A tiny menu bar utility that shows a check mark only when ⌘C actually copied something — so you never paste just to find out." Primary button "Download for macOS" (links to GitHub latest release), secondary text link "View on GitHub". Small print: "Free · Open source · macOS 14+". The HUD demo animation sits beside or below the headline.
2. **Problem** — two sentences about the silent-⌘C anxiety: pressing copy, not being sure, pasting just to check, copying three times "to be safe".
3. **How it works** — a simple 3-step horizontal diagram: "⌘C pressed (trigger)" → "clipboard change verified (~300ms window)" → "check HUD shown". Caption: "A keypress is only a trigger. The HUD appears only after the clipboard change counter actually changes — nothing copied, nothing shown."
4. **Privacy** — the trust section, visually distinct. Four short points: never reads clipboard contents (only an integer counter); no analytics, no crash reporting, no data collection; only network access is a daily update check; open source under MIT — verify it yourself. Include a "Read the source" link.
5. **Lightweight** — three stat cards: "~0% idle CPU", "0 polling while idle (event-driven)", "< 40 MB memory".
6. **Features grid** — six small items with simple line icons: three HUD positions (near cursor / bottom center / top right); works over full-screen apps; click-through, never steals focus; light & dark aware; Liquid Glass on macOS 26+ (native HUD fallback on 14–15); auto-updates via Sparkle; English & Korean.
7. **Install** — three numbered steps: download & move to Applications; grant Accessibility permission ("CopyNod only observes ⌘C/⌘X key events — it never modifies or blocks them"); optionally enable Launch at Login.
8. **FAQ** — collapsible items: Why Accessibility permission? / Does it read my clipboard? / Does it drain battery? / Is it a clipboard manager? (No — deliberately not.) / Which macOS versions?
9. **Footer** — GitHub, Releases, MIT License. Minimal.

**Localization (required in v1):**
- The page ships in **English and Korean**. English is the default; a small **EN / KO toggle** lives in the top-right corner (next to nothing else — there is no nav bar).
- On first visit, auto-select the language from the browser locale; persist the user's choice in `localStorage`. Update `<html lang>` accordingly.
- All copy — headlines, body, FAQ, button labels, small print — must exist in both languages. Keep the two versions equivalent in tone: quiet and factual, no hype in either language.
- Korean hero copy to use: headline "방금 그거, 복사됐을까?", subline "⌘C로 실제로 복사됐을 때만 체크 표시를 띄워주는 작은 메뉴바 유틸리티 — 확인하려고 붙여넣어 볼 필요가 없습니다.", button "macOS용 다운로드", small print "무료 · 오픈소스 · macOS 14+". Translate the remaining sections in the same register (해요체 대신 건조한 합쇼체/명사형, no exclamation marks).
- Design must tolerate both languages' text lengths — Korean lines run shorter but wrap differently; don't hard-size text containers.

**Constraints:**
- Single static page, responsive, no signup/newsletter/pricing elements anywhere.
- No build tooling assumed — implement the toggle with a single inline JS string dictionary (en/ko).
- Keep total copy sparse — this page should feel like it takes 30 seconds to read.
- Placeholder assets are fine for the app icon and screenshots; mark their slots clearly.

---

## 3. 프롬프트에 함께 첨부하면 좋은 에셋

- 앱 아이콘 PNG (저장소 루트 `icon-concept-final.png` 또는 확정 아이콘 익스포트)
- HUD 실제 스크린샷 또는 화면 녹화 (다크/라이트 각 1장)
- 메뉴바 드롭다운 스크린샷 1장
