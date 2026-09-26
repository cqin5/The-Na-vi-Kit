//
//  KeyboardToolbar.swift
//  Na'vi Keyboard
//

import UIKit

/// The bar above the keys, laid out like the toolbars of third-party keyboards
/// such as WeChat's: the keyboard's settings on the left and a button that hides
/// the keyboard on the right.
///
/// The keyboard's owner adds the buttons' actions.
class KeyboardToolbar: ExtraView {

    let settingsButton = UIButton(type: .system)
    let dismissButton = UIButton(type: .system)

    override var darkMode: Bool {
        didSet {
            self.updateAppearance()
        }
    }

    required init(globalColors: GlobalColors.Type?, darkMode: Bool, solidColorMode: Bool) {
        super.init(globalColors: globalColors, darkMode: darkMode, solidColorMode: solidColorMode)

        // The keyboard glyph is wider than the gear, so it is drawn smaller to
        // carry the same visual weight.
        self.add(self.settingsButton, symbol: "gearshape", pointSize: 19, label: "Keyboard Settings")
        self.add(self.dismissButton, symbol: "keyboard.chevron.compact.down", pointSize: 17, label: "Hide Keyboard")

        // Each button is 44 points wide, which centres its symbol over the
        // middle of the first or last letter key.
        NSLayoutConstraint.activate([
            self.settingsButton.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 2),
            self.settingsButton.topAnchor.constraint(equalTo: self.topAnchor),
            self.settingsButton.bottomAnchor.constraint(equalTo: self.bottomAnchor),
            self.settingsButton.widthAnchor.constraint(equalToConstant: 44),

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

    private func add(_ button: UIButton, symbol: String, pointSize: CGFloat, label: String) {
        let configuration = UIImage.SymbolConfiguration(pointSize: pointSize, weight: .regular)
        button.setImage(UIImage(systemName: symbol, withConfiguration: configuration), for: .normal)
        button.accessibilityLabel = label
        button.translatesAutoresizingMaskIntoConstraints = false
        self.addSubview(button)
    }

    // Drawn in the keys' text colour, like the system's own globe and
    // microphone below the keyboard.
    func updateAppearance() {
        let colour = (self.globalColors ?? GlobalColors.self).text(self.darkMode)
        self.settingsButton.tintColor = colour
        self.dismissButton.tintColor = colour
    }
}
