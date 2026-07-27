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
