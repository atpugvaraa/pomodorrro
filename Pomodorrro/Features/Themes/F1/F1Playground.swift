import SwiftUI

/// Internal development tool for tuning the F1 animation without editing source.
/// Usability over looks: the track fills the top, every knob sits below it.
struct F1Playground: View {
    @State private var circuit: F1Circuit = .monza
    @State private var isRunning = false
    @State private var startDate = Date()
    @State private var scrubProgress = 0.0
    @State private var lapDuration = 60.0

    @State private var cameraZoom = 4.5
    @State private var cameraAnchorX = 0.5
    @State private var cameraAnchorY = 0.72
    @State private var cameraInertia = 0.14
    @State private var cameraSmoothing = true

    @State private var trackWidth = 13.0
    @State private var outlineWidth = 17.0
    @State private var carWidth = 22.0
    @State private var carHeight = 60.0

    @State private var backgroundColor = Color(white: 0.10)
    @State private var trackColor = Color(white: 0.17)
    @State private var outlineColor = Color(white: 0.62)

    @State private var showLapTrail = false
    @State private var useSpeedProfile = true

    var body: some View {
        VStack(spacing: 0) {
            trackArea.frame(height: 360)
            Divider()
            controls
        }
    }

    private var trackArea: some View {
        Group {
            if isRunning {
                TimelineView(.animation) { context in
                    styled(F1TrackView(circuit, elapsedTime: context.date.timeIntervalSince(startDate),
                                       isRunning: true, lapDuration: lapDuration))
                }
            } else {
                styled(F1TrackView(circuit, progress: scrubProgress))
            }
        }
        .frame(maxWidth: .infinity)
    }

    /// Applies every playground control through the public modifiers, so the tool
    /// exercises exactly the API the app uses.
    private func styled(_ view: F1TrackView) -> some View {
        view
            .cameraZoom(cameraZoom)
            .cameraAnchor(UnitPoint(x: cameraAnchorX, y: cameraAnchorY))
            .cameraInertia(cameraSmoothing ? cameraInertia : 0)
            .trackWidth(trackWidth)
            .trackOutlineWidth(outlineWidth)
            .trackColor(trackColor)
            .trackOutlineColor(outlineColor)
            .backgroundColour(backgroundColor)
            .lapTrail(show: showLapTrail)
            .carSize(CGSize(width: carWidth, height: carHeight))
            .speedProfile(useSpeedProfile)
    }

    private var controls: some View {
        Form {
            Section("Circuit") {
                Picker("Circuit", selection: $circuit) {
                    ForEach(F1Circuit.allCases) { Text($0.displayName).tag($0) }
                }
                Button(isRunning ? "Pause" : "Play") {
                    if !isRunning { startDate = Date() }
                    isRunning.toggle()
                }
                if !isRunning { slider("Scrub", $scrubProgress, 0...1) }
                slider("Lap duration (s)", $lapDuration, 5...120)
            }
            Section("Metrics") { metrics }
            Section("Compare vs telemetry") { comparison }
            Section("Camera") {
                slider("Zoom", $cameraZoom, 1...12)
                slider("Anchor X", $cameraAnchorX, 0...1)
                slider("Anchor Y", $cameraAnchorY, 0...1)
                Toggle("Smoothing", isOn: $cameraSmoothing)
                if cameraSmoothing { slider("Inertia", $cameraInertia, 0.01...0.6) }
            }
            Section("Track & car") {
                slider("Track width", $trackWidth, 1...40)
                slider("Outline width", $outlineWidth, 1...44)
                slider("Car width", $carWidth, 4...80)
                slider("Car height", $carHeight, 10...200)
            }
            Section("Colours") {
                ColorPicker("Background", selection: $backgroundColor)
                ColorPicker("Track", selection: $trackColor)
                ColorPicker("Outline", selection: $outlineColor)
            }
            Section("Toggles") {
                Toggle("Lap trail", isOn: $showLapTrail)
                Toggle("Speed profile", isOn: $useSpeedProfile)
            }
        }
    }

    @ViewBuilder
    private var metrics: some View {
        if let track = circuit.loadTrack() {
            let report = F1SpeedProfileReport(track: track, circuit: circuit)
            Text(String(format: "speed  min %.2f  max %.2f  var %.2f", report.minimumSpeed, report.maximumSpeed, report.speedVariation))
            Text(String(format: "brake %.2f  accel %.2f  longest straight %.0f%%", report.hardestBraking, report.strongestAcceleration, report.longestStraightFraction * 100))
            Text(report.anomalies.isEmpty ? "no anomalies" : "⚠︎ " + report.anomalies.joined(separator: ", "))
                .foregroundStyle(report.anomalies.isEmpty ? Color.secondary : Color.orange)
        }
    }

    @ViewBuilder
    private var comparison: some View {
        if let track = circuit.loadTrack(), let telemetry = F1Telemetry.reference(for: circuit) {
            let result = F1SpeedComparison(track: track, telemetry: telemetry)
            Text(String(format: "RMS vs %@ %d: %.3f", telemetry.source, telemetry.season, result.rootMeanSquareError))
                .font(.caption.monospaced())
            SpeedChart(generated: result.generated, measured: result.measured,
                       lapMarker: isRunning ? nil : scrubProgress)
                .frame(height: 120)
            Text("cyan = ours · orange = real (\(telemetry.season))")
                .font(.caption2).foregroundStyle(.secondary)
            CurvatureStrip(curvature: track.speedProfile.curvature).frame(height: 36)
            Text("curvature (detected corners)").font(.caption2).foregroundStyle(.secondary)
        } else {
            Text("no telemetry for \(circuit.displayName) — inferred only")
                .font(.caption).foregroundStyle(.secondary)
        }
    }

    private struct CurvatureStrip: View {
        let curvature: [CGFloat]
        var body: some View {
            Canvas { context, size in
                let peak = max(curvature.max() ?? 1, 0.0001)
                for (index, value) in curvature.enumerated() {
                    let x = size.width * CGFloat(index) / CGFloat(curvature.count - 1)
                    let height = size.height * value / peak
                    context.stroke(Path { $0.move(to: CGPoint(x: x, y: size.height)); $0.addLine(to: CGPoint(x: x, y: size.height - height)) },
                                   with: .color(.red.opacity(0.5)), lineWidth: 1)
                }
            }
        }
    }

    private struct SpeedChart: View {
        let generated: [CGFloat]
        let measured: [CGFloat]
        let lapMarker: Double?
        var body: some View {
            Canvas { context, size in
                let peak = max(generated.max() ?? 1, measured.max() ?? 1, 1.2)
                func line(_ values: [CGFloat]) -> Path {
                    var path = Path()
                    for (index, value) in values.enumerated() {
                        let x = size.width * CGFloat(index) / CGFloat(values.count - 1)
                        let y = size.height * (1 - value / peak)
                        index == 0 ? path.move(to: CGPoint(x: x, y: y)) : path.addLine(to: CGPoint(x: x, y: y))
                    }
                    return path
                }
                context.stroke(line(measured), with: .color(.orange), lineWidth: 1.5)
                context.stroke(line(generated), with: .color(.cyan), lineWidth: 1.5)
                if let lapMarker {
                    let x = size.width * CGFloat(lapMarker)
                    context.stroke(Path { $0.move(to: CGPoint(x: x, y: 0)); $0.addLine(to: CGPoint(x: x, y: size.height)) },
                                   with: .color(.white.opacity(0.5)), lineWidth: 1)
                }
            }
        }
    }

    private func slider(_ label: String, _ value: Binding<Double>, _ range: ClosedRange<Double>) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("\(label): \(value.wrappedValue, specifier: "%.2f")").font(.caption.monospaced())
            Slider(value: value, in: range)
        }
    }
}

#Preview("F1 Playground") {
    F1Playground()
}
