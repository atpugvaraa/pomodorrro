import SwiftUI

/// A Formula 1 circuit. The raw value is the bundled SVG's filename, so adding a
/// circuit is just adding its `.svg` and a case here. Being an enum also makes
/// picking a random circuit trivial (`F1Circuit.random`).
enum F1Circuit: String, CaseIterable {
    case austin, bahrain, baku, catalunya, hungaroring, interlagos, jeddah
    case lasVegas = "las-vegas"
    case lusail, madring
    case marinaBay = "marina-bay"
    case melbourne
    case mexicoCity = "mexico-city"
    case miami, monaco, montreal, monza, shanghai, silverstone
    case spaFrancorchamps = "spa-francorchamps"
    case spielberg, suzuka
    case yasMarina = "yas-marina"
    case zandvoort

    static var random: F1Circuit { allCases.randomElement()! }

    private static var loadedTracks: [F1Circuit: F1Track] = [:]

    /// Loads (and caches) this circuit's geometry. The SVG's path order is fixed:
    /// index 0 is the racing line, index 1 is the start/finish marker.
    func loadTrack() -> F1Track? {
        if let alreadyLoaded = F1Circuit.loadedTracks[self] { return alreadyLoaded }
        let drawing = SVG(rawValue)
        guard let racingLine = drawing.paths[safe: 0], let viewBox = drawing.viewBox else { return nil }
        let startFinishMarker = drawing.paths[safe: 1]
        let track = F1Track(racingLine: racingLine, startFinishMarker: startFinishMarker, viewBox: viewBox)
        F1Circuit.loadedTracks[self] = track
        return track
    }
}

/// The geometry of one circuit, computed once: the racing line the car follows,
/// the visual start/finish marker, and the two derived values the animation needs
/// — where the start line sits on the racing line, and the corner-aware speed profile.
final class F1Track {
    let racingLine: SVGPath
    let startFinishMarker: SVGPath?
    let viewBox: SVGViewBox
    let startLineProgress: CGFloat
    let speedProfile: F1SpeedProfile

    init(racingLine: SVGPath, startFinishMarker: SVGPath?, viewBox: SVGViewBox) {
        self.racingLine = racingLine
        self.startFinishMarker = startFinishMarker
        self.viewBox = viewBox
        if let startFinishMarker {
            self.startLineProgress = findStartLineProgress(on: racingLine, markedBy: startFinishMarker)
        } else {
            self.startLineProgress = 0
        }
        self.speedProfile = F1SpeedProfile(racingLine: racingLine)
    }
}

extension F1Circuit: Identifiable {
    var id: String { rawValue }
    /// Human-readable name for pickers, e.g. "las-vegas" → "Las Vegas".
    var displayName: String {
        rawValue.split(separator: "-").map { $0.capitalized }.joined(separator: " ")
    }
}

private extension Array {
    subscript(safe index: Int) -> Element? { indices.contains(index) ? self[index] : nil }
}
