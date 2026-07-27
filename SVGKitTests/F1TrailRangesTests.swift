import XCTest
import CoreGraphics
@testable import pomodorrro

final class F1TrailRangesTests: XCTestCase {
    private func lap() -> F1Lap {
        F1Lap(track: F1Circuit.monza.loadTrack()!, lapDuration: 60)
    }
    func test_noWrapSingleRange() {
        let lap = lap()
        let start = lap.track.startLineProgress
        let car = start + 0.1 <= 1 ? start + 0.1 : start - 0.1
        let ranges = lap.completedLapTrail(upTo: max(car, 0))
        XCTAssertTrue(ranges.allSatisfy { $0.from <= $0.to })
    }
    func test_wrapProducesTwoRangesCoveringSeam() {
        let lap = lap()
        let start = lap.track.startLineProgress
        let car = max(start - 0.1, 0.0)
        if start > 0.05 {
            let ranges = lap.completedLapTrail(upTo: car)
            XCTAssertEqual(ranges.count, 2)
            XCTAssertEqual(ranges[0].to, 1, accuracy: 1e-9)
            XCTAssertEqual(ranges[1].from, 0, accuracy: 1e-9)
        }
    }
}
