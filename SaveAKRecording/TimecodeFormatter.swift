//
//  TimecodeFormatter.swift
//  SaveAKRecording
//
//  Created by Mark Jeschke on 6/17/17.
//  Copyright © 2017 Mark Jeschke. All rights reserved.
//

import Foundation

class TimecodeFormatter {
    func convertSecondsToTimecode(totalSeconds: Int) -> String {
        let seconds: Int = totalSeconds % 60
        let minutes: Int = (totalSeconds / 60) % 60
        let hours: Int = totalSeconds / 3600
        return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
    }
}
