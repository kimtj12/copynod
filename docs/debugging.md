# HUD가 안 뜰 때 디버깅 절차

"⌘C를 눌러도 HUD가 안 뜬다"의 원인을 계층별로 좁히는 절차. 실제 장애
(2026-07-18 잠자기 복귀 무반응, 하단 사례) 진단에 쓴 방법을 그대로 정리했다.

## 사전 지식: 로그 레벨과 영속성

os_log는 레벨에 따라 저장 위치가 다르다 — 이걸 모르면 "로그가 없다"를 오판한다.

| 레벨 | 저장 | 조회 |
|---|---|---|
| debug, info | 메모리 버퍼만 (디스크 미영속) | `log stream`으로 실시간만 가능 |
| notice(기본) 이상 | 디스크 영속 | `log show`로 사후 조회 가능 |

- `verify` 카테고리(감지 판정)는 **debug** — 키 입력에 인접한 고빈도 로그라 의도적으로
  영속하지 않는다. 사후에 `log show`로 안 보이는 게 정상.
- `lifecycle` 카테고리(감지기 start/stop, 권한 전이, 잠자기 복귀 재등록)는 **notice** —
  "언제부터 안 됐는지"를 사후 추적하는 용도.
- zsh에서 `log`는 셸 내장 명령과 겹치므로 반드시 `/usr/bin/log`로 실행.

## 1단계: 프로세스 확인

```sh
pgrep -fl CopyNod
ps -axo pid,lstart,command | grep -i copynod | grep -v grep
```

- 없음 → 앱이 죽은 것. 크래시 리포트(`~/Library/Logs/DiagnosticReports/`) 확인 후 재실행.
- 경로 확인: `/Applications/CopyNod.app`(설치본) 또는 `build/dev-export/`(개발판)만 정상.
  DerivedData 경로면 서명이 다른 빌드 — TCC 꼬임 위험 (CLAUDE.md 참조).

## 2단계: 라이브 로그 + ⌘C — 핵심 판정

```sh
/usr/bin/log stream --predicate 'subsystem == "kr.ai.simpool.CopyNod"' --level debug
```

켜둔 상태에서 아무 앱에서 텍스트를 선택하고 ⌘C를 몇 번 누른다.

| 관찰 | 진단 |
|---|---|
| `verified immediately` 또는 아무 로그 없이 HUD 뜸 | 정상 |
| `verify miss`가 찍힘 | 이벤트는 도달, 복사만 실패(선택 없음 등) — 감지 계층 정상 |
| 로그가 찍히는데 HUD만 안 뜸 | 표시 계층(HUDPresenter) 문제 |
| **한 줄도 안 찍힘** | **이벤트 미도달** — 3단계로 |

주의: 폴링 경로로 성공한 판정은 로그를 안 찍는다. "로그 없음 + HUD 뜸"은 정상이다.

## 3단계: 이벤트 미도달의 원인 좁히기

순서대로 확인:

```sh
# (a) Secure Input 점유 — 켜져 있으면 글로벌 키 모니터가 이벤트를 못 받는다
ioreg -l -w 0 | grep SecureInput
# 출력이 있으면 해당 PID의 앱(주로 패스워드 입력 중인 앱)을 정리

# (b) 감지기 라이프사이클 이력 — 언제 stop됐고 재시작됐는지 (notice라 영속)
/usr/bin/log show --last 1d --predicate 'subsystem == "kr.ai.simpool.CopyNod" AND category == "lifecycle"' --style compact

# (c) TCC 권한 이력 — 권한 출렁임과 WindowServer의 자격 확인 결과
/usr/bin/log show --last 1d --predicate 'process == "tccd" AND eventMessage CONTAINS "CopyNod"' --style compact
```

(c)에서 볼 것: `AUTHREQ_RESULT`의 `authValue` — 0=거부, 1=미확정, 2=허용.
`requesting={com.apple.WindowServer...}` 줄은 WindowServer가 이벤트 배달 자격을
재평가한 것으로, 글로벌 모니터 (재)등록 시점에도 발생한다.

앱이 살아있는지 의심되면 메인 스레드 샘플링:

```sh
sample <PID> 2
# 정상: __CFRunLoopRun → _DPSBlockUntilNextEvent...에서 대기. 다른 곳에 박혀 있으면 행.
```

## 4단계: 복구

1. 앱 재시작 — 글로벌 모니터가 죽은 채 방치된 경우(잠자기 복귀 등) 이걸로 복구된다.
   ```sh
   pkill -x CopyNod; open -a CopyNod        # 설치본
   ```
2. 그래도 안 되면 TCC 꼬임 — `scripts/reset-accessibility.sh` 후 권한 재부여 (CLAUDE.md).

## 함정: 테스트 로그와 혼동 주의

`log stream`에 `CopyNod.debug.dylib` 표기 + `baseline=100` 근처 값 + 같은 밀리초에
여러 스레드가 몰린 패턴은 **유닛 테스트 실행 로그**다 (FakePasteboard가 changeCount=100에서
시작, Swift Testing 병렬 실행). 실제 시스템 pasteboard의 changeCount는 수천 단위.
`arm skipped: lag=40ms`도 `laggedArmIsIgnored` 테스트가 넘기는 고정값(maxArmLag+0.01)이다.

## 사례: 2026-07-18 잠자기 복귀 무반응

- 증상: 전날 23:12 실행 후 밤새 정상 → 잠자기 복귀 후 ⌘C 완전 무반응 (`verify miss`조차 없음).
- 프로세스 생존, 메인 스레드 정상 대기, Secure Input 없음, TCC는 시스템 설정상 허용.
- tccd 이력: 복귀 직후 15:03 TCC DB 출렁임(접근성 앱들 일제 재확인) 속에서 WindowServer의
  CopyNod 자격 확인이 `authValue=1`(미확정) → 이 시점에 이벤트 배달이 끊김.
  15:07 재확인은 `authValue=2`(허용)로 복귀했지만, **이미 등록된 NSEvent 글로벌 모니터는
  스스로 재등록하지 않아** 죽은 채 방치됨.
- 앱 재시작으로 즉시 복구 → 가설 확정.
- 수정: `AppDelegate.startWatchingWake()` — `NSWorkspace.didWakeNotification`에서
  감지기 stop→start로 모니터 재등록. 라이프사이클 notice 로깅도 이때 추가.
