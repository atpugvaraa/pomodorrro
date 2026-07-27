import SwiftUI

/// Diagnostics for one circuit's speed profile: what the algorithm actually does,
/// so tuning is measured rather than guessed. Speed is normalized so the average
/// is ≈1 over a lap (one lap always takes one lap duration).
struct F1SpeedProfileReport {
    let circuit: F1Circuit
    let minimumSpeed: CGFloat
    let maximumSpeed: CGFloat
    let averageSpeed: CGFloat
    let speedVariation: CGFloat            // maximum / minimum
    let hardestBraking: CGFloat            // most negative change in speed per lap-fraction
    let strongestAcceleration: CGFloat     // most positive change in speed per lap-fraction
    let tightestCornerProgress: CGFloat
    let tightestCornerCurvature: CGFloat
    let longestStraightFraction: CGFloat   // longest low-curvature run, as a fraction of the lap
    let speedOscillations: Int             // sign changes in acceleration
    let anomalies: [String]

    init(track: F1Track, circuit: F1Circuit, sampleCount: Int = 400) {
        self.circuit = circuit
        let stepCount = max(sampleCount, 16)

        // Speed = how fast track distance advances per unit of lap (time) progress.
        var speeds = [CGFloat](repeating: 0, count: stepCount)
        for step in 0..<stepCount {
            let lapProgressStart = CGFloat(step) / CGFloat(stepCount)
            let lapProgressEnd = CGFloat(step + 1) / CGFloat(stepCount)
            let distanceStart = track.speedProfile.distanceProgress(forLapProgress: lapProgressStart)
            let distanceEnd = track.speedProfile.distanceProgress(forLapProgress: lapProgressEnd)
            speeds[step] = (distanceEnd - distanceStart) * CGFloat(stepCount)
        }
        let minimum = speeds.min() ?? 0
        let maximum = speeds.max() ?? 0
        let average = speeds.reduce(0, +) / CGFloat(stepCount)

        // Acceleration = change in speed between steps (negative = braking).
        var accelerations = [CGFloat](repeating: 0, count: stepCount - 1)
        for step in 0..<(stepCount - 1) {
            accelerations[step] = (speeds[step + 1] - speeds[step]) * CGFloat(stepCount)
        }
        let strongestAcceleration = accelerations.max() ?? 0
        let hardestBraking = accelerations.min() ?? 0
        var oscillations = 0
        for step in 1..<accelerations.count where accelerations[step].sign != accelerations[step - 1].sign {
            oscillations += 1
        }

        // Curvature straight from the racing line (turning per lap-fraction).
        var curvatures = [CGFloat](repeating: 0, count: stepCount)
        var previousAngle = CGFloat(track.racingLine.angle(at: 0).radians)
        for step in 0..<stepCount {
            let lapProgress = CGFloat(step + 1) / CGFloat(stepCount)
            let angle = CGFloat(track.racingLine.angle(at: lapProgress).radians)
            var change = angle - previousAngle
            while change > .pi { change -= 2 * .pi }
            while change < -.pi { change += 2 * .pi }
            curvatures[step] = abs(change) * CGFloat(stepCount)
            previousAngle = angle
        }
        let meanCurvature = max(curvatures.reduce(0, +) / CGFloat(stepCount), 0.0001)
        let tightestIndex = curvatures.indices.max(by: { curvatures[$0] < curvatures[$1] }) ?? 0

        // Longest straight = longest contiguous run well below the mean curvature.
        let straightThreshold = meanCurvature * 0.4
        var longestRun = 0, currentRun = 0
        for curvature in curvatures {
            currentRun = curvature < straightThreshold ? currentRun + 1 : 0
            longestRun = max(longestRun, currentRun)
        }

        var largestSpeedJump: CGFloat = 0
        for step in 0..<(stepCount - 1) {
            largestSpeedJump = max(largestSpeedJump, abs(speeds[step + 1] - speeds[step]))
        }

        self.minimumSpeed = minimum
        self.maximumSpeed = maximum
        self.averageSpeed = average
        self.speedVariation = minimum > 0 ? maximum / minimum : .infinity
        self.hardestBraking = hardestBraking
        self.strongestAcceleration = strongestAcceleration
        self.tightestCornerProgress = CGFloat(tightestIndex) / CGFloat(stepCount)
        self.tightestCornerCurvature = curvatures[tightestIndex]
        self.longestStraightFraction = CGFloat(longestRun) / CGFloat(stepCount)
        self.speedOscillations = oscillations

        // Observations for a human to judge — flagged, not enforced.
        var anomalies: [String] = []
        if minimum > 0 && maximum / minimum < 1.25 { anomalies.append("almost constant speed") }
        if minimum < 0.12 { anomalies.append("excessive braking") }
        if oscillations > stepCount / 6 { anomalies.append("oscillating speed") }
        if largestSpeedJump > 0.5 { anomalies.append("sudden speed spike") }
        self.anomalies = anomalies
    }

    /// One aligned row for the console report.
    var tableRow: String {
        let name = circuit.displayName.padding(toLength: 18, withPad: " ", startingAt: 0)
        func f(_ value: CGFloat) -> String { String(format: "%5.2f", value) }
        let flags = anomalies.isEmpty ? "" : "  ⚠︎ " + anomalies.joined(separator: ", ")
        return "\(name) min \(f(minimumSpeed))  max \(f(maximumSpeed))  var \(f(speedVariation))  "
             + "brake \(f(hardestBraking))  accel \(f(strongestAcceleration))  "
             + "straight \(f(longestStraightFraction))  osc \(speedOscillations)\(flags)"
    }
}
