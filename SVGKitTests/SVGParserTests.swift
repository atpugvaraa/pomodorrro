import XCTest
@testable import pomodorrro

final class SVGParserTests: XCTestCase {
    private func monza() -> SVGParseResult {
        let url = Bundle(for: SVGParserTests.self).url(forResource: "monza", withExtension: "svg")!
        return SVGParser.parse(data: try! Data(contentsOf: url))!
    }
    func test_viewBoxFromWidthHeight() {
        XCTAssertEqual(monza().viewBox, SVGViewBox(x: 0, y: 0, width: 500, height: 500))
    }
    func test_fourPathsInOrder() {
        XCTAssertEqual(monza().paths.count, 4)
    }
    func test_path0_track_style() {
        let s = monza().paths[0].style
        XCTAssertEqual(s.fill, .some(.none))
        XCTAssertEqual(s.stroke, .color(red: 1, green: 1, blue: 1)) // #fff
        XCTAssertEqual(s.strokeWidth, 20)
    }
    func test_path3_outline_black() {
        let s = monza().paths[3].style
        XCTAssertEqual(s.stroke, .color(red: 0, green: 0, blue: 0)) // #000
        XCTAssertEqual(s.strokeWidth, 5)
    }
    func test_explicitViewBox() {
        let svg = #"<svg viewBox="1 2 30 40"><path d="M0 0 L1 1"/></svg>"#
        let r = SVGParser.parse(data: Data(svg.utf8))!
        XCTAssertEqual(r.viewBox, SVGViewBox(x: 1, y: 2, width: 30, height: 40))
    }
}
