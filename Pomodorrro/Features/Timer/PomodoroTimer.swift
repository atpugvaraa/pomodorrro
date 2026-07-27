//
//  PomodoroTimer.swift
//  pomodorrro
//

import Foundation
import Observation

/// Theme-agnostic Pomodoro clock: 20 minutes of work, 5 minutes of break, alternating forever.
///
/// Elapsed time is derived from a wall-clock anchor rather than counted tick by tick, so the
/// countdown neither drifts nor loses time while the app is suspended — the next `tick(at:)`
/// recomputes from the current date and self-corrects.
@Observable
final class PomodoroTimer {
    enum Phase {
        case work, rest

        var duration: TimeInterval {
            switch self {
            case .work: 20 * 60
            case .rest: 5 * 60
            }
        }

        var title: String {
            switch self {
            case .work: "Focus"
            case .rest: "Break"
            }
        }

        var next: Phase { self == .work ? .rest : .work }
    }

    private(set) var phase: Phase = .work
    private(set) var elapsed: TimeInterval = 0
    private(set) var isRunning = false

    /// Bumps every time a work phase begins, so the UI can hand the theme a fresh identity.
    private(set) var sessionIndex = 0

    private(set) var completedSessions: Int {
        didSet { defaults.set(completedSessions, forKey: Self.completedSessionsKey) }
    }

    var remaining: Int { max(0, Int((phase.duration - elapsed).rounded(.up))) }

    private static let completedSessionsKey = "completedSessions"

    private let defaults: UserDefaults
    private var accumulated: TimeInterval = 0
    private var startedAt: Date?
    private var ticker: Timer?

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        self.completedSessions = defaults.integer(forKey: Self.completedSessionsKey)
    }

    deinit { ticker?.invalidate() }

    func start(at now: Date = Date()) {
        guard !isRunning else { return }
        startedAt = now
        isRunning = true
        ticker = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            self?.tick()
        }
    }

    func pause(at now: Date = Date()) {
        guard isRunning else { return }
        accumulated = elapsedTime(at: now)
        elapsed = accumulated
        startedAt = nil
        isRunning = false
        ticker?.invalidate()
        ticker = nil
    }

    /// Stops the clock and rewinds the current phase to its start.
    func reset(at now: Date = Date()) {
        pause(at: now)
        accumulated = 0
        elapsed = 0
    }

    /// Jumps to the next phase, keeping the clock running if it already was.
    func skip(at now: Date = Date()) {
        advance(at: now)
    }

    /// Recomputes `elapsed` from the wall clock and rolls over to the next phase when due.
    func tick(at now: Date = Date()) {
        elapsed = elapsedTime(at: now)

        // A long suspension can span more than one phase, so keep rolling until we land inside one.
        while elapsed >= phase.duration {
            let overshoot = elapsed - phase.duration
            advance(at: now)
            accumulated = overshoot
            elapsed = elapsedTime(at: now)
        }
    }

    private func elapsedTime(at now: Date) -> TimeInterval {
        guard let startedAt else { return accumulated }
        return accumulated + max(0, now.timeIntervalSince(startedAt))
    }

    private func advance(at now: Date) {
        if phase == .work { completedSessions += 1 }
        phase = phase.next
        if phase == .work { sessionIndex += 1 }

        accumulated = 0
        elapsed = 0
        startedAt = isRunning ? now : nil
    }
}
