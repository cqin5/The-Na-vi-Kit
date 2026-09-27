//
//  KeyboardSettings.swift
//  Na'vi Keyboard
//
//  Compiled into the app as well as the keyboard: the app's Settings tab
//  changes these settings, and the keyboard reads them.
//

import Foundation

/// The keyboard's settings, kept in the App Group that the app and the keyboard
/// share. A keyboard without Full Access may read the group but not write to it,
/// which is all the keyboard does, so the settings apply either way. A value the
/// group does not hold reads as the default registered here.
struct KeyboardSettings {

    /// The App Group that both targets' entitlements declare.
    static let appGroup = "group.live.moquan.eywa"

    static let autoCapitalizationKey = "kAutoCapitalization"
    static let periodShortcutKey = "kPeriodShortcut"
    static let keyboardClicksKey = "kKeyboardClicks"
    static let hapticsKey = "kKeyboardHaptics"
    static let hapticStrengthKey = "kHapticStrength"

    static let defaultAutoCapitalization = true
    static let defaultPeriodShortcut = true
    static let defaultKeyboardClicks = false
    // Haptics play only once the keyboard has Full Access, which is off until
    // the user turns it on.
    static let defaultHaptics = true
    static let defaultHapticStrength = HapticStrength.medium

    /// The shared App Group's settings. Outside an app that declares the group,
    /// as in tests, this is a separate, empty store.
    static var sharedStore: UserDefaults {
        return UserDefaults(suiteName: appGroup) ?? .standard
    }

    let store: UserDefaults

    /// - Parameter store: where the settings live; the shared App Group unless
    ///   tests pass their own.
    init(store: UserDefaults = KeyboardSettings.sharedStore) {
        self.store = store
        store.register(defaults: [
            KeyboardSettings.autoCapitalizationKey: KeyboardSettings.defaultAutoCapitalization,
            KeyboardSettings.periodShortcutKey: KeyboardSettings.defaultPeriodShortcut,
            KeyboardSettings.keyboardClicksKey: KeyboardSettings.defaultKeyboardClicks,
            KeyboardSettings.hapticsKey: KeyboardSettings.defaultHaptics,
            KeyboardSettings.hapticStrengthKey: KeyboardSettings.defaultHapticStrength.rawValue
        ])
    }

    var autoCapitalization: Bool {
        return self.store.bool(forKey: KeyboardSettings.autoCapitalizationKey)
    }

    var periodShortcut: Bool {
        return self.store.bool(forKey: KeyboardSettings.periodShortcutKey)
    }

    var keyboardClicks: Bool {
        return self.store.bool(forKey: KeyboardSettings.keyboardClicksKey)
    }

    var haptics: Bool {
        return self.store.bool(forKey: KeyboardSettings.hapticsKey)
    }

    /// A value this version does not know, such as one a later version wrote,
    /// reads as the default.
    var hapticStrength: HapticStrength {
        return self.store.string(forKey: KeyboardSettings.hapticStrengthKey).flatMap(HapticStrength.init(rawValue:))
            ?? KeyboardSettings.defaultHapticStrength
    }
}

/// How firmly a key taps. The app plays the same tap as a sample when the
/// strength is chosen, so both sides take the weight and intensity from here.
enum HapticStrength: String, CaseIterable, Sendable {
    case light
    case medium
    case strong

    /// Whether the tap uses the medium impact rather than the light one.
    var usesMediumWeight: Bool {
        return self == .strong
    }

    /// The tap's intensity, from 0 to 1.
    var intensity: Double {
        return self == .light ? 0.5 : 1.0
    }
}
