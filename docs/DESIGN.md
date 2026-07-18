---
name: CopyNod
description: 복사가 실제로 됐을 때만 체크를 띄우는 macOS 유틸리티의 랜딩 — macOS의 재질을 그대로 입는 디자인 시스템
colors:
  verified-green: "#32d74b"
  verified-green-light: "#34c759"
  ink: "#f5f5f7"
  ink-secondary: "#EBEBF599"
  ink-tertiary: "#EBEBF559"
  midnight: "#0a0a0c"
  hairline: "#FFFFFF1A"
  panel: "#FFFFFF0A"
  glass: "#1E1E248C"
  keycap-fill: "#FFFFFF12"
  ink-light: "#1d1d1f"
  ink-light-secondary: "#1D1D1F9E"
  ink-light-tertiary: "#1D1D1F61"
  porcelain: "#fbfbfd"
  hairline-light: "#0000001A"
  panel-light: "#00000008"
typography:
  display:
    fontFamily: "-apple-system, BlinkMacSystemFont, 'SF Pro Display', 'SF Pro Text', 'Helvetica Neue', 'Apple SD Gothic Neo', sans-serif"
    fontSize: "clamp(40px, 7vw, 64px)"
    fontWeight: 700
    lineHeight: 1.05
    letterSpacing: "-0.025em"
  headline:
    fontFamily: "-apple-system, BlinkMacSystemFont, 'SF Pro Display', 'SF Pro Text', 'Helvetica Neue', 'Apple SD Gothic Neo', sans-serif"
    fontSize: "32px"
    fontWeight: 700
    letterSpacing: "-0.02em"
  title:
    fontFamily: "-apple-system, BlinkMacSystemFont, 'SF Pro Text', 'Apple SD Gothic Neo', sans-serif"
    fontSize: "15px"
    fontWeight: 600
  body:
    fontFamily: "-apple-system, BlinkMacSystemFont, 'SF Pro Text', 'Apple SD Gothic Neo', sans-serif"
    fontSize: "14px"
    fontWeight: 400
    lineHeight: 1.55
  label:
    fontFamily: "-apple-system, BlinkMacSystemFont, 'SF Pro Text', 'Apple SD Gothic Neo', sans-serif"
    fontSize: "12px"
    fontWeight: 600
    letterSpacing: "0.1em"
rounded:
  pill: "999px"
  panel: "26px"
  stage: "24px"
  badge: "20px"
  card: "18px"
  tile: "16px"
  key: "8px"
spacing:
  gap: "14px"
  item: "28px"
  hero-top: "96px"
  section: "110px"
components:
  button-primary:
    backgroundColor: "{colors.ink}"
    textColor: "{colors.midnight}"
    rounded: "{rounded.pill}"
    padding: "13px 30px"
  lang-toggle-active:
    backgroundColor: "{colors.ink}"
    textColor: "{colors.midnight}"
    rounded: "{rounded.pill}"
    padding: "4px 12px"
  step-card:
    backgroundColor: "{colors.panel}"
    rounded: "{rounded.card}"
    padding: "26px 22px"
  stat-card:
    backgroundColor: "{colors.panel}"
    rounded: "{rounded.card}"
    padding: "32px 24px"
  hud-badge:
    backgroundColor: "{colors.glass}"
    rounded: "{rounded.badge}"
    size: "68px"
  keycap:
    backgroundColor: "{colors.keycap-fill}"
    rounded: "{rounded.key}"
    padding: "7px 11px"
---

# Design System: CopyNod

## 1. Overview

**Creative North Star: "시스템의 연장 (An Extension of the System)"**

이 페이지는 자기만의 브랜드 세계를 짓지 않는다. macOS의 재질·폰트·색을 그대로 입어, 방문자가 "이미 내 맥의 일부"를 보고 있다고 느끼게 한다. 시스템 폰트 스택, Apple systemGreen 값 그대로의 액센트, 프로스티드 글래스와 헤어라인 보더 — 페이지의 모든 시각 어휘는 운영체제에서 빌려온 것이고, 그래야 한다. 제품(HUD)이 OS의 일부처럼 동작하듯, 랜딩도 OS의 일부처럼 보인다.

밀도는 낮고 목소리는 하나다. PRODUCT.md의 성격 그대로 — 조용함·정밀함·절제 — 과장 카피, 가입·뉴스레터·가격표, 과한 스크롤 애니메이션을 명시적으로 거부한다. 페이지 전체에서 움직이는 것은 히어로의 HUD 데모 루프 하나뿐이며, 이것이 이 시스템의 모션 예산 전부다.

**Key Characteristics:**

- 다크 기본 + 라이트 대응. 두 테마 모두 Apple 시스템 값 기반 (`#0a0a0c`/`#f5f5f7` ↔ `#fbfbfd`/`#1d1d1f`).
- 단일 액센트: Verified Green. 체크마크에만 존재.
- 표면은 평평하게(헤어라인 + 반투명 틴트), 그림자는 떠 있는 물체에만.
- 시스템 폰트 단일 패밀리, 웨이트와 크기만으로 위계.
- EN/KO 동등 — 텍스트 컨테이너를 언어 하나에 맞춰 고정하지 않는다.

## 2. Colors: The System Palette

macOS가 이미 정한 값을 빌려 쓰는 무채색 + 단일 그린 팔레트 — 발명하지 않고 인용한다.

### Primary

- **Verified Green** (`#32d74b` 다크 / `#34c759` 라이트): Apple systemGreen 값 그대로. 체크마크(브랜드 마크, HUD 데모의 체크 스트로크)에만 나타난다. 화면 전체에서 1% 미만 — 검증된 순간에만 등장하는 색이라는 것 자체가 제품의 메시지다.

### Neutral

- **Ink** (`#f5f5f7`): 다크 테마의 주 텍스트, 그리고 반전되어 프라이머리 버튼의 배경이 된다.
- **Ink Secondary** (`#EBEBF599`, 60%): 본문·설명 텍스트, 아이콘 스트로크. 정보를 담는 보조 텍스트의 하한선.
- **Ink Tertiary** (`#EBEBF559`, 35%): 장식·비정보성 요소 전용 (데모 캡션, 스텝 화살표). **AA 대비 미달(≈2.8:1)이므로 읽어야 하는 텍스트에는 금지** — 정보성 텍스트가 필요하면 Ink Secondary 이상으로 올린다.
- **Midnight** (`#0a0a0c`): 다크 테마 바탕. 순흑이 아닌 아주 미세한 블루 틴트.
- **Hairline** (`#FFFFFF1A`, 10%): 모든 보더·디바이더. 표면을 구분하는 유일한 선.
- **Panel** (`#FFFFFF0A`, 4%): 카드·패널의 반투명 틴트. 배경에서 살짝만 떠오른다.
- **Glass** (`#1E1E248C`, 55%): HUD 배지 전용 — blur(24px)와 함께 쓰여 Liquid Glass 재질을 재현한다.
- **Keycap Fill** (`#FFFFFF12`, 7%): 키캡 배경.
- 라이트 테마 대응값: **Porcelain** (`#fbfbfd`) 바탕, **Ink Light** (`#1d1d1f`) 계열 텍스트, `#0000001A` 헤어라인, `#00000008` 패널.

### Named Rules

**The One Green Rule.** Verified Green은 체크마크가 있는 곳에만 존재한다. 버튼, 링크, 호버, 장식에 쓰는 것을 금지한다. 이 색의 희소성이 곧 "오탐 없음"이라는 제품 주장이다.

**The Borrowed Value Rule.** 새 색을 발명하지 않는다. 필요한 값이 생기면 먼저 Apple 시스템 팔레트(systemGreen처럼)에서 인용할 수 있는지 찾는다. 인용할 수 없는 색이 필요하다는 것은 대개 디자인이 시스템의 연장에서 벗어나고 있다는 신호다.

## 3. Typography

**Display/Body Font:** 시스템 스택 단일 패밀리 — `-apple-system, BlinkMacSystemFont, "SF Pro Display", "SF Pro Text", "Helvetica Neue", "Apple SD Gothic Neo", sans-serif`

**Character:** 맥에서 열면 SF Pro, 한국어는 Apple SD Gothic Neo — OS가 렌더링하는 그대로. 두 번째 패밀리는 없다. 위계는 전적으로 웨이트(400–700)와 크기, 자간으로만 만든다.

### Hierarchy

- **Display** (700, `clamp(40px, 7vw, 64px)`, 1.05, -0.025em): 히어로 헤드라인 전용. 페이지에 한 번.
- **Headline** (700, 32px, -0.02em): 섹션 제목.
- **Statement** (500, `clamp(22px, 3.4vw, 29px)`, 1.45, -0.015em): Problem 섹션의 서술형 강조 문단 — 제목과 본문 사이의 중간 목소리.
- **Title** (600, 15–16px): 카드·아이템 제목 (step-title 16px, priv-title/feat-name/faq-q 15px).
- **Body** (400, 13.5–14px, 1.55–1.6): 설명 텍스트, Ink Secondary. 히어로 서브만 19px의 리드(lede) 크기를 쓴다.
- **Label** (600, 12px, 0.1em, uppercase): 킥커 전용 — 페이지에 단 한 번, Problem 섹션의 "The problem"에만 쓴다.
- **Stat Numeral** (700, 42px, -0.03em, `tabular-nums`): 스탯 카드의 수치. 숫자는 항상 tabular로.

### Named Rules

**The Single Voice Rule.** 두 번째 폰트 패밀리는 금지. "기술적인 느낌"을 위한 모노스페이스 추가도 금지 — 키보드 키는 폰트가 아니라 키캡 컴포넌트로 표현한다.

**The Two-Language Rule.** 모든 텍스트 컨테이너는 EN과 KO 양쪽 길이를 견뎌야 한다. 한 언어에 맞춘 고정 폭·고정 높이 금지.

## 4. Elevation

**The Only-What-Floats Rule.** 실제로 화면 위에 떠 있는 물체만 그림자를 가진다 — HUD 배지, 앱 아이콘, 그리고 키캡(눌리는 물체의 inset). 정보를 담는 표면(카드·패널·섹션)은 절대 그림자를 갖지 않고, 헤어라인 보더 + Panel 틴트로만 배경과 구분된다. 깊이의 또 다른 축은 그림자가 아니라 **재질** — 헤더와 HUD 배지는 backdrop blur로 뒤를 비춘다.

### Shadow Vocabulary

- **Float — HUD** (`box-shadow: 0 12px 40px rgba(0,0,0,.35), inset 0 1px 0 rgba(255,255,255,.12)`): HUD 배지 전용. 바깥 그림자로 떠오르고, 안쪽 1px 하이라이트로 유리 윗면을 잡는다.
- **Float — Icon** (`box-shadow: 0 18px 50px rgba(0,0,0,.3)`): 히어로 앱 아이콘 전용.
- **Pressed — Keycap** (`box-shadow: inset 0 -2px 0 rgba(0,0,0,.15)`): 키캡 아랫면. 눌리는 물체라는 물성 표현.
- **Material — Header/Glass** (`backdrop-filter: blur(20–24px)`): 그림자가 아닌 재질. 스티키 헤더(blur 20px)와 HUD 배지(blur 24px)에만.

## 5. Components

성격: **"재질로 말하는"** — 유리(HUD·헤더), 키캡, 헤어라인. 컴포넌트는 장식이 아니라 만질 수 있는 재질감으로 구분된다. 상태 변화는 조용하다(투명도·색만, 0.2s).

### Buttons

- **Shape:** 완전한 필 (`999px`)
- **Primary:** Ink 배경 + Midnight 텍스트(테마 반전 — 라이트에서는 Ink Light 배경 + Porcelain 텍스트), 15px/600, 패딩 `13px 30px`
- **Hover:** `opacity: .85` — 색상 변화 없음, 조용한 감쇠
- **Focus:** 현재 브라우저 기본 (알려진 개선 여지 — 커스텀 focus-visible 링 없음)
- **Secondary:** 버튼이 아니라 텍스트 링크 (`gh-link` — Ink Secondary, 호버 시 Ink)

### Chips / Segmented Control

- **Style:** 언어 토글 — 헤어라인 보더의 필 컨테이너 안에 필 버튼 2개
- **State:** 활성 = Ink 배경 + Midnight 텍스트 (버튼 프라이머리와 같은 반전 문법), 비활성 = 투명 배경 + Ink Secondary

### Cards / Containers

- **Corner Style:** 위계별 라디우스 — 큰 패널 `26px`(Privacy), 스테이지 `24px`, 카드 `18px`(step/stat), 타일 `16px`(feature), 슬롯 `14px`
- **Background:** Panel 틴트 (`#FFFFFF0A`) — 프라이버시 패널·step/stat 카드. feature 타일은 보더만
- **Shadow Strategy:** 없음 — The Only-What-Floats Rule
- **Border:** 항상 Hairline 1px
- **Internal Padding:** 카드 `26px 22px` ~ `32px 24px`, 큰 패널 `52px 48px` (모바일 `36px 24px`)

### Navigation (Header)

- **Style:** 스티키 + `backdrop-filter: blur(20px)` + 72% 불투명 배경 틴트 + 헤어라인 하단 보더. 좌측 브랜드(체크 아이콘 17px + 이름 15px/600), 우측 언어 토글뿐 — 내비게이션 메뉴 없음.

### FAQ Accordion

- **Style:** 헤어라인 디바이더 리스트 (카드 아님). 질문 = Title 15px/600 풀폭 버튼, `aria-expanded` 반영
- **State:** 우측 `+` 표식이 열림 시 45° 회전(0.2s). 답변은 Body/Ink Secondary, max-width 560px

### HUD Badge (Signature)

제품 그 자체의 재현 — 이 시스템의 시그니처 컴포넌트. `68px` 정사각, `20px` 라디우스, Glass 배경 + `blur(24px)`, Hairline 보더, Float-HUD 그림자. 내부에 Verified Green 체크 스트로크(3.5px, round cap). 히어로 데모에서는 2.6s 주기로 팝(스케일 .86→1) + 체크 드로잉(`stroke-dashoffset` 30→0) + 페이드아웃을 반복한다.

### Keycap (Signature)

`⌘` `C` — Keycap Fill 배경, `8px` 라디우스, Hairline 보더, Pressed inset 그림자, 14px/600 Ink Secondary. 데모에서 HUD 팝 직전에 2px 눌림(translateY) 애니메이션.

## 6. Do's and Don'ts

### Do:

- **Do** Verified Green을 체크마크에만 쓴다 — The One Green Rule.
- **Do** 정보를 담는 텍스트는 Ink Secondary(60%) 이상으로 — Ink Tertiary(35%)는 AA 미달이므로 장식 전용.
- **Do** 모든 애니메이션에 `prefers-reduced-motion` 대안을 제공한다 — HUD 데모는 정적인 체크 완료 상태로 대체 (현재 미구현, 필수 보완).
- **Do** 스탯 수치에는 `tabular-nums`, 제목에는 `text-wrap: balance` 계열의 안정 장치.
- **Do** 표면 구분은 헤어라인 + Panel 틴트로. 그림자를 쓰고 싶다면 "이게 실제로 떠 있는 물체인가"부터 묻는다.
- **Do** 모든 카피·컴포넌트를 EN/KO 양쪽에서 검증한다. 두 언어의 정보 범위는 같아야 한다.
- **Do** 320px 폭에서 레이아웃을 확인한다 (고정 폭 슬롯 금지 — `min(300px, 100%)` 패턴).

### Don't:

- **Don't** 과장 카피 금지 — "혁신적인", "생산성 10배" 류의 하이프 언어, 느낌표 (PRODUCT.md 앤티레퍼런스).
- **Don't** 가입, 뉴스레터, 가격표 — 전환 방해 요소는 어떤 형태로도 추가하지 않는다 (PRODUCT.md).
- **Don't** 과한 스크롤 애니메이션 금지 — 히어로의 HUD 데모가 페이지의 유일한 의미 있는 모션이어야 한다 (PRODUCT.md).
- **Don't** 새 색·새 폰트 패밀리 발명 금지 — 시스템에서 인용할 수 없으면 시스템의 연장이 아니다.
- **Don't** 그라디언트 텍스트, 장식용 글래스모피즘 금지 — 유리는 OS에서 실제로 유리인 것(헤더, HUD)에만.
- **Don't** 업퍼케이스 킥커를 섹션마다 반복하지 않는다 — 킥커는 Problem 섹션 단 한 곳의 장치다.
- **Don't** 평평한 카드에 보더 + 넓은 그림자를 함께 얹지 않는다 — 그 조합은 떠 있는 물체(HUD·아이콘)의 전유물이다.
- **Don't** 텍스트 컨테이너를 한 언어 길이에 맞춰 고정하지 않는다.
