# 감지 API 비교 — CGEventTap vs NSEvent.addGlobalMonitorForEvents

> [planning.md](planning.md) 3.2절(감지 계층 선택)과 9절(배포 방식)의 근거 문서.
> 작성일: 2026-07-17 · App Store 관련 사실은 Apple Developer Forums(DTS 답변 포함)로 확인.

## 1. 결론 요약

- **v1 (개인 사용 / notarized 직접 배포)**: NSEvent global monitor 유지. 이벤트 수정이 필요 없고, false negative의 피해가 작으며, 탭 재활성화·시스템 입력 지연 같은 운영 리스크가 없다.
- **레이스 구조적 해결이 필요해지면**: **active CGEventTap**(`.defaultTap`)으로 승격. listen-only 탭은 타이밍 보장이 없어 교체 의미가 없다.
- **Mac App Store 배포 시**: NSEvent 모니터는 샌드박스에서 동작하지 않으므로 **CGEventTap listen-only + Input Monitoring 권한**이 유일한 경로. 이 경우 active 탭 승격 경로는 포기해야 한다.
- 어느 경로든 `CopyDetector` 프로토콜 뒤에 감지 계층을 격리해 구현체 교체로 대응한다.
- **2026-07-17 후속**: baseline을 시점 샘플이 아닌 **워터마크 + ⌘-down arm**으로 재설계하면 active 승격 없이 레이스가 제거된다 — [detection-race-solutions.md](detection-race-solutions.md)가 본 문서의 "레이스 구조적 해결 = active 승격" 결론을 대체한다. 감지 API와 무관한 `CopyVerifier` 계층의 변경이므로 MAS의 listen-only 경로에도 그대로 적용된다.

## 2. API 비교

| 비교 축 | NSEvent.addGlobalMonitorForEvents | CGEventTap |
|---|---|---|
| API 계층 | AppKit 고수준, 블록 기반 | Quartz(Core Graphics) 저수준 C API |
| 이벤트 개입 | 관찰만 가능 (수정·차단 불가) | active 탭(`.defaultTap`)은 수정·삼키기 가능, `.listenOnly`는 관찰만 |
| 전달 타이밍 | **비동기** — 대상 앱 전달과 무관하게 나중에 호출 | active 탭은 **동기** — 대상 앱 도달 **전**에 콜백 실행 |
| 자기 앱 이벤트 | 안 잡힘 (local monitor 별도 필요) | 자기 앱 포함 전부 잡힘 |
| 필요 권한 | 손쉬운 사용 (Accessibility) | active 탭: Accessibility / listen-only 키보드 탭: **입력 모니터링(Input Monitoring)** |
| 권한 없을 때 | **조용히 실패** (에러 없음, 콜백만 안 옴) | `CGEventTapCreate`가 NULL 반환 → **실패를 감지 가능** |
| 운영 부담 | 없음 (등록하면 끝) | 타임아웃/사용자 입력으로 탭 비활성화 처리, 재활성화 로직 필수 |
| 시스템 영향 | 없음 (복사본을 나중에 받을 뿐) | active 탭은 시스템 전체 키 입력 지연 경로에 들어감 |
| 실행 스레드 | 메인 스레드 | 원하는 런루프에 붙일 수 있음 (전용 스레드 가능) |
| Secure Keyboard Entry | 키 이벤트 안 들어옴 | 동일하게 안 들어옴 |
| App Sandbox / MAS | **불가** | listen-only는 **가능**, active는 불가 (4절 참조) |

### 2.1 전달 타이밍 — 이 앱에서 가장 중요한 축

- **NSEvent global monitor**는 이벤트가 대상 앱으로 이미 전달되는(또는 전달 중인) 시점에 그 **복사본**을 비동기로 받는다. 이것이 planning.md 3.2의 false negative 레이스의 원인이다: 대상 앱이 우리 핸들러보다 먼저 `copy:`를 끝내면 baseline `changeCount`가 이미 "복사 후" 값이 된다. 완화(핸들러 첫 줄 샘플링, 핸들러 경량화)는 가능해도 구조적 제거는 불가.
- **active CGEventTap**(`.defaultTap`)은 이벤트가 대상 앱에 도달하기 **전에** 콜백이 동기 실행된다. 콜백이 리턴해야 이벤트가 계속 흘러가므로, 콜백 안에서 읽은 `changeCount`는 항상 "복사 이전" 값임이 보장된다. 이 레이스를 구조적으로 없애는 유일한 방법.
- **주의**: listen-only 탭(`.listenOnly`)에는 이 보장이 **없다**. 관찰 전용 탭은 이벤트 흐름을 막지 않으므로 타이밍 관점에선 NSEvent 모니터와 같다. "CGEventTap으로 바꾸면 해결"이 아니라 "**active** CGEventTap이어야 해결"이다.

### 2.2 동기 실행의 대가 (active 탭)

active 탭의 동기성은 양날의 검이다. 콜백이 시스템 전체 키 입력 배달 경로에 끼어들기 때문에:

- 콜백이 느리면 **사용자의 모든 타이핑이 지연**된다.
- 콜백이 제때 응답하지 못하면 시스템이 탭을 강제 비활성화한다(`kCGEventTapDisabledByTimeout`). 이후로는 조용히 감지가 멈추므로, 콜백에서 이 이벤트를 받아 `CGEvent.tapEnable`로 재활성화하는 방어 코드가 필수. `kCGEventTapDisabledByUserInput`도 동일 처리.
- 콜백에서는 ⌘C/⌘X 판별 + `changeCount` 샘플링만 하고, 검증 체인은 메인 스레드로 넘겨 최소화해야 한다.
- active 탭은 이벤트를 삼킬 수도 있는데 이 앱은 절대 삼키면 안 된다(⌘C 자체가 죽음). 콜백에서 반드시 이벤트를 그대로 반환할 것 — 실수 한 번이 "복사가 안 되는 앱"이라는 최악의 버그가 된다.

NSEvent 모니터에는 이런 부담이 전혀 없다. 핸들러가 느려도 피해자는 우리 앱뿐이다.

### 2.3 권한과 실패 감지

- NSEvent global monitor(keyDown)는 Accessibility 권한이 없으면 **에러 없이 조용히 실패** → `AXIsProcessTrustedWithOptions` 확인 온보딩 필수 (planning.md 4절).
- CGEventTap은 권한이 없으면 `CGEventTapCreate`가 NULL을 반환 → 실패 시점을 코드로 알 수 있다.
- 권한 종류가 갈린다: **active 탭은 Accessibility**, **listen-only 키보드 탭은 Input Monitoring**(macOS 10.15+).
  - 함의 1: NSEvent 모니터 → active 탭 승격은 둘 다 Accessibility라서 **새 권한 요구 없음**.
  - 함의 2: listen-only 탭 경로는 Input Monitoring이라는 별도 권한이 필요하지만, `CGRequestListenEventAccess()`로 시스템 프롬프트를 직접 띄울 수 있어 온보딩 UX는 오히려 낫다 (Accessibility는 시스템 설정 수동 안내만 가능).

### 2.4 기타

- **탭 위치**: 이 용도는 `kCGSessionEventTap`(로그인 세션 레벨)이면 충분. `kCGHIDEventTap`은 권한 요구가 더 까다로워 불필요.
- **자기 앱 커버리지**: CGEventTap은 세션 전체를 보므로 local monitor 병행이 불필요해진다.
- **키 반복 판별**: 양쪽 다 가능 (`isARepeat` / `kCGKeyboardEventAutorepeat`).

## 3. App Store 배포

planning.md 9절의 초기 가정("Accessibility 때문에 사실상 불가")은 **NSEvent 경로에만 해당**한다. Apple DTS(Quinn)가 포럼에서 확인한 사실:

| | NSEvent global monitor | CGEventTap (listen-only) | CGEventTap (active) |
|---|---|---|---|
| 필요 TCC 권한 | Accessibility | **Input Monitoring** | Accessibility 계열 |
| App Sandbox에서 동작 | **불가** | **가능** | 불가 |
| MAS 배포 | 불가 | **가능** | 불가 |
| 권한 요청 UX | 시스템 설정 수동 안내만 | `CGRequestListenEventAccess()` 시스템 프롬프트 | — |

- **NSEvent 모니터는 샌드박스에서 아예 동작하지 않는다.** Xcode 개발 빌드에서는 되다가 App Store 빌드에서 조용히 실패한 사례가 보고돼 있고, DTS가 샌드박스 비호환을 확인했다. 두 API의 권한이 갈리는 이유는 Quinn 표현으로 "weird historical reasons".
- **MAS 경로는 CGEventTap listen-only가 유일하다.** Quinn이 제시한 구성이 정확히 이 앱에 맞는다: `.cgSessionEventTap` + `.headInsertEventTap` + `.listenOnly` + keyDown 마스크. 권한 상태는 `CGPreflightListenEventAccess()`로 확인.
- **active 탭은 샌드박스에서 불가** → MAS 버전에서는 2.1의 레이스 구조적 해결책을 포기하고 완화책만으로 안고 가야 한다.
- **심사 정책 리스크 (Guideline 2.4.5)**: 키 입력 모니터링 앱은 심사 리스크가 있고, 클립보드 매니저가 `CGEvent.post` 사용으로 리젝된 사례도 있다. 이 앱은 방어 논리가 좋은 편 — 클립보드 **내용을 읽지 않고** `changeCount` 정수만 보며, 키 입력도 ⌘C/⌘X 판별 외 아무것도 기록하지 않음을 심사 노트에 명시할 수 있다. 그래도 리젝 가능성은 0이 아니다.
- 앱의 나머지 구성(LSUIElement 메뉴바 상주, `SMAppService` 자동 실행, NSPanel HUD)은 전부 샌드박스와 호환. 걸림돌은 키 감지 계층 하나뿐이다.

### 배포 전략별 감지 계층

1. **개인 사용 / notarized 직접 배포**: NSEvent 모니터 + Accessibility. active 탭 승격 경로 유지. (v1 계획)
2. **MAS 배포**: CGEventTap listen-only + Input Monitoring. local monitor 불필요, 탭 재활성화 처리 필요, active 승격 경로 없음.
3. **양쪽 다**: `CopyDetector` 프로토콜 뒤에서 빌드 타깃별로 구현체 교체.

## 4. 출처

- [Accessibility permission in sandboxed app — Apple Developer Forums (Quinn/DTS)](https://developer.apple.com/forums/thread/707680)
- [Accessibility Permission In Sandbox For Keyboard — Apple Developer Forums](https://developer.apple.com/forums/thread/789896)
- [CGEventTap and App Store — Apple Developer Forums](https://developer.apple.com/forums/thread/668975)
- [Clipboard manager rejected under Guideline 2.4.5 — Apple Developer Forums](https://developer.apple.com/forums/thread/820594)
