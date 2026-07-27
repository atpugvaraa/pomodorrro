import XCTest
import CoreGraphics
@testable import pomodorrro

final class F1CircuitValidationTests: XCTestCase {
    /// Every bundled circuit must load and produce a sane profile. Anomalies are
    /// printed for human review, not failed on.
    func test_allCircuitsAreValidAndReported() {
        var rows: [String] = []
        var flagged: [String] = []

        for circuit in F1Circuit.allCases {
            guard let track = circuit.loadTrack() else {
                XCTFail("\(circuit.displayName): failed to load"); continue
            }
            XCTAssertGreaterThan(track.racingLine.length, 0, "\(circuit.displayName): empty racing line")

            let report = F1SpeedProfileReport(track: track, circuit: circuit)
            // True invariants (a failure here is a real bug, not a taste call):
            XCTAssertFalse(report.averageSpeed.isNaN, "\(circuit.displayName): NaN speed")
            XCTAssertGreaterThan(report.minimumSpeed, 0, "\(circuit.displayName): non-positive minimum speed")
            XCTAssertEqual(report.averageSpeed, 1, accuracy: 0.2, "\(circuit.displayName): average speed should be ≈1")
            XCTAssertEqual(track.speedProfile.distanceProgress(forLapProgress: 0), 0, accuracy: 1e-6)
            XCTAssertEqual(track.speedProfile.distanceProgress(forLapProgress: 1), 1, accuracy: 1e-6)

            rows.append(report.tableRow)
            if !report.anomalies.isEmpty { flagged.append("\(circuit.displayName): \(report.anomalies.joined(separator: ", "))") }
        }

        print("\n===== F1 SPEED PROFILE REPORT (\(F1Circuit.allCases.count) circuits) =====")
        rows.forEach { print($0) }
        print("\n----- FLAGGED -----")
        flagged.isEmpty ? print("none") : flagged.forEach { print($0) }
        print("===================================================\n")
    }
}
