//
//  KeyboardInputTraits.swift
//  RussianPhoneticKeyboard
//
//  Created by Alexei Baboulevitch on 11/1/14.
//  Copyright (c) 2014 Alexei Baboulevitch ("Archagon"). All rights reserved.
//

import UIKit

extension KeyboardViewController {

    /// Keeps the key colours in step with the appearance around the keyboard.
    ///
    /// Three things can change it: the system switching between light and dark,
    /// Reduce Transparency being turned on or off, and focus moving to a field that
    /// asks for a dark keyboard. The first two are observed here; the third arrives
    /// through `textDidChange(_:)`, which calls `refreshAppearance()` directly.
    func addInputTraitsObservers() {
        self.registerForTraitChanges(
            [UITraitUserInterfaceStyle.self],
            action: #selector(KeyboardViewController.appearanceTraitsChanged)
        )

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(KeyboardViewController.reduceTransparencyChanged(_:)),
            name: UIAccessibility.reduceTransparencyStatusDidChangeNotification,
            object: nil
        )
    }

    @objc func appearanceTraitsChanged() {
        self.refreshAppearance()
    }

    @objc func reduceTransparencyChanged(_ notification: Notification) {
        self.refreshAppearance()
    }

    /// Re-applies the key colours if the effective appearance has changed.
    func refreshAppearance() {
        guard let layout = self.layout else {
            return
        }

        let appearanceIsDark = self.darkMode()
        if appearanceIsDark != layout.darkMode || self.solidColorMode() != layout.solidColorMode {
            self.updateAppearances(appearanceIsDark)
        }
    }
}
