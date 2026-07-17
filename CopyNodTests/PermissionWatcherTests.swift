import Testing
import Foundation
@testable import CopyNod

// 시임: PermissionWatcher — 권한 DB 변경 신호 in → 부여/회수 전이 out.
// 신뢰 상태 제공자와 스케줄러를 주입해 지연 재확인·신호 폭주 코얼레싱을 결정적으로 검증한다.

struct PermissionWatcherTests {
    private final class Box { var changes: [Bool] = [] }

    private func makeWatcher(initiallyTrusted: Bool,
                             scheduler: FakeScheduler) -> (trusted: (Bool) -> Void, changes: () -> [Bool], signal: () -> Void) {
        let box = Box()
        var trusted = initiallyTrusted
        let watcher = PermissionWatcher(isTrusted: { trusted },
                                        scheduler: scheduler) { box.changes.append($0) }
        return ({ trusted = $0 }, { box.changes }, { watcher.accessibilityDatabaseChanged() })
    }

    @Test("권한 회수: 신호 후 재확인에서 false로 바뀌었으면 onChange(false) 1회")
    func revocationFiresOnChangeFalse() {
        let scheduler = FakeScheduler()
        let (setTrusted, changes, signal) = makeWatcher(initiallyTrusted: true, scheduler: scheduler)
        setTrusted(false)
        signal()
        scheduler.tick()
        #expect(changes() == [false])
    }

    @Test("권한 재부여: false → true 전이도 감지한다")
    func regrantFiresOnChangeTrue() {
        let scheduler = FakeScheduler()
        let (setTrusted, changes, signal) = makeWatcher(initiallyTrusted: false, scheduler: scheduler)
        setTrusted(true)
        signal()
        scheduler.tick()
        #expect(changes() == [true])
    }

    @Test("상태가 그대로면 콜백이 없다 (다른 앱의 권한 변경 신호)")
    func unchangedStateFiresNothing() {
        let scheduler = FakeScheduler()
        let (_, changes, signal) = makeWatcher(initiallyTrusted: true, scheduler: scheduler)
        signal()
        scheduler.tick()
        #expect(changes().isEmpty)
    }

    @Test("신호 폭주: 한 번의 변경에 신호가 여러 번 와도 콜백은 1회")
    func burstOfSignalsCoalescesToOneCallback() {
        let scheduler = FakeScheduler()
        let (setTrusted, changes, signal) = makeWatcher(initiallyTrusted: true, scheduler: scheduler)
        setTrusted(false)
        signal(); signal(); signal()
        for _ in 0..<3 { scheduler.tick() }
        #expect(changes() == [false])
    }

    @Test("회수 후 재부여: 전이마다 콜백이 한 번씩 온다")
    func revokeThenRegrantFiresBoth() {
        let scheduler = FakeScheduler()
        let (setTrusted, changes, signal) = makeWatcher(initiallyTrusted: true, scheduler: scheduler)
        setTrusted(false)
        signal()
        scheduler.tick()
        setTrusted(true)
        signal()
        scheduler.tick()
        #expect(changes() == [false, true])
    }
}
