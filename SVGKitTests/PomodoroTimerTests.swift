import XCTest
@testable import pomodorrro

final class PomodoroTimerTests: XCTestCase {
    private static let suite = "PomodoroTimerTests"
    private var defaults: UserDefaults!

    override func setUp() {
        super.setUp()
        defaults = UserDefaults(suiteName: Self.suite)!
        wipe()
    }

    override func tearDown() {
        wipe()
        super.tearDown()
    }

    /// The tests run inside the host app, where an unregistered suite name resolves back to the
    /// app's own preferences domain — so clear both, otherwise a test run leaves the real app
    /// showing whatever session count the last assertion happened to end on.
    private func wipe() {
        defaults.removePersistentDomain(forName: Self.suite)
        UserDefaults.standard.removeObject(forKey: "completedSessions")
    }

    func testPhasesAdvanceOnSchedule() {
        let start = Date(timeIntervalSince1970: 0)
        let timer = PomodoroTimer(defaults: defaults)

        timer.start(at: start)
        XCTAssertEqual(timer.phase, .work)
        XCTAssertEqual(timer.remaining, 20 * 60)

        timer.tick(at: start.addingTimeInterval(19 * 60))
        XCTAssertEqual(timer.phase, .work)
        XCTAssertEqual(timer.remaining, 60)

        // 20 minutes in: work is done, break begins, the session is banked.
        timer.tick(at: start.addingTimeInterval(20 * 60))
        XCTAssertEqual(timer.phase, .rest)
        XCTAssertEqual(timer.completedSessions, 1)
        XCTAssertEqual(timer.remaining, 5 * 60)

        // 5 more minutes: back to work on a fresh session.
        timer.tick(at: start.addingTimeInterval(25 * 60))
        XCTAssertEqual(timer.phase, .work)
        XCTAssertEqual(timer.sessionIndex, 1)
        XCTAssertEqual(timer.completedSessions, 1)
    }

    func testSuspensionSpanningSeveralPhasesCatchesUp() {
        let start = Date(timeIntervalSince1970: 0)
        let timer = PomodoroTimer(defaults: defaults)

        timer.start(at: start)
        // 50 minutes = work, break, work, break — two sessions banked, back at work.
        timer.tick(at: start.addingTimeInterval(50 * 60))

        XCTAssertEqual(timer.phase, .work)
        XCTAssertEqual(timer.completedSessions, 2)
        XCTAssertEqual(timer.remaining, 20 * 60)
    }

    func testPauseFreezesTheClockAndResetRewindsThePhase() {
        let start = Date(timeIntervalSince1970: 0)
        let timer = PomodoroTimer(defaults: defaults)

        timer.start(at: start)
        timer.pause(at: start.addingTimeInterval(5 * 60))
        XCTAssertFalse(timer.isRunning)
        XCTAssertEqual(timer.remaining, 15 * 60)

        // Time passing while paused must not move the clock.
        timer.tick(at: start.addingTimeInterval(30 * 60))
        XCTAssertEqual(timer.phase, .work)
        XCTAssertEqual(timer.remaining, 15 * 60)

        timer.reset()
        XCTAssertEqual(timer.remaining, 20 * 60)
        XCTAssertEqual(timer.completedSessions, 0)
    }

    func testCompletedSessionsSurviveANewInstance() {
        let start = Date(timeIntervalSince1970: 0)
        let timer = PomodoroTimer(defaults: defaults)
        timer.start(at: start)
        timer.tick(at: start.addingTimeInterval(20 * 60))
        XCTAssertEqual(timer.completedSessions, 1)

        XCTAssertEqual(PomodoroTimer(defaults: defaults).completedSessions, 1)
    }
}
