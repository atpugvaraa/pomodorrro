import XCTest
import CoreGraphics
@testable import pomodorrro

final class SVGFitTests: XCTestCase {
    func test_pathInRect_scalesViewBox() {
        let vb = SVGViewBox(x: 0, y: 0, width: 100, height: 100)
        let el = SVGPathElement(cgPath: SVGPathData.cgPath(from: "M0 0 L100 0 L100 100"),
                                style: SVGStyle())
        let sp = SVGPath(element: el, viewBox: vb)
        let cg = sp.path(in: CGRect(x: 0, y: 0, width: 200, height: 200)).cgPath
        XCTAssertEqual(cg.boundingBoxOfPath.maxX, 200, accuracy: 0.5) // 100 -> 200
    }
    func test_geometryLengthInNativeCoords() {
        let vb = SVGViewBox(x: 0, y: 0, width: 100, height: 100)
        let el = SVGPathElement(cgPath: SVGPathData.cgPath(from: "M0 0 L100 0"), style: SVGStyle())
        XCTAssertEqual(SVGPath(element: el, viewBox: vb).length, 100, accuracy: 0.5)
    }
}
