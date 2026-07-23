import XCTest
import SwiftUI
@testable import pomodorrro

final class SVGColorTests: XCTestCase {
    func test_none() { XCTAssertEqual(SVGPaint("none"), .some(.none)) }
    func test_hex6() {
        XCTAssertEqual(SVGPaint("#ffffff"), .color(red: 1, green: 1, blue: 1))
        XCTAssertEqual(SVGPaint("#000000"), .color(red: 0, green: 0, blue: 0))
    }
    func test_hex3_expands() {
        XCTAssertEqual(SVGPaint("#fff"), .color(red: 1, green: 1, blue: 1))
        XCTAssertEqual(SVGPaint("#f00"), .color(red: 1, green: 0, blue: 0))
    }
    func test_named() {
        XCTAssertEqual(SVGPaint("black"), .color(red: 0, green: 0, blue: 0))
        XCTAssertEqual(SVGPaint("  WHITE "), .color(red: 1, green: 1, blue: 1))
    }
    func test_unknown_nil() { XCTAssertNil(SVGPaint("chartreuse")) }
    func test_colorWithOpacity_noneIsNil() { XCTAssertNil(SVGPaint.none.color(opacity: 1)) }
}
