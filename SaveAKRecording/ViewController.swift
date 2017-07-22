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
    @IBOutlet weak var deleteAllRecordingsButton: UIButton!
    @IBOutlet weak var snareButton: UIButton!
    @IBOutlet weak var recordToggleButton: UIButton!
    @IBOutlet weak var playStopToggleButton: UIButton!
    @IBOutlet weak var exportBtn: UIButton!
    @IBOutlet weak var showRecordingsBtn: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        initializeUI()
        
        conductor.setExportedAudioPath()
        if (conductor.recordingsFound) {
            exportBtn.isEnabled = true
            deleteAllRecordingsButton.isEnabled = true
            showRecordingsBtn.isEnabled = true
        } else {
            exportBtn.isEnabled = false
            deleteAllRecordingsButton.isEnabled = false
            showRecordingsBtn.isEnabled = false
        }
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
//        exportBtn.isEnabled = false
//        playStopToggleButton.isEnabled = false
    }
    
    private func playButtonFormatting() {
        playStopToggleButton.setTitle("▶︎ Play", for: .normal)
        playStopToggleButton.setTitleColor(.playColor, for: .normal)
        playStopToggleButton.layer.backgroundColor = UIColor.clear.cgColor
        playStopToggleButton.layer.borderColor = UIColor.playColor.cgColor
        playStopToggleButton.isEnabled = true
    }
    
    // MARK: === Export via Email ===
    
    private func exportToEmail() {
        let configuredMailComposeViewController = emailComposer.configuredMailComposeViewController()
        if emailComposer.canSendMail() {
            present(configuredMailComposeViewController, animated: true, completion: nil)
        } else {
            showSendMailErrorAlert()
        }
    }
    
    private func showSendMailErrorAlert() {
        let sendMailErrorAlert = UIAlertController(title: "Could Not Send Email", message: "Your device could not send email. Please check email configuration and try again.", preferredStyle: .actionSheet)
        
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
    
    private func deleteAudioFiles() {
        conductor.deleteAllFiles()
        playStopToggleButton.isEnabled = false
        playStopToggleButton.setTitleColor(.lightGray, for: .normal)
        playStopToggleButton.layer.borderColor = UIColor.lightGray.cgColor
        playStopToggleButton.layer.backgroundColor = UIColor.clear.cgColor
        exportBtn.isEnabled = false
        deleteAllRecordingsButton.isEnabled = false
        showRecordingsBtn.isEnabled = false
    }
    
    // MARK: === Share Activity Controller (More Options) ===
    
    private func exportTap() {
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
    
    //MARK: === IBActions ===
    
    @IBAction func recordToggleAction(_ sender: UIButton) {
        conductor.recordToggle()
        print("conductor.playingState: \(conductor.playingState)")
        switch(conductor.recordingState) {
        case .readyToRecord:
            recordToggleButton.setTitle("◉ Record", for: .normal)
            recordToggleButton.setTitleColor(.recordColor, for: .normal)
            recordToggleButton.layer.borderColor = UIColor.recordColor.cgColor
            recordToggleButton.layer.backgroundColor = UIColor.clear.cgColor
            playButtonFormatting()
            exportBtn.isEnabled = true
            deleteAllRecordingsButton.isEnabled = true
            showRecordingsBtn.isEnabled = true
        case .recording:
            recordToggleButton.setTitle("◼︎ Stop", for: .normal)
            recordToggleButton.setTitleColor(.white, for: .normal)
            recordToggleButton.layer.backgroundColor = UIColor.recordColor.cgColor
            playStopToggleButton.isEnabled = false
            playStopToggleButton.setTitleColor(.lightGray, for: .normal)
            playStopToggleButton.layer.borderColor = UIColor.lightGray.cgColor
            playStopToggleButton.layer.backgroundColor = UIColor.clear.cgColor
        }
    }
    
    @IBAction func playStopToggleAction(_ sender: Any) {
        conductor.playStopToggle()
        switch(conductor.playingState) {
        case .playing:
            playStopToggleButton.setTitle("◼︎ Stop", for: .normal)
            playStopToggleButton.setTitleColor(.white, for: .normal)
            playStopToggleButton.layer.backgroundColor = UIColor.playColor.cgColor
            recordToggleButton.isEnabled = false
            recordToggleButton.setTitleColor(.lightGray, for: .normal)
            recordToggleButton.layer.borderColor = UIColor.lightGray.cgColor
            recordToggleButton.layer.backgroundColor = UIColor.clear.cgColor
        case .readyToPlay:
            recordToggleButton.setTitleColor(.recordColor, for: .normal)
            recordToggleButton.layer.borderColor = UIColor.recordColor.cgColor
            recordToggleButton.layer.backgroundColor = UIColor.clear.cgColor
            playButtonFormatting()
            recordToggleButton.isEnabled = true
        case .disabled:
            playStopToggleButton.isEnabled = false
        }
    }
    
    @IBAction func deleteAllRecordingsAction(_ sender: Any) {
        
        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)

        // Select destructive style when deleting or changing data.
        let deleteAction = UIAlertAction(title: "Delete All Recordings", style: .destructive) { (action) in
            self.deleteAudioFiles()
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)

        alertController.addAction(deleteAction)
        alertController.addAction(cancelAction)
        
        self.present(alertController, animated: true)
    }
    
    @IBAction func triggerKick() {
        conductor.playKick()
    }
    
    @IBAction func triggerSnare() {
        conductor.playSnare()
    }
    
    @IBAction func sendEmailButtonTapped(_ sender: AnyObject) {

        let alertController = UIAlertController(title: self.conductor.exportedAudioFile, message: nil, preferredStyle: .actionSheet)
        
        // AudioShare SDK
        let audioShareAction = UIAlertAction(title: "AudioShare", style: .default) { (action) in
            self.conductor.exportToAudioShare()
        }
        // Email
        let emailAction = UIAlertAction(title: "Email", style: .default) { (action) in
            self.exportToEmail()
        }
        // Share
        let shareAction = UIAlertAction(title: "More", style: .default) { (action) in
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
    
}
