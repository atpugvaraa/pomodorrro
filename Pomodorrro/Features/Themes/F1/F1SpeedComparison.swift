import SwiftUI

/// Compares our generated speed profile against a real telemetry lap. Both are
/// mean-normalized; we search circular phase shift + orientation so the score
/// reflects SHAPE differences, not where the lap happens to start or wind.
struct F1SpeedComparison {
    let rootMeanSquareError: CGFloat
    let generated: [CGFloat]     // aligned to measured, for plotting
    let measured: [CGFloat]
    let shift: Int
    let reversed: Bool

    /// Mean-normalized generated speed (track distance advanced per unit of lap progress).
    static func generatedSpeed(track: F1Track, sampleCount: Int) -> [CGFloat] {
        generatedSpeed(profile: track.speedProfile, sampleCount: sampleCount)
    }

    /// Same, from any profile — lets calibration score arbitrary parameter sets.
    static func generatedSpeed(profile: F1SpeedProfile, sampleCount: Int) -> [CGFloat] {
        var speeds = [CGFloat](repeating: 0, count: sampleCount)
        for step in 0..<sampleCount {
            let start = profile.distanceProgress(forLapProgress: CGFloat(step) / CGFloat(sampleCount))
            let end = profile.distanceProgress(forLapProgress: CGFloat(step + 1) / CGFloat(sampleCount))
            speeds[step] = (end - start) * CGFloat(sampleCount)
        }
        let mean = max(speeds.reduce(0, +) / CGFloat(sampleCount), 0.0001)
        return speeds.map { $0 / mean }
    }

    /// Best-aligned RMS between a generated curve and telemetry (shape only —
    /// searches circular phase shift + orientation).
    static func rootMeanSquareError(generated: [CGFloat], telemetry: F1Telemetry) -> CGFloat {
        alignedError(generated: generated, telemetry: telemetry).error
    }

    /// Position-independent shape error: compares the speed DISTRIBUTION (sorted
    /// curves), so a correctly-shaped corner counts even when our SVG-centerline
    /// places it at a slightly different lap position than the real lap. Rewards
    /// matching how much of the lap is spent slow / medium / fast — not flatness.
    static func shapeError(generated: [CGFloat], telemetry: F1Telemetry) -> CGFloat {
        let count = generated.count
        let measured = (0..<count).map { telemetry.speed(atLapDistance: CGFloat($0) / CGFloat(count - 1)) }
        let sortedGenerated = generated.sorted()
        let sortedMeasured = measured.sorted()
        let total = zip(sortedGenerated, sortedMeasured).reduce(CGFloat(0)) { $0 + ($1.0 - $1.1) * ($1.0 - $1.1) }
        return sqrt(total / CGFloat(count))
    }

    /// Best phase-aligned Pearson correlation between generated and telemetry speed
    /// (searches circular shift + orientation). Rewards matching the real ups/downs —
    /// dips at corners, rises on straights — and scores a flat "average" curve ~0.
    static func shapeCorrelation(generated: [CGFloat], telemetry: F1Telemetry) -> CGFloat {
        let count = generated.count
        let measured = (0..<count).map { telemetry.speed(atLapDistance: CGFloat($0) / CGFloat(count - 1)) }
        func pearson(_ a: [CGFloat], _ b: [CGFloat]) -> CGFloat {
            let meanA = a.reduce(0, +) / CGFloat(a.count)
            let meanB = b.reduce(0, +) / CGFloat(b.count)
            var covariance: CGFloat = 0, varianceA: CGFloat = 0, varianceB: CGFloat = 0
            for i in a.indices {
                let x = a[i] - meanA, y = b[i] - meanB
                covariance += x * y; varianceA += x * x; varianceB += y * y
            }
            let denominator = (varianceA * varianceB).squareRoot()
            return denominator > 0 ? covariance / denominator : 0
        }
        var best = -CGFloat.greatestFiniteMagnitude
        for reversed in [false, true] {
            let oriented = reversed ? Array(measured.reversed()) : measured
            for shift in stride(from: 0, to: count, by: 2) {
                best = max(best, pearson(generated, Array(oriented[shift...] + oriented[..<shift])))
            }
        }
        return best   // −1…1
    }

    private static func alignedError(generated: [CGFloat], telemetry: F1Telemetry)
        -> (error: CGFloat, measured: [CGFloat], shift: Int, reversed: Bool) {
        let count = generated.count
        let measuredCurve = (0..<count).map { telemetry.speed(atLapDistance: CGFloat($0) / CGFloat(count - 1)) }
        func rootMeanSquare(_ a: [CGFloat], _ b: [CGFloat]) -> CGFloat {
            let total = zip(a, b).reduce(CGFloat(0)) { $0 + ($1.0 - $1.1) * ($1.0 - $1.1) }
            return sqrt(total / CGFloat(a.count))
        }
        var best = (error: CGFloat.greatestFiniteMagnitude, measured: measuredCurve, shift: 0, reversed: false)
        for reversed in [false, true] {
            let oriented = reversed ? Array(measuredCurve.reversed()) : measuredCurve
            for shift in stride(from: 0, to: count, by: 2) {
                let rotated = Array(oriented[shift...] + oriented[..<shift])
                let error = rootMeanSquare(generated, rotated)
                if error < best.error { best = (error, rotated, shift, reversed) }
            }
        }
        return best
    }

    init(track: F1Track, telemetry: F1Telemetry, sampleCount: Int = 200) {
        let generatedCurve = F1SpeedComparison.generatedSpeed(track: track, sampleCount: sampleCount)
        let best = F1SpeedComparison.alignedError(generated: generatedCurve, telemetry: telemetry)
        self.rootMeanSquareError = best.error
        self.generated = generatedCurve
        self.measured = best.measured
        self.shift = best.shift
        self.reversed = best.reversed
    }
}
