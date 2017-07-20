//
//  Conductor.swift
//  SaveAKRecording
//
//  Created by Mark Jeschke on 6/15/17.
//  Copyright © 2017 Mark Jeschke. All rights reserved.
//

import AudioKit

class Conductor {
    
    enum RecordingState {
        case readyToRecord
        case recording
    }
    
    enum PlayingState {
        case readyToPlay
        case playing
        case disabled
    }
    
    enum Format: String {
        case m4a = ".m4a"
        case wav = ".wav"
        case mp4 = ".mp4"
        case aif = ".aif"
        case caf = ".caf"
        func selectExtension() -> AKAudioFile.ExportFormat {
            switch self {
            case .m4a:
                return .m4a
            case .wav:
                return .wav
            case .mp4:
                return .mp4
            case .aif:
                return .aif
            case .caf:
                return .caf
            }
        }
    }
    
    static let sharedInstance = Conductor()
    
    let audioShareSDK = AudioShare()
    
    // Set instance variables
    let kickSampler: Instrument
    let snareSampler: Instrument
    
    var instrumentMixer = AKMixer()
    var outputMixer = AKMixer()
    
    var kickDelay: AKDelay!
    var kickReverb: AKReverb!
    var kickDistortion: AKDistortion!
    
    var snareDelay: AKDelay!
    var snareReverb: AKReverb!
    var snareDistortion: AKDistortion!
    
    var booster: AKBooster!
    var delay: AKDelay!
    var delayMixer: AKDryWetMixer!
    var reverb: AKReverb!
    var reverbMixer: AKDryWetMixer!
    var distortion: AKDistortion!
    var distortionMixer: AKDryWetMixer!
    
    var recordingState: RecordingState = .readyToRecord
    var playingState: PlayingState = .disabled
    var recorder: AKNodeRecorder!
    var player: AKAudioPlayer!
    var exportedAudioFileName = "SavedAudioKitFile"
    var exportedAudioFilePath: String = ""
    var exportedAudioFile: String = ""
    let timecodeFormatter = TimecodeFormatter()
    var audioFileDuration = "00:00:00"
    var exportedAudio: URL?
    var audioFormat:Format = .m4a // Set the audio format. This should be set by the user via UISegmentedControl.
    var recordingsFound = false
    var directoryContent = [String()]
    let documentsFolder = NSSearchPathForDirectoriesInDomains(.documentDirectory,.userDomainMask, true)
    var recordingPath = ""
    
    init() {
        
        // Clean tempFiles !
        //AKAudioFile.cleanTempDirectory()
        
        // Session settings
        AKSettings.bufferLength = .medium
        
        do {
            try AKSettings.setSession(category: .playAndRecord, with: .mixWithOthers)
        } catch {
            AKLog("Could not set session category.")
        }
        
        self.kickSampler = Instrument(
            pitch: 60,
            samplePath: "Sounds/min_kick_02_C",
            midiNote: 36,
            midiProgramChange: 4,
            midiContinuousControl: 9)
        
        self.snareSampler = Instrument(
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
        
        // Provide independent delay, distortion and reverb effects for the kick and snare drum sounds.
        
        // kick sampler node into a delay
        kickDelay = AKDelay(kickSampler)
        kickDelay.time = 0.03 // seconds
        kickDelay.feedback  = 0.02 // Normalized Value 0 - 1
        kickDelay.dryWetMix = 0.0  // Normalized Value 0 - 1
        kickDelay.lowPassCutoff = 15000
        
        // kick distortion
        kickDistortion = AKDistortion(kickDelay)
        kickDistortion.squaredTerm = 0.4
        kickDistortion.cubicTerm = 1.0
        kickDistortion.decay = 7.0
        kickDistortion.delay = 0.3
        kickDistortion.delayMix = 0.1
        kickDistortion.rounding = 0.0
        kickDistortion.softClipGain = 7.0
        kickDistortion.polynomialMix = 0.0
        kickDistortion.finalMix = 0.3
        kickDistortion.decimation = 0.6
        kickDistortion.decimationMix = 1.0
        
        // kick reverb
        kickReverb = AKReverb(kickDistortion)
        kickReverb.dryWetMix = 0.15
        kickReverb.loadFactoryPreset(.mediumRoom)
        
        // snare sampler node into a delay
        snareDelay = AKDelay(snareSampler)
        snareDelay.time = 0.2 // seconds
        snareDelay.feedback  = 0.2 // Normalized Value 0 - 1
        snareDelay.dryWetMix = 0.01  // Normalized Value 0 - 1
        snareDelay.lowPassCutoff = 15000
        
        // snare distortion
        snareDistortion = AKDistortion(snareDelay)
        snareDistortion.finalMix = 0.0
        
        // snare reverb
        snareReverb = AKReverb(snareDistortion)
        snareReverb.dryWetMix = 0.3
        snareReverb.loadFactoryPreset(.largeHall)
        
        // Combine the ending result of the kick and snare nodes, and combine them with a mixer.
        instrumentMixer = AKMixer(kickReverb, snareReverb)
        
        // Connect the mixer output to the booster node.
        booster = AKBooster(instrumentMixer)
        booster.gain = 1.0
        
        // Connect the booster output to the delay node.
        delay = AKDelay(booster)
        delay.time = 0.12 // seconds
        delay.feedback  = 0.07 // Normalized Value 0 - 1
        delay.dryWetMix = 0.0  // Normalized Value 0 - 1
        delay.lowPassCutoff = 15000
        
        // Connect the booster output and the delay effect to its own delayMixer.
        // mixer output 0 << 0.5 >> 1.0 delay effect
        delayMixer = AKDryWetMixer(booster, delay)
        delayMixer.balance = 0.5
        
        // Connect the delayMixer output to the reverb node.
        reverb = AKReverb(delayMixer)
        reverb.dryWetMix = 0.0
        reverb.loadFactoryPreset(.mediumChamber)
        
        // Connect the mixer output and the reverb effect to its own reverbMixer.
        // mixer output 0 << 0.5 >> 1.0 reverb effect
        reverbMixer = AKDryWetMixer(delayMixer, reverb)
        reverbMixer.balance = 0.5
        
        // Connect reverbMixer to the distortion node.
        distortion = AKDistortion(reverbMixer)
        distortion.squaredTerm = 0.0
        distortion.cubicTerm = 1.0
        distortion.decay = 7.0
        distortion.delay = 0.3
        distortion.delayMix = 0.1
        distortion.rounding = 0.1
        distortion.softClipGain = 5.0
        distortion.polynomialMix = 0.0
        distortion.finalMix = 0.0
        distortion.decimation = 0.1
        distortion.decimationMix = 0.8
        distortionMixer = AKDryWetMixer(reverbMixer, distortion)
        distortionMixer.balance = 0.5
        
        // Connect the recorder to the output of the distortionMixer(with reverbMixer).
        recorder = try? AKNodeRecorder(node: distortionMixer)
        if let file = recorder.audioFile {
            player = try? AKAudioPlayer(file: file)
        }
        player.looping = true
        player.completionHandler = playingEnded
        
        // Mix the distortionMixer(with reverbMixer) and player node into the outputMixer.
        outputMixer = AKMixer(distortionMixer, player)
        
        // Connect the end of the audio chain to the AudioKit engine output.
        AudioKit.output = outputMixer
        
        // Allow audio to play while the iOS device is muted.
        AKSettings.playbackWhileMuted = true
        
        /// Whether to DefaultToSpeaker when audio input is enabled
        AKSettings.defaultToSpeaker = true
        
        // Start the audio engine
        AudioKit.start()
        print("Audio engine started")
        
        recordingPath = documentsFolder[0]
        
        print("documentsFolder: \(documentsFolder)")
        print("recordingPath: \(recordingPath)")
        
        deleteAllFiles()
        
    }
    
    // Print out all of the found files in the Documents directory.
    internal func showFilesOnDevice() {

        do {
            directoryContent = try FileManager.default.contentsOfDirectory(atPath: recordingPath)
            for item in directoryContent {
                print("Found: \(item)")
            }
            if directoryContent.count > 0 {
                print("directoryContent.count: \(directoryContent.count)")
                recordingsFound = true
            } else {
                recordingsFound = false
            }
        } catch {
            print("Can't find any items")
        }
        
        print("directoryContent: \(directoryContent)")
        print("directoryContent.count: \(directoryContent.count)")
        print("recordingsFound: \(recordingsFound)")
        
    }
    
    internal func deleteAllFiles() {
        if (directoryContent.count > 0) {
            for fileName in directoryContent {
                let filePathName = "\(recordingPath)/\(fileName)"
                do {
                    try FileManager.default.removeItem(atPath: filePathName)
                } catch {
                    print("No files found to delete")
                }
            }
        }
    }
    
    internal func playingEnded() {
        DispatchQueue.main.async {
            print("Finished playing the audio file.")
            self.setupUIForPlaying()
        }
    }
    
    internal func recordToggle() {
        print("state: \(recordingState)")
        switch recordingState {
        case .readyToRecord :
            // Recording...
            if (playingState == .readyToPlay || playingState == .playing) {
                do {
                    try recorder.reset()
                } catch {
                    print("Errored resetting.")
                }
            }
            recordingState = .recording
            playingState = .disabled
            do {
                try recorder.record()
            } catch {
                print("Error recording.")
            }
        case .recording :
            do {
                try player.reloadFile()
            } catch {
                print("Error reloading.")
            }
            let recordedDuration = player != nil ? player.audioFile.duration  : 0
            if recordedDuration > 0.0 {
                recorder.stop()
                player.audioFile.exportAsynchronously(name: exportedAudioFileName,
                                                      baseDir: .documents,
                                                      exportFormat: audioFormat.selectExtension()) {_, exportError in
                                                        if let error = exportError {
                                                            print("Export Failed \(error)")
                                                        } else {
                                                            print("Export succeeded")
                                                        }
                }
                setupUIForPlaying()
                recordingState = .readyToRecord
                playingState = .readyToPlay
                setExportedAudioPath()
            }
        }
    }
    
    internal func playStopToggle() {
        switch playingState {
        case .readyToPlay:
            player.play()
            playingState = .playing
        case .playing:
            player.stop()
            setupUIForPlaying()
            playingState = .readyToPlay
        case .disabled:
            break
        }
        print("playingState: \(playingState)")
    }
    
    internal func setupUIForPlaying() {
        let recordedDuration = player != nil ? player.audioFile.duration: 0
        print("Recorded: \(String(format: "%0.1f", recordedDuration)) seconds")
        audioFileDuration = timecodeFormatter.convertSecondsToTimecode(totalSeconds: Int(recordedDuration))
    }
    
    internal func setExportedAudioPath() {

        if let exportedAudioPath = String(recordingPath) {
            self.exportedAudioFilePath = exportedAudioPath
            print("self.exportedAudioFilePath: \(String(describing: self.exportedAudioFilePath))")
        }

        // Concatenate the exported audio file name with the audio format extension.
        self.exportedAudioFile = "\(self.exportedAudioFileName)\(self.audioFormat.rawValue)"
        
        // Append the exported audio file name to the URL.
        if var path = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
            path.appendPathComponent(self.exportedAudioFile)
            exportedAudio = path
        }
        
        // Show all of the files on the device, if they exist.
        showFilesOnDevice()

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
