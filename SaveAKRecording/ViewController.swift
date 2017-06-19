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

    var mainCGColor: CGColor = UIColor(red:10/255, green:96/255, blue:255/255, alpha:1.0).cgColor
    var mainColor: UIColor = UIColor(red:10/255, green:96/255, blue:255/255, alpha:1.0)
    
    @IBOutlet weak var kickButton: UIButton!
    @IBOutlet weak var snareButton: UIButton!
    @IBOutlet weak var recordPlayToggleButton: UIButton!
    @IBOutlet weak var exportBtn: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.recordPlayToggleButton.setTitle("◉ Record", for: .normal)
        self.recordPlayToggleButton.setTitleColor(.recordColor, for: .normal)
        self.recordPlayToggleButton.layer.cornerRadius = 5.0
        self.recordPlayToggleButton.layer.borderWidth = 0.5
        self.recordPlayToggleButton.layer.borderColor = UIColor.recordColor.cgColor
        
    }
    
    //MARK: IBActions
    @IBAction func recordPlayToggleAction(_ sender: UIButton) {
        conductor.recordPlayToggle()
        switch(conductor.state) {
        case .readyToRecord:
            recordPlayToggleButton.setTitle("◉ Record", for: .normal)
            recordPlayToggleButton.setTitleColor(.recordColor, for: .normal)
            recordPlayToggleButton.layer.borderColor = UIColor.recordColor.cgColor
        case .recording:
            recordPlayToggleButton.setTitle("◼︎ Stop", for: .normal)
            self.recordPlayToggleButton.setTitleColor(.white, for: .normal)
            self.recordPlayToggleButton.layer.backgroundColor = UIColor.recordColor.cgColor
        case .playing:
            recordPlayToggleButton.setTitle("◼︎ Stop", for: .normal)
            self.recordPlayToggleButton.setTitleColor(.white, for: .normal)
            self.recordPlayToggleButton.layer.backgroundColor = UIColor.playColor.cgColor
        case .readyToPlay:
            recordPlayToggleButton.setTitle("▶︎ Play", for: .normal)
            self.recordPlayToggleButton.setTitleColor(.playColor, for: .normal)
            self.recordPlayToggleButton.layer.backgroundColor = UIColor.clear.cgColor
            recordPlayToggleButton.layer.borderColor = UIColor.playColor.cgColor
        }
    }
    
    @IBAction func triggerKick() {
        conductor.playKick()
        self.change(color: .darkGray)
    }
    
    @IBAction func triggerSnare() {
        conductor.playSnare()
        self.change(color: .darkGray)
    }
    
    @IBAction func sendEmailButtonTapped(_ sender: AnyObject) {

        let alertController = UIAlertController(title: "Export Audio Recording", message: "\"\(self.conductor.exportedAudioFile)\"", preferredStyle: .alert)
        
        // AudioShare
        let audioShareAction = UIAlertAction(title: "AudioShare", style: .default) { (action) in
            self.conductor.exportToAudioShare()
        }
        // Email
        let emailAction = UIAlertAction(title: "Email", style: .default) { (action) in
            self.exportToEmail()
        }
        // Share
        let shareAction = UIAlertAction(title: "More options", style: .default) { (action) in
            self.exportTap()
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .default)
        
        alertController.addAction(audioShareAction)
        alertController.addAction(emailAction)
        alertController.addAction(shareAction)
        alertController.addAction(cancelAction)
        
        self.present(alertController, animated: true)

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
    
    //MARK: Animate background view color
    func change(color : UIColor) {
        self.view.backgroundColor = color
        UIView.animate(withDuration: 0.5) {
            self.view.backgroundColor = .white
        }
    }
    
}
