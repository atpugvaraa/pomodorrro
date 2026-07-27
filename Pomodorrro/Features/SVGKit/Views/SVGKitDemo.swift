import SwiftUI

#Preview("Track + car at progress") {
    struct Demo: View {
        @State private var progress: CGFloat = 0.2
        var body: some View {
            let svg = SVG("monza")
            VStack {
                SVGCanvas(svg) { fit in
                    if let track = svg.paths.first {
                        F1Car()
                            .frame(width: 24, height: 24)
                            .position(fit(track.point(at: progress)))
//                            .rotationEffect(track.angle(at: progress))
                    }
                }
                .scaleEffect(10)
//                .background(.black)
                Slider(value: $progress, in: 0...1)
            }
            .padding()
        }
    }
    return Demo()
}

#Preview("Recolour + completed lap") {
    let svg = SVG("monza")
    return ZStack {
        svg.paths[safe: 3]?.stroke(.white)      // outline
        svg.paths[safe: 0]?.stroke(.gray)       // track recoloured
        svg.paths[safe: 1]?.fill(.red)          // start-finish
        if let track = svg.paths[safe: 0] {
            track.trimmed(from: 0, to: 0.4).stroke(.green) // completed lap
        }
    }
    .background(.black)
    .padding()
}

private extension Array {
    subscript(safe i: Int) -> Element? { indices.contains(i) ? self[i] : nil }
}
