//
//  PomodoroTheme.swift
//  pomodorrro
//

import SwiftUI

/// The visual skins a work session can be rendered with. Each case owns one theme view and
/// nothing else — the timer never learns what a circuit, a court or a canvas is.
///
/// Adding a theme is a case here plus a view file under `Features/Themes/<name>/`.
enum PomodoroTheme: String, CaseIterable, Identifiable {
    case formula1

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .formula1: "Formula 1"
        }
    }

    static var random: PomodoroTheme { allCases.randomElement()! }

    /// The full-bleed backdrop for a work session, driven by the timer's elapsed seconds.
    @ViewBuilder
    func workView(elapsed: TimeInterval, isRunning: Bool) -> some View {
        switch self {
        case .formula1:
            F1ThemeView(elapsed: elapsed, isRunning: isRunning)
        }
    }
}
