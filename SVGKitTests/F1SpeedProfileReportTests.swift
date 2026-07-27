import XCTest
import CoreGraphics
@testable import pomodorrro

final class F1SpeedProfileReportTests: XCTestCase {
    private func makeTrack(_ d: String) -> F1Track {
        let racingLine = SVGPath(element: SVGPathElement(cgPath: SVGPathData.cgPath(from: d), style: SVGStyle()),
                                 viewBox: SVGViewBox(x: 0, y: 0, width: 400, height: 400))
        return F1Track(racingLine: racingLine, startFinishMarker: nil, viewBox: SVGViewBox(x: 0, y: 0, width: 400, height: 400))
    }
    func test_straightHasFlatProfile() {
        let report = F1SpeedProfileReport(track: makeTrack("M0 0 L100 0"), circuit: .monza)
        XCTAssertEqual(report.averageSpeed, 1, accuracy: 0.05)
        XCTAssertEqual(report.speedVariation, 1, accuracy: 0.1)          // no corners → constant
        XCTAssertTrue(report.anomalies.contains { $0.contains("constant") })
    }
    func test_squareLoopVaries() {
        let report = F1SpeedProfileReport(track: makeTrack("M0 0 L100 0 L100 100 L0 100 Z"), circuit: .monza)
        XCTAssertGreaterThan(report.speedVariation, 1.3)                 // corners slow it
        XCTAssertGreaterThan(report.maximumSpeed, report.minimumSpeed)
        XCTAssertGreaterThan(report.averageSpeed, 0.8)
        XCTAssertLessThan(report.averageSpeed, 1.2)
    }
    func test_noNaNs() {
        let report = F1SpeedProfileReport(track: makeTrack("M0 0 L100 0 L100 100 L0 100 Z"), circuit: .monza)
        for value in [report.minimumSpeed, report.maximumSpeed, report.averageSpeed,
                      report.hardestBraking, report.strongestAcceleration, report.longestStraightFraction] {
            XCTAssertFalse(value.isNaN); XCTAssertFalse(value.isInfinite)
        }
    }
}
