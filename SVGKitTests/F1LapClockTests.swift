import XCTest
import CoreGraphics
@testable import pomodorrro

final class F1LapClockTests: XCTestCase {
    private func lap() -> F1Lap {
        F1Lap(track: F1Circuit.monza.loadTrack()!, lapDuration: 60)
    }
    func test_lapProgress() {
        XCTAssertEqual(lap().lapProgress(atElapsedTime: 0), 0, accuracy: 1e-9)
        XCTAssertEqual(lap().lapProgress(atElapsedTime: 30), 0.5, accuracy: 1e-9)
        XCTAssertEqual(lap().lapProgress(atElapsedTime: 60), 0, accuracy: 1e-9)
        XCTAssertEqual(lap().lapProgress(atElapsedTime: 90), 0.5, accuracy: 1e-9)
    }
    func test_completedLaps() {
        XCTAssertEqual(lap().completedLaps(atElapsedTime: 0), 0)
        XCTAssertEqual(lap().completedLaps(atElapsedTime: 59), 0)
        XCTAssertEqual(lap().completedLaps(atElapsedTime: 60), 1)
        XCTAssertEqual(lap().completedLaps(atElapsedTime: 25 * 60), 25)
    }
    func test_continuousElapsedTimeExtrapolatesWhenRunning() {
        let anchorDate = Date(timeIntervalSince1970: 1000)
        let now = Date(timeIntervalSince1970: 1002.5)
        XCTAssertEqual(lap().continuousElapsedTime(anchorElapsed: 10, anchorDate: anchorDate,
                                                   now: now, isRunning: true), 12.5, accuracy: 1e-9)
    }
    func test_continuousElapsedTimeFrozenWhenPaused() {
        let anchorDate = Date(timeIntervalSince1970: 1000)
        let now = Date(timeIntervalSince1970: 1002.5)
        XCTAssertEqual(lap().continuousElapsedTime(anchorElapsed: 10, anchorDate: anchorDate,
                                                   now: now, isRunning: false), 10, accuracy: 1e-9)
    }
}
