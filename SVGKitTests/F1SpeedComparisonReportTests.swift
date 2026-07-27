import XCTest
import CoreGraphics
@testable import pomodorrro

final class F1SpeedComparisonReportTests: XCTestCase {
    /// Prints how far each circuit's generated profile sits from real telemetry
    /// (mean-normalized RMS, best circular alignment). For human review; asserts
    /// only that the comparison runs without NaN.
    func test_reportGeneratedVsTelemetry() {
        var rows: [(circuit: String, source: String, season: Int, rms: CGFloat)] = []

        for circuit in F1Circuit.allCases {
            guard let track = circuit.loadTrack(),
                  let telemetry = F1Telemetry.reference(for: circuit) else { continue }
            let comparison = F1SpeedComparison(track: track, telemetry: telemetry)
            XCTAssertFalse(comparison.rootMeanSquareError.isNaN, "\(circuit.displayName): NaN RMS")
            rows.append((circuit.displayName, telemetry.source, telemetry.season, comparison.rootMeanSquareError))
        }

        rows.sort { $0.rms > $1.rms }   // worst first
        print("\n===== GENERATED vs TELEMETRY (RMS, mean-normalized) =====")
        for row in rows {
            let name = row.circuit.padding(toLength: 18, withPad: " ", startingAt: 0)
            print(String(format: "%@ %@ %d   RMS %.3f", name, row.source, row.season, row.rms))
        }
        let meanError = rows.map(\.rms).reduce(0, +) / CGFloat(max(rows.count, 1))
        print(String(format: "\nmean RMS over %d circuits: %.3f", rows.count, meanError))
        print("=========================================================\n")
    }
}
