//
//  F1ThemeView.swift
//  pomodorrro
//

import SwiftUI

/// The Formula 1 skin for a work session: a car laps a randomly chosen circuit, one lap per
/// minute, for as long as the timer runs.
///
/// The circuit is picked once per instance, so the shell gets a fresh track per session simply
/// by giving this view a new identity (`.id(timer.sessionIndex)`).
struct F1ThemeView: View {
    let elapsed: TimeInterval
    let isRunning: Bool

    @State private var circuit = F1Circuit.random

    var body: some View {
        // The elapsed-time initializer interpolates between updates on its own, so feeding it
        // once a second is enough for frame-rate-smooth motion.
        F1TrackView(circuit, elapsedTime: elapsed, isRunning: isRunning)
            .cameraZoom(5)
            .cameraAnchor(.init(x: 0.5, y: 0.55))
            .backgroundColour(.green.gradient)
    }
}

#Preview("F1 Theme") {
    TimelineView(.animation) { context in
        F1ThemeView(elapsed: context.date.timeIntervalSince1970, isRunning: true)
    }
    .ignoresSafeArea()
}
