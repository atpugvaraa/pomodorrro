import CoreGraphics
import SwiftUI

final class SVGPathGeometry {
    let samples: [CGPoint]
    let cumulative: [CGFloat]   // cumulative[i] = arc length up to samples[i]; cumulative[0] = 0
    let boundingBox: CGRect
    var length: CGFloat { cumulative.last ?? 0 }

    private static let subdivisions = 24

    init(_ cgPath: CGPath) {
        var pts: [CGPoint] = []
        var current = CGPoint.zero
        var subStart = CGPoint.zero

        func addCubic(_ p1: CGPoint, _ c1: CGPoint, _ c2: CGPoint, _ p2: CGPoint) {
            let n = SVGPathGeometry.subdivisions
            for k in 1...n {
                let t = CGFloat(k) / CGFloat(n), u = 1 - t
                let x = u*u*u*p1.x + 3*u*u*t*c1.x + 3*u*t*t*c2.x + t*t*t*p2.x
                let y = u*u*u*p1.y + 3*u*u*t*c1.y + 3*u*t*t*c2.y + t*t*t*p2.y
                pts.append(CGPoint(x: x, y: y))
            }
        }
        func addQuad(_ p1: CGPoint, _ c: CGPoint, _ p2: CGPoint) {
            let n = SVGPathGeometry.subdivisions
            for k in 1...n {
                let t = CGFloat(k) / CGFloat(n), u = 1 - t
                let x = u*u*p1.x + 2*u*t*c.x + t*t*p2.x
                let y = u*u*p1.y + 2*u*t*c.y + t*t*p2.y
                pts.append(CGPoint(x: x, y: y))
            }
        }

        cgPath.applyWithBlock { elementPtr in
            let e = elementPtr.pointee
            switch e.type {
            case .moveToPoint:
                current = e.points[0]; subStart = current; pts.append(current)
            case .addLineToPoint:
                current = e.points[0]; pts.append(current)
            case .addQuadCurveToPoint:
                addQuad(current, e.points[0], e.points[1]); current = e.points[1]
            case .addCurveToPoint:
                addCubic(current, e.points[0], e.points[1], e.points[2]); current = e.points[2]
            case .closeSubpath:
                pts.append(subStart); current = subStart
            @unknown default: break
            }
        }

        var cum: [CGFloat] = pts.isEmpty ? [] : [0]
        if pts.count > 1 {
            for i in 1..<pts.count {
                let d = hypot(pts[i].x - pts[i-1].x, pts[i].y - pts[i-1].y)
                cum.append(cum[i-1] + d)
            }
        }
        self.samples = pts
        self.cumulative = cum
        self.boundingBox = cgPath.boundingBoxOfPath
    }

    func point(at progress: CGFloat) -> CGPoint {
        guard samples.count > 1 else { return samples.first ?? .zero }
        let target = length * min(max(progress, 0), 1)
        let i = indexForLength(target)
        let segLen = cumulative[i] - cumulative[i-1]
        let f = segLen > 0 ? (target - cumulative[i-1]) / segLen : 0
        let a = samples[i-1], b = samples[i]
        return CGPoint(x: a.x + (b.x - a.x) * f, y: a.y + (b.y - a.y) * f)
    }

    func angle(at progress: CGFloat) -> Angle {
        guard samples.count > 1 else { return .zero }
        let target = length * min(max(progress, 0), 1)
        let i = indexForLength(target)
        let a = samples[i-1], b = samples[i]
        return Angle(radians: Double(atan2(b.y - a.y, b.x - a.x)))
    }

    /// Smallest i (>=1) with cumulative[i] >= target. Binary search.
    private func indexForLength(_ target: CGFloat) -> Int {
        var lo = 1, hi = cumulative.count - 1
        while lo < hi {
            let mid = (lo + hi) / 2
            if cumulative[mid] < target { lo = mid + 1 } else { hi = mid }
        }
        return lo
    }

    func trimmedPath(from: CGFloat, to: CGFloat) -> CGPath {
        let f = min(max(from, 0), 1), t = min(max(to, 0), 1)
        let path = CGMutablePath()
        guard f < t, samples.count > 1 else { return path }
        let startLen = length * f, endLen = length * t
        path.move(to: point(at: f))
        for i in 1..<samples.count where cumulative[i] > startLen && cumulative[i] < endLen {
            path.addLine(to: samples[i])
        }
        path.addLine(to: point(at: t))
        return path
    }
}
