//
//  Int+clockFormat.swift
//  pomodorrro
//
//  Created by Aarav Gupta on 22/07/26.
//

import Foundation

extension Int {
    func clockFormat() -> String {
        let minutes = self / 60
        let seconds = self % 60
        
        return "\(minutes.formatted()):\(seconds.formatted(.number.precision(.integerLength(2))))"
    }
}
