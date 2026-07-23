import CoreGraphics
import Foundation

enum SVGPathData {
    static func cgPath(from d: String) -> CGPath {
        let path = CGMutablePath()
        var scanner = NumberScanner(d)
        var current = CGPoint.zero
        var start = CGPoint.zero
        var lastControl: CGPoint? = nil
        var lastCmd: Character = " "

        func num() -> CGFloat? { scanner.nextNumber() }
        func pt(rel: Bool) -> CGPoint? {
            guard let x = num(), let y = num() else { return nil }
            return rel ? CGPoint(x: current.x + x, y: current.y + y) : CGPoint(x: x, y: y)
        }

        while let cmd = scanner.nextCommand(previous: lastCmd) {
            let rel = cmd.isLowercase
            switch Character(cmd.lowercased()) {
            case "m":
                guard let p = pt(rel: rel) else { break }
                current = p; start = p; path.move(to: p)
                lastControl = nil
            case "l":
                guard let p = pt(rel: rel) else { break }
                path.addLine(to: p); current = p; lastControl = nil
            case "h":
                guard let x = num() else { break }
                current.x = rel ? current.x + x : x
                path.addLine(to: current); lastControl = nil
            case "v":
                guard let y = num() else { break }
                current.y = rel ? current.y + y : y
                path.addLine(to: current); lastControl = nil
            case "c":
                guard let c1 = pt(rel: rel), let c2 = pt(rel: rel), let p = pt(rel: rel) else { break }
                path.addCurve(to: p, control1: c1, control2: c2)
                current = p; lastControl = c2
            case "s":
                let c1 = (lastCmd.lowercased() == "c" || lastCmd.lowercased() == "s")
                    ? reflect(lastControl, about: current) : current
                guard let c2 = pt(rel: rel), let p = pt(rel: rel) else { break }
                path.addCurve(to: p, control1: c1, control2: c2)
                current = p; lastControl = c2
            case "q":
                guard let c = pt(rel: rel), let p = pt(rel: rel) else { break }
                path.addQuadCurve(to: p, control: c); current = p; lastControl = c
            case "t":
                let c = (lastCmd.lowercased() == "q" || lastCmd.lowercased() == "t")
                    ? reflect(lastControl, about: current) : current
                guard let p = pt(rel: rel) else { break }
                path.addQuadCurve(to: p, control: c); current = p; lastControl = c
            case "a":
                guard let rx = num(), let ry = num(), let rot = num(),
                      let laf = num(), let sf = num(), let end = pt(rel: rel) else { break }
                addArc(path, from: current, to: end, rx: rx, ry: ry,
                       xAxisRotationDeg: rot, largeArc: laf != 0, sweep: sf != 0)
                current = end; lastControl = nil
            case "z":
                path.closeSubpath(); current = start; lastControl = nil
            default: break
            }
            lastCmd = cmd
        }
        return path
    }

    private static func reflect(_ control: CGPoint?, about p: CGPoint) -> CGPoint {
        guard let c = control else { return p }
        return CGPoint(x: 2 * p.x - c.x, y: 2 * p.y - c.y)
    }

    /// SVG elliptical arc → cubic béziers (endpoint → center parameterization).
    /// Target circuit SVGs contain no arcs; included for subset completeness.
    private static func addArc(_ path: CGMutablePath, from p0: CGPoint, to p1: CGPoint,
                               rx: CGFloat, ry: CGFloat, xAxisRotationDeg: CGFloat,
                               largeArc: Bool, sweep: Bool) {
        if rx == 0 || ry == 0 || p0 == p1 { path.addLine(to: p1); return }
        var rx = abs(rx), ry = abs(ry)
        let phi = xAxisRotationDeg * .pi / 180
        let cosP = cos(phi), sinP = sin(phi)
        let dx = (p0.x - p1.x) / 2, dy = (p0.y - p1.y) / 2
        let x1p = cosP * dx + sinP * dy
        let y1p = -sinP * dx + cosP * dy
        // Correct radii if too small.
        let lambda = (x1p * x1p) / (rx * rx) + (y1p * y1p) / (ry * ry)
        if lambda > 1 { let s = sqrt(lambda); rx *= s; ry *= s }
        var num = rx*rx*ry*ry - rx*rx*y1p*y1p - ry*ry*x1p*x1p
        num = max(num, 0)
        let den = rx*rx*y1p*y1p + ry*ry*x1p*x1p
        var co = den == 0 ? 0 : sqrt(num / den)
        if largeArc == sweep { co = -co }
        let cxp = co * rx * y1p / ry
        let cyp = -co * ry * x1p / rx
        let cx = cosP * cxp - sinP * cyp + (p0.x + p1.x) / 2
        let cy = sinP * cxp + cosP * cyp + (p0.y + p1.y) / 2

        func angle(_ ux: CGFloat, _ uy: CGFloat, _ vx: CGFloat, _ vy: CGFloat) -> CGFloat {
            let dot = ux*vx + uy*vy
            let len = sqrt((ux*ux+uy*uy)*(vx*vx+vy*vy))
            var a = acos(min(max(dot/len, -1), 1))
            if ux*vy - uy*vx < 0 { a = -a }
            return a
        }
        let theta1 = angle(1, 0, (x1p-cxp)/rx, (y1p-cyp)/ry)
        var dTheta = angle((x1p-cxp)/rx, (y1p-cyp)/ry, (-x1p-cxp)/rx, (-y1p-cyp)/ry)
        if !sweep && dTheta > 0 { dTheta -= 2 * .pi }
        if sweep && dTheta < 0 { dTheta += 2 * .pi }

        let segments = Int(ceil(abs(dTheta) / (.pi / 2)))
        let delta = dTheta / CGFloat(segments)
        let t = 4.0 / 3.0 * tan(delta / 4)
        var angleStart = theta1
        for _ in 0..<segments {
            let cos1 = cos(angleStart), sin1 = sin(angleStart)
            let angleEnd = angleStart + delta
            let cos2 = cos(angleEnd), sin2 = sin(angleEnd)
            func map(_ cx0: CGFloat, _ cy0: CGFloat) -> CGPoint {
                let ex = rx * cx0, ey = ry * cy0
                return CGPoint(x: cosP * ex - sinP * ey + cx, y: sinP * ex + cosP * ey + cy)
            }
            let endPt = map(cos2, sin2)
            let c1 = map(cos1 - t * sin1, sin1 + t * cos1)
            let c2 = map(cos2 + t * sin2, sin2 - t * cos2)
            path.addCurve(to: endPt, control1: c1, control2: c2)
            angleStart = angleEnd
        }
    }
}

private struct NumberScanner {
    private let chars: [Character]
    private var i = 0
    init(_ s: String) { chars = Array(s) }

    private mutating func skipSeparators() {
        while i < chars.count, chars[i] == " " || chars[i] == "," ||
              chars[i] == "\n" || chars[i] == "\t" || chars[i] == "\r" { i += 1 }
    }

    /// Next explicit command letter, or repeats `previous` if the next token is
    /// a number (implicit repeat; M→L, m→l per SVG).
    mutating func nextCommand(previous: Character) -> Character? {
        skipSeparators()
        guard i < chars.count else { return nil }
        let c = chars[i]
        if c.isLetter { i += 1; return c }
        switch previous {
        case "M": return "L"
        case "m": return "l"
        case " ": return nil
        default:  return previous
        }
    }

    mutating func nextNumber() -> CGFloat? {
        skipSeparators()
        guard i < chars.count else { return nil }
        var s = ""
        if chars[i] == "+" || chars[i] == "-" { s.append(chars[i]); i += 1 }
        var seenDot = false, seenExp = false
        while i < chars.count {
            let c = chars[i]
            if c.isNumber { s.append(c); i += 1 }
            else if c == "." && !seenDot && !seenExp { seenDot = true; s.append(c); i += 1 }
            else if (c == "e" || c == "E") && !seenExp {
                seenExp = true; s.append(c); i += 1
                if i < chars.count, chars[i] == "+" || chars[i] == "-" { s.append(chars[i]); i += 1 }
            } else { break }
        }
        return Double(s).map { CGFloat($0) }
    }
}
