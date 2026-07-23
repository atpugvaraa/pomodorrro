import CoreGraphics
import Foundation

final class SVGDocument {
    let viewBox: SVGViewBox
    let elements: [SVGPathElement]

    init(viewBox: SVGViewBox, elements: [SVGPathElement]) {
        self.viewBox = viewBox
        self.elements = elements
    }

    private static var cache: [String: SVGDocument] = [:]
    private static let lock = NSLock()

    static func cached(named name: String, bundle: Bundle = .main) -> SVGDocument? {
        let key = "\(ObjectIdentifier(bundle).hashValue):\(name)"
        lock.lock(); defer { lock.unlock() }
        if let hit = cache[key] { return hit }
        guard let url = bundle.url(forResource: name, withExtension: "svg"),
              let data = try? Data(contentsOf: url),
              let result = SVGParser.parse(data: data) else { return nil }
        let doc = SVGDocument(viewBox: result.viewBox, elements: result.paths)
        cache[key] = doc
        return doc
    }
}

extension SVGViewBox {
    func scale(in rect: CGRect) -> CGFloat {
        guard width > 0, height > 0 else { return 1 }
        return min(rect.width / width, rect.height / height)
    }
    func fitTransform(in rect: CGRect) -> CGAffineTransform {
        let s = scale(in: rect)
        let tx = rect.minX + (rect.width - CGFloat(width) * s) / 2 - CGFloat(x) * s
        let ty = rect.minY + (rect.height - CGFloat(height) * s) / 2 - CGFloat(y) * s
        return CGAffineTransform(a: s, b: 0, c: 0, d: s, tx: tx, ty: ty)
    }
}
