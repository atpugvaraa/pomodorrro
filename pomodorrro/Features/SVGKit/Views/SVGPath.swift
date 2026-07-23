import SwiftUI

struct SVGPath: Shape {
    let element: SVGPathElement
    let viewBox: SVGViewBox
    private let geoBox: GeometryBox

    init(element: SVGPathElement, viewBox: SVGViewBox) {
        self.element = element
        self.viewBox = viewBox
        self.geoBox = GeometryBox(element.cgPath)
    }

    // MARK: Shape (used by SwiftUI's .fill / .stroke overrides)
    func path(in rect: CGRect) -> Path {
        var t = viewBox.fitTransform(in: rect)
        if let transformed = element.cgPath.copy(using: &t) {
            return Path(transformed)
        }
        return Path(element.cgPath)
    }

    // MARK: default rendering (bare `svg.paths[0]`)
    var body: some View {
        GeometryReader { proxy in
            let rect = CGRect(origin: .zero, size: proxy.size)
            let scale = viewBox.scale(in: rect)
            let style = element.style
            ZStack {
                if let fill = style.fill?.color(opacity: style.fillOpacity) {
                    path(in: rect).fill(fill)
                }
                if let stroke = style.stroke?.color(opacity: style.strokeOpacity) {
                    path(in: rect).stroke(stroke, style: StrokeStyle(
                        lineWidth: CGFloat(style.strokeWidth) * scale,
                        lineCap: style.lineCap,
                        lineJoin: style.lineJoin))
                }
            }
        }
    }

    // MARK: geometry (native viewBox coords)
    var length: CGFloat { geoBox.geometry.length }
    var boundingBox: CGRect { geoBox.geometry.boundingBox }
    func point(at progress: CGFloat) -> CGPoint { geoBox.geometry.point(at: progress) }
    func angle(at progress: CGFloat) -> Angle { geoBox.geometry.angle(at: progress) }
    func trimmed(from: CGFloat, to: CGFloat) -> SVGPath {
        let trimmed = geoBox.geometry.trimmedPath(from: from, to: to)
        return SVGPath(element: SVGPathElement(cgPath: trimmed, style: element.style),
                       viewBox: viewBox)
    }
}

/// Shared, lazily-built geometry so struct copies during SwiftUI body passes
/// don't recompute the arc-length table.
private final class GeometryBox {
    private let cgPath: CGPath
    private var cached: SVGPathGeometry?
    init(_ p: CGPath) { cgPath = p }
    var geometry: SVGPathGeometry {
        if let c = cached { return c }
        let g = SVGPathGeometry(cgPath); cached = g; return g
    }
}
