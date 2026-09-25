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
| App life cycle | `UIApplicationDelegate` only | `UIScene` life cycle |
| Design language | Hand-built blur and gradient | System Liquid Glass |
| Dependency managers | CocoaPods + Swift Package Manager | None |

**Why iOS 18.** As of Apple's June 2026 App Store figures, iOS 18 or later runs on
about 93% of active iPhones, against 79% for iOS 26 alone. iOS 26 no longer supports
the iPhone XS and XR, and iOS 17 runs on exactly the same hardware as iOS 18, so a
lower floor would reach very few additional people. iOS 27, 26 and 18 are also the
three most recent major releases. The only version-dependent code in the app, the
Liquid Glass effect, falls back cleanly on iOS 18 through 25.

People on iOS 14 to 17 keep the version they already have and can re-download the
last compatible version from their purchase history. The vocabulary and recordings
are bundled, so that version keeps working; it simply stops receiving updates.

---

## 2. App Store and SDK compliance

These items block submission or correct behaviour on current systems.

### 2.1 UIScene life cycle

An app built against the iOS 27 SDK without the scene life cycle does not launch.
The app now declares and implements it:

- `Na'vi/SceneDelegate.swift` — new `UIWindowSceneDelegate`.
- `Na'vi/AppDelegate.swift` — `@main`, with `configurationForConnecting` and
  `didDiscardSceneSessions`.
- `Na'vi/Info.plist` — `UIApplicationSceneManifest` naming the delegate and
  `Dictionary.storyboard` as the scene's initial interface.

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

## 3. Design: Liquid Glass

Building against the iOS 26 SDK or later makes the system apply Liquid Glass to
standard controls on its own. The December 2025 styling worked against that: a
blue-to-purple gradient sat behind every screen, a `UIVisualEffectView` sat behind
every row, and the navigation and search bars were overridden with custom
transparent appearances.

The approach is now inverted — the system supplies the material, and the app
styles only what it draws itself.

**Removed**

- The gradient background layer and the code that tracked its frame and colours.
- Per-row blur views and their reuse bookkeeping.
- Custom `UINavigationBarAppearance` overrides.
- Hard-coded text colours built from black and white with alpha, in favour of
  semantic colours (`.label`, `.secondaryLabel`). These track Dark Mode, Increase
  Contrast and Reduce Transparency without any per-trait code, which is why the
  three `traitCollectionDidChange` overrides could be removed rather than migrated.
- `layer.shouldRasterize` on blurred views, which defeats the material it was
  meant to accelerate.
- A hand-built blur and tint layer behind the keyboard's keys. The system draws the
  keyboard's backdrop itself — as Liquid Glass on iOS 26 — and that layer also
  broke typing (§6.1).

**Retained, deliberately**

Two surfaces still use glass, because both float above scrolling content:

- The search field at the bottom of the dictionary, as an interactive capsule.
- The section headers in the dictionary list.

`Na'vi/GlassUIHelper.swift` builds these with `UIGlassEffect` on iOS 26 and later
and falls back to the closest system material on iOS 18 to 25, so one view
hierarchy serves the whole deployment range.

---

## 4. Deprecated and legacy API removed

| API | Replacement | Location |
| --- | --- | --- |
| `@UIApplicationMain` | `@main` | `AppDelegate.swift` |
| `UIAlertView` | `UIAlertController` | `MainViewController.swift` |
| `traitCollectionDidChange(_:)` | Semantic colours (no override needed) | 3 call sites |
| `UIScreen.main` | Window scene, or `traitCollection.displayScale` | `KeyboardLayout.swift`, `KeyboardKey.swift`, `KeyboardViewController.swift` |
| `UIDevice.current.userInterfaceIdiom` | The trait collection's idiom | `KeyboardLayout.swift`, `KeyboardViewController.swift` |
| `UIViewController.interfaceOrientation` | `UIWindowScene.interfaceOrientation`, with a size-class fallback | `KeyboardViewController.swift` |
| `willRotate(to:duration:)` / `didRotate(from:)` | `viewWillTransition(to:with:)` | `KeyboardViewController.swift` |
| Keyboard notifications with a fixed offset | `view.keyboardLayoutGuide` | `NDDictionaryMainViewController.swift` |
| Polling with `UIScreen.displayLink(withTarget:selector:)` | Trait-change registration and `textDidChange(_:)` | `KeyboardInputTraits.swift` |
| String `Selector("…")` | `#selector`, with the target marked `@objc` | `KeyboardViewController.swift` |
| `Hashable` via a `hashValue` requirement | `hash(into:)` | `KeyboardModel.swift`, `KeyboardLayout.swift` |
| `protocol …: class` | `protocol …: AnyObject` | `KeyboardKey.swift`, `KeyboardConnector.swift` |
| `NSLayoutConstraint(item:attribute:…)` | Layout anchors | `KeyboardViewController.swift` |
| `String.substring(from:)`, `arc4random`, `UIActivityIndicatorView.Style.white`, `MPVolumeView.showsRouteButton` | — | Removed with unused helper code |

---

## 5. App code quality

### 5.1 Dictionary loading

`NDDictionary` parsed `vocabulary.json` through `NSDictionary`, `AnyObject` and a
chain of forced unwraps and `as!` casts, then de-duplicated sections by round-
tripping arrays through `NSSet`. Malformed or missing data crashed the app on
launch.

It now decodes into `NDDictionaryEntry` with `Codable` and groups entries with
`Dictionary(grouping:)`. Section and entry ordering are unchanged. A missing or
malformed file yields an empty dictionary rather than a crash.

### 5.2 Pronunciation playback

Playback was owned by the table view cell that started it, so scrolling cut a
recording short as soon as that cell was reused. Each tap also reconfigured and
re-activated the audio session, which was then never released.

`Na'vi/PronunciationPlayer.swift` moves playback to a single shared player. The
playback category is configured once — recordings stay audible when the ring
switch is silenced — and the session is released when the clip ends so any audio
the listener had playing can resume.

### 5.3 Search

The list view held a mutable copy of the dictionary that one delegate path reset
without reloading the table, leaving the data source and the table disagreeing
about row counts. Filtering now derives from an immutable source list, and
matching uses `localizedCaseInsensitiveContains` rather than `uppercased()`
comparison, which is correct for the diacritics in the Na'vi alphabet.

### 5.4 Search field and the keyboard

The search field was lifted above the keyboard by `keyboardHeight - 40` points, a
guess at the height of the home indicator. On Face ID iPhones that left the field
overlapping the keyboard by 6 points; on the iPhone SE, which has no home
indicator, by 40 points, hiding most of the field. It also ignored floating,
split and hardware keyboards and resizable iPad windows.

The field is now pinned to `view.keyboardLayoutGuide`, which sits on the safe area
when no keyboard is showing and on top of whichever keyboard is, animating with it.
The keyboard notification handlers and the helper that animated them are gone.

### 5.5 Dynamic Type

The dictionary list used fixed font sizes. Its title, pronunciation and definition
now scale with the reader's text size setting through `UIFontMetrics`, starting
from the storyboard's sizes, so the list looks exactly as designed at the default
setting and rows grow to fit larger text.

### 5.6 Contact

The contact button relied on `MFMailComposeViewController`, which works only when
Apple Mail has an account set up. When it does not, the button now opens a
`mailto:` link, which reaches whichever app the reader has chosen as their default
mail app. The alert appears only when no mail app can take the message.

### 5.7 Build settings

- `SWIFT_VERSION` was `5.9`, which is not one of the values Xcode accepts
  (`4.0`, `4.2`, `5.0`, `6.0`). The app target is now `6.0`; the keyboard is
  `5.0` (see §9.2).
- `SWIFT_SWIFT3_OBJC_INFERENCE = On` removed. The current Xcode build system no
  longer defines this setting, so it had no effect; the one method called by
  name from Objective-C is now marked `@objc` explicitly (§6.2).
- `CLANG_CXX_LANGUAGE_STANDARD`: `gnu++0x` → `gnu++20`.
- `GCC_C_LANGUAGE_STANDARD`: `gnu99` → `gnu17`.
- `CODE_SIGN_IDENTITY[sdk=iphoneos*]`: `iPhone Developer` → `Apple Development`.
- Project format: `objectVersion` 54 → 56, `compatibilityVersion` `Xcode 3.2` →
  `Xcode 14.0`.

---

## 6. Keyboard extension

### 6.1 Taps not registering

The keyboard receives every touch in one view, `ForwardingView`, which hands it to
the nearest subview. The December 2025 styling inserted a full-size blur view and
tint layer into that same view, beneath the keys. Being full-size, they were the
nearest subview to every touch, so taps went to them and no key responded.

The layer is removed (§3), and `ForwardingView` now considers only controls, so a
decorative view can no longer capture input.

### 6.2 Crash when sliding off a key

Character keys hide their popup through a control action registered with the string
`Selector("hidePopup")`. The method was not visible to Objective-C, so the action
would raise an unrecognised-selector exception the moment a finger slid off a key
or a touch was cancelled. The method is now `@objc` and registered with
`#selector`, which the compiler checks.

### 6.3 Appearance

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

### 6.4 Key popups

The December styling added a blur view and a second shadow to each key popup. The
popup is drawn as one continuous shape with its key, and its shadow already uses an
explicit path; the added shadow had none, which forces an offscreen render every
time a popup appears — that is, on every keypress. Both additions are removed.

### 6.5 Key colours

The December styling also changed the keys to translucent colours tuned against
the removed blur layer. Because taps were not registering (§6.1), that design never
reached anyone in working form. The keys use the palette of the current App Store
release again; styling them for the iOS 26 keyboard is listed in §9.3.

### 6.6 Swift

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

### 6.7 Globe key

The keyboard decided whether to draw a globe key by comparing the screen's pixel
height against `2436`, the iPhone X. That matched no later device and, on the
iPhone X itself, removed the only way to switch keyboards. Every page now carries
a globe key, as a custom keyboard requires.

---

## 7. Dependencies removed

**CocoaPods.** The `Podfile` declared no pods, yet every build ran two
`[CP] Check Pods Manifest.lock` script phases against a CocoaPods 1.11.3 sandbox
and linked two empty frameworks. The integration, the generated xcconfigs and the
`Pods.xcodeproj` workspace reference are gone.

**KeyboardKit and KeyboardKitPro.** Both were pinned at 6.0.0 and linked into the
app target, and neither was imported anywhere in the codebase. Versions of that
age do not build on a current toolchain.

The project no longer depends on any third-party code, and
`Na-vi.xcworkspace` now contains only `Na-vi.xcodeproj`.

---

## 8. Verification

`./build-verify.sh` runs `Scripts/preflight.py` and then `xcodebuild`. The
pre-flight checks need only Python and cover:

- **Project file** — balanced delimiters, every object reference resolving, no
  CocoaPods or KeyboardKit remnants, valid `SWIFT_VERSION` values.
- **Property lists** — all four parse; the scene manifest is present and names a
  delegate that exists; 64-bit device capabilities; export compliance declared;
  matching version strings across app and extension; complete privacy manifests.
- **App Store icon** — 1024×1024 with no alpha channel.
- **Target membership** — every file a target compiles exists on disk, and any
  Swift file belonging to no target is listed.
- **Deprecated and legacy API** — the patterns in §4, plus debug prints, enforced
  against compiled sources only.
- **Keyboard touch routing** — `ForwardingView` still limits itself to controls
  (§6.1).
- **Storyboards** — a warning for layouts still pinned to the pre-iOS 11 layout
  guides.

All checks pass. Run against the previous revision, the new rules report every
issue described in §2.5, §5.4 and §6. Compiling and running on device requires
Xcode 26 or later and has not been performed as part of this change.

---

## 9. Follow-up work

### 9.1 Files to delete

These files are no longer part of any target. They were left on disk so the
removal can be reviewed before it is made permanent:

| File | Why it is dead |
| --- | --- |
| `Keyboard/Na'vi Keyboard.swift` | The `Catboard` sample class. Never instantiated — the extension's principal class is `KeyboardViewController` — and it injects cat emoji into typed text and writes screenshots to a hard-coded path on a stranger's Mac. |
| `Keyboard/CatboardBanner.swift` | Swift 2 source (`NSUserDefaults`, `UIControlEvents`) that has not compiled for years; it was already outside the build. |
| `Keyboard/CQMPHelper.swift` | An `MPVolumeView` extension with no callers, built on API deprecated in iOS 13. |
| `Keyboard/CQStdHelper.swift` | A `delay(bySeconds:)` helper with no callers. |
| `Keyboard/CQUIHelper.swift` | The keyboard-animation helper replaced by the keyboard layout guide (§5.4). |
| `Keyboard/Utilities.swift` | An unused `memoize` function and an unused global profiling closure. |
| `UIDevice.swift` | The `hasBottom` device check described in §6.7, now unused. |
| `Na'vi Keyboard/KeyboardView.swift`, `KeyboardViewController.swift`, `NSHelper.swift`, `Keyboard.xib`, `Keyboard.storyboard` | An abandoned second keyboard implementation, never referenced by the project. |
| `Keyboard/Info.plist` | Never referenced; the extension uses `Na'vi Keyboard/Info.plist`. |
| `Podfile`, `Podfile.lock`, `Pods/` | Left behind by the CocoaPods removal in §7. |

`Scripts/preflight.py` lists the Swift files among these on every run, so that
warning disappears once they are removed.

### 9.2 Keyboard extension and Swift 6

The extension is roughly 4,700 lines inherited from the 2014 *tasty-imitation-
keyboard* project. It is pinned to the Swift 5 language mode with
`SWIFT_STRICT_CONCURRENCY = minimal`, which compiles under the Swift 6 compiler.
Its mutable global state is now gone (§6.3, §6.6); the main remaining step is to
isolate `KeyboardLayout`, an `NSObject` subclass that drives UIKit views, to the
main actor. After that, raising strict concurrency to `complete` and then moving
to the Swift 6 language mode is a self-contained change.

### 9.3 Needs Xcode, a device or design input

- **Safe area layout guides.** All three storyboards are still pinned to the top
  and bottom layout guides deprecated in iOS 11. In Interface Builder, select each
  storyboard and enable *Use Safe Area Layout Guides* in the File inspector; Xcode
  converts the constraints.
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
- **Content beneath the search field.** The list currently ends at the top of the
  glass search field. Extending it to the bottom edge, with a matching content
  inset, lets rows scroll beneath the glass as Liquid Glass intends.
- **Dynamic Type elsewhere.** The setup instructions screen is a fixed layout
  without a scroll view, and the section index headers have a fixed height, so
  scaling their text needs layout changes in Interface Builder first.
- **App icon.** iOS 26 renders icons with Liquid Glass and offers dark, clear and
  tinted appearances. A layered icon made in Icon Composer would use them.

### 9.4 Smaller items

- **`GoogleService-Info.plist`** is bundled into both targets, but no Firebase
  SDK is linked and nothing reads it. It ships project identifiers to no purpose
  and should be removed from both Resources build phases.
- **Dictionary loading is synchronous.** Roughly 890 KB of JSON, 2,678 entries,
  is decoded on the main thread while the first view controller initialises.
  Moving it off the main thread would shorten launch.
- **Section headers reuse `dequeueReusableCell`.** The correct API is
  `dequeueReusableHeaderFooterView(withIdentifier:)`, which requires registering
  a header view.
- **The detail screen is unreachable.** `NDDefinitionViewController` is wired into
  `Dictionary.storyboard` but row selection does nothing; the push was commented
  out. It is either worth restoring or worth removing.
- **The keyboard's settings panel is unreachable.** Its key is commented out of
  the layout, so its options are fixed at their defaults. Its key-click option
  would also need the Full Access permission, which the keyboard does not
  request. The panel is either worth restoring or worth removing.
- **Tests.** The project has no test target. A Swift Testing target covering
  dictionary decoding, grouping and search would guard the logic in §5.1 and §5.3.
