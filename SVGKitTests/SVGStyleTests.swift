import XCTest
@testable import pomodorrro

final class SVGStyleTests: XCTestCase {
    func test_styleAttr_parsed() {
        let s = SVGStyle.resolve(presentation: [:],
            style: "fill:none;stroke:#fff;stroke-width:20;stroke-linejoin:round")
        XCTAssertEqual(s.fill, .some(.none))
        XCTAssertEqual(s.stroke, .color(red: 1, green: 1, blue: 1))
        XCTAssertEqual(s.strokeWidth, 20)
        XCTAssertEqual(s.lineJoin, .round)
    }
    func test_presentationAttrs_parsed() {
        let s = SVGStyle.resolve(presentation: ["fill": "#D9D9D9", "stroke": "black"], style: nil)
        XCTAssertEqual(s.stroke, .color(red: 0, green: 0, blue: 0))
    }
    func test_styleOverridesPresentation() {
        let s = SVGStyle.resolve(presentation: ["stroke": "black"], style: "stroke:#fff")
        XCTAssertEqual(s.stroke, .color(red: 1, green: 1, blue: 1))
    }
    func test_lineCapSquare_and_defaults() {
        let s = SVGStyle.resolve(presentation: [:], style: "stroke-linecap:square")
        XCTAssertEqual(s.lineCap, .square)
        XCTAssertEqual(s.strokeWidth, 1)     // default
        XCTAssertEqual(s.fill, .color(red: 0, green: 0, blue: 0)) // default black
    }
}
