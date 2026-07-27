import XCTest
import CoreGraphics
@testable import pomodorrro

final class F1SpeedComparisonTests: XCTestCase {
    func test_identicalCurvesScoreZero() {
        // A telemetry curve equal to the generated curve must align to ~0 error.
        let track = F1Circuit.monza.loadTrack()!
        let generated = F1SpeedComparison.generatedSpeed(track: track, sampleCount: 200)
        let fake = F1Telemetry(circuit: "monza", source: "test", season: 0, speed: generated)
        let comparison = F1SpeedComparison(track: track, telemetry: fake, sampleCount: 200)
        XCTAssertLessThan(comparison.rootMeanSquareError, 0.02)
    }
    func test_shiftedCurveStillAligns() {
        let track = F1Circuit.monza.loadTrack()!
        let base = F1SpeedComparison.generatedSpeed(track: track, sampleCount: 200)
        let shifted = Array(base[50...] + base[..<50])          // phase-shift
        let fake = F1Telemetry(circuit: "monza", source: "test", season: 0, speed: shifted)
        let comparison = F1SpeedComparison(track: track, telemetry: fake, sampleCount: 200)
        XCTAssertLessThan(comparison.rootMeanSquareError, 0.05)  // circular align recovers it
    }
}
