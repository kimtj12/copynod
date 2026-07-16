# CopyNod — 기획 문서

> macOS에서 ⌘C/⌘X로 복사·잘라내기가 **실제로 성공했을 때만** 체크 HUD를 잠깐 띄워주는 메뉴바 상주 유틸리티.
> 작성일: 2026-07-17 · 상태: 기획 확정 (그릴링 완료, 구현 전) · 결정 기록: [decisions.md](decisions.md) · 이후 작업: [backlog.md](backlog.md)

## 0. 제품 정체성

| 항목 | 값 |
|---|---|
| 앱 이름 | **CopyNod** |
| 번들 ID | `kr.ai.simpool.CopyNod` |
| 배포 | 공개 배포 (Developer ID + notarization), 무료 |
| 라이선스 | MIT, 공개 저장소 |
| 지원 버전 | macOS 14+ (26+에서 Liquid Glass, 미만은 폴백) |
| 언어 | 영어 기본 + 한국어 (String Catalog) |
| 앱 아이콘 | 미정 — 시안 4종은 [icon-concepts.html](icon-concepts.html) 참조 |

## 1. 배경과 목표

⌘C를 눌렀을 때 복사가 실제로 됐는지 시각적 피드백이 없어서, 사용자가 붙여넣기 전까지 불안해하거나 복사를 여러 번 반복하는 경우가 있다. 이 앱은 **복사가 실제로 성공한 순간에만** 작은 HUD를 띄워 그 불안을 없앤다.

핵심 가치:

- 복사 성공 여부를 즉시, 확실하게 알려준다 (오탐 없이).
- 배터리·리소스 영향이 측정 불가능한 수준이어야 한다.
- 설치하고 잊어버릴 수 있는 앱 — 설정은 최소한만.
- **아무것도 전송하지 않는다** — 클립보드 내용을 읽지 않고(`changeCount` 정수만 확인), 분석·크래시 리포팅도 없다. 네트워크 접근은 Sparkle 업데이트 확인이 유일. 오픈소스로 이를 코드로 증명한다.

### 비목표 (Non-goals)

- 클립보드 히스토리 / 클립보드 매니저 기능.
- 메뉴·우클릭 등 단축키 외 경로의 복사 감지. 이 HUD의 가치는 "단축키가 먹었는지 불안한 순간"에 있고, 메뉴 복사는 메뉴가 닫히는 시각 피드백이 이미 있다. 또한 전 경로 감지는 상시 폴링과 오탐(백그라운드 앱의 클립보드 조작)을 유발한다.
- 클립보드 내용의 저장·전송.

## 2. 기능 명세

### 2.1 Copied HUD 표시

- 사용자가 **⌘C 또는 ⌘X**를 누르고 **클립보드가 실제로 변경되면** HUD를 표시한다. 두 단축키 모두 동일한 검증 파이프라인(3.3)을 탄다.
- 표시 시간: 약 1초, 페이드 인/아웃.
- 클릭 불가(click-through), 포커스를 빼앗지 않음, 모든 Space·전체화면 위에 표시.
- 선택 영역이 없거나 앱이 복사·잘라내기를 거부해 클립보드가 안 바뀐 경우 → **표시하지 않음**.

**HUD 디자인 — 애니메이션 체크 아이콘**:

- 원형 배지 안에 체크마크가 **그려지는(stroke-drawing) 애니메이션**. 체크 경로를 `CAShapeLayer.strokeEnd`(SwiftUI라면 `trim`)로 약 0.25초에 걸쳐 그린 뒤, 잠깐 유지하고 페이드 아웃. 전체 수명 ~1초로 에너지 예산 유지.
- **배경 재질 — 버전 분기 (분기 지점은 이 한 곳뿐)**:
  - macOS 26+: **Liquid Glass** (`NSGlassEffectView`) — 26의 시스템 볼륨 HUD와 같은 재질.
  - macOS 14~15: `NSVisualEffectView` + `.hudWindow` material — 해당 OS의 시스템 HUD 룩.
- 다크/라이트 모드 자동 대응 (semantic color 사용).
- v1에서는 복사와 잘라내기 모두 동일한 체크 HUD를 사용한다. 잘라내기 구분 표시(가위 아이콘 등)는 백로그.
- 애니메이션 종료 후 패널 `orderOut` 필수 (3.5 참조).

### 2.2 HUD 위치 옵션 (3종)

| 옵션 | 설명 | 비고 |
|---|---|---|
| 커서 근처 (기본값) | ⌘C 시점의 마우스 커서 옆 | 키 입력 시점에 위치를 1회만 캡처 |
| 화면 하단 중앙 | 커서가 있는 화면의 하단 중앙 | 멀티 모니터: 커서가 있는 화면 기준 |
| 오른쪽 위 | 커서가 있는 화면의 우상단 | 알림 배너와 겹치지 않게 오프셋 |

### 2.3 로그인 시 자동 실행

- `SMAppService.mainApp`으로 등록/해제. 설정 UI에 토글 제공.

### 2.4 메뉴바 아이콘과 설정 UI

- **메뉴바 아이콘: 기본 표시 + "메뉴바 아이콘 숨기기" 설정 제공.**
  - 기본값이 표시인 이유: Accessibility 권한(전역 키 감시)을 가진 앱이 완전히 보이지 않으면 신뢰 문제가 생긴다. 아이콘은 "지금 떠 있고, 여기서 끌 수 있다"는 가시성이다.
  - 숨긴 상태에서의 설정 접근: **앱 재실행 패턴** — Spotlight/Launchpad에서 CopyNod를 다시 실행하면 `applicationShouldHandleReopen`이 설정 창을 띄운다.
- 메뉴바 드롭다운(얇게 유지): HUD 위치 서브메뉴, 자동 실행 토글, 설정 창 열기, Check for Updates, 종료.
- **설정 창(SwiftUI, 작게 1개)**: HUD 위치 3종, 로그인 자동 실행, 메뉴바 아이콘 숨기기, 업데이트 확인.
- Dock 아이콘 없는 상주 앱 (`LSUIElement = YES`).
- 권한이 회수된 경우: 메뉴바 아이콘 경고 배지 + **시스템 알림**(아이콘 숨김 상태 대비).

### 2.5 자동 업데이트

- **Sparkle 2** 내장. appcast는 GitHub(Pages 또는 Releases) 호스팅.
- 주기 체크 1일 1회 — 유휴 예산에 영향 없음. EdDSA 서명 키는 배포 단계(백로그 M4)에서 생성.

## 3. 아키텍처 결정 사항

논의를 거쳐 확정한 핵심 설계. 각 결정의 근거를 함께 기록한다.

### 3.1 기술 스택: Swift + AppKit 네이티브, XcodeGen

- Electron/웹뷰 계열은 상주 메모리 150MB+와 유휴 wakeup 때문에 이런 초경량 유틸리티에 부적합.
- 목표 수치: 상주 메모리 20~40MB, 유휴 CPU ~0%, 유휴 wakeup ~0회.
- 설정 UI는 SwiftUI (창 하나뿐이라 가벼움).
- **프로젝트 정의는 XcodeGen** (`project.yml`) — `.xcodeproj`는 생성물로 취급. 프로젝트 설정이 리뷰 가능한 텍스트로 남는다. 빌드는 `xcodebuild`.
- 의존성: Sparkle 2 (SPM) 하나뿐.

### 3.2 ⌘C/⌘X 감지: NSEvent.addGlobalMonitorForEvents

CGEventTap과 비교 후 결정. 상세 비교는 [detection-api-comparison.md](detection-api-comparison.md) 참조.

- 이벤트를 수정·차단할 필요가 없으므로 관찰 전용인 NSEvent 모니터로 충분.
- CGEventTap은 타임아웃 시 탭이 비활성화되는(`kCGEventTapDisabledByTimeout`) 운영 부담이 있음.
- 자기 앱 내부의 ⌘C는 global monitor에 안 잡히므로 `addLocalMonitorForEvents`를 함께 등록 (local monitor는 동기 호출이라 아래 레이스도 없음).
- **키 판정은 keyCode가 아니라 문자 기반** (`charactersIgnoringModifiers` == "c"/"x") — Dvorak 등 비QWERTY 레이아웃에서 keyCode 8이 C가 아니기 때문.

**알려진 한계 — 비동기 전달 레이스**: global monitor 핸들러는 이벤트가 대상 앱으로 전달되는 것과 무관하게 **비동기로** 호출된다. 대상 앱이 우리 핸들러보다 먼저 복사를 끝내면 baseline이 이미 "복사 후" 값이 되어 HUD를 놓친다(false negative).

- 실전 빈도는 낮음: 모니터 콜백은 보통 밀리초 미만에 불리는 반면, 대상 앱은 keyDown → 메뉴 key equivalent 매칭 → `copy:` → 파스트보드 XPC 쓰기를 거쳐야 한다. 레이스에 지는 주 원인은 우리 메인 스레드가 바쁠 때.
- 완화책: baseline 샘플링을 핸들러 **첫 줄**에서 수행하고, 핸들러에서 무거운 작업을 하지 않는다.
- 결과의 방향이 "HUD 안 뜸"(false negative)이지 "잘못 뜸"이 아니므로 v1에서 수용한다.
- 금지 우회책: "지난번 changeCount를 기억해두고 비교"하는 방식은 백그라운드 앱(패스워드 매니저 등)의 클립보드 조작 후 첫 ⌘C에서 false positive를 만들므로 쓰지 않는다.
- 구조적 해결은 **active CGEventTap**(`.defaultTap`)뿐 — 이벤트가 대상 앱에 도달하기 전에 콜백이 동기 실행되어 baseline이 항상 복사 이전 값임이 보장된다 (listen-only 탭은 이 보장이 없음). 실사용에서 놓침이 체감되면 감지 계층을 이것으로 교체한다. 이 승격 경로를 위해 감지 로직을 프로토콜(`CopyDetector`) 뒤에 격리한다.

### 3.3 오탐 방지: 하이브리드 검증 (이벤트 = 트리거, changeCount = 검증)

키 이벤트는 "복사 시도" 신호일 뿐 "복사 성공" 증거가 아니다. 선택 없음·앱의 복사 거부 시 HUD가 잘못 뜨는 것을 막기 위해:

1. ⌘C 핸들러 첫 줄에서 `NSPasteboard.general.changeCount`(baseline)와 커서 위치를 기록.
2. 50ms 간격으로 최대 6회(~300ms) `changeCount != baseline` 여부를 확인.
3. 달라졌으면 HUD 표시, 아니면 조용히 포기.

- 비교는 `>`가 아니라 **`!=`** — 묻는 건 "기준값과 달라졌는가"이지 "증가했는가"가 아니며, changeCount의 단조 증가는 문서화된 계약이 아니라 구현 세부사항이다.
- 재시도를 두는 이유: 웹앱(JS clipboard API)이나 무거운 앱은 키다운 후 수십~수백 ms 뒤에 파스트보드에 쓴다.
- 같은 내용을 두 번 복사해도 changeCount는 바뀌므로 정상 동작.
- 앱별 예외(VS Code의 선택 없는 ⌘C = 줄 복사 등)도 "클립보드가 실제로 바뀌었는가" 하나로 자동 수렴 — 앱별 분기 불필요.
- 폴링은 ⌘C 직후 300ms 동안만 발생하므로 상시 폴링의 배터리 단점 없음.

**동시 체인 방지 — 세대(generation) 카운터**: ⌘C 연타 시 검증 체인이 겹쳐 변경 하나에 HUD가 여러 번 뜨는 것을 막는다. 검증기는 단일 객체로 두고, 트리거마다 `generation`을 증가시킨 뒤 각 체인은 매 tick에서 자기 세대가 최신인지 확인하고 아니면 스스로 소멸한다. 전 과정을 메인 스레드에서 돌려 락 없이 처리한다.

```swift
final class CopyVerifier {
    private var generation = 0

    func trigger() {  // ⌘C 핸들러에서 호출, 메인 스레드
        generation += 1
        let gen = generation
        let baseline = NSPasteboard.general.changeCount  // 첫 줄 샘플링 (3.2 레이스 완화)
        let cursor = NSEvent.mouseLocation
        check(gen: gen, baseline: baseline, at: cursor, attempt: 0)
    }

    private func check(gen: Int, baseline: Int, at pos: NSPoint, attempt: Int) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) { [weak self] in
            guard let self, gen == self.generation else { return }  // 구세대 체인 소멸
            if NSPasteboard.general.changeCount != baseline {
                showHUD(at: pos)
            } else if attempt < 5 {
                self.check(gen: gen, baseline: baseline, at: pos, attempt: attempt + 1)
            }
        }
    }
}
```

남는 미세 케이스: 첫 복사의 파스트보드 쓰기가 두 번째 ⌘C의 baseline 샘플링 이후에 도착하면, HUD가 두 번째 누름에 귀속될 수 있다. 창이 밀리초 단위이고 사용자에겐 "방금 복사한 게 떴다"로 보이므로 수용한다.

### 3.4 커서 위치: 온디맨드 1회 조회

- mouse-moved 이벤트 구독 금지 (이 앱에서 가장 큰 전력 소모원이 될 수 있음).
- ⌘C 이벤트 발생 시점에 `NSEvent.mouseLocation`을 한 번만 읽는다.

### 3.5 HUD 창: NSPanel

- `NSPanel` + `.nonactivatingPanel`, `ignoresMouseEvents = true`, `level = .statusBar` 이상.
- `collectionBehavior`: `.canJoinAllSpaces`, `.fullScreenAuxiliary`.
- 애니메이션 종료 후 반드시 `orderOut` — 투명도 0으로 숨기는 방식은 컴포지터가 레이어를 계속 관리하게 되므로 금지.

### 3.6 테스트 시임 (확정 — 2026-07-17, 스펙: [#1](https://github.com/kimtj12/copynod/issues/1))

- 최상위 시임 하나를 지향: **"트리거 이벤트 in → HUD 표시 요청 out"** 파이프라인. 파스트보드(`changeCount` 제공자), 스케줄러(시간), 화면 정보를 주입 가능하게 하여 레이스·세대·재시도 로직을 결정적으로 테스트.
- `HUDPositioner`는 순수 함수(위치 옵션 + 커서 좌표 + 화면 프레임 → 패널 원점)로 두어 그대로 테스트.
- NSEvent 모니터(감지)와 NSPanel(표시)은 시임 바깥의 얇은 껍데기로 유지.

## 4. 권한

| 권한 | 용도 | 시점 |
|---|---|---|
| 손쉬운 사용 (Accessibility) | 전역 keyDown 모니터링 | 최초 실행 시 |

- NSEvent global monitor는 권한이 없으면 **조용히 실패**한다 (에러 없음, 콜백만 안 옴).
- 따라서 `AXIsProcessTrustedWithOptions`로 상태를 확인하고, 미허용 시 온보딩 화면에서 시스템 설정으로 안내하는 흐름이 필수.
- 권한이 나중에 회수된 경우도 감지: 메뉴바 아이콘 경고 배지 + 시스템 알림 (2.4 참조).

## 5. 엣지 케이스

- **키 반복**: ⌘C 꾹 누름 → keyDown 연사. `event.isARepeat`이면 무시. HUD 표시 중 재트리거 시 타이머 연장(디바운스).
- **연속 복사**: 세대 카운터로 이전 검증 체인을 무효화하고 새 baseline으로 재시작 (구현은 3.3 참조). 변경 하나에 HUD는 최대 한 번.
- **복사를 놓치는 레이스**: global monitor의 비동기 전달로 baseline이 늦게 샘플링되면 HUD가 안 뜰 수 있음 (false negative). v1 수용, 상세와 승격 경로는 3.2 참조.
- **비QWERTY 레이아웃**: Dvorak 등에서 keyCode 기반 판정은 오동작 → 문자 기반 판정 (3.2 참조).
- **Secure Keyboard Entry** (비밀번호 입력창): 키 이벤트가 안 들어옴 → HUD 안 뜸. 보안상 의도된 동작이며 이 앱에선 올바른 결과.
- **⌘X (잘라내기)**: v1에 포함 (2.1 참조). 감지 키만 추가될 뿐 검증·표시 파이프라인은 ⌘C와 공유. 읽기 전용 문서에서 ⌘X가 무시되는 경우도 changeCount 검증이 자동으로 걸러준다.
- **멀티 모니터**: "하단 중앙"·"오른쪽 위" 옵션은 커서가 있는 `NSScreen` 기준으로 계산.
- **메뉴바에서 복사**: 비목표. 감지하지 않음.

## 6. 배터리 / 성능 예산

| 항목 | 목표 |
|---|---|
| 유휴 CPU | ~0% (이벤트 기반, 상시 폴링 없음) |
| 유휴 Idle Wake Ups | ~0회/초 |
| 상주 메모리 | 40MB 이하 (Sparkle 포함) |
| ⌘C 1회당 작업 | 정수 비교 최대 6회 + 1초 페이드 렌더링 |
| 네트워크 | Sparkle 업데이트 체크 1회/일이 전부 |

검증 방법: Activity Monitor의 Energy Impact·Idle Wake Ups 컬럼, `powermetrics`로 유휴 상태 측정.

## 7. 프로젝트 구조 (안)

```
copynod/
├── project.yml                    # XcodeGen 프로젝트 정의 (.xcodeproj는 생성물)
├── CopyNod/
│   ├── App/
│   │   ├── CopyNodApp.swift          # 진입점, LSUIElement 상주 앱, reopen 처리
│   │   ├── StatusBarController.swift # 메뉴바 아이콘 + 메뉴 (숨김 설정 반영)
│   │   └── UpdaterController.swift   # Sparkle SPUStandardUpdaterController 래핑
│   ├── Core/
│   │   ├── CopyDetector.swift        # 프로토콜 (감지 계층 추상화 — CGEventTap 승격 대비)
│   │   ├── KeyEventCopyDetector.swift# NSEvent 모니터 + changeCount 검증
│   │   └── PermissionManager.swift   # Accessibility 상태 확인·안내·회수 감지
│   ├── HUD/
│   │   ├── HUDPanel.swift            # NSPanel 설정
│   │   ├── HUDView.swift             # 체크 애니메이션 + 배경 재질 버전 분기
│   │   └── HUDPositioner.swift       # 위치 3종 계산 (멀티 모니터 대응, 순수 함수)
│   ├── Settings/
│   │   ├── SettingsStore.swift       # UserDefaults 래핑
│   │   └── SettingsView.swift        # 위치·자동 실행·아이콘 숨김·업데이트 (SwiftUI)
│   ├── Onboarding/
│   │   └── OnboardingView.swift      # 최초 실행 권한 안내
│   └── Resources/
│       └── Localizable.xcstrings     # 영어 기본 + 한국어
└── docs/                          # 이 문서들
```

## 8. 마일스톤

**이번 구현 범위: M1 + M2.** M3 이후는 [backlog.md](backlog.md).

1. **M1 — 코어 파이프라인**: 상주 앱 + 권한 온보딩 + ⌘C/⌘X 감지 + changeCount 검증. HUD는 로그 출력으로 대체.
2. **M2 — HUD**: NSPanel HUD, 체크 애니메이션, Liquid Glass/폴백 분기, 커서 근처 위치.

## 9. 다음 단계

1. 사용자가 저장소 생성 (`~/github/copynod`, GitHub 공개 저장소).
2. 이 `docs/`를 저장소로 이관.
3. `/to-spec`으로 스펙 작성 (테스트 시임 3.6 초안 확정 포함) → 이슈 트래커 등록.
4. M1 → M2 구현.

## 10. 열린 질문

- **앱 아이콘**: 시안 4종([icon-concepts.html](icon-concepts.html)) 중 미정. 개발은 플레이스홀더로 진행. 확정 시 Icon Composer(26+ Liquid Glass) + 14~15 폴백 에셋 두 벌 제작.

### 결정된 질문

그릴링 세션(2026-07-17)에서 해소된 결정 14건은 [decisions.md](decisions.md)에 근거와 함께 기록.
