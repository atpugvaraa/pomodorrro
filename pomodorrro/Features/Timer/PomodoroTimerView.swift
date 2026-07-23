//
//  PomodoroTimerView.swift
//  pomodorrro
//
//  Created by Aarav Gupta on 22/07/26.
//

import SwiftUI

struct PomodoroTimerView: View {
    @State private var focusTime = 25 * 60
//    @State private var breakTime = 5 * 60
    @State private var breakTime = 5 * 1
    @State private var timer: Timer?
    @State private var canResetTimer: Bool = false
    
    var body: some View {
        VStack {
            Text(breakTime.clockFormat())
                .font(.title)
            
            Button("Reset & Pause Timer") {
                if canResetTimer {
                    destroyTimer()
                    breakTime = 5
                }
            }
            
            Button("Start Timer") {
                createTimer()
            }
        }
        .onAppear {
            createTimer()
        }
        .onDisappear {
            destroyTimer()
        }
    }
    
    func createTimer() {
        guard timer == nil else { return }
        
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { timer in
            guard breakTime > 0 else { return }
            
            breakTime -= 1
            
            if breakTime <= 0 {
                destroyTimer()
                canResetTimer = true
                print("you can now reset the timer")
            } else {
                canResetTimer = false
            }
        }
    }

    func destroyTimer() {
        if timer?.isValid == true {
            timer?.invalidate()
            timer = nil
        }
    }
}
