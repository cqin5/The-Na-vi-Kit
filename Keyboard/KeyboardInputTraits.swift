//
//  KeyboardInputTraits.swift
//  RussianPhoneticKeyboard
//
//  Created by Alexei Baboulevitch on 11/1/14.
//  Copyright (c) 2014 Alexei Baboulevitch ("Archagon"). All rights reserved.
//

import Foundation
import QuartzCore
import UIKit

//        optional var autocorrectionType: UITextAutocorrectionType { get set } // default is UITextAutocorrectionTypeDefault
//        @availability(iOS, introduced=5.0)
//        optional var spellCheckingType: UITextSpellCheckingType { get set } // default is UITextSpellCheckingTypeDefault;
//        optional var keyboardType: UIKeyboardType { get set } // default is UIKeyboardTypeDefault
//        optional var returnKeyType: UIReturnKeyType { get set } // default is UIReturnKeyDefault (See note under UIReturnKeyType enum)
//        optional var enablesReturnKeyAutomatically: Bool { get set } // default is NO (when YES, will automatically disable return key when text widget has zero-length contents, and will automatically enable when text widget has non-zero-length contents)

var traitPollingTimer: CADisplayLink?

// Weak proxy so the CADisplayLink does NOT retain the keyboard view controller.
// A strong target kept the whole keyboard alive after dismissal (a leak), and the
// link kept firing pollTraits every frame forever.
final class DisplayLinkProxy: NSObject {
    weak var target: KeyboardViewController?
    init(target: KeyboardViewController) {
        self.target = target
        super.init()
    }
    @objc func tick() {
        target?.pollTraits()
    }
}

extension KeyboardViewController {

    func addInputTraitsObservers() {
        // note that KVO doesn't work on textDocumentProxy, so we have to poll
        traitPollingTimer?.invalidate()
        let link = CADisplayLink(target: DisplayLinkProxy(target: self), selector: #selector(DisplayLinkProxy.tick))
        link.add(to: RunLoop.current, forMode: RunLoop.Mode.default)
        traitPollingTimer = link
    }
    
    @objc func pollTraits() {
        let proxy = self.textDocumentProxy
        
        if let layout = self.layout {
            let appearanceIsDark = (proxy.keyboardAppearance == UIKeyboardAppearance.dark)
            if appearanceIsDark != layout.darkMode {
                self.updateAppearances(appearanceIsDark)
            }
        }
    }
}
