//
//  KeyboardToolbar.swift
//  Na'vi Keyboard
//

import UIKit

/// The bar above the keys, with a button on the right that hides the keyboard,
/// as on the toolbars of third-party keyboards such as WeChat's. The keyboard's
/// settings are in the app. The bar also gives the top row's key popups room to
/// grow into.
///
/// The keyboard's owner adds the button's actions.
class KeyboardToolbar: ExtraView {

    let dismissButton = UIButton(type: .system)

    override var darkMode: Bool {
        didSet {
            self.updateAppearance()
        }
    }

    required init(globalColors: GlobalColors.Type?, darkMode: Bool, solidColorMode: Bool) {
        super.init(globalColors: globalColors, darkMode: darkMode, solidColorMode: solidColorMode)

        let configuration = UIImage.SymbolConfiguration(pointSize: 17, weight: .regular)
        self.dismissButton.setImage(UIImage(systemName: "keyboard.chevron.compact.down", withConfiguration: configuration), for: .normal)
        self.dismissButton.accessibilityLabel = "Hide Keyboard"
        self.dismissButton.translatesAutoresizingMaskIntoConstraints = false
        self.addSubview(self.dismissButton)

        // The button is 44 points wide, which centres its symbol over the middle
        // of the last letter key.
        NSLayoutConstraint.activate([
            self.dismissButton.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -2),
            self.dismissButton.topAnchor.constraint(equalTo: self.topAnchor),
            self.dismissButton.bottomAnchor.constraint(equalTo: self.bottomAnchor),
            self.dismissButton.widthAnchor.constraint(equalToConstant: 44)
        ])

        self.updateAppearance()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("NSCoding not supported")
    }

    // Drawn in the keys' text colour, like the system's own globe and
    // microphone below the keyboard.
    func updateAppearance() {
        self.dismissButton.tintColor = (self.globalColors ?? GlobalColors.self).text(self.darkMode)
    }
}
