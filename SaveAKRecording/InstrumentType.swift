//
//  InstrumentType.swift
//  AudioKit-Sampler
//
//  Created by Mark Jeschke on 5/22/17.
//  Copyright © 2017 Mark Jeschke. All rights reserved.
//

import Foundation

var audioPath: String?

enum InstrumentType: String {
  case
      kickLeft = "Kick Left",
      kickRight = "Kick Right",
      snare = "Snare",
      cowbell = "Cowbell",
      hiTom = "Hi-Tom",
      lowTom = "Low-Tom",
      floorTom = "Floor-Tom"
  
  func audioFilePath() -> String {
    switch(self) {
    case .kickLeft:
      audioPath = "kickLeft.wav"
    case .kickRight:
      audioPath = "kickRight.wave"
    case .snare:
      audioPath = "snare.wave"
    default:
      print("I have an unexpected case.")
    }
    return audioPath!
  }
  
}
