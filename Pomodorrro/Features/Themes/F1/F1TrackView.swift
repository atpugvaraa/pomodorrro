import SwiftUI

/// A moving window onto a Formula 1 circuit: the world scrolls beneath a car
/// pinned near the lower third while the camera eases along behind it. Drive it
/// with elapsed time (1 lap per lap duration) or scrub it with `progress` for debugging.
///
///     F1TrackView(.monza, elapsedTime: seconds, isRunning: true)
///         .cameraZoom(5)
///         .trackColor(.black)
///
struct F1TrackView: View {
    private let circuit: F1Circuit
    private let drive: Drive
    private var camera = F1Camera()
    private var style = F1TrackStyle()
    private var usesSpeedProfile = true

    private enum Drive {
        case time(elapsedTime: TimeInterval, isRunning: Bool, lapDuration: TimeInterval)
        case scrub(progress: Double)
    }

    init(_ circuit: F1Circuit, elapsedTime: TimeInterval, isRunning: Bool = true,
         lapDuration: TimeInterval = 60) {
        self.circuit = circuit
        self.drive = .time(elapsedTime: elapsedTime, isRunning: isRunning, lapDuration: lapDuration)
    }

    init(_ circuit: F1Circuit, progress: Double) {
        self.circuit = circuit
        self.drive = .scrub(progress: progress)
    }

    // Smoothing state, kept alive across TimelineView redraws.
    @State private var cameraFollower = CameraFollower()
    @State private var cameraFollowerReady = false
    @State private var anchorElapsedTime: TimeInterval = 0
    @State private var anchorDate = Date(timeIntervalSince1970: 0)
    var carArtRotation: Angle = .degrees(90)   // car art points north; +90° aligns with +x heading

    var body: some View {
        GeometryReader { proxy in
            let viewport = proxy.size
            if let track = circuit.loadTrack() {
                scene(track: track, viewport: viewport)
            } else {
                Rectangle().fill(style.background)
            }
        }
    }

    @ViewBuilder
    private func scene(track: F1Track, viewport: CGSize) -> some View {
        switch drive {
        case let .scrub(progress):
            let lap = F1Lap(track: track, lapDuration: 60)
            let currentTrackProgress = lap.trackProgress(atLapProgress: CGFloat(progress.truncatingRemainder(dividingBy: 1)), speedProfiled: usesSpeedProfile)
            let currentTrackPosition = track.racingLine.point(at: currentTrackProgress)
            let cameraOffset = camera.offset(focusing: currentTrackPosition, in: viewport)
            let heading = track.racingLine.angle(at: currentTrackProgress)   // instant scrub
            trackScene(track: track, viewport: viewport,
                       trackProgress: currentTrackProgress, cameraOffset: cameraOffset, heading: heading)

        case let .time(elapsedTime, isRunning, lapDuration):
            let lap = F1Lap(track: track, lapDuration: lapDuration)
            TimelineView(.animation) { context in
                let now = context.date
                let currentElapsedTime = lap.continuousElapsedTime(
                    anchorElapsed: anchorElapsedTime, anchorDate: anchorDate,
                    now: now, isRunning: isRunning)
                let currentTrackProgress = lap.trackProgress(atElapsedTime: currentElapsedTime, speedProfiled: usesSpeedProfile)
                let currentTrackPosition = track.racingLine.point(at: currentTrackProgress)
                let targetCameraOffset = camera.offset(focusing: currentTrackPosition, in: viewport)
                let cameraOffset = smoothedCameraOffset(movingToward: targetCameraOffset,
                                                        isRunning: isRunning, at: now)
                let heading = track.racingLine.angle(at: currentTrackProgress)
                trackScene(track: track, viewport: viewport,
                           trackProgress: currentTrackProgress, cameraOffset: cameraOffset, heading: heading)
            }
            .onAppear { anchorElapsedTime = elapsedTime; anchorDate = Date() }
            .onChange(of: elapsedTime) { _, updated in anchorElapsedTime = updated; anchorDate = Date() }
            .onChange(of: isRunning) { _, _ in anchorElapsedTime = elapsedTime; anchorDate = Date() }
        }
    }

    private func smoothedCameraOffset(movingToward target: CGSize, isRunning: Bool, at now: Date) -> CGSize {
        if !cameraFollowerReady {
            cameraFollower.reset(to: target)
            DispatchQueue.main.async { cameraFollowerReady = true }
            return target
        }
        guard isRunning else { cameraFollower.reset(to: target); return target }
        return cameraFollower.smoothedOffset(movingToward: target, inertia: camera.inertia, at: now)
    }

    /// Draws the circuit (two bands + optional trail + start line) and the car,
    /// sized to the world and shifted by the camera, clipped to the viewport.
    private func trackScene(track: F1Track, viewport: CGSize,
                            trackProgress: CGFloat, cameraOffset: CGSize, heading: Angle) -> some View {
        let worldSize = camera.worldSize(for: track.viewBox)
        let viewBoxToWorld = track.viewBox.fitTransform(in: CGRect(origin: .zero, size: worldSize))
        let carPosition = track.racingLine.point(at: trackProgress).applying(viewBoxToWorld)

        return ZStack(alignment: .topLeading) {
            Rectangle().fill(style.background)

            ZStack {
                track.racingLine.stroke(style.outlineColor, style: band(width: style.outlineWidth))
                track.racingLine.stroke(style.asphaltColor, style: band(width: style.trackWidth))

                if style.showsLapTrail {
                    let lap = F1Lap(track: track, lapDuration: 60)
                    ForEach(Array(lap.completedLapTrail(upTo: trackProgress).enumerated()), id: \.offset) { _, stretch in
                        track.racingLine.trimmed(from: stretch.from, to: stretch.to)
                            .stroke(style.lapTrailColor, style: band(width: style.trackWidth))
                    }
                }

                if let startFinishMarker = track.startFinishMarker {
                    startFinishMarker.fill(style.startLineColor)
                }

                F1Car(size: style.carSize)
                    .rotationEffect(carArtRotation + heading)
                    .position(carPosition)
            }
            .frame(width: worldSize.width, height: worldSize.height)
            .offset(cameraOffset)
        }
        .frame(width: viewport.width, height: viewport.height, alignment: .topLeading)
        .clipped()
    }

    private func band(width viewBoxUnits: CGFloat) -> StrokeStyle {
        StrokeStyle(lineWidth: viewBoxUnits * camera.zoom, lineCap: .round, lineJoin: .round)
    }

    // MARK: Camera modifiers
    func cameraZoom(_ zoom: CGFloat) -> F1TrackView { with { $0.camera.zoom = zoom } }
    func cameraAnchor(_ anchor: UnitPoint) -> F1TrackView { with { $0.camera.anchor = anchor } }
    func cameraInertia(_ inertia: Double) -> F1TrackView { with { $0.camera.inertia = inertia } }

    // MARK: Track & car modifiers
    func trackWidth(_ width: CGFloat) -> F1TrackView { with { $0.style.trackWidth = width } }
    func trackOutlineWidth(_ width: CGFloat) -> F1TrackView { with { $0.style.outlineWidth = width } }
    func trackColor(_ color: Color) -> F1TrackView { with { $0.style.asphaltColor = color } }
    func trackOutlineColor(_ color: Color) -> F1TrackView { with { $0.style.outlineColor = color } }
    func startLineColor(_ color: Color) -> F1TrackView { with { $0.style.startLineColor = color } }
    /// Track background — a plain colour (`.backgroundColour(.black)`) or a gradient
    /// (`.backgroundColour(.green.gradient)`); anything that is a `ShapeStyle`.
    func backgroundColour(_ style: some ShapeStyle) -> F1TrackView {
        with { $0.style.background = AnyShapeStyle(style) }
    }
    func lapTrail(show: Bool, color: Color = Color(red: 0.90, green: 0.22, blue: 0.27)) -> F1TrackView {
        with { $0.style.showsLapTrail = show; $0.style.lapTrailColor = color }
    }
    func carSize(_ size: CGSize) -> F1TrackView { with { $0.style.carSize = size } }
    func speedProfile(_ enabled: Bool) -> F1TrackView { with { $0.usesSpeedProfile = enabled } }

    private func with(_ change: (inout F1TrackView) -> Void) -> F1TrackView {
        var copy = self
        change(&copy)
        return copy
    }
}
