//
//  RecordingsTableViewController.swift
//  SaveAKRecording
//
//  Created by Mark Jeschke on 7/21/17.
//  Copyright © 2017 Mark Jeschke. All rights reserved.
//

import UIKit

class RecordingsTableViewController: UITableViewController {
    
    var conductor = Conductor.sharedInstance

    @IBAction func dismissAction(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.tableFooterView = UIView(frame: .zero)
        conductor.setExportedAudioPath()
        
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return conductor.directoryContent.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        
        let fileName = conductor.directoryContent[indexPath.row]
        let fileToNumber = conductor.sizeForLocalFilePath(filePath: fileName)
        
        cell.selectionStyle = .none
        cell.textLabel?.text = "\(fileName) \(conductor.covertToFileString(with: fileToNumber))"

        return cell
    }

}
