//
//  test_keyboard_haptics.swift
//
//  Checks when the keyboard plays haptics, and that it reads the settings the
//  app saves. Keys are pressed as a finger presses them: ForwardingView turns
//  each touch into control events for the key under it, and these checks send
//  the same events through it. Run it with Scripts/test_keyboard_haptics.sh,
//  which compiles it together with the keyboard's sources for Mac Catalyst, so no
//  simulator is needed.
//

import ObjectiveC
import SwiftUI
import UIKit

extension UIControl {

    /// Stands in for `sendAction(_:to:for:)`, which hands each action to
    /// `UIApplication.shared`. A process without an app has none, so every action
    /// would go nowhere. This delivers it to its target as UIApplication does,
    /// with the control and the event as arguments.
    @objc func deliverWithoutApplication(_ action: Selector, to target: Any?, for event: UIEvent?) {
        _ = (target as? NSObject)?.perform(action, with: self, with: event)
    }

    static func deliverActionsWithoutApplication() {
        guard let original = class_getInstanceMethod(UIControl.self, #selector(UIControl.sendAction(_:to:for:))),
              let replacement = class_getInstanceMethod(UIControl.self, #selector(UIControl.deliverWithoutApplication(_:to:for:))) else {
            fatalError("UIControl.sendAction(_:to:for:) not found")
        }
        method_exchangeImplementations(original, replacement)
    }
}

/// Counts the haptics the keyboard asks for instead of playing them.
final class RecordingHaptics: KeyboardHaptics {

    var strengths: [HapticStrength] = []
    var ticks = 0
    var prepares = 0

    var taps: Int {
        return self.strengths.count
    }

    override func prepare(strength: HapticStrength) {
        self.prepares += 1
    }

    override func keyDown(strength: HapticStrength) {
        self.strengths.append(strength)
    }

    override func repeatStep() {
        self.ticks += 1
    }
}

/// A keyboard whose Full Access the checks decide. Outside a keyboard extension,
/// UIKit reports Full Access.
final class TestKeyboardViewController: KeyboardViewController {

    var fullAccess = true

    override var hasFullAccess: Bool {
        return self.fullAccess
    }
}

@main
@MainActor
struct KeyboardHapticsTests {

    static var failures = 0
    static var checks = 0

    /// The settings the checks change. Scripts/test_keyboard_haptics.sh names each
    /// run's process, and so this store, uniquely, and deletes it afterwards.
    static let store = UserDefaults.standard

    static let settingKeys = [
        KeyboardSettings.autoCapitalizationKey,
        KeyboardSettings.periodShortcutKey,
        KeyboardSettings.keyboardClicksKey,
        KeyboardSettings.hapticsKey,
        KeyboardSettings.hapticStrengthKey
    ]

    static func check(_ condition: Bool, _ message: @autoclosure () -> String) {
        checks += 1
        if !condition {
            failures += 1
            print("  FAIL: \(message())")
        }
    }

    /// Settings as a fresh install has them: nothing stored.
    static func clearSettings() {
        for key in settingKeys {
            store.removeObject(forKey: key)
        }
    }

    /// A keyboard on a 402-point iPhone that has just appeared, reading fresh-install
    /// settings from the checks' store, with its haptics counted from the start.
    static func makeKeyboard(fullAccess: Bool = true, width: CGFloat = 402) -> (TestKeyboardViewController, RecordingHaptics) {
        clearSettings()
        let controller = TestKeyboardViewController(nibName: nil, bundle: nil)
        controller.fullAccess = fullAccess
        controller.settings = KeyboardSettings(store: store)
        let haptics = RecordingHaptics(view: controller.view)
        controller.haptics = haptics
        controller.view.frame = CGRect(x: 0, y: 0, width: width, height: 258)
        controller.viewWillAppear(false)
        controller.view.layoutIfNeeded()
        controller.viewDidLayoutSubviews()
        return (controller, haptics)
    }

    /// Shows a page and returns the view of one of its keys. Typing a character
    /// returns the keyboard to the letters, so callers ask again for each key.
    static func view(for key: Key, onPage page: Int, of controller: KeyboardViewController) -> KeyboardKey? {
        controller.currentMode = page
        guard let keyView = controller.layout?.viewForKey(key), !keyView.isHidden else {
            return nil
        }
        return keyView
    }

    static func letter(_ letter: String, of controller: KeyboardViewController) -> KeyboardKey? {
        let key = controller.keyboard.pages[0].rows.joined().first { $0.lowercaseOutput == letter }
        return key.flatMap { view(for: $0, onPage: 0, of: controller) }
    }

    static func delete(of controller: KeyboardViewController) -> KeyboardKey? {
        let key = controller.keyboard.pages[0].rows.joined().first { $0.type == .backspace }
        return key.flatMap { view(for: $0, onPage: 0, of: controller) }
    }

    static func send(_ event: UIControl.Event, to keyView: KeyboardKey, in controller: KeyboardViewController) {
        controller.forwardingView.handleControl(keyView, controlEvent: event)
    }

    /// A finger that goes down on a key and lifts without leaving it.
    static func press(_ keyView: KeyboardKey, in controller: KeyboardViewController) {
        send(.touchDown, to: keyView, in: controller)
        send(.touchUpInside, to: keyView, in: controller)
    }

    /// Lets timers fire, such as the one that repeats a held Delete key.
    static func wait(_ seconds: TimeInterval) {
        RunLoop.current.run(until: Date(timeIntervalSinceNow: seconds))
    }

    static func main() {
        UIControl.deliverActionsWithoutApplication()

        checkEveryKey()
        checkTouches()
        checkHeldDelete()
        checkToolbar()
        checkSetting()
        checkStrength()
        checkWithoutFullAccess()
        checkRelayout()
        checkSettingsContract()

        print("\(checks - failures) of \(checks) checks passed")
        exit(failures == 0 ? 0 : 1)
    }

    // MARK: - Checks

    /// Every key on every page taps once as it goes down, and not again as it
    /// comes up.
    static func checkEveryKey() {
        let (controller, haptics) = makeKeyboard()

        check(controller.settings.haptics, "haptic feedback is off on a fresh install")
        check(haptics.prepares == 1, "appearing readied the Taptic Engine \(haptics.prepares) times, expected once")

        var pressed = 0
        for (page, keys) in controller.keyboard.pages.enumerated() {
            for key in keys.rows.joined() {
                guard let keyView = view(for: key, onPage: page, of: controller) else {
                    check(false, "page \(page): no view for a \(key.type) key")
                    continue
                }
                let label = "page \(page) \(key.type) key '\(keyView.text)'"
                let taps = haptics.taps

                send(.touchDown, to: keyView, in: controller)
                check(haptics.taps == taps + 1, "\(label): \(haptics.taps - taps) taps as it went down, expected 1")

                // A page change forgets the touch that caused it, and the globe
                // key would switch to another keyboard, so neither gets a touch up.
                if key.type != .modeChange && key.type != .keyboardChange {
                    send(.touchUpInside, to: keyView, in: controller)
                    check(haptics.taps == taps + 1, "\(label): tapped again as it came up")
                }
                pressed += 1
            }
        }

        check(pressed >= 90, "only \(pressed) keys pressed across the pages")
        check(haptics.taps == pressed, "\(haptics.taps) taps for \(pressed) keys")
        check(haptics.ticks == 0, "\(haptics.ticks) repeat ticks without a held Delete key")
        check(haptics.strengths.allSatisfy { $0 == .medium }, "a fresh install tapped at \(Set(haptics.strengths)), not medium")

        // Fast typing: every key taps, however quickly the next one comes.
        if let e = letter("e", of: controller) {
            let taps = haptics.taps
            for _ in 0..<200 {
                press(e, in: controller)
            }
            check(haptics.taps == taps + 200, "200 quick presses gave \(haptics.taps - taps) taps")
        } else {
            check(false, "no e key")
        }
    }

    /// Touches that slide, roll over or repeat still tap once for each finger
    /// that goes down.
    static func checkTouches() {
        let (controller, haptics) = makeKeyboard()
        guard let a = letter("a", of: controller), let s = letter("s", of: controller) else {
            check(false, "no a or s key")
            return
        }

        // A finger slides from a to s before lifting: s is typed, a tapped.
        var taps = haptics.taps
        send(.touchDown, to: a, in: controller)
        send(.touchDragExit, to: a, in: controller)
        send(.touchDragEnter, to: s, in: controller)
        send(.touchDragInside, to: s, in: controller)
        send(.touchUpInside, to: s, in: controller)
        check(haptics.taps == taps + 1, "sliding from a to s gave \(haptics.taps - taps) taps, expected 1")

        // Rollover: s goes down before a comes up.
        taps = haptics.taps
        send(.touchDown, to: a, in: controller)
        send(.touchDown, to: s, in: controller)
        send(.touchUpInside, to: a, in: controller)
        send(.touchUpInside, to: s, in: controller)
        check(haptics.taps == taps + 2, "two overlapping presses gave \(haptics.taps - taps) taps, expected 2")

        // A touch the system cancels, as when a gesture takes over.
        taps = haptics.taps
        send(.touchDown, to: a, in: controller)
        send(.touchCancel, to: a, in: controller)
        check(haptics.taps == taps + 1, "a cancelled touch gave \(haptics.taps - taps) taps, expected 1")

        // Shift double-tapped for Caps Lock: the second touch goes down with a
        // repeat event as well, which must not tap a second time.
        guard let shiftKey = controller.keyboard.pages[0].rows.joined().first(where: { $0.type == .shift }),
              let shift = view(for: shiftKey, onPage: 0, of: controller) else {
            check(false, "no Shift key")
            return
        }
        controller.shiftState = .disabled
        taps = haptics.taps
        press(shift, in: controller)
        send(.touchDown, to: shift, in: controller)
        send(.touchDownRepeat, to: shift, in: controller)
        send(.touchUpInside, to: shift, in: controller)
        check(controller.shiftState == .locked, "the double tap left Shift \(controller.shiftState), not locked")
        check(haptics.taps == taps + 2, "a double tap on Shift gave \(haptics.taps - taps) taps, expected 2")
    }

    /// Holding Delete taps once, then ticks for each character it removes, and
    /// stops as soon as the finger lifts or slides off.
    static func checkHeldDelete() {
        let (controller, haptics) = makeKeyboard()
        guard let delete = delete(of: controller) else {
            check(false, "no Delete key")
            return
        }

        // Repeats start 0.5 seconds after the key goes down, one every 0.07
        // seconds, so a one-second hold removes up to nine characters.
        send(.touchDown, to: delete, in: controller)
        check(haptics.taps == 1, "Delete going down gave \(haptics.taps) taps")
        wait(1.0)
        check(haptics.ticks >= 3 && haptics.ticks <= 9, "a one-second hold gave \(haptics.ticks) ticks, expected 3 to 9")
        check(haptics.taps == 1, "the repeats tapped as well as ticked")

        send(.touchUpInside, to: delete, in: controller)
        let ticks = haptics.ticks
        wait(0.3)
        check(haptics.ticks == ticks, "\(haptics.ticks - ticks) ticks after the finger lifted")
        check(!controller.backspaceActive, "Delete still repeating after the finger lifted")

        // The finger slides off Delete while it repeats.
        send(.touchDown, to: delete, in: controller)
        wait(0.7)
        send(.touchDragExit, to: delete, in: controller)
        let ticksWhenLeft = haptics.ticks
        wait(0.3)
        check(haptics.ticks > ticks, "the second hold did not tick")
        check(haptics.ticks == ticksWhenLeft, "\(haptics.ticks - ticksWhenLeft) ticks after the finger slid off")

        // A quick tap on Delete removes one character and never repeats.
        let before = (taps: haptics.taps, ticks: haptics.ticks)
        press(delete, in: controller)
        wait(0.7)
        check(haptics.taps == before.taps + 1 && haptics.ticks == before.ticks, "a quick tap on Delete gave \(haptics.taps - before.taps) taps and \(haptics.ticks - before.ticks) ticks")
    }

    /// The toolbar's button taps like a key, and the toolbar has no settings
    /// button, since the settings are in the app. It is tall enough to keep the
    /// button clear of the keyboard's rounded corners.
    static func checkToolbar() {
        let (controller, haptics) = makeKeyboard()
        guard let toolbar = controller.bannerView as? KeyboardToolbar else {
            check(false, "no toolbar")
            return
        }

        toolbar.dismissButton.sendActions(for: .touchDown)
        check(haptics.taps == 1, "the hide-keyboard button gave \(haptics.taps) taps")

        let buttons = toolbar.subviews.compactMap { $0 as? UIButton }
        check(buttons.count == 1, "the toolbar has \(buttons.count) buttons, expected only the hide-keyboard button")
        check(near(toolbar.frame.height, 44), "the toolbar is \(toolbar.frame.height) points tall in portrait, expected 44")
    }

    static func near(_ a: CGFloat, _ b: CGFloat) -> Bool {
        return abs(a - b) < 0.01
    }

    /// Turning haptics off in the app takes effect on the next key, without the
    /// keyboard reloading, and turning them on again does too.
    static func checkSetting() {
        let (controller, haptics) = makeKeyboard()
        guard let e = letter("e", of: controller), let delete = delete(of: controller) else {
            check(false, "no e or Delete key")
            return
        }

        store.set(false, forKey: KeyboardSettings.hapticsKey)
        press(e, in: controller)
        send(.touchDown, to: delete, in: controller)
        wait(0.8)
        send(.touchUpInside, to: delete, in: controller)
        (controller.bannerView as? KeyboardToolbar)?.dismissButton.sendActions(for: .touchDown)
        check(haptics.taps == 0 && haptics.ticks == 0, "with haptics off, \(haptics.taps) taps and \(haptics.ticks) ticks")

        let prepares = haptics.prepares
        controller.viewWillAppear(false)
        check(haptics.prepares == prepares, "appearing with haptics off readied the Taptic Engine")

        store.set(true, forKey: KeyboardSettings.hapticsKey)
        press(e, in: controller)
        check(haptics.taps == 1, "turning haptics back on gave \(haptics.taps) taps on the next key")
    }

    /// The strength chosen in the app reaches the next key; a value this version
    /// does not know reads as the default.
    static func checkStrength() {
        let (controller, haptics) = makeKeyboard()
        guard let e = letter("e", of: controller) else {
            check(false, "no e key")
            return
        }

        for strength in HapticStrength.allCases {
            store.set(strength.rawValue, forKey: KeyboardSettings.hapticStrengthKey)
            press(e, in: controller)
            check(haptics.strengths.last == strength, "stored \(strength), the key tapped at \(String(describing: haptics.strengths.last))")
        }

        for stored in ["ultra", "", "Strong", "light "] as [Any] + [3, true] {
            store.set(stored, forKey: KeyboardSettings.hapticStrengthKey)
            press(e, in: controller)
            check(haptics.strengths.last == .medium, "stored \(stored), the key tapped at \(String(describing: haptics.strengths.last)), not the default")
        }

        store.set("strong", forKey: KeyboardSettings.hapticStrengthKey)
        controller.viewWillAppear(false)
        check(haptics.prepares == 2, "appearing again readied the Taptic Engine \(haptics.prepares - 1) times")
    }

    /// Without Full Access nothing plays, whatever the setting.
    static func checkWithoutFullAccess() {
        let (controller, haptics) = makeKeyboard(fullAccess: false)
        check(controller.settings.haptics, "the setting is off")
        check(haptics.prepares == 0, "appearing without Full Access readied the Taptic Engine")

        for key in controller.keyboard.pages[0].rows.joined() where key.type != .modeChange && key.type != .keyboardChange {
            if let keyView = view(for: key, onPage: 0, of: controller) {
                press(keyView, in: controller)
            }
        }
        if let delete = delete(of: controller) {
            send(.touchDown, to: delete, in: controller)
            wait(0.8)
            send(.touchUpInside, to: delete, in: controller)
        }
        (controller.bannerView as? KeyboardToolbar)?.dismissButton.sendActions(for: .touchDown)
        check(haptics.taps == 0 && haptics.ticks == 0, "without Full Access, \(haptics.taps) taps and \(haptics.ticks) ticks")
    }

    /// Laying the keys out again, as rotation does, wires each key afresh
    /// rather than adding a second haptic to it.
    static func checkRelayout() {
        let (controller, haptics) = makeKeyboard()

        for width: CGFloat in [375, 874, 402] {
            controller.view.frame.size.width = width
            controller.viewDidLayoutSubviews()
        }
        controller.setupKeys()
        controller.setupKeys()

        guard let e = letter("e", of: controller) else {
            check(false, "no e key after laying out again")
            return
        }
        press(e, in: controller)
        check(haptics.taps == 1, "after laying out again, a key gave \(haptics.taps) taps")
    }

    /// The app saves settings with @AppStorage and the keyboard reads them with
    /// KeyboardSettings: each value the app can save reads back as that value, and
    /// a store that holds nothing, as when the App Group is missing from a build,
    /// gives the defaults.
    static func checkSettingsContract() {
        clearSettings()
        let fresh = KeyboardSettings(store: store)
        check(fresh.autoCapitalization == KeyboardSettings.defaultAutoCapitalization
              && fresh.periodShortcut == KeyboardSettings.defaultPeriodShortcut
              && fresh.keyboardClicks == KeyboardSettings.defaultKeyboardClicks
              && fresh.haptics == KeyboardSettings.defaultHaptics
              && fresh.hapticStrength == KeyboardSettings.defaultHapticStrength,
              "a fresh install does not read the defaults")

        let autoCapitalization = AppStorage(wrappedValue: KeyboardSettings.defaultAutoCapitalization, KeyboardSettings.autoCapitalizationKey, store: store)
        let periodShortcut = AppStorage(wrappedValue: KeyboardSettings.defaultPeriodShortcut, KeyboardSettings.periodShortcutKey, store: store)
        let keyboardClicks = AppStorage(wrappedValue: KeyboardSettings.defaultKeyboardClicks, KeyboardSettings.keyboardClicksKey, store: store)
        let haptics = AppStorage(wrappedValue: KeyboardSettings.defaultHaptics, KeyboardSettings.hapticsKey, store: store)
        let strength = AppStorage(wrappedValue: KeyboardSettings.defaultHapticStrength, KeyboardSettings.hapticStrengthKey, store: store)

        for value in [false, true] {
            autoCapitalization.wrappedValue = value
            periodShortcut.wrappedValue = !value
            keyboardClicks.wrappedValue = value
            haptics.wrappedValue = !value
            let read = KeyboardSettings(store: store)
            check(read.autoCapitalization == value && read.periodShortcut == !value && read.keyboardClicks == value && read.haptics == !value,
                  "the app saved \(value), \(!value), \(value), \(!value); the keyboard read \(read.autoCapitalization), \(read.periodShortcut), \(read.keyboardClicks), \(read.haptics)")
        }
        for value in HapticStrength.allCases {
            strength.wrappedValue = value
            check(KeyboardSettings(store: store).hapticStrength == value, "the app saved \(value), the keyboard read \(KeyboardSettings(store: store).hapticStrength)")
        }

        let empty = UserDefaults(suiteName: "never.written.\(UUID().uuidString)")!
        let fallback = KeyboardSettings(store: empty)
        check(fallback.autoCapitalization && fallback.periodShortcut && !fallback.keyboardClicks && fallback.haptics && fallback.hapticStrength == .medium,
              "a store holding nothing does not give the defaults")

        clearSettings()
    }
}
