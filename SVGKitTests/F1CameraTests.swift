import XCTest
import SwiftUI
@testable import pomodorrro

final class F1CameraTests: XCTestCase {
    private let vb = SVGViewBox(x: 0, y: 0, width: 500, height: 500)

    func test_worldSize_scalesByZoom() {
        let cam = F1Camera(zoom: 3, anchor: UnitPoint(x: 0.5, y: 0.72))
        XCTAssertEqual(cam.worldSize(viewBox: vb), CGSize(width: 1500, height: 1500))
    }

    func test_carScreen_atAnchor() {
        let cam = F1Camera(zoom: 3, anchor: UnitPoint(x: 0.5, y: 0.72))
        let a = cam.carScreen(in: CGSize(width: 300, height: 400))
        XCTAssertEqual(a.x, 150, accuracy: 0.01)
        XCTAssertEqual(a.y, 288, accuracy: 0.01) // 0.72 * 400
    }

    /// The core contract: the canvas is placed top-left; a viewBox point renders
    /// at `p * zoom` in canvas-local coords. After applying worldOffset, that
    /// point must land exactly on the car's screen anchor.
    func test_worldOffset_placesTargetUnderCar() {
        let cam = F1Camera(zoom: 3, anchor: UnitPoint(x: 0.5, y: 0.72))
        let viewport = CGSize(width: 300, height: 400)
        let target = CGPoint(x: 218, y: 50)   // viewBox point
        let off = cam.worldOffset(target: target, viewportSize: viewport)

        // canvas-local render = target * zoom; + offset must == car anchor
        let rendered = CGPoint(x: target.x * cam.zoom + off.width,
                               y: target.y * cam.zoom + off.height)
        let anchor = cam.carScreen(in: viewport)
        XCTAssertEqual(rendered.x, anchor.x, accuracy: 0.01)
        XCTAssertEqual(rendered.y, anchor.y, accuracy: 0.01)
    }
}
