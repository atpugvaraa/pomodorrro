import SwiftUI

// MARK: - Start line

/// Finds where the SVG's visual start/finish marker lies on the racing line, so
/// lap progress 0 can be anchored to the start line for any circuit.
func findStartLineProgress(on racingLine: SVGPath, markedBy startFinishMarker: SVGPath,
                           sampleCount: Int = 2000) -> CGFloat {
    let startLineCenter = startFinishMarker.boundingBox.center

    var closestTrackProgress: CGFloat = 0
    var shortestDistance = CGFloat.greatestFiniteMagnitude

    for sampleIndex in 0...sampleCount {
        let progress = CGFloat(sampleIndex) / CGFloat(sampleCount)
        let trackPoint = racingLine.point(at: progress)
        let distanceToStartLine = trackPoint.distanceSquared(to: startLineCenter)
        if distanceToStartLine < shortestDistance {
            shortestDistance = distanceToStartLine
            closestTrackProgress = progress
        }
    }
    return closestTrackProgress
}

private extension CGRect {
    var center: CGPoint { CGPoint(x: midX, y: midY) }
}
private extension CGPoint {
    func distanceSquared(to other: CGPoint) -> CGFloat {
        let deltaX = x - other.x
        let deltaY = y - other.y
        return deltaX * deltaX + deltaY * deltaY
    }
}

// MARK: - Speed profile

/// Reshapes lap TIME into lap DISTANCE so the car brakes into corners and
/// accelerates onto straights, while one lap still takes exactly one lap duration
/// (time and distance both span 0…1). Built once per circuit.
struct F1SpeedProfile {
    let curvature: [CGFloat]                                // turning per lap-fraction, per sample
    let speed: [CGFloat]                                    // final speed per sample, post forward-backward
    private let distanceProgressByLapProgress: [CGFloat]    // sampled at uniform lap-progress

    // Defaults calibrated to hug the real trace (max shape correlation) across all 23
    // circuits — the small window sharpens corner detection so the curve dips into
    // corners instead of sitting at the average. Generic, no per-circuit tuning.
    init(racingLine: SVGPath, sampleCount: Int = 400, curvatureWindowFraction: CGFloat = 0.015,
         corneringGrip: CGFloat = 3, accelLimit: CGFloat = 3, brakeLimit: CGFloat = 9,
         minimumSpeed: CGFloat = 0.28, smoothingWindow: Int = 5) {
        let count = max(sampleCount, 32)
        let stepDistance = 1.0 / CGFloat(count)             // each sample = 1/count of the lap

        // Tangent angle at each sample (SVGPathGeometry samples uniformly by arc length).
        var angle = [CGFloat](repeating: 0, count: count)
        for i in 0..<count { angle[i] = CGFloat(racingLine.angle(at: CGFloat(i) / CGFloat(count)).radians) }

        // Curvature = turning measured over a fixed arc-length WINDOW (not adjacent
        // samples), so tangent jitter doesn't create phantom corners. Turning per lap-fraction.
        let window = max(1, Int((curvatureWindowFraction * CGFloat(count)).rounded()))
        var rawCurvature = [CGFloat](repeating: 0, count: count)
        for i in 0..<count {
            var change = angle[(i + window) % count] - angle[(i - window + count) % count]
            while change > .pi { change -= 2 * .pi }
            while change < -.pi { change += 2 * .pi }
            rawCurvature[i] = abs(change) / (2 * curvatureWindowFraction)
        }
        let smoothedCurvature = F1SpeedProfile.circularMovingAverage(rawCurvature, window: smoothingWindow)

        // Corner speed limit in [minimumSpeed, 1]: tighter corner → lower limit.
        var speed = smoothedCurvature.map { minimumSpeed + (1 - minimumSpeed) / (1 + corneringGrip * $0) }

        // Forward-backward acceleration-limited pass (v² form) so speed can only rise
        // as fast as the car accelerates and only fall as fast as it brakes; braking is
        // harder than acceleration. Iterated because the lap is a closed loop.
        for _ in 0..<3 {
            for i in 0..<count {                            // forward: acceleration-limited
                let previous = speed[(i - 1 + count) % count]
                speed[i] = min(speed[i], (previous * previous + 2 * accelLimit * stepDistance).squareRoot())
            }
            for i in stride(from: count - 1, through: 0, by: -1) {   // backward: braking-limited
                let next = speed[(i + 1) % count]
                speed[i] = min(speed[i], (next * next + 2 * brakeLimit * stepDistance).squareRoot())
            }
        }

        // Time to cover each equal-distance step = distance / speed; invert the
        // cumulative-time curve to get distance progress at uniform lap (time) progress.
        var timeAtDistance = [CGFloat](repeating: 0, count: count + 1)
        for i in 0..<count { timeAtDistance[i + 1] = timeAtDistance[i] + stepDistance / max(speed[i], 0.0001) }
        let totalTime = max(timeAtDistance[count], 0.0001)

        var table = [CGFloat](repeating: 0, count: count + 1)
        var segment = 0
        for j in 0...count {
            let targetTime = CGFloat(j) / CGFloat(count) * totalTime
            while segment < count && timeAtDistance[segment + 1] < targetTime { segment += 1 }
            if segment >= count { table[j] = 1; continue }
            let start = timeAtDistance[segment], end = timeAtDistance[segment + 1]
            let fraction = end > start ? (targetTime - start) / (end - start) : 0
            table[j] = (CGFloat(segment) + fraction) / CGFloat(count)
        }
        table[0] = 0
        table[count] = 1

        self.curvature = smoothedCurvature
        self.speed = speed
        self.distanceProgressByLapProgress = table
    }

    /// Distance travelled along the lap (0…1) for a linear lap (time) progress (0…1).
    func distanceProgress(forLapProgress lapProgress: CGFloat) -> CGFloat {
        let clampedLapProgress = min(max(lapProgress, 0), 1)
        let position = clampedLapProgress * CGFloat(distanceProgressByLapProgress.count - 1)
        let lowerIndex = min(Int(position), distanceProgressByLapProgress.count - 2)
        let fraction = position - CGFloat(lowerIndex)
        let lower = distanceProgressByLapProgress[lowerIndex]
        let upper = distanceProgressByLapProgress[lowerIndex + 1]
        return lower + (upper - lower) * fraction
    }

    private static func circularMovingAverage(_ values: [CGFloat], window: Int) -> [CGFloat] {
        guard window > 1 else { return values }
        let count = values.count
        return (0..<count).map { i in
            var sum: CGFloat = 0
            for offset in -(window / 2)...(window / 2) { sum += values[((i + offset) % count + count) % count] }
            return sum / CGFloat(window / 2 * 2 + 1)
        }
    }
}

// MARK: - Lap

/// Turns elapsed seconds into a position on the racing line. One lap takes exactly
/// `lapDuration` (default 60s); the speed profile only changes WHERE the car is at
/// a given moment, and the start-line anchor makes lap progress 0 the start line.
struct F1Lap {
    let track: F1Track
    let lapDuration: TimeInterval

    /// Linear progress through the current lap (0…1), before the speed profile.
    func lapProgress(atElapsedTime elapsedTime: TimeInterval) -> CGFloat {
        let laps = elapsedTime / lapDuration
        return CGFloat(laps - laps.rounded(.down))
    }

    func completedLaps(atElapsedTime elapsedTime: TimeInterval) -> Int {
        Int((elapsedTime / lapDuration).rounded(.down))
    }

    /// Extrapolates a low-frequency (e.g. 1 Hz) elapsed clock up to frame rate so
    /// motion stays smooth between ticks; frozen while paused.
    func continuousElapsedTime(anchorElapsed: TimeInterval, anchorDate: Date,
                               now: Date, isRunning: Bool) -> TimeInterval {
        guard isRunning else { return anchorElapsed }
        return anchorElapsed + max(0, now.timeIntervalSince(anchorDate))
    }

    /// Position on the racing line (0…1) for a linear lap progress, anchored to the
    /// start line. With `speedProfiled` false the car holds a constant speed.
    func trackProgress(atLapProgress lapProgress: CGFloat, speedProfiled: Bool = true) -> CGFloat {
        let distanceProgress = speedProfiled
            ? track.speedProfile.distanceProgress(forLapProgress: lapProgress)
            : lapProgress
        return (track.startLineProgress + distanceProgress).truncatingRemainder(dividingBy: 1)
    }

    func trackProgress(atElapsedTime elapsedTime: TimeInterval, speedProfiled: Bool = true) -> CGFloat {
        trackProgress(atLapProgress: lapProgress(atElapsedTime: elapsedTime), speedProfiled: speedProfiled)
    }

    /// The stretch already driven this lap (start line → car), split at the 0/1 seam.
    func completedLapTrail(upTo trackProgress: CGFloat) -> [(from: CGFloat, to: CGFloat)] {
        let start = track.startLineProgress
        if trackProgress >= start { return [(start, trackProgress)] }
        return [(start, 1), (0, trackProgress)]
    }
}
