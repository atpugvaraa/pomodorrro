import XCTest
import CoreGraphics
@testable import pomodorrro

final class SVGDocumentCacheTests: XCTestCase {
    func test_cacheReturnsSameInstance() {
        let b = Bundle(for: SVGDocumentCacheTests.self)
        let a = SVGDocument.cached(named: "monza", bundle: b)
        let c = SVGDocument.cached(named: "monza", bundle: b)
        XCTAssertNotNil(a)
        XCTAssertTrue(a === c)          // parsed once, reused
    }
    func test_missingReturnsNil() {
        XCTAssertNil(SVGDocument.cached(named: "does-not-exist",
                                        bundle: Bundle(for: SVGDocumentCacheTests.self)))
    }
    func test_fitTransform_squareIntoSquare_identityScale() {
        let vb = SVGViewBox(x: 0, y: 0, width: 500, height: 500)
        let t = vb.fitTransform(in: CGRect(x: 0, y: 0, width: 500, height: 500))
        XCTAssertEqual(t.a, 1, accuracy: 1e-6)
        XCTAssertEqual(t.tx, 0, accuracy: 1e-6)
    }
    func test_fitTransform_centersWithLetterbox() {
        let vb = SVGViewBox(x: 0, y: 0, width: 100, height: 100)
        let t = vb.fitTransform(in: CGRect(x: 0, y: 0, width: 200, height: 100))
        XCTAssertEqual(t.a, 1, accuracy: 1e-6)
        XCTAssertEqual(t.tx, 50, accuracy: 1e-6)
    }
}
