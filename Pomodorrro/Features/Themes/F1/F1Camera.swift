import SwiftUI

/// The following camera: how zoomed the world is, where the car sits on screen,
/// and how much the framing lags behind (inertia). The car stays on the true
/// track point; only the framing is smoothed, giving a broadcast chase-cam feel.
struct F1Camera {
    /// Screen points per viewBox unit. Larger = more zoomed in (smaller window).
    var zoom: CGFloat = 4.5
    /// Where the car sits in the viewport. Lower third ≈ 0.72 shows more track ahead.
    var anchor: UnitPoint = UnitPoint(x: 0.5, y: 0.72)
    /// Camera smoothing time constant (seconds). Larger = softer, laggier follow.
    var inertia: Double = 0.14

    func worldSize(for viewBox: SVGViewBox) -> CGSize {
        CGSize(width: CGFloat(viewBox.width) * zoom, height: CGFloat(viewBox.height) * zoom)
    }

    func carScreenPosition(in viewport: CGSize) -> CGPoint {
        CGPoint(x: anchor.x * viewport.width, y: anchor.y * viewport.height)
    }

    /// Offset to apply to the (top-left placed) world so `point` renders under the car.
    /// The world draws the racing line at `point × zoom`, so we shift by the difference.
    func offset(focusing point: CGPoint, in viewport: CGSize) -> CGSize {
        let carScreenPosition = carScreenPosition(in: viewport)
        return CGSize(width: carScreenPosition.x - point.x * zoom,
                      height: carScreenPosition.y - point.y * zoom)
    }
}

/// Smooths the camera offset toward its target, frame-rate independently, so the
/// framing eases instead of snapping. Held as a reference so it survives redraws.
final class CameraFollower {
    private(set) var value: CGSize = .zero
    private var lastUpdate: Date?

    func reset(to target: CGSize) { value = target; lastUpdate = nil }

    func smoothedOffset(movingToward target: CGSize, inertia: Double, at now: Date) -> CGSize {
        let secondsSinceLastUpdate = lastUpdate.map { now.timeIntervalSince($0) } ?? 0
        lastUpdate = now
        let blend = secondsSinceLastUpdate <= 0 ? 0 : 1 - exp(-secondsSinceLastUpdate / max(inertia, 0.0001))
        value = CGSize(width: value.width + (target.width - value.width) * CGFloat(blend),
                       height: value.height + (target.height - value.height) * CGFloat(blend))
        return value
    }
}
