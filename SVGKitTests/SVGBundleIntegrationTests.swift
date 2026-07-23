import XCTest
@testable import pomodorrro

/// Verifies the circuit SVGs are copied into the host app bundle (Bundle.main
/// in a hosted unit test is the app), so `SVG("monza")` works at runtime.
final class SVGBundleIntegrationTests: XCTestCase {
    func test_monzaLoadsFromMainBundle() {
        let doc = SVGDocument.cached(named: "monza")   // bundle defaults to .main
        XCTAssertNotNil(doc, "monza.svg must be bundled in the app")
        XCTAssertEqual(doc?.elements.count, 4)
    }
    func test_publicAPI_pathsAndGeometry() {
        let svg = SVG("monza")
        XCTAssertEqual(svg.paths.count, 4)
        let track = svg.paths[0]
        XCTAssertGreaterThan(track.length, 0)
        // point(0) and point(1) differ -> geometry table is real
        XCTAssertNotEqual(track.point(at: 0), track.point(at: 1))
    }
}
