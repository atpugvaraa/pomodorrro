import SwiftUI

/// Pure geometry for the following camera. No SwiftUI state, no side effects —
/// all the "world moves under a fixed car" math lives here, out of the view body.
///
/// The world is an `SVGCanvas` of size `worldSize` placed top-left in the
/// viewport. Inside that canvas a viewBox point `p` renders at `p * zoom`
/// (the canvas draws the track and places the car with the same `fit`, so the
/// car is always on the track). The camera just translates the whole canvas so
/// the current track point lands under the car's fixed screen anchor.
struct F1Camera {
    /// Screen points per viewBox unit. Larger = more zoomed in (smaller window).
    var zoom: CGFloat = 3
    /// Where the car sits in the viewport. Lower third => y ~0.72.
    var anchor: UnitPoint = UnitPoint(x: 0.5, y: 0.72)

    func worldSize(viewBox: SVGViewBox) -> CGSize {
        CGSize(width: CGFloat(viewBox.width) * zoom, height: CGFloat(viewBox.height) * zoom)
    }

    func carScreen(in viewportSize: CGSize) -> CGPoint {
        CGPoint(x: anchor.x * viewportSize.width, y: anchor.y * viewportSize.height)
    }

    /// Offset to apply to the (top-left placed) world canvas so `target` — the
    /// canvas-local point `viewBoxPoint * zoom` — renders under the car anchor.
    func worldOffset(target: CGPoint, viewportSize: CGSize) -> CGSize {
        let anchor = carScreen(in: viewportSize)
        return CGSize(width: anchor.x - target.x * zoom,
                      height: anchor.y - target.y * zoom)
    }
}
