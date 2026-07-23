import SwiftUI

struct SVG: View {
    private let document: SVGDocument?

    init(_ name: String, bundle: Bundle = .main) {
        document = SVGDocument.cached(named: name, bundle: bundle)
    }
    init(named name: String, bundle: Bundle = .main) {
        self.init(name, bundle: bundle)
    }

    var paths: [SVGPath] {
        guard let doc = document else { return [] }
        return doc.elements.map { SVGPath(element: $0, viewBox: doc.viewBox) }
    }

    var viewBox: SVGViewBox? { document?.viewBox }

    var body: some View {
        ZStack {
            ForEach(Array(paths.enumerated()), id: \.offset) { _, p in p }
        }
    }
}
