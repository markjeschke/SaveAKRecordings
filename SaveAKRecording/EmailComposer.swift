//
//  EmailComposer.swift
//  SaveAKRecording
//
//  Created by Mark Jeschke on 6/17/17.
//  Copyright © 2017 Mark Jeschke. All rights reserved.
//

import Foundation
import MessageUI

class EmailComposer: NSObject, MFMailComposeViewControllerDelegate {
    
    var conductor = Conductor.sharedInstance
    
    // Did this in order to mitigate needing to import MessageUI in my View Controller
    func canSendMail() -> Bool {
        return MFMailComposeViewController.canSendMail()
    }
    
    func configuredMailComposeViewController() -> MFMailComposeViewController {
        let mail = MFMailComposeViewController()
        mail.mailComposeDelegate = self
        
        let emailSubject = "\(self.conductor.exportedAudioFileName)"
        //let emailRecipients = "your-email@some-address.com"
        let emailMessageBody = "<p>Check out my recording made with <a href=\'http://audiokit.io/'>AudioKit!</a><br /><br />\(String(describing: self.conductor.audioFileDuration))"
        
        mail.setSubject(emailSubject)
        //mail.setToRecipients([emailRecipients])
        mail.setMessageBody(emailMessageBody, isHTML: true)
        
        let filePath = "\(String(describing: conductor.exportedAudioFilePath))/\(conductor.exportedAudioFile)"
        print("filePath: \(filePath)")
        print("filePath: \(self.conductor.exportedAudioFile)")
        if let emailAudio = conductor.exportedAudio {
            if let fileData = try? Data(contentsOf: emailAudio) {
                mail.addAttachmentData(fileData, mimeType: "audio/m4a", fileName: "\(self.conductor.exportedAudioFile)")
            }
        }
        
        return mail
    }
    
    // MARK: MFMailComposeViewControllerDelegate Method
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        controller.dismiss(animated: true, completion: nil)
    }
    
}
