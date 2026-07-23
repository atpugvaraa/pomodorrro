import Foundation
import CoreGraphics

struct SVGViewBox: Equatable { let x, y, width, height: Double }
struct SVGPathElement { let cgPath: CGPath; let style: SVGStyle }
struct SVGParseResult { let viewBox: SVGViewBox; let paths: [SVGPathElement] }

enum SVGParser {
    static func parse(data: Data) -> SVGParseResult? {
        let delegate = Delegate()
        let parser = XMLParser(data: data)
        parser.delegate = delegate
        guard parser.parse(), let vb = delegate.viewBox else { return nil }
        return SVGParseResult(viewBox: vb, paths: delegate.paths)
    }

    private final class Delegate: NSObject, XMLParserDelegate {
        var viewBox: SVGViewBox?
        var paths: [SVGPathElement] = []

        func parser(_ parser: XMLParser, didStartElement name: String,
                    namespaceURI: String?, qualifiedName: String?,
                    attributes attr: [String: String]) {
            switch name {
            case "svg":
                if let vb = attr["viewBox"] {
                    let n = vb.split(whereSeparator: { $0 == " " || $0 == "," }).compactMap { Double($0) }
                    if n.count == 4 { viewBox = SVGViewBox(x: n[0], y: n[1], width: n[2], height: n[3]) }
                }
                if viewBox == nil, let w = attr["width"].flatMap(parseLength),
                                    let h = attr["height"].flatMap(parseLength) {
                    viewBox = SVGViewBox(x: 0, y: 0, width: w, height: h)
                }
            case "path":
                guard let d = attr["d"] else { return }
                let presentation = attr.filter { presentationKeys.contains($0.key) }
                let style = SVGStyle.resolve(presentation: presentation, style: attr["style"])
                paths.append(SVGPathElement(cgPath: SVGPathData.cgPath(from: d), style: style))
            default: break
            }
        }
    }
}

private let presentationKeys: Set<String> = [
    "fill", "stroke", "stroke-width", "stroke-linejoin", "stroke-linecap",
    "stroke-opacity", "fill-opacity"
]

private func parseLength(_ s: String) -> Double? {
    Double(s.trimmingCharacters(in: .whitespaces).replacingOccurrences(of: "px", with: ""))
}
