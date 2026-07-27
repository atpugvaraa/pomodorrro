import XCTest
import CoreGraphics
@testable import pomodorrro

final class F1SpeedDirectionTests: XCTestCase {
    /// The car MUST be slower where the track is more curved. Compares the model's
    /// speed in the most-curved quarter of samples vs the least-curved quarter, on a
    /// real circuit — a direct guard against any speed/curvature inversion.
    func test_cornersAreSlowerThanStraights() {
        for circuit in [F1Circuit.monza, .silverstone, .monaco] {
            let profile = circuit.loadTrack()!.speedProfile
            let indices = profile.curvature.indices.sorted { profile.curvature[$0] < profile.curvature[$1] }
            let quarter = max(indices.count / 4, 1)
            let straightSamples = indices.prefix(quarter)      // lowest curvature
            let cornerSamples = indices.suffix(quarter)        // highest curvature
            let straightSpeed = straightSamples.map { profile.speed[$0] }.reduce(0, +) / CGFloat(quarter)
            let cornerSpeed = cornerSamples.map { profile.speed[$0] }.reduce(0, +) / CGFloat(quarter)
            XCTAssertLessThan(cornerSpeed, straightSpeed, "\(circuit.displayName): corners not slower than straights")
        }
    }
}
