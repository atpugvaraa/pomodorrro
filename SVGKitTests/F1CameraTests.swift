import XCTest
import SwiftUI
@testable import pomodorrro

final class F1CameraTests: XCTestCase {
    private let viewBox = SVGViewBox(x: 0, y: 0, width: 500, height: 500)

    func test_worldSizeScalesByZoom() {
        let camera = F1Camera(zoom: 3, anchor: UnitPoint(x: 0.5, y: 0.72), inertia: 0.14)
        XCTAssertEqual(camera.worldSize(for: viewBox), CGSize(width: 1500, height: 1500))
    }

    func test_carScreenPositionAtAnchor() {
        let camera = F1Camera(zoom: 3, anchor: UnitPoint(x: 0.5, y: 0.72), inertia: 0.14)
        let position = camera.carScreenPosition(in: CGSize(width: 300, height: 400))
        XCTAssertEqual(position.x, 150, accuracy: 0.01)
        XCTAssertEqual(position.y, 288, accuracy: 0.01) // 0.72 * 400
    }

    /// The core contract: the focus point renders exactly under the car anchor.
    func test_offsetPlacesFocusPointUnderCar() {
        let camera = F1Camera(zoom: 3, anchor: UnitPoint(x: 0.5, y: 0.72), inertia: 0.14)
        let viewport = CGSize(width: 300, height: 400)
        let focusPoint = CGPoint(x: 218, y: 50)
        let offset = camera.offset(focusing: focusPoint, in: viewport)
        let rendered = CGPoint(x: focusPoint.x * camera.zoom + offset.width,
                               y: focusPoint.y * camera.zoom + offset.height)
        let carScreenPosition = camera.carScreenPosition(in: viewport)
        XCTAssertEqual(rendered.x, carScreenPosition.x, accuracy: 0.01)
        XCTAssertEqual(rendered.y, carScreenPosition.y, accuracy: 0.01)
    }
}
