import SwiftUI

enum SVGPaint: Equatable {
    case none
    case color(red: Double, green: Double, blue: Double)

    init?(_ raw: String) {
        let s = raw.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if s == "none" { self = .none; return }
        if s.hasPrefix("#") {
            let hex = String(s.dropFirst())
            let full: String
            switch hex.count {
            case 3: full = hex.map { "\($0)\($0)" }.joined()
            case 6: full = hex
            default: return nil
            }
            guard let v = UInt32(full, radix: 16) else { return nil }
            self = .color(red: Double((v >> 16) & 0xff) / 255,
                          green: Double((v >> 8) & 0xff) / 255,
                          blue: Double(v & 0xff) / 255)
            return
        }
        switch s {
        case "black": self = .color(red: 0, green: 0, blue: 0)
        case "white": self = .color(red: 1, green: 1, blue: 1)
        case "red":   self = .color(red: 1, green: 0, blue: 0)
        case "gray", "grey": self = .color(red: 0.5, green: 0.5, blue: 0.5)
        default: return nil
        }
    }

    func color(opacity: Double) -> Color? {
        guard case let .color(r, g, b) = self else { return nil }
        return Color(.sRGB, red: r, green: g, blue: b, opacity: opacity)
    }
}
