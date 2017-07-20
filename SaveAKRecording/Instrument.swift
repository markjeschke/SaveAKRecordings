//
//  Instrument.swift
//  AudioKit-Sampler
//
//  Created by Mark Jeschke on 5/22/17.
//  Copyright © 2017 Mark Jeschke. All rights reserved.
//

import AudioKit

enum EffectType: Double {
    case reverb
    case delay
}

struct GlobalEffectParams {
    var bypassed = false
    var wetDryMix = 0.5
}

class Instrument: AKMIDISampler {
  var pitch: MIDINoteNumber
  var samplePath: String
  var midiNote: MIDINoteNumber
  var midiProgramChange: MIDIByte
  var midiContinuousControl: MIDIByte
  
  init(
       pitch: MIDINoteNumber,
       samplePath: String,
       midiNote: MIDINoteNumber,
       midiProgramChange: MIDIByte,
       midiContinuousControl: MIDIByte)
  {
    self.pitch = pitch
    self.samplePath = samplePath
    self.midiNote = midiNote
    self.midiProgramChange = midiProgramChange
    self.midiContinuousControl = midiContinuousControl
  }
    
}
