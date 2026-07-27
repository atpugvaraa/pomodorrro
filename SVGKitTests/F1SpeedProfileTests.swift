import XCTest
import CoreGraphics
@testable import pomodorrro

final class F1SpeedProfileTests: XCTestCase {
    private func makePath(_ d: String) -> SVGPath {
        SVGPath(element: SVGPathElement(cgPath: SVGPathData.cgPath(from: d),
                style: SVGStyle()), viewBox: SVGViewBox(x: 0, y: 0, width: 400, height: 400))
    }
    func test_endpointsExact() {
        let profile = F1SpeedProfile(racingLine: makePath("M0 0 L100 0 L100 100 L0 100 Z"))
        XCTAssertEqual(profile.distanceProgress(forLapProgress: 0), 0, accuracy: 1e-6)
        XCTAssertEqual(profile.distanceProgress(forLapProgress: 1), 1, accuracy: 1e-6)
    }
    func test_straightLineIsIdentity() {
        // No curvature => uniform speed => lap progress == distance progress.
        let profile = F1SpeedProfile(racingLine: makePath("M0 0 L100 0"))
        XCTAssertEqual(profile.distanceProgress(forLapProgress: 0.25), 0.25, accuracy: 0.03)
        XCTAssertEqual(profile.distanceProgress(forLapProgress: 0.5), 0.5, accuracy: 0.03)
        XCTAssertEqual(profile.distanceProgress(forLapProgress: 0.75), 0.75, accuracy: 0.03)
    }
    func test_monotonicIncreasing() {
        let profile = F1SpeedProfile(racingLine: makePath("M0 0 L100 0 L100 100 L0 100 Z"))
        var previous: CGFloat = -1
        for step in 0...100 {
            let value = profile.distanceProgress(forLapProgress: CGFloat(step) / 100)
            XCTAssertGreaterThanOrEqual(value + 1e-6, previous)
            previous = value
        }
    }
    func test_cornerReshapesProfile() {
        // Explicit lively params (not the calibrated defaults) to test the mechanism.
        let profile = F1SpeedProfile(racingLine: makePath("M0 0 L100 0 L100 100 L0 100 Z"),
                                     corneringGrip: 6, minimumSpeed: 0.15)
        var maxDelta: CGFloat = 0
        for step in 0...20 {
            let lapProgress = CGFloat(step) / 20
            maxDelta = max(maxDelta, abs(profile.distanceProgress(forLapProgress: lapProgress) - lapProgress))
        }
        XCTAssertGreaterThan(maxDelta, 0.03)   // pronounced, not a near-identity
    }
    func test_speedClearlyVariesAcrossLap() {
        let profile = F1SpeedProfile(racingLine: makePath("M0 0 L100 0 L100 100 L0 100 Z"))
        let steps = 200
        var minStep = CGFloat.greatestFiniteMagnitude, maxStep: CGFloat = 0
        for step in 0..<steps {
            let start = CGFloat(step) / CGFloat(steps)
            let end = CGFloat(step + 1) / CGFloat(steps)
            let travelled = profile.distanceProgress(forLapProgress: end) - profile.distanceProgress(forLapProgress: start)
            minStep = min(minStep, travelled); maxStep = max(maxStep, travelled)
        }
        XCTAssertLessThan(minStep / maxStep, 0.6)    // clear speed variation
    }
    func test_squareLoopCurvaturePeaksAtCorners() {
        // Four 90° corners → clear curvature peaks, near-zero on the straight sides.
        let profile = F1SpeedProfile(racingLine: makePath("M0 0 L100 0 L100 100 L0 100 Z"))
        let peak = profile.curvature.max() ?? 0
        let straightCount = profile.curvature.filter { $0 < peak * 0.2 }.count
        XCTAssertGreaterThan(peak, 0)
        XCTAssertGreaterThan(straightCount, profile.curvature.count / 2)   // mostly straight
    }
    func test_brakingSharperThanAcceleration() {
        // Forward-backward pass: speed falls into a corner faster than it rises out.
        let profile = F1SpeedProfile(racingLine: makePath("M0 0 L100 0 L100 100 L0 100 Z"))
        let steps = 400
        func speed(_ t: CGFloat) -> CGFloat {
            let a = profile.distanceProgress(forLapProgress: t)
            let b = profile.distanceProgress(forLapProgress: min(t + 1.0 / CGFloat(steps), 1))
            return (b - a) * CGFloat(steps)
        }
        var steepestDrop: CGFloat = 0, steepestRise: CGFloat = 0
        for i in 0..<steps {
            let change = speed(CGFloat(i + 1) / CGFloat(steps)) - speed(CGFloat(i) / CGFloat(steps))
            steepestDrop = min(steepestDrop, change); steepestRise = max(steepestRise, change)
        }
        XCTAssertGreaterThan(abs(steepestDrop), steepestRise)   // braking is sharper
    }
}
