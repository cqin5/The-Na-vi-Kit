//
//  KeyboardHaptics.swift
//  Na'vi Keyboard
//

import UIKit

/// The keys' haptic feedback, as the system keyboard plays it with its own Haptic
/// Feedback setting on: a tap as each key goes down, at the strength chosen in the
/// app, and a lighter tick for each character a held Delete key removes.
///
/// iOS plays a keyboard extension's haptics only while the keyboard has Full
/// Access, so the keyboard's owner asks for them only then.
class KeyboardHaptics {

    private let lightTap: UIImpactFeedbackGenerator
    private let mediumTap: UIImpactFeedbackGenerator
    private let tick: UISelectionFeedbackGenerator

    /// - Parameter view: the keyboard's view, which the generators attach to.
    init(view: UIView) {
        self.lightTap = UIImpactFeedbackGenerator(style: .light, view: view)
        self.mediumTap = UIImpactFeedbackGenerator(style: .medium, view: view)
        self.tick = UISelectionFeedbackGenerator(view: view)
    }

    private func tap(for strength: HapticStrength) -> UIImpactFeedbackGenerator {
        return strength.usesMediumWeight ? self.mediumTap : self.lightTap
    }

    /// Readies the Taptic Engine, which is otherwise slow to play the first tap.
    /// It stays ready for a few seconds.
    func prepare(strength: HapticStrength) {
        self.tap(for: strength).prepare()
    }

    /// A key went down.
    func keyDown(strength: HapticStrength) {
        let tap = self.tap(for: strength)
        tap.impactOccurred(intensity: CGFloat(strength.intensity))
        // Typing is quick, so the next key is likely soon.
        tap.prepare()
    }

    /// A held Delete key removed another character.
    func repeatStep() {
        self.tick.selectionChanged()
        self.tick.prepare()
    }
}
