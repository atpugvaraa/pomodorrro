import SwiftUI

/// A moving window onto a circuit: the world (SVG) scrolls under a car fixed
/// near the lower third of the viewport. World translates only — no rotation.
/// `progress` (0...1) is owned by the parent (slider now, race timer later).
///
/// The car is drawn *inside* `SVGCanvas` via the same `fit` transform that draws
/// the track, so it is always exactly on the racing line. The camera then just
/// offsets the whole canvas so the current point sits under the car anchor.
struct F1TrackView: View {
    var circuit: String = "monza"
    var progress: Double
    var trackIndex: Int = 0
    var camera: F1Camera = F1Camera()
    var carSize: CGSize = CGSize(width: 12, height: 34)
    var carArtRotation: Angle = .degrees(90)
    var follow: Animation = .spring(response: 0.35, dampingFraction: 0.9)
    var background: Color = Color(white: 0.12)

    private var svg: SVG { SVG(circuit) } // SVGDocument is cached; cheap to re-make

    var body: some View {
        GeometryReader { proxy in
            let viewport = proxy.size
            let clamped = CGFloat(min(max(progress, 0), 1))

            ZStack(alignment: .topLeading) {
                background

                if let track = svg.paths[safe: trackIndex], let vb = svg.viewBox {
                    let worldSize = camera.worldSize(viewBox: vb)
                    // canvas-local point under the car = viewBoxPoint * zoom
                    let target = track.point(at: clamped)
                    let offset = camera.worldOffset(
                        target: target, viewportSize: viewport)

                    SVGCanvas(svg) { fit in
                        F1Car(size: carSize)
                            .rotationEffect(carArtRotation + track.angle(at: clamped))
                            .position(fit(track.point(at: clamped)))
                    }
                    .frame(width: worldSize.width, height: worldSize.height)
                    .offset(offset)
                    .animation(follow, value: progress)
                }
            }
            .frame(width: viewport.width, height: viewport.height, alignment: .topLeading)
            .clipped()
        }
    }
}

private extension Array {
    subscript(safe i: Int) -> Element? { indices.contains(i) ? self[i] : nil }
}
