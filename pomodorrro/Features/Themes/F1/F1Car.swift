//
//  F1Car.swift
//  pomodorrro
//
//  Created by Aarav Gupta on 22/07/26.
//

import SwiftUI

struct F1Car: View {
    var size: CGSize = CGSize(width: 100, height: 300)

    var body: some View {
        Image(.f1Car)
            .resizable()
            .frame(width: size.width, height: size.height)
    }
}

#Preview("Car") {
    F1Car()
}

#Preview("Following camera — scrub the lap") {
    struct Demo: View {
        @State private var progress: Double = 0.0
        var body: some View {
            VStack(spacing: 16) {
                F1TrackView(progress: progress)
                    .scaleEffect(1.4)
                    .frame(width: 320, height: 420)
                    .clipShape(RoundedRectangle(cornerRadius: 20))

                Slider(value: $progress, in: 0...1)
                Text("progress \(progress, specifier: "%.2f")")
                    .font(.caption).monospacedDigit()
            }
            .padding()
        }
    }
    return Demo()
}
