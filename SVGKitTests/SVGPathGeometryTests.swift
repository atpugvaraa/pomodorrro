import XCTest
import CoreGraphics
@testable import pomodorrro

final class SVGPathGeometryTests: XCTestCase {
    private func line() -> SVGPathGeometry {
        SVGPathGeometry(SVGPathData.cgPath(from: "M0 0 L100 0"))
    }
    func test_lengthOfStraightLine() {
        XCTAssertEqual(line().length, 100, accuracy: 0.5)
    }
    func test_endpoints() {
        XCTAssertEqual(line().point(at: 0).x, 0, accuracy: 0.5)
        XCTAssertEqual(line().point(at: 1).x, 100, accuracy: 0.5)
        XCTAssertEqual(line().point(at: 0.5).x, 50, accuracy: 0.5)
    }
    func test_progressClamped() {
        XCTAssertEqual(line().point(at: 2).x, 100, accuracy: 0.5)
        XCTAssertEqual(line().point(at: -1).x, 0, accuracy: 0.5)
    }
    func test_angleOfHorizontalLine_isZero() {
        XCTAssertEqual(line().angle(at: 0.5).degrees, 0, accuracy: 0.5)
    }
    func test_angleOfVerticalLine_is90() {
        let g = SVGPathGeometry(SVGPathData.cgPath(from: "M0 0 L0 100"))
        XCTAssertEqual(abs(g.angle(at: 0.5).degrees), 90, accuracy: 0.5)
    }
    func test_boundingBox() {
        XCTAssertEqual(line().boundingBox.width, 100, accuracy: 0.5)
    }
    func test_curveLengthApproxSemicircle() {
        let g = SVGPathGeometry(SVGPathData.cgPath(from: "M0 0 C0 60 100 60 100 0"))
        XCTAssertGreaterThan(g.length, 100)
    }
}
