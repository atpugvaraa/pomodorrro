import XCTest
import CoreGraphics
@testable import pomodorrro

final class F1LapTests: XCTestCase {
    func test_loadTrackCachesInstance() {
        XCTAssertTrue(F1Circuit.monza.loadTrack() === F1Circuit.monza.loadTrack())
    }
    func test_lapAnchorsStartLine() {
        let track = F1Circuit.monza.loadTrack()
        XCTAssertNotNil(track)
        let lap = F1Lap(track: track!, lapDuration: 60)
        // At lap progress 0 the car sits on the start line.
        XCTAssertEqual(lap.trackProgress(atLapProgress: 0), track!.startLineProgress, accuracy: 1e-6)
    }
    func test_lapProgressOneReturnsToStart() {
        let track = F1Circuit.monza.loadTrack()!
        let lap = F1Lap(track: track, lapDuration: 60)
        XCTAssertEqual(lap.trackProgress(atLapProgress: 0),
                       lap.trackProgress(atLapProgress: 1), accuracy: 1e-6)
    }
    func test_speedProfileDisabledIsConstantSpeed() {
        let track = F1Circuit.monza.loadTrack()!
        let lap = F1Lap(track: track, lapDuration: 60)
        // With the profile off, distance advances linearly: half a lap of progress
        // sits half the track past the start line.
        let expected = (track.startLineProgress + 0.5).truncatingRemainder(dividingBy: 1)
        XCTAssertEqual(lap.trackProgress(atLapProgress: 0.5, speedProfiled: false), expected, accuracy: 1e-6)
    }
}
