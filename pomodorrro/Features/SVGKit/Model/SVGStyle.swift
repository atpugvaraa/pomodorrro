import CoreGraphics
import Foundation

struct SVGStyle: Equatable {
    var fill: SVGPaint? = .color(red: 0, green: 0, blue: 0)
    var stroke: SVGPaint? = nil
    var strokeWidth: Double = 1
    var fillOpacity: Double = 1
    var strokeOpacity: Double = 1
    var lineCap: CGLineCap = .butt
    var lineJoin: CGLineJoin = .miter

    static func resolve(presentation: [String: String], style: String?) -> SVGStyle {
        var s = SVGStyle()
        func apply(_ key: String, _ value: String) {
            let v = value.trimmingCharacters(in: .whitespaces)
            switch key.trimmingCharacters(in: .whitespaces) {
            case "fill":   s.fill = SVGPaint(v) ?? s.fill
            case "stroke": s.stroke = SVGPaint(v) ?? s.stroke
            case "stroke-width":   s.strokeWidth = Double(v) ?? s.strokeWidth
            case "fill-opacity":   s.fillOpacity = Double(v) ?? s.fillOpacity
            case "stroke-opacity": s.strokeOpacity = Double(v) ?? s.strokeOpacity
            case "stroke-linecap":
                s.lineCap = ["round": .round, "square": .square, "butt": .butt][v] ?? s.lineCap
            case "stroke-linejoin":
                s.lineJoin = ["round": .round, "bevel": .bevel, "miter": .miter][v] ?? s.lineJoin
            default: break
            }
        }
        for (k, v) in presentation { apply(k, v) }        // presentation first
        for pair in (style ?? "").split(separator: ";") { // style overrides
            let kv = pair.split(separator: ":", maxSplits: 1)
            if kv.count == 2 { apply(String(kv[0]), String(kv[1])) }
        }
        return s
    }
}
