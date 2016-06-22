//
//  KeyboardViewController.swift
//  Na'vi Keyboard
//
//  Created by Chuhan Qin on 2016-06-22.
//  Copyright © 2016 CQ. All rights reserved.
//

import UIKit

class KeyboardViewController: UIInputViewController {
    
    @IBOutlet var keyboardView:KeyboardView!
    
    let lettersRow1 = ["ä","w","e","r","t","tx","u","i","o","p"]
    let lettersRow2 = ["a","s","px","f","'","h","ì","k","l"]
    let lettersRow3 = ["ts","y","kx","v","ng","n","m"]
        
    override func updateViewConstraints() {
        super.updateViewConstraints()
        
        // Add custom view sizing constraints here
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        loadInterface()
    }
    
    func loadInterface() {
        // load the nib file
        let keyboardNib = UINib(nibName: "Keyboard", bundle: nil)
        // instantiate the view
        keyboardView = keyboardNib.instantiateWithOwner(self, options: nil)[0] as! KeyboardView
        
        // add the interface to the main view
        view.addSubview(keyboardView)
        
        for letterButton in keyboardView.letterButtons {
            letterButton.addTarget(self, action: Selector("keyPressed:"), forControlEvents: .TouchUpInside)
        }
        
        // copy the background color
//        view.backgroundColor = keyboardView.backgroundColor
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated
    }
    
    func keyPressed(key key: UIButton?) {
        let title = key!.titleForState(.Normal)
        (textDocumentProxy as UIKeyInput).insertText(title!)
    }
    
    override func textWillChange(textInput: UITextInput?) {
        // The app is about to change the document's contents. Perform any preparation here.
    }
    
    override func textDidChange(textInput: UITextInput?) {
        // The app has just changed the document's contents, the document context has been updated.
        
//        var textColor: UIColor
//        let proxy = self.textDocumentProxy
//        if proxy.keyboardAppearance == UIKeyboardAppearance.Dark {
//            textColor = UIColor.whiteColor()
//        } else {
//            textColor = UIColor.blackColor()
//        }
//        self.nextKeyboardButton.setTitleColor(textColor, forState: .Normal)
    }
    
}
