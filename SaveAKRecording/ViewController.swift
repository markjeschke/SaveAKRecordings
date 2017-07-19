//
//  ViewController.swift
//  SaveAKRecording
//
//  Created by Mark Jeschke on 6/15/17.
//  Copyright © 2017 Mark Jeschke. All rights reserved.
//

import UIKit
import MessageUI

class ViewController: UIViewController {

    var conductor = Conductor.sharedInstance
    let emailComposer = EmailComposer()
    
    @IBOutlet weak var audioFormatSelectorSegmentedControl: UISegmentedControl!
    @IBOutlet weak var kickButton: UIButton!
    @IBOutlet weak var snareButton: UIButton!
    @IBOutlet weak var recordToggleButton: UIButton!
    @IBOutlet weak var playStopToggleButton: UIButton!
    @IBOutlet weak var exportBtn: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        initializeUI()
        
    }
    
    private func initializeUI() {
        recordToggleButton.setTitle("◉ Record", for: .normal)
        recordToggleButton.setTitleColor(.recordColor, for: .normal)
        recordToggleButton.layer.cornerRadius = 5.0
        recordToggleButton.layer.borderWidth = 0.5
        recordToggleButton.layer.borderColor = UIColor.recordColor.cgColor
        playStopToggleButton.setTitle("▶︎ Play", for: .normal)
        playStopToggleButton.layer.cornerRadius = 5.0
        playStopToggleButton.layer.borderWidth = 0.5
        exportBtn.isEnabled = false
        playStopToggleButton.isEnabled = false
    }
    
    //MARK: IBActions
    @IBAction func recordToggleAction(_ sender: UIButton) {
        conductor.recordToggle()
        switch(conductor.recordingState) {
        case .readyToRecord:
            conductor.player.stop()
            do {
                try conductor.recorder.reset()
            } catch { print("Errored resetting.") }
            
            //try? player.replaceFile((recorder.audioFile)!)
            //setupUIForRecording()
            //conductor.recordToggle()
            recordToggleButton.setTitle("◉ Record", for: .normal)
            recordToggleButton.setTitleColor(.recordColor, for: .normal)
            recordToggleButton.layer.borderColor = UIColor.recordColor.cgColor
            recordToggleButton.layer.backgroundColor = UIColor.clear.cgColor
            playStopToggleButton.isEnabled = true
            playButtonFormatting()
        case .recording:
            recordToggleButton.setTitle("◼︎ Stop", for: .normal)
            recordToggleButton.setTitleColor(.white, for: .normal)
            recordToggleButton.layer.backgroundColor = UIColor.recordColor.cgColor
            playStopToggleButton.isEnabled = false
        }
    }
    
    @IBAction func playStopToggleAction(_ sender: UIButton) {
        conductor.playStopToggle()
        switch(conductor.playingState) {
        case .playing:
            playStopToggleButton.setTitle("◼︎ Stop", for: .normal)
            playStopToggleButton.setTitleColor(.white, for: .normal)
            playStopToggleButton.layer.backgroundColor = UIColor.playColor.cgColor
        case .readyToPlay:
            playButtonFormatting()
            exportBtn.isEnabled = true
        case .disabled:
            playStopToggleButton.isEnabled = false
        }
    }
    
    private func playButtonFormatting() {
        playStopToggleButton.setTitle("▶︎ Play", for: .normal)
        playStopToggleButton.setTitleColor(.playColor, for: .normal)
        playStopToggleButton.layer.backgroundColor = UIColor.clear.cgColor
        playStopToggleButton.layer.borderColor = UIColor.playColor.cgColor
        playStopToggleButton.isEnabled = true

    }
    
    @IBAction func triggerKick() {
        conductor.playKick()
    }
    
    @IBAction func triggerSnare() {
        conductor.playSnare()
    }
    
    @IBAction func sendEmailButtonTapped(_ sender: AnyObject) {

        let alertController = UIAlertController(title: "Export Audio Recording", message: "\"\(self.conductor.exportedAudioFile)\"", preferredStyle: .actionSheet)
        
        // AudioShare
        let audioShareAction = UIAlertAction(title: "AudioShare", style: .default) { (action) in
            self.conductor.exportToAudioShare()
        }
        // Email
        let emailAction = UIAlertAction(title: "Email", style: .default) { (action) in
            self.exportToEmail()
        }
        // Share
        let shareAction = UIAlertAction(title: "More sharing options", style: .default) { (action) in
            self.exportTap()
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
        
        alertController.addAction(audioShareAction)
        alertController.addAction(emailAction)
        alertController.addAction(shareAction)
        alertController.addAction(cancelAction)
        
        self.present(alertController, animated: true)

    }
    
    @IBAction func audioFormatSelectorAction(_ sender: Any) {
        switch audioFormatSelectorSegmentedControl.selectedSegmentIndex
        {
        case 0:
            conductor.audioFormat = .m4a
        case 1:
            conductor.audioFormat = .mp4
        case 2:
            conductor.audioFormat = .caf
        case 3:
            conductor.audioFormat = .aif
        case 4:
            conductor.audioFormat = .wav
        default:
            conductor.audioFormat = .m4a
        }
    }
    
    func exportToEmail() {
        let configuredMailComposeViewController = emailComposer.configuredMailComposeViewController()
        if emailComposer.canSendMail() {
            present(configuredMailComposeViewController, animated: true, completion: nil)
        } else {
            showSendMailErrorAlert()
        }
    }
    
    func showSendMailErrorAlert() {
        let sendMailErrorAlert = UIAlertController(title: "Could Not Send Email", message: "You device could not send email. Please check email configuration and try again.", preferredStyle: .actionSheet)
        
        let cancelAction = UIAlertAction(title: "Cancel", style: UIAlertActionStyle.cancel) { (result : UIAlertAction) -> Void in
            print("Cancel")
        }
        let okAction = UIAlertAction(title: "OK", style: UIAlertActionStyle.default) { (result : UIAlertAction) -> Void in
            print("OK")
        }
        sendMailErrorAlert.addAction(cancelAction)
        sendMailErrorAlert.addAction(okAction)
        self.present(sendMailErrorAlert, animated: true, completion: nil)
    }
    
    // MARK: === Share Activity Controller (More Options) ===
    
    func exportTap() {
        // Show the share controller
        if let audioURL: URL = conductor.exportedAudio {
            let shareText = "Listen to \(conductor.exportedAudioFileName)"
            let controller = UIActivityViewController(activityItems: [shareText, audioURL], applicationActivities: nil)
            // Set the email's subject name to the exported audio file name.
            controller.setValue(self.conductor.exportedAudioFileName, forKey: "subject")
            controller.completionWithItemsHandler = { activity, success, items, error in
                self.dismiss(animated: true, completion: nil)
            }
            if UIDevice.current.userInterfaceIdiom == UIUserInterfaceIdiom.pad {
                controller.popoverPresentationController?.sourceView = self.exportBtn
                controller.modalPresentationStyle = UIModalPresentationStyle.popover
            }
            DispatchQueue.main.async {
                self.present(controller, animated: true, completion: nil)
            }
        }
        
    }
    
}
