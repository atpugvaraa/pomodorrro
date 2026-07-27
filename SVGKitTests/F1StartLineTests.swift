import XCTest
import CoreGraphics
@testable import pomodorrro

final class F1StartLineTests: XCTestCase {
    private func makePath(_ d: String, vb: SVGViewBox = SVGViewBox(x: 0, y: 0, width: 100, height: 100)) -> SVGPath {
        SVGPath(element: SVGPathElement(cgPath: SVGPathData.cgPath(from: d), style: SVGStyle()), viewBox: vb)
    }
    func test_startLineProgressIsNearestPointOnTrack() {
        let racingLine = makePath("M0 0 L100 0")                      // straight, x = progress*100
        let startFinishMarker = makePath("M45 -1 L55 -1 L55 1 L45 1 Z") // centre ≈ (50, 0)
        let progress = findStartLineProgress(on: racingLine, markedBy: startFinishMarker)
        XCTAssertEqual(progress, 0.5, accuracy: 0.02)
    }
    func test_startLineProgressAtStart() {
        let racingLine = makePath("M0 0 L100 0")
        let startFinishMarker = makePath("M-1 -1 L1 -1 L1 1 L-1 1 Z")  // centre ≈ (0,0)
        XCTAssertEqual(findStartLineProgress(on: racingLine, markedBy: startFinishMarker), 0.0, accuracy: 0.02)
    }
}
