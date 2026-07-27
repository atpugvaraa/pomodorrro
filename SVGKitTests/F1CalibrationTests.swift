import XCTest
import CoreGraphics
@testable import pomodorrro

final class F1CalibrationTests: XCTestCase {
    /// Searches the GLOBAL speed-model parameters against real telemetry, minimizing
    /// mean aligned RMS across every available circuit. Prints the ranked configs so
    /// tuning is objective; no per-circuit branching.
    func test_searchGenericParametersAgainstTelemetry() {
        let circuits = F1Circuit.allCases.compactMap { circuit -> (F1Track, F1Telemetry)? in
            guard let track = circuit.loadTrack(), let telemetry = F1Telemetry.reference(for: circuit) else { return nil }
            return (track, telemetry)
        }
        struct Config { let grip, accel, brake, window, minSpeed: CGFloat }
        var results: [(config: Config, shape: CGFloat)] = []

        // Rank by SHAPE CORRELATION (dips at corners, rises on straights). Band allows
        // deep corners so the winner can actually hug the real trace, not sit at the mean.
        for grip in [CGFloat(3), 5, 8] {
          for accel in [CGFloat(3), 6] {
            for brake in [CGFloat(9), 18] {
              for window in [CGFloat(0.015), 0.025, 0.035] {
                for minSpeed in [CGFloat(0.12), 0.20, 0.28] {
                    var correlation: CGFloat = 0
                    for (track, telemetry) in circuits {
                        let profile = F1SpeedProfile(racingLine: track.racingLine, curvatureWindowFraction: window,
                            corneringGrip: grip, accelLimit: accel, brakeLimit: brake, minimumSpeed: minSpeed)
                        let generated = F1SpeedComparison.generatedSpeed(profile: profile, sampleCount: 200)
                        correlation += F1SpeedComparison.shapeCorrelation(generated: generated, telemetry: telemetry)
                    }
                    results.append((Config(grip: grip, accel: accel, brake: brake, window: window, minSpeed: minSpeed),
                                    correlation / CGFloat(circuits.count)))
                }}}}}

        results.sort { $0.shape > $1.shape }   // `shape` field holds mean correlation; higher is better
        print("\n===== CORRELATION CALIBRATION (mean shape correlation over \(circuits.count) circuits) =====")
        for result in results.prefix(8) {
            print(String(format: "grip %.0f  accel %.0f  brake %.0f  window %.3f  minSpeed %.2f  ->  corr %.3f",
                         result.config.grip, result.config.accel, result.config.brake,
                         result.config.window, result.config.minSpeed, result.shape))
        }
        let best = results.first!.config
        var positional: CGFloat = 0
        for (track, telemetry) in circuits {
            let profile = F1SpeedProfile(racingLine: track.racingLine, curvatureWindowFraction: best.window,
                corneringGrip: best.grip, accelLimit: best.accel, brakeLimit: best.brake, minimumSpeed: best.minSpeed)
            positional += F1SpeedComparison.rootMeanSquareError(
                generated: F1SpeedComparison.generatedSpeed(profile: profile, sampleCount: 200), telemetry: telemetry)
        }
        print(String(format: "winner: corr %.3f  positional RMS %.3f", results.first!.shape, positional / CGFloat(circuits.count)))
        print("=================================================================================\n")
        XCTAssertGreaterThan(results.first!.shape, 0)
    }
}
