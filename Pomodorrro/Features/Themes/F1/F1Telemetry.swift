import SwiftUI

/// A real reference lap for one circuit, loaded from bundled telemetry. Speed is
/// mean-normalized (average 1) and indexed by lap distance, so it lines up with
/// our generated profile for shape comparison.
struct F1Telemetry: Decodable {
    let circuit: String
    let source: String       // "fastf1" | "openf1"
    let season: Int
    let speed: [CGFloat]

    private static var cache: [String: F1Telemetry] = [:]

    /// The bundled reference lap for a circuit, or nil if none exists (e.g. Madrid).
    static func reference(for circuit: F1Circuit) -> F1Telemetry? {
        if let alreadyLoaded = cache[circuit.rawValue] { return alreadyLoaded }
        guard let url = Bundle.main.url(forResource: circuit.rawValue, withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let telemetry = try? JSONDecoder().decode(F1Telemetry.self, from: data) else { return nil }
        cache[circuit.rawValue] = telemetry
        return telemetry
    }

    func speed(atLapDistance progress: CGFloat) -> CGFloat {
        guard speed.count > 1 else { return speed.first ?? 1 }
        let position = min(max(progress, 0), 1) * CGFloat(speed.count - 1)
        let lowerIndex = min(Int(position), speed.count - 2)
        let fraction = position - CGFloat(lowerIndex)
        return speed[lowerIndex] + (speed[lowerIndex + 1] - speed[lowerIndex]) * fraction
    }
}
