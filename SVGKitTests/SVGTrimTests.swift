import XCTest
import CoreGraphics
@testable import pomodorrro

final class SVGTrimTests: XCTestCase {
    private func line() -> SVGPathGeometry {
        SVGPathGeometry(SVGPathData.cgPath(from: "M0 0 L100 0"))
    }
    func test_trimHalf_boundingBox() {
        let p = line().trimmedPath(from: 0, to: 0.5)
        XCTAssertEqual(p.boundingBoxOfPath.maxX, 50, accuracy: 1.0)
    }
    func test_trimMiddle_startsAtQuarter() {
        let p = line().trimmedPath(from: 0.25, to: 0.75)
        XCTAssertEqual(p.boundingBoxOfPath.minX, 25, accuracy: 1.0)
        XCTAssertEqual(p.boundingBoxOfPath.maxX, 75, accuracy: 1.0)
    }
    func test_invalidRange_empty() {
        XCTAssertTrue(line().trimmedPath(from: 0.8, to: 0.2).isEmpty)
    }
}
