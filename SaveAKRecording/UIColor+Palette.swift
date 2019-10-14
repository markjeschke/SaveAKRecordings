//
//  UIColor+Palette.swift
//  SaveAKRecording
//
//  Created by Mark Jeschke on 6/18/17.
//  Copyright © 2017 Mark Jeschke. All rights reserved.
//

import Foundation
import UIKit

public extension UIColor {
    class var recordColor: UIColor {
        return UIColor(red:200/255, green:0/255, blue:0/255, alpha:1.0)
    }
    class var playColor: UIColor {
        return UIColor(red:0/255, green:200/255, blue:0/255, alpha:1.0)
    }
    class var defaultColor: UIColor {
        return UIColor(red:10/255, green:96/255, blue:255/255, alpha:1.0)
    }
}
