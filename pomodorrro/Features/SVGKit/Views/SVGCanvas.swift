import SwiftUI

/// Draws an `SVG` and an overlay in the same rendered coordinate space.
/// `overlay` receives a `fit` closure mapping native viewBox points into the
/// rendered rect, so a car placed via `.position(fit(track.point(at:)))` lines
/// up exactly with the drawn track. Angles need no mapping (uniform scale).
struct SVGCanvas<Overlay: View>: View {
    let svg: SVG
    let overlay: (@escaping (CGPoint) -> CGPoint) -> Overlay

    init(_ svg: SVG,
         @ViewBuilder overlay: @escaping (@escaping (CGPoint) -> CGPoint) -> Overlay) {
        self.svg = svg
        self.overlay = overlay
    }

    var body: some View {
        GeometryReader { proxy in
            let rect = CGRect(origin: .zero, size: proxy.size)
            let vb = svg.viewBox ?? SVGViewBox(x: 0, y: 0, width: 1, height: 1)
            let t = vb.fitTransform(in: rect)
            let fit: (CGPoint) -> CGPoint = { $0.applying(t) }
            ZStack {
                svg
                overlay(fit)
            }
        }
    }
}
