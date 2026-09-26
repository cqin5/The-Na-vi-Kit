# The Na'vi Kit — Platform Modernization

This document records the work that brings **Eywa** (the Na'vi dictionary app) and
its **Na'vi Keyboard** extension up to the current Apple platform standard.

---

## 1. Platform baseline

| Item | Before | After |
| --- | --- | --- |
| Build SDK | iOS 18 era settings | iOS 26 / 27 SDK (Xcode 26 or later) |
| Deployment target | iOS 14.0 in the last App Store release | iOS 18.0 |
| Swift language mode | `5.9`, which is not a value Xcode accepts | `6.0` (app), `5.0` (keyboard) |
| App interface | Storyboards and UIKit view controllers | SwiftUI |
| App life cycle | `UIApplicationDelegate` only | SwiftUI `App`, which is scene-based |
| Launch screen | Storyboard | `UILaunchScreen` in `Info.plist` |
| Design language | Hand-built blur and gradient | System Liquid Glass |
| Dependency managers | CocoaPods + Swift Package Manager | None |

**Why iOS 18.** As of Apple's June 2026 App Store figures, iOS 18 or later runs on
about 93% of active iPhones, against 79% for iOS 26 alone. iOS 26 no longer supports
the iPhone XS and XR, and iOS 17 runs on exactly the same hardware as iOS 18, so a
lower floor would reach very few additional people. iOS 27, 26 and 18 are also the
three most recent major releases. The app uses two iOS 26 features — Liquid Glass
and SwiftUI's list section index — and both fall back cleanly on iOS 18 through 25.

People on iOS 14 to 17 keep the version they already have and can re-download the
last compatible version from their purchase history. The vocabulary and recordings
are bundled, so that version keeps working; it simply stops receiving updates.

---

## 2. App Store and SDK compliance

These items block submission or correct behaviour on current systems.

### 2.1 Scene-based app life cycle

An app built against the iOS 27 SDK without the scene life cycle does not launch.
The app's entry point is now a SwiftUI `App` (`Na'vi/EywaApp.swift`), which is
scene-based by design, so no application or scene delegate is needed. The scene
manifest in `Info.plist` declares only whether multiple windows are supported.

### 2.2 Privacy manifests

Both targets now ship `PrivacyInfo.xcprivacy`. Each declares no tracking and no
collected data. The keyboard additionally declares its use of `UserDefaults`
under the required-reason category `NSPrivacyAccessedAPICategoryUserDefaults`
(reason `CA92.1`, access to the app's own settings).

### 2.3 Property list corrections

| Key | Change | Reason |
| --- | --- | --- |
| `UIRequiredDeviceCapabilities` | `armv7` → `arm64` | iOS has been 64-bit only since iOS 11; the old value described a device class that no longer exists. |
| `CFBundleSignature` | Removed | A Carbon-era key with no meaning on iOS. |
| `UIRequiresFullScreen` | Removed | No longer honoured on iPadOS 26 and later; the app is now resizable on iPad. |
| `UIMainStoryboardFile` | Removed | The interface is SwiftUI. |
| `UILaunchStoryboardName` | Replaced by `UILaunchScreen` | The launch screen is now declared in `Info.plist`. It uses the system background, so it matches Dark Mode; the old storyboard was always white. |
| `CFBundleVersion` | `4` → `$(CURRENT_PROJECT_VERSION)` | Build numbers now come from the project rather than a hard-coded literal. |
| `ITSAppUsesNonExemptEncryption` | Added (`false`) | Removes the export-compliance prompt on every upload. |
| `UIViewControllerBasedStatusBarAppearance` | Added (`true`) | Replaces the obsolete global `UIStatusBarStyle` key, which the system already ignored. |

### 2.4 Version alignment

The keyboard extension declared marketing version `1.4.1` while the app declared
`1.5.2`. An extension must carry the same short version string as its host app,
so the extension now tracks `1.5.2`. Both bundles take their build number from
`CURRENT_PROJECT_VERSION`, set to `5`.

### 2.5 App Store icon

The 1024×1024 App Store icon was stored as RGBA. App Store Connect rejects a
marketing icon with an alpha channel (ITMS-90717). Every pixel was already fully
opaque, so the file was re-encoded as RGB with identical colour values; it is also
13% smaller.

---

## 3. SwiftUI interface

### 3.1 Screens

| Screen | Before | After |
| --- | --- | --- |
| Entry point | `AppDelegate`, `SceneDelegate` | `EywaApp.swift` |
| Dictionary | `Dictionary.storyboard`, `NDDictionaryMainViewController`, two prototype cells | `DictionaryView.swift`, `DictionaryEntryRow.swift` |
| Keyboard setup | `Main.storyboard`, `MainViewController` | `KeyboardSetupView.swift` |
| Launch screen | `LaunchScreen.storyboard` | `UILaunchScreen` in `Info.plist` |
| Entry detail | `NDDefinitionViewController` | Removed — row selection had been disabled, so the screen was unreachable, and each row already shows the full entry |

The app target no longer contains a storyboard or nib, and compiles seven Swift
files where it compiled thirteen.

### 3.2 Behaviour

- **Search.** `.searchable` provides the search field. On iPhone with iOS 26 the
  system places it at the bottom of the screen in Liquid Glass — where the app
  already kept it — and keeps it above the keyboard. On iOS 18 to 25 it sits in
  the navigation bar, as is standard on those releases. The keyboard-tracking code
  the UIKit version needed is gone. An empty search shows the system's
  "No Results" view.
- **Letter index.** On iOS 26, the list uses SwiftUI's native section index. SwiftUI
  has no section index before iOS 26, so on iOS 18 to 25 a compact index of its own
  keeps A–Z navigation, which the UIKit version offered on every release.
- **Loading.** The 890 KB vocabulary is decoded on a background task instead of on
  the main thread while the first screen initialises. Entries are now value types,
  which is what lets them cross from that task to the interface under Swift 6's
  data-race checking.
- **Text and colour.** Every screen uses text styles and semantic colours, so
  Dynamic Type, Bold Text, Dark Mode and Increase Contrast apply throughout. The
  setup screen now scrolls, so its instructions can grow with larger text.
- **Setup screen appearance.** It follows the system appearance instead of a fixed
  dark background.
- **Icons.** The keyboard-setup and play-pronunciation buttons use SF Symbols,
  which scale with text and carry accessibility labels.
- **Contact.** "Contact Developer" opens a message in the reader's default mail app,
  whichever that is. The in-app Mail composer is gone; it worked only when Apple
  Mail had an account set up.
- **Previews.** Both screens have `#Preview`s, and previews are enabled for the app
  target.

---

## 4. Design: Liquid Glass

Building against the iOS 26 SDK or later makes the system apply Liquid Glass to
standard controls on its own. The December 2025 styling worked against that: a
blue-to-purple gradient sat behind every screen, a blur view sat behind every row,
the navigation and search bars were overridden with custom transparent
appearances, and a hand-built blur sat behind the keyboard's keys.

All of it is gone. In the app, the navigation bar, toolbar button, search field and
setup sheet take on Liquid Glass from SwiftUI, and no custom glass code remains. The
keyboard sits on the system's own backdrop, which is Liquid Glass on iOS 26; the
hand-built layer it replaces also broke typing (§7.1).

---

## 5. Deprecated and legacy API removed

| API | Replacement | Where |
| --- | --- | --- |
| `@UIApplicationMain` | SwiftUI `@main` `App` | App |
| Storyboards pinned to the top and bottom layout guides (deprecated in iOS 11) | SwiftUI | App |
| `UIAlertView` | SwiftUI `.alert` | App |
| `traitCollectionDidChange(_:)` | Semantic colours, which need no override | App |
| Keyboard notifications with a fixed offset | `.searchable`, positioned by the system | App |
| `UIScreen.main` | Window scene, or `traitCollection.displayScale` | Keyboard |
| `UIDevice.current.userInterfaceIdiom` | The trait collection's idiom | Keyboard |
| `UIViewController.interfaceOrientation` | `UIWindowScene.interfaceOrientation`, with a size-class fallback | Keyboard |
| `willRotate(to:duration:)` / `didRotate(from:)` | `viewWillTransition(to:with:)` | Keyboard |
| Polling with `UIScreen.displayLink(withTarget:selector:)` | Trait-change registration and `textDidChange(_:)` | Keyboard |
| String `Selector("…")` | `#selector`, with the target marked `@objc` | Keyboard |
| `Hashable` via a `hashValue` requirement | `hash(into:)` | Keyboard |
| `protocol …: class` | `protocol …: AnyObject` | Keyboard |
| `NSLayoutConstraint(item:attribute:…)` | Layout anchors | Keyboard |
| `String.substring(from:)`, `arc4random`, `UIActivityIndicatorView.Style.white`, `MPVolumeView.showsRouteButton` | — | Removed with unused helper code |

---

## 6. App code quality

### 6.1 Dictionary data

`NDDictionary` parsed `vocabulary.json` through `NSDictionary`, `AnyObject` and a
chain of forced unwraps and `as!` casts, then de-duplicated sections by round-
tripping arrays through `NSSet`. Malformed or missing data crashed the app on
launch.

It now decodes value-type `NDDictionaryEntry`s with `Codable` and groups them into
`DictionarySection`s with `Dictionary(grouping:)`. Section and entry ordering are
unchanged. A missing or malformed file yields an empty dictionary rather than a
crash.

### 6.2 Pronunciation playback

Playback was owned by the table view cell that started it, so scrolling cut a
recording short as soon as that cell was reused. Each tap also reconfigured and
re-activated the audio session, which was then never released.

`Na'vi/PronunciationPlayer.swift` moves playback to a single shared player. The
playback category is configured once — recordings stay audible when the ring
switch is silenced — and the session is released when the clip ends so any audio
the listener had playing can resume.

### 6.3 Search

`NDDictionary.filtered(_:matching:)` keeps entries whose Na'vi or English text
contains the query, ignoring case and surrounding whitespace but not diacritics:
ä and ì are separate letters in Na'vi, not accented forms of a and i. The UIKit
version compared `uppercased()` strings, and one of its paths reset the data source
without reloading the table.

### 6.4 Build settings

- `SWIFT_VERSION` was `5.9`, which is not one of the values Xcode accepts
  (`4.0`, `4.2`, `5.0`, `6.0`). The app target is now `6.0`; the keyboard is
  `5.0` (see §10.1).
- `SWIFT_SWIFT3_OBJC_INFERENCE = On` removed. The current Xcode build system no
  longer defines this setting, so it had no effect; the one method called by
  name from Objective-C is now marked `@objc` explicitly (§7.2).
- `ENABLE_PREVIEWS = YES` for the app target.
- `CLANG_CXX_LANGUAGE_STANDARD`: `gnu++0x` → `gnu++20`.
- `GCC_C_LANGUAGE_STANDARD`: `gnu99` → `gnu17`.
- `CODE_SIGN_IDENTITY[sdk=iphoneos*]`: `iPhone Developer` → `Apple Development`.
- Project format: `objectVersion` 54 → 56, `compatibilityVersion` `Xcode 3.2` →
  `Xcode 14.0`.

---

## 7. Keyboard extension

The keyboard remains UIKit. It uses no storyboards, and a keyboard's per-key touch
handling is better served by UIKit's controls than by SwiftUI.

### 7.1 Taps not registering

The keyboard receives every touch in one view, `ForwardingView`, which hands it to
the nearest subview. The December 2025 styling inserted a full-size blur view and
tint layer into that same view, beneath the keys. Being full-size, they were the
nearest subview to every touch, so taps went to them and no key responded.

The layer is removed (§4), and `ForwardingView` now considers only controls, so a
decorative view can no longer capture input.

### 7.2 Crash when sliding off a key

Character keys hide their popup through a control action registered with the string
`Selector("hidePopup")`. The method was not visible to Objective-C, so the action
would raise an unrecognised-selector exception the moment a finger slid off a key
or a touch was cancelled. The method is now `@objc` and registered with
`#selector`, which the compiler checks.

### 7.3 Appearance

- **Dark Mode.** The keyboard decided between light and dark keys only from the
  field's requested `keyboardAppearance`, which most fields leave at `.default`.
  In system Dark Mode it drew light keys on a dark backdrop. It now also reads the
  trait collection.
- **Polling.** The appearance was checked by a display link on every screen
  refresh — up to 120 times a second for as long as the keyboard existed — held in
  a global variable, and the display link retained the keyboard's view controller.
  Changes are now observed instead: a trait-change registration for Dark Mode, a
  notification for Reduce Transparency, and `textDidChange(_:)` for fields that
  request a dark keyboard.

### 7.4 Key popups

The December styling added a blur view and a second shadow to each key popup. The
popup is drawn as one continuous shape with its key, and its shadow already uses an
explicit path; the added shadow had none, which forces an offscreen render every
time a popup appears — that is, on every keypress. Both additions are removed.

### 7.5 Key colours

The December styling also changed the keys to translucent colours tuned against
the removed blur layer. Because taps were not registering (§7.1), that design never
reached anyone in working form. The keys use the palette of the current App Store
release again; styling them for the iOS 26 keyboard is listed in §10.2.

### 7.6 Swift

- `Key` implemented `Hashable` through a stored `hashValue` fed by a global mutable
  counter. It now uses identity — every key was already distinct — through
  `hash(into:)`.
- `CGRect` and `CGSize` were retroactively conformed to `Hashable` with the same
  deprecated requirement. Only `CGSize` was used as a dictionary key; a small local
  key type replaces both conformances.
- A debug `print` that ran on every key-cap update is removed, as is an unused
  global profiling closure.
- A `switch` over `UITextAutocapitalizationType`, an enum that can gain cases, now
  has an `@unknown default`.

With these changes the keyboard holds no mutable global state.

### 7.7 Globe key

The keyboard decided whether to draw a globe key by comparing the screen's pixel
height against `2436`, the iPhone X. That matched no later device and, on the
iPhone X itself, removed the only way to switch keyboards. Every page now carries
a globe key, as a custom keyboard requires.

---

## 8. Dependencies and unused files removed

**CocoaPods.** The `Podfile` declared no pods, yet every build ran two
`[CP] Check Pods Manifest.lock` script phases against a CocoaPods 1.11.3 sandbox
and linked two empty frameworks. The integration and the `Pods.xcodeproj`
workspace reference are gone, and so are the `Podfile`, `Podfile.lock` and the
`Pods/` directory of generated support files.

**KeyboardKit and KeyboardKitPro.** Both were pinned at 6.0.0 and linked into the
app target, and neither was imported anywhere in the codebase. Versions of that
age do not build on a current toolchain.

The project no longer depends on any third-party code, and
`Na-vi.xcworkspace` now contains only `Na-vi.xcodeproj`.

**Unused files.** The following files belonged to no target. They are deleted,
together with the entries that still listed them in Xcode's project navigator:

| File | Why it was removed |
| --- | --- |
| `Keyboard/Na'vi Keyboard.swift` | The `Catboard` sample class. Never instantiated — the extension's principal class is `KeyboardViewController` — and it injected cat emoji into typed text and wrote screenshots to a hard-coded path on the original sample author's Mac. |
| `Keyboard/CatboardBanner.swift` | Swift 2 source (`NSUserDefaults`, `UIControlEvents`) that had not compiled for years. |
| `Keyboard/CQMPHelper.swift` | An `MPVolumeView` extension with no callers, built on API deprecated in iOS 13. |
| `Keyboard/CQStdHelper.swift` | A `delay(bySeconds:)` helper with no callers. |
| `Keyboard/CQUIHelper.swift` | A keyboard-animation helper for the former UIKit search field. |
| `Keyboard/Utilities.swift` | An unused `memoize` function and an unused global profiling closure. |
| `UIDevice.swift` | The `hasBottom` device check described in §7.7, no longer used. |
| `Na'vi Keyboard/KeyboardView.swift`, `KeyboardViewController.swift`, `NSHelper.swift`, `Keyboard.xib`, `Keyboard.storyboard` | An abandoned second keyboard implementation, never referenced by the project. |
| `Keyboard/Info.plist` | Not used by the build; the extension uses `Na'vi Keyboard/Info.plist`. |

Every Swift file in the repository is now compiled into a target, and the only
Interface Builder file left is the keyboard's settings panel, `DefaultSettings.xib`
(§10.3).

---

## 9. Verification

`./build-verify.sh` runs `Scripts/preflight.py` and then `xcodebuild`. The
pre-flight checks need only Python and cover:

- **Project file** — balanced delimiters, every object reference resolving, no
  CocoaPods or KeyboardKit remnants, valid `SWIFT_VERSION` values.
- **Property lists** — all four parse; 64-bit device capabilities; export
  compliance declared; matching version strings across app and extension; complete
  privacy manifests.
- **App life cycle and launch screen** — a SwiftUI `App` entry point or a scene
  delegate the app actually compiles; a launch screen declared; no storyboard named
  in `Info.plist` that the app does not bundle.
- **App Store icon** — 1024×1024 with no alpha channel.
- **Target membership** — every file a target compiles exists on disk, and any
  Swift file belonging to no target is listed.
- **Deprecated and legacy API** — the patterns in §5, plus debug prints, enforced
  against compiled sources only.
- **Keyboard touch routing** — `ForwardingView` still limits itself to controls
  (§7.1).
- **Interface Builder files** — which storyboards and nibs each target bundles.

All checks pass. Run against earlier revisions, or with the relevant mistake
reintroduced, the rules report every issue described in §2.5, §7 and the life-cycle
and launch-screen section. Compiling and running on device requires Xcode 26 or
later and has not been performed as part of this change.

---

## 10. Follow-up work

### 10.1 Keyboard extension and Swift 6

The extension is roughly 4,700 lines inherited from the 2014 *tasty-imitation-
keyboard* project. It is pinned to the Swift 5 language mode with
`SWIFT_STRICT_CONCURRENCY = minimal`, which compiles under the Swift 6 compiler.
Its mutable global state is now gone (§7.3, §7.6); the main remaining step is to
isolate `KeyboardLayout`, an `NSObject` subclass that drives UIKit views, to the
main actor. After that, raising strict concurrency to `complete` and then moving
to the Swift 6 language mode is a self-contained change.

### 10.2 Needs a device or design input

- **Keyboard styling for iOS 26.** The keyboard now sits on the system's Liquid
  Glass backdrop with the key palette of the current release. Whether the keys
  should become translucent to match the iOS 26 system keyboard is a design
  decision to make by eye on a device, in light and dark mode and with Reduce
  Transparency on.
- **Globe key menu.** Holding the globe key on the system keyboard lists every
  installed keyboard. Custom keyboards get this through
  `handleInputModeList(from:with:)`, which needs the original touch event;
  `ForwardingView` currently forwards actions without one. Passing the event
  through, then testing on a device, would enable it.
- **App icon.** iOS 26 renders icons with Liquid Glass and offers dark, clear and
  tinted appearances. A layered icon made in Icon Composer would use them.
- **Setup instructions.** The five steps follow Settings → General → Keyboard. A
  keyboard's switch also appears on the app's own page in Settings, which the app
  can open directly with `UIApplication.openSettingsURLString`; that is a shorter
  path worth considering, along with refreshed screenshots.

### 10.3 Smaller items

- **Bundle contents.** The app bundle ships `Eywa.sketch` (a 2.5 MB design file),
  `vocabulary-2016.json` and `vocabulary-20220106.csv`, none of which the app reads,
  and `GoogleService-Info.plist`, although no Firebase SDK is linked. Removing all
  four from the app's Resources build phase makes the download about 3.2 MB smaller;
  the Firebase file is also bundled into the keyboard.
- **Unused assets.** The asset catalog still holds images that only the storyboards
  used: `Keyboard Icon`, `InfoIcon`, `Play Audio`, `Bookmarked` and
  `Keyboard Screen Shot`.
- **Unused Core Data model.** `Na_vi.xcdatamodeld` is compiled into the app but
  never loaded.
- **The keyboard's settings panel is unreachable.** Its key is commented out of
  the layout, so its options are fixed at their defaults, and its key-click option
  would also need the Full Access permission, which the keyboard does not request.
  The panel is the one remaining nib (`DefaultSettings.xib`); it is either worth
  restoring or worth removing.
- **Tests.** The project has no test target. A Swift Testing target covering
  dictionary decoding, grouping and `NDDictionary.filtered(_:matching:)` would guard
  the logic in §6.1 and §6.3.
