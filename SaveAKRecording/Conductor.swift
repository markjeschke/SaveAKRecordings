//
//  Conductor.swift
//  SaveAKRecording
//
//  Created by Mark Jeschke on 6/15/17.
//  Copyright © 2017 Mark Jeschke. All rights reserved.
//

import AudioKit

class Conductor {
    
    enum CurrentInstrument: String {
        case none
        case kick
        case snare
    }
    
    enum State {
        case readyToRecord
        case recording
        case readyToPlay
        case playing
    }
    
    static let sharedInstance = Conductor()
    
    let audioShareSDK = AudioShare()
    
    // Set instance variables
    let kickSampler: Instrument
    let snareSampler: Instrument
    
    var mixer = AKMixer()
    var mainMixer = AKMixer()
    
    var delay: AKDelay!
    var delayMixer: AKDryWetMixer!
    var reverb: AKReverb!
    var reverbMixer: AKDryWetMixer!
    var distortion: AKDistortion!
    var distortionMixer: AKDryWetMixer!
    
    var booster: AKBooster!

    var currentInstrument: CurrentInstrument = .none
    
    var state: State = .readyToRecord
    var recorder: AKNodeRecorder!
    var player: AKAudioPlayer!
    let exportedAudioFileName = "SavedAudioKitFile"
    var exportedAudioFilePath = String(describing: FileManager.default.urls(for: .documentDirectory, in: .userDomainMask))
    let exportedAudioFile: String = "SavedAudioKitFile.m4a"
    let timecodeFormatter = TimecodeFormatter()
    var audioFileDuration = "00:00:00"
    var exportedAudio: URL?
    
    init() {
        
        self.kickSampler = Instrument(
            type: .kickLeft,
            pitch: 60,
            samplePath: "Sounds/min_kick_02_C",
            midiNote: 36,
            midiProgramChange: 4,
            midiContinuousControl: 9)
        
        self.snareSampler = Instrument(
            type: .snare,
            pitch: 60,
            samplePath: "Sounds/Ensoniq-ESQ-1-Snare",
            midiNote: 38,
            midiProgramChange: 1,
            midiContinuousControl: 13)
        
        do {
            try self.kickSampler.loadWav(self.kickSampler.samplePath)
            try self.snareSampler.loadWav(self.snareSampler.samplePath)
        } catch {
            print("Could not locate the wav files.")
        }
        
        // Combine the kick and snare drum samples output into a mixer.
        mixer = AKMixer(kickSampler, snareSampler)
        
        // Clean tempFiles !
        AKAudioFile.cleanTempDirectory()
        
        // Session settings
        AKSettings.bufferLength = .medium
        
        do {
            try AKSettings.setSession(category: .playAndRecord, with: .allowBluetoothA2DP)
        } catch {
            AKLog("Could not set session category.")
        }
        
        booster = AKBooster(mixer)
        booster.gain = 1.0
        
        // Connect the mixer output to the delay node.
        delay = AKDelay(booster)
        delay.time = 1.0 // seconds
        delay.feedback  = 0.1 // Normalized Value 0 - 1
        delay.dryWetMix = 0.2  // Normalized Value 0 - 1
        delay.lowPassCutoff = 15000
        
        // Connect the mixer output and the delay effect to its own delayMixer.
        // mixer output 0 << 0.5 >> 1.0 delay effect
        delayMixer = AKDryWetMixer(mixer, delay)
        delayMixer.balance = 0.5
        
        // Connect the delayMixer output to the reverb node.
        reverb = AKReverb(delayMixer)
        reverb.dryWetMix = 0.5
        reverb.loadFactoryPreset(.largeRoom)
        
        // Connect the mixer output and the reverb effect to its own reverbMixer.
        // mixer output 0 << 0.5 >> 1.0 reverb effect
        reverbMixer = AKDryWetMixer(delayMixer, reverb)
        reverbMixer.balance = 0.5
        
        distortion = AKDistortion(reverbMixer)
        distortion.squaredTerm = 0.7
        distortion.polynomialMix = 0.7
        distortion.finalMix = 0.6
        distortionMixer = AKDryWetMixer(reverbMixer, distortion)
        distortionMixer.balance = 0.5
        
        recorder = try? AKNodeRecorder(node: distortionMixer)
        if let file = recorder.audioFile {
            player = try? AKAudioPlayer(file: file)
        }
        player.looping = true
        player.completionHandler = playingEnded
        
        mainMixer = AKMixer(distortionMixer, player)
        
        // Connect the end of the audio chain to the global output.
        AudioKit.output = mainMixer
        
        // Allow audio to play while the iOS device is muted.
        AKSettings.playbackWhileMuted = true
        
        AKSettings.defaultToSpeaker = true
        
        // Start the audio engine
        AudioKit.start()
        print("Audio engine started")
        
        print("state: \(state)")
    }
    
    func playingEnded() {
        DispatchQueue.main.async {
            print("Finished playing the audio file.")
            self.setupUIForPlaying ()
        }
    }
    
    func recordPlayToggle() {
        print("state: \(state)")
        switch state {
        case .readyToRecord :
            // Recording...
            state = .recording
            do {
                try recorder.record()
            } catch { print("Error recording.") }
            
        case .recording :
            do {
                try player.reloadFile()
            } catch { print("Error reloading.") }
            
            let recordedDuration = player != nil ? player.audioFile.duration  : 0
            if recordedDuration > 0.0 {
                recorder.stop()
                player.audioFile.exportAsynchronously(name: exportedAudioFileName,
                                                      baseDir: .documents,
                                                      exportFormat: .m4a) {_, exportError in
                                                        if let error = exportError {
                                                            print("Export Failed \(error)")
                                                        } else {
                                                            print("Export succeeded")
                                                        }
                }
                setupUIForPlaying ()
            }
        case .readyToPlay :
            player.play()
            state = .playing
        case .playing :
            player.stop()
            setupUIForPlaying()
        }
        
    }
    
    func setupUIForPlaying () {
        let recordedDuration = player != nil ? player.audioFile.duration: 0
        print("Recorded: \(String(format: "%0.1f", recordedDuration)) seconds")
        audioFileDuration = timecodeFormatter.convertSecondsToTimecode(totalSeconds: Int(recordedDuration))
        showFiles()
        state = .readyToPlay
    }
    
    func getDocumentsDirectory() -> String {
        
        let paths = NSSearchPathForDirectoriesInDomains(.documentDirectory,.userDomainMask, true) as [String]
        
        return paths[0]
    }
    
    func showFiles() {
        print("getDocumentsDirectory: \(getDocumentsDirectory())")
        print("show files")

        if let exportedAudio = String(getDocumentsDirectory()) {
            self.exportedAudioFilePath = exportedAudio
        }

        var path = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
        path?.appendPathComponent(exportedAudioFile)
        
        print("path: \(String(describing: path))")
        
        exportedAudio = path
        
        do {
            let items = try FileManager.default.contentsOfDirectory(atPath: getDocumentsDirectory())
            
            for item in items {
                print("Found \(item)")
            }
        } catch {
            print("Can't find any items")
        }
    }
    
    internal func playKick() {
        kickSampler.play(noteNumber:kickSampler.pitch, velocity:127, channel: 0)
    }
    
    internal func playSnare() {
        snareSampler.play(noteNumber:snareSampler.pitch, velocity:127, channel: 0)
    }
    
    //Mark - Export to AudioShare
    
    internal func exportToAudioShare () {
        audioShareSDK.addSound(from: exportedAudio, withName: exportedAudioFileName)
    }
    
}
