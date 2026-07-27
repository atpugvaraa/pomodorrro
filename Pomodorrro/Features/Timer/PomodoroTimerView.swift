//
//  PomodoroTimerView.swift
//  pomodorrro
//
//  Created by Aarav Gupta on 22/07/26.
//

import SwiftUI

struct PomodoroTimerView: View {
    @State private var timer = PomodoroTimer()
    @State private var theme = PomodoroTheme.random
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        ZStack {
            backdrop
            controls
        }
        .onChange(of: scenePhase) { _, phase in
            // Catch up on everything that elapsed while the app was suspended.
            if phase == .active { timer.tick() }
        }
        .onChange(of: timer.sessionIndex) { _, _ in
            theme = .random
        }
    }

    @ViewBuilder
    private var backdrop: some View {
        switch timer.phase {
        case .work:
            theme.workView(elapsed: timer.elapsed, isRunning: timer.isRunning)
                .id(timer.sessionIndex)   // new session, new theme instance, new circuit
                .ignoresSafeArea()
        case .rest:
            Color.secondary.opacity(0.15)   // ponytail: plain break screen until themes cover breaks too
                .ignoresSafeArea()
        }
    }

    private var controls: some View {
        VStack(spacing: 0) {
            Spacer()
            panel
        }
    }

    private var panel: some View {
        VStack(spacing: 16) {
            Text(timer.phase.title)
                .font(.headline)
                .textCase(.uppercase)

            Text(timer.remaining.clockFormat())
                .font(.system(size: 64, weight: .semibold, design: .rounded))
                .monospacedDigit()

            HStack(spacing: 12) {
                Button(timer.isRunning ? "Pause" : "Start") {
                    timer.isRunning ? timer.pause() : timer.start()
                }
                .buttonStyle(.borderedProminent)

                Button("Reset") { timer.reset() }
                Button("Skip") { timer.skip() }
            }
            .buttonStyle(.bordered)

            Text("Sessions completed: \(timer.completedSessions)")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 20)
        .frame(maxWidth: .infinity)
        .background(.ultraThinMaterial)   // keeps the clock legible over a theme backdrop
    }
}

#Preview {
    PomodoroTimerView()
}
