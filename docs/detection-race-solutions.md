# 감지 레이스 해결 전략 — baseline 재설계 (워터마크 + ⌘-down arm)

> [planning.md](planning.md) 3.2의 "비동기 전달 레이스"와 [detection-api-comparison.md](detection-api-comparison.md)의
> "구조적 해결 = active CGEventTap뿐" 결론에 대한 후속 분석. 작성일: 2026-07-17.
> 계기: 실사용에서 false negative(HUD 안 뜸)가 체감 ~20%로, planning.md 3.2의 "실전 빈도는 낮음" 가정을 초과.

## 1. 결론 요약

- 레이스의 본질은 감지 API의 비동기성이 아니라 **baseline 샘플링 시점이 사용자 의도 시점보다 늦다**는 것.
  샘플링 시점을 의도 이전으로 옮기면 이벤트 기반을 유지한 채 이 FN 클래스를 제거할 수 있다.
- **워터마크 단독은 planning.md 3.2의 "금지 우회책" 그대로이며 여전히 금지가 타당하다** (FP 창이 무한).
  그러나 **⌘-down arm과 결합하면 FP 창이 "⌘를 누르고 있는 sub-second"로 줄어 금지 사유가 해소된다**.
- 채택 시 detection-api-comparison.md의 "active 탭 승격" 경로와 backlog의 해당 항목은 **불필요해진다**.
  워터마크+arm은 감지 API와 무관하게 `CopyVerifier` 계층에서 동작하므로 MAS의 listen-only 탭 경로에도 그대로 적용된다.
- 체감 20%에는 레이스 외에 **늦은 write**(검증 창 300ms 초과)와 **자기 메인 스레드 혼잡**이 섞여 있을 수 있다.
  검증 창을 ~1s로 넓히고 miss 로그로 분해 확인한다 (7절).

## 2. 문제 재정의

현재 구조 (`CopyVerifier.swift`): ⌘C keyDown 핸들러 **진입 시점**에 `baseline = changeCount`를 샘플링하고,
50ms×6회 창에서 `!= baseline`을 검사한다. global monitor는 비동기 전달이므로 대상 앱이 핸들러보다 먼저
복사를 끝내면 baseline이 이미 "복사 후" 값 → 창 내 변화 없음 → FN.

핵심 관찰: **changeCount는 정산 가능한 누적값이다.** 대상 앱이 아무리 먼저 write해도 그 흔적은 값의 변화로
남아 있다. 놓치는 이유는 오직 "변화가 일어난 뒤에 기준점을 읽기" 때문이다. 기준점을 의도 이전 값으로 확보하는
방법은 두 가지가 있고, 서로 보완적이다:

1. **워터마크**: 마지막으로 정산한 changeCount를 영속 보관 (시점 샘플 → 누적 정산).
2. **⌘-down arm**: 사용자가 물리적으로 C보다 ⌘를 먼저 누른다는 사실을 이용해, `flagsChanged`(⌘ 눌림) 시점에
   기준점을 갱신. 이 시점엔 대상 앱이 아직 복사할 수 없으므로(=C가 도착하지 않았으므로) 거의 확실히 "복사 이전" 값.

## 3. 해법 1 — 워터마크, 그리고 planning.md의 금지 우회책과의 관계

`CopyVerifier`에 `lastAccounted: Int`(시작 시 현재 changeCount로 초기화)를 두고:

- keyDown 진입 시 `changeCount != lastAccounted`면 **즉시** 복사 성공으로 판정 (레이스에 진 write가 여기서 잡힘).
- 검증 성공(즉시/체인) 시 `lastAccounted`를 현재 값으로 갱신.

이것만으로 FN은 구조적으로 0이 된다. 그러나 planning.md 3.2가 이미 지적했듯 **FP 창이 "마지막 정산 이후 전체"**다:
패스워드 매니저·`pbcopy` 스크립트·Universal Clipboard 등 백그라운드 write가 몇 시간 전에 있었어도, 그 뒤 첫
⌘C가 빈 선택(실제 복사 없음)이면 헛 nod가 나간다. "복사 안 됐는데 됐다고 표시"는 이 앱의 존재 이유(정직한
피드백)를 정면으로 배반하므로, **워터마크 단독 도입은 여전히 금지가 타당하다**. 해법 2가 이 사유를 해소한다.

## 4. 해법 2 — ⌘-down arm (금지 사유를 해소하는 부품)

`flagsChanged`에서 **⌘가 새로 눌리는 순간** `lastAccounted = changeCount`로 갱신(arm)한다. 효과:

- ⌘-down 이전의 모든 백그라운드 write는 arm이 **조용히 흡수** (nod 없이 정산). 금지 우회책의 FP 시나리오
  — "패스워드 매니저 write 후 첫 ⌘C" — 는 arm이 그 write를 이미 정산했으므로 발생하지 않는다.
- FP 창은 "⌘를 누르고 있는 동안 + C 이전"으로 축소. 사람의 ⌘→C 간격은 보통 50~300ms이므로 그 틈에
  백그라운드 write가 끼어들 확률은 무시 가능 수준.
- 레이스 관점: arm 배달이 밀려도 **⌘→C 간격만큼의 여유**가 생긴다. 현재 레이스는 "핸들러 배달 지연 vs 대상
  앱의 copy 실행"이라는 ms 단위 동전 던지기(그래서 20%)지만, arm 후에는 배달 지연이 수백 ms를 넘어야
  레이스가 성립한다.
- 부수 이득: ⌘⇧4(클립보드 스크린샷) 같은 "⌘C 아닌 pasteboard write"도 다음 ⌘C의 arm이 흡수하므로
  오귀속되지 않는다.

### 4.1 arm의 자체 위험과 가드

arm이 **너무 늦게 배달되면**(⌘→C 간격 + 대상 앱 copy 시간보다 늦게) "복사 후" 값을 기준점으로 덮어써
FN을 재도입한다. 이를 가드로 막는다:

1. **⌘ 새로 눌림만 arm**: detector가 직전 modifier 상태를 기억, `flags.contains(.command) && !wasCommandDown`일 때만.
   (⇧ 등 다른 modifier 변화, ⌘ 유지 중 재통지는 무시.)
2. **배달 지연 가드**: `lag = ProcessInfo.processInfo.systemUptime - event.timestamp` (둘 다 커널 uptime 시간축이라
   직접 비교 가능). `lag > 30ms`면 arm을 **스킵**하고 이전 워터마크를 유지한다. 스킵 시 그 1회는 FP 창이
   "마지막 정산 이후"로 넓어질 뿐(=워터마크 폴백), FN은 생기지 않는다 — 오류를 항상 덜 해로운 쪽(FP)으로 밀어낸다.
   임계값 30ms 근거: 유휴 시 배달은 <5ms, 사람의 최속 ⌘→C 코드(chord)는 ~50ms — 30ms면 안전 마진 내.
3. local monitor(자기 앱)는 동기 호출이라 lag ≈ 0, 가드 통과.

### 4.2 잔여 오류 상황 정리

| 상황 | 결과 | 비고 |
|---|---|---|
| 대상 앱이 핸들러보다 먼저 write (현재의 20% 레이스) | **즉시 판정으로 감지** | FN 제거 — 이 작업의 목적 |
| ⌘-hold 중(⌘-down~C 사이) 백그라운드 write + 빈 선택 ⌘C | 헛 nod 1회 (FP) | sub-second 창, 병적 케이스 |
| arm 스킵된 press(혼잡) + 마지막 정산 이후 백그라운드 write + 빈 선택 ⌘C | 헛 nod 1회 (FP) | 이중 우연, 드묾 |
| pboard 데몬 재시작으로 changeCount 리셋 | 헛 nod 최대 1회 | 기존 `!=` 비교 설계와 동일 계열 |
| write가 검증 창(확대 후 ~1s)보다 늦음 | 그 press에선 miss, 다음 ⌘C의 arm이 흡수 | 7절 창 확대로 완화 |
| arm 배달 지연이 30ms 가드를 통과할 만큼 크되 ⌘→C보다 늦음 | 이론상 FN | 가드 상수로 제어 가능, 실측 대상 |

## 5. 구현 스펙 (CopyVerifier 중심, detector는 통로만)

```swift
// CopyVerifier 추가 상태
private var lastAccounted: Int   // init에서 pasteboard.changeCount

// 새 진입점 — detector의 flagsChanged에서 호출
func commandDown(lag: TimeInterval) {
    guard lag < Self.maxArmLag else { return }   // 4.1 가드 2
    lastAccounted = pasteboard.changeCount
}

// keyDown 변경
func keyDown(isRepeat: Bool, cursor: CGPoint) {
    let current = pasteboard.changeCount
    if isRepeat { return }
    generation += 1
    if current != lastAccounted {
        lastAccounted = current
        onCopyVerified(cursor)
        startAbsorbChain(gen: generation)        // 아래 "조용한 흡수" — nod 없이 정산만
        return
    }
    check(gen: generation, baseline: current, cursor: cursor, attempt: 0)  // 성공 시 lastAccounted 갱신
}
```

- **조용한 흡수 체인**: 즉시 판정이 난 press에서도 검증 창 동안 changeCount를 계속 관찰해 `lastAccounted`만
  갱신한다(추가 nod 없음). 즉시 판정의 diff가 사실 stale write였고 이번 press의 실제 write가 직후에 도착하는
  경우, 그 write를 정산해 두지 않으면 다음 ⌘C에서 FP가 된다. 기존 generation 메커니즘 재사용.
- **검증 창 확대**: `maxAttempts` 6 → 20 (50ms 유지, ~1s). Office·원격 데스크톱·대용량 웹 선택은 300ms를
  초과하는 경우가 흔하다. generation 가드가 연타 중복을 이미 막으므로 비용은 사실상 0. 폴링은 여전히
  ⌘C 직후에만 발생 — planning.md 3.3의 배터리 원칙 유지.
- **detector 변경**: `KeyEventCopyDetector`의 모니터 mask를 `[.keyDown, .flagsChanged]`로 확장(global/local 동일),
  ⌘ 새로 눌림 판정 후 `onCommandDown(lag:)` 콜백. `CopyDetector` 프로토콜에 콜백 1개 추가.
  flagsChanged는 ⇧ 포함 모든 modifier 변화마다 배달되므로(빠른 타이핑 시 초당 수 회) 핸들러는 비트마스크
  비교 후 즉시 리턴하는 수준으로 유지한다. 상시 타이머 폴링보다 훨씬 싸다.
- **테스트 추가** (기존 시임 `PasteboardChangeCounting`/`Scheduling` 그대로 사용):
  1. keyDown 시점에 이미 변해 있으면 즉시 감지 — **현재 재현 불가능한 레이스의 결정적 재현**
  2. ⌘-down arm 후 write → keyDown: 즉시 감지 (레이스 시나리오 + arm)
  3. 백그라운드 write → ⌘-down arm → 빈 선택 keyDown: **nod 없음** — 금지 우회책의 FP 시나리오가 통과함을 증명
  4. `lag > maxArmLag`면 arm 무시 (이전 워터마크 유지)
  5. 즉시 판정 후 같은 창 내 추가 write: 추가 nod 없음 + 다음 keyDown에서 FP 없음 (조용한 흡수)
  6. 기존 generation·isRepeat·`!=` 비교 테스트 전부 유지

## 6. 전략적 대안 — changeCount 폴링을 1차 신호로 (기록만, 보류)

Maccy·Paste 등 모든 클립보드 매니저의 방식. 100~150ms 타이머로 changeCount만 폴링하고 변화 시 nod.

- **최대 함의: Accessibility 권한이 통째로 사라진다.** changeCount 폴링과 `NSEvent.mouseLocation`은 TCC 불요
  → 온보딩·권한 회수 감지·Guideline 2.4.5 리스크·샌드박스 제약 전부 소멸. MAS도 Input Monitoring 없이 가능.
  키 감시 앱의 신뢰 확보(D9, D11의 근거)라는 부담 자체가 없어진다.
- 커버리지 확대: 메뉴의 Copy, 웹앱 "링크 복사" 버튼, iTerm2 copy-on-select까지 잡음. FN 개념 자체가 소멸.
- 대가: (a) 평균 폴링 간격/2의 표시 지연, (b) 프로그램적 write에도 nod → "⌘C에 대한 반응"이라는 제품 정체성이
  "복사 사건에 대한 반응"으로 바뀜, (c) planning.md 3.3의 상시 폴링 회피 원칙과 정면 충돌.
- 원격(iPhone) 클립보드는 `com.apple.is-remote-clipboard` 타입 마커로 필터 가능 — 타입 목록만 읽으므로
  "내용을 읽지 않는다" 원칙과는 충돌하지 않음.
- **판단**: 워터마크+arm으로 FN이 잡히면 도입 이유가 없다. 남는 유일한 동기는 "권한 제거"라는 제품 전략적
  가치인데, 이는 감지 품질이 아니라 포지셔닝 결정이므로 별도 논의로 분리한다.

## 7. 진단 — 체감 20%의 분해

miss가 전부 이 레이스라는 보장이 없다. 용의자 3종:

1. **레이스** (baseline이 복사 후 값) — 워터마크+arm으로 해결.
2. **늦은 write** (검증 창 300ms 초과) — 창 ~1s 확대로 해결. 대상: Office, 원격 데스크톱, 대용량 웹 선택.
3. **자기 메인 스레드 혼잡** — HUD 애니메이션 중에는 모니터 배달과 `asyncAfter` 둘 다 밀린다. 연속 ⌘C에서
   miss가 집중됐다면 이것. arm의 lag 가드 통계로 간접 관측 가능.

구현 시 체인 소진(=판정 실패) 지점에 `os_log`(debug)로 `(lastAccounted, baseline, current, attempt)`를 남기면
배포 빌드에 부담 없이 잔여 miss의 클래스를 사후 분류할 수 있다.

## 8. 막다른 길 (재탐색 방지용 기록)

- **파스트보드 변경 알림**: macOS에는 iOS `UIPasteboard.changedNotification`에 해당하는 **공개 API가 없다**.
  모든 클립보드 매니저가 폴링하는 이유. Darwin notify/비공개 분산 알림은 문서화되지 않아 배포용 부적합.
- **listen-only CGEventTap**: 타이밍 보장이 없어 이 레이스에 무력 — detection-api-comparison.md 2.1에서 확정된
  사실 재확인. (MAS 경로로서의 가치는 별개.)
- **active CGEventTap**: 유일한 "동기 보장" 해법이었으나, 워터마크+arm 채택 시 **불필요**. 동기 콜백 안에서
  changeCount를 읽는 것 자체가 pboard XPC를 시스템 전역 키 입력 경로에 넣는 위험이기도 했다.
- **AXObserver로 각 앱 메뉴의 Copy 선택 관찰**: 앱별 옵저버 등록·수명 관리가 무겁고 깨지기 쉬움. 메뉴 복사
  커버리지는 6절 폴링 대안이 훨씬 싸게 제공.
- **`NSEvent.timestamp` 단독 활용**: 커널이 찍은 진짜 누름 시각을 주지만, pasteboard 쪽에 대응할 write
  타임스탬프가 없어 단독으로는 판정 불가. (arm의 lag 가드 재료로는 사용 — 4.1.)
- **AXSelectedText로 선택 내용과 클립보드 비교**: 클립보드 **내용을 읽어야 하므로** 프라이버시 원칙(D9,
  README의 "changeCount 정수만") 위반. 기각.

## 9. 기존 문서와의 관계

- planning.md 3.2의 **"금지 우회책" 항목은 "단독 금지"로 유지**하되, arm 결합 시 해소됨을 본 문서로 링크.
- detection-api-comparison.md 1절의 "레이스 구조적 해결 = active 승격" 결론은 본 문서가 대체.
- backlog.md "v1 이후 아이디어"의 active 탭 승격 항목은 본 문서 채택 시 제거 대상.
- 채택 확정 시 decisions.md에 D15로 기록할 것 (결정/근거/기각 대안: active 탭 승격, 폴링 1차 신호).
