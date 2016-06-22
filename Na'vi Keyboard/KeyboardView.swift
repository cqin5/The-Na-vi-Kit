//
//  KeyboardView.swift
//  Na'vi
//
//  Created by Chuhan Qin on 2016-06-22.
//  Copyright © 2016 CQ. All rights reserved.
//

import UIKit

class KeyboardView: UIView {

    @IBOutlet var letterButtons: [UIButton]!
    @IBOutlet var shiftButton: UIButton!
    @IBOutlet var numberButton: UIButton!
    @IBOutlet var nextKeyboardButton: UIButton!
    @IBOutlet var spaceButton: UIButton!
    @IBOutlet var returnButton: UIButton!
    @IBOutlet var backspaceButton: UIButton!
    
    var shiftKeyPressed : Bool = false
    
    override func awakeFromNib() {
        super.awakeFromNib()
        nextKeyboardButton.addTarget(self, action: #selector(UIInputViewController.advanceToNextInputMode), forControlEvents: .TouchUpInside)
    }
    
    @IBAction func shiftKeypressed(key key: UIButton?) {
        switch shiftKeyPressed {
        case true:
            for key in self.letterButtons {
                let keyTitle = key.titleForState(.Normal)!.capitalizedFirstLetter
                key.setTitle(keyTitle, forState: .Normal)
            }
        case false:
            for key in self.letterButtons {
                let keyTitle = key.titleForState(.Normal)!.lowercaseString
                key.setTitle(keyTitle, forState: .Normal)
            }
        }
        
    }

}
