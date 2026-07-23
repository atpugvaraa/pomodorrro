import XCTest
import CoreGraphics
@testable import pomodorrro

final class SVGPathDataTests: XCTestCase {
    func test_absoluteLineBox_boundingBox() {
        let p = SVGPathData.cgPath(from: "M0 0 L10 0 L10 10 L0 10 Z")
        XCTAssertEqual(p.boundingBoxOfPath, CGRect(x: 0, y: 0, width: 10, height: 10))
    }
    func test_relativeCommands() {
        let p = SVGPathData.cgPath(from: "m10 10 l5 0")
        XCTAssertEqual(p.boundingBoxOfPath.minX, 10, accuracy: 1e-6)
        XCTAssertEqual(p.boundingBoxOfPath.maxX, 15, accuracy: 1e-6)
    }
    func test_hv() {
        let p = SVGPathData.cgPath(from: "M0 0 H10 V5")
        XCTAssertEqual(p.boundingBoxOfPath, CGRect(x: 0, y: 0, width: 10, height: 5))
    }
    func test_cubic_producesCurveWithinHull() {
        let p = SVGPathData.cgPath(from: "M0 0 C0 10 10 10 10 0")
        let bb = p.boundingBoxOfPath
        XCTAssertEqual(bb.minX, 0, accuracy: 1e-6)
        XCTAssertEqual(bb.maxX, 10, accuracy: 1e-6)
        XCTAssertGreaterThan(bb.maxY, 0)
        XCTAssertLessThanOrEqual(bb.maxY, 10 + 1e-6)
    }
    func test_gluedNegativeNumbers() {
        let p = SVGPathData.cgPath(from: "M218.372 50.51c17.128-1.458 28.349-2.045 40.274-3.238")
        XCTAssertFalse(p.isEmpty)
        XCTAssertEqual(p.boundingBoxOfPath.minX, 218.372, accuracy: 1e-3)
    }
    func test_implicitLineAfterMove() {
        let p = SVGPathData.cgPath(from: "M0 0 10 0 10 10")
        XCTAssertEqual(p.boundingBoxOfPath, CGRect(x: 0, y: 0, width: 10, height: 10))
    }
}
