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
13% smaller. The fourteen smaller icon sizes carried the same unused alpha channel
and are re-encoded the same way, with identical pixels.

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

- **Navigation.** A tab bar leads to the dictionary, Translate, the phrasebook and
  Settings, which holds the keyboard setup guide. Each tab keeps its own navigation
  stack, and a restored scene reopens on the tab last used. The vocabulary and the
  grammar engine load once, in the background, for the three tabs that need them.
- **Search.** `.searchable` provides the search field. On iPhone it sits below the
  navigation title, as is standard in an app with a tab bar; on iPad with iOS 26 it
  collapses to a search button beside the tab bar. The keyboard-tracking code the
  UIKit version needed is gone. An empty search shows the system's "No Results"
  view.
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
- **Icons.** The tab bar and the play-pronunciation buttons use SF Symbols with
  accessibility labels, and the play buttons scale with text.
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

All of it is gone. In the app, the navigation bar, tab bar and search field take on
Liquid Glass from SwiftUI, and no custom glass code remains. The
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
`DictionarySection`s with `Dictionary(grouping:)`. A missing or malformed file
yields an empty dictionary rather than a crash.

**Alphabetical order.** Sections and entries were sorted by Unicode code point,
which puts ä and ì after z: the Ä and Ì sections came last, and within a section
a word containing ä or ì sorted as if that letter followed z. `NDDictionary.collationKey(_:)` now
sorts by the Na'vi alphabet, with ä after a and ì after i. A space sorts before
every letter, so a phrase still follows the word it starts with, and digraphs such
as kx and ts sort by their letters.

**Part of speech.** The source data abbreviates each entry's part of speech, and a
fixed list of codes spelled them out. 122 entries used codes missing from that
list, such as `inter.` (57), `adp.` (48) and `adv., n.`, and showed the raw
abbreviation. Each abbreviation in a code is now spelled out on its own, so any
combination reads as, for example, "Adverb, noun". Two labels changed: `num.` is
"Numeral" rather than "Number", and `svin.` is "Stative intransitive verb" rather
than "Intransitive verb".

Both fixes, and the quote fix in §6.3, were first made on the July 2026 recovery
branch, `fix/ios26-uiux-bugs`, for the UIKit app; they were carried over when that
branch was merged.

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

Smart Punctuation, which is on by default, turns a typed apostrophe into a curly
quote, while the vocabulary spells every glottal stop with a straight apostrophe.
Searching for any word containing one therefore found nothing. Curly quotes in the
query now match straight apostrophes.

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

### 6.5 Bundle contents

The app bundled four files that nothing reads:

- `Resources/Eywa.sketch`, a 2.5 MB Sketch design file.
- `Resources/vocabulary-2016.json`, an old export of the vocabulary. The app reads
  only `Resources/vocabulary.json`.
- `Resources/vocabulary-20220106.csv`, a source export of the vocabulary.
- `GoogleService-Info.plist`, Firebase configuration left behind when the Firebase
  pods were removed in 2022. The keyboard bundled a copy as well.

The design file and the two exports stay in the repository as source material, but
no target copies them any more. Firebase is not planned, so its configuration file
is deleted; its API key is covered in §10.3.

Two more things were used only by code that no longer exists:

- Five images in `Assets.xcassets` — `Keyboard Icon`, `InfoIcon`, `Play Audio`,
  `Bookmarked` and `Keyboard Screen Shot` — that only the storyboards displayed.
  The SwiftUI screens use SF Symbols instead (§3.2).
- The Core Data model `Na_vi.xcdatamodeld`, compiled into the app although no code
  ever loaded a Core Data stack.

The app is 3.3 MB smaller installed and about 2.3 MB smaller to download. A build
without `vocabulary.json` would still succeed, and a release build would show an
empty dictionary rather than crash, so the pre-flight checks now fail if the app
stops bundling it (§9).

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
reached anyone in working form. The keys now follow the iOS 26 system keyboard
(§7.13).

The Shift and Delete keys drew their symbols in white in both appearances. On the
grey special keys of the light palette that is a contrast of about 2:1, so at rest
both keys looked blank. In light mode their symbols are now black, as on the system
keyboard.

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
iPhone X itself, removed the only way to switch keyboards.

It now asks the system, through `needsInputModeSwitchKey`. iPhones without a Home
button draw their own globe key below every keyboard, custom ones included, and
report `false`; there the keyboard leaves its own out, so the bottom row no longer
shows two globes. iPads report `true` and keep the key on every page. The keys are
rebuilt if the answer changes while the keyboard is open.

### 7.8 Crash in an empty field

In a field that capitalizes every word, such as a name field, the keyboard turns
Shift on according to the character before the cursor. It read that character by
stepping back from the end of the text, which traps when a field reports its empty
text as an empty string rather than as no text. It now reads the text's last
character, which is simply absent when the text is empty.

### 7.9 Keyboard height

The keyboard reserved 30 points at the top for a banner it never created, so an
empty strip sat above the keys. That space now holds the toolbar (§7.12), and the
height includes it only when the toolbar exists.

Rotation set the new height only in `viewWillTransition(to:with:)`, although a note
in the controller records that none of the `UIContentContainer` methods, which
include that one, are called for it. The height is now also set during layout, once
for each change of orientation, so a landscape keyboard is not left at its portrait
height.

### 7.10 Key clicks

Key clicks played a system sound through AudioToolbox, which a keyboard can do only
with Full Access. This keyboard does not request Full Access, so its Keyboard
Clicks option never made a sound. Clicks now use `UIDevice.playInputClick()`, which
needs no Full Access and plays only when keyboard clicks are also on in the
system's Sounds settings. The note in the keyboard's settings saying clicks need
Full Access is removed.

### 7.11 Key caps

Whether the letter keys show capitals was computed three different ways, so the key
caps changed case depending on whether a keypress, a mode change or a relayout had
run last. All three now follow one setting.

That setting, formerly Allow Lowercase Key Caps and now Show Lowercase Keys, was off
by default, so the letters stayed capitals whatever the state of Shift. It is now on
by default: the letters are lowercase while Shift is off and capitals while it is
on or locked, as on the system keyboard. Turning it off brings back capitals at all
times. The keyboard's settings were unreachable in the App Store release (§7.12),
so no one has a stored value that would keep the old behaviour.

### 7.12 Settings panel

The key that opens the keyboard's settings panel was commented out of the layout,
so Auto-Capitalization, the “.” Shortcut, Keyboard Clicks and Allow Lowercase Key
Caps were fixed at their defaults.

The settings now open from a toolbar above the keys, laid out like the toolbars of
third-party keyboards such as WeChat's: a gear on the left and, on the right, a
button that hides the keyboard. The bottom row keeps only 123, the space bar and
Return, with the globe key where §7.7 needs it. The panel itself is built in code
as a grouped list in the style of the Settings app, with a round back button;
`DefaultSettings.xib`, the keyboard's last nib, is gone.

§7.8 to §7.12 and the Shift and Delete colours in §7.5 were first fixed on the July
2026 recovery branch, `fix/ios26-uiux-bugs`, and carried over when that branch was
merged. None of them has been tried on a device: a custom keyboard cannot be used in
the simulator until it is enabled in Settings, which these checks did not do.

### 7.13 Styling for iOS 26

The keys were drawn as they were on iOS 8: a 4-point corner, a one-point shadow
under each key and grey special keys. They now match the iOS 26 system keyboard,
measured from screenshots of it in the iOS 26.5 simulator on a 402-point-wide
iPhone 17 Pro. iOS 27 kept this design.

- **Shape.** An 8-point continuous corner, the curve `UIBezierPath(roundedRect:)`
  draws; fitted against the system's key outline, it matches to a fraction of a
  pixel. No shadow and no border.
- **Colour.** Every key shares one fill: white in light mode and RGB 61, 61, 61 in
  dark mode, the system's values. Keys without a popup, such as Delete, turn grey
  while held. Return is blue where the field's Return key performs an action, such
  as searching.
- **Type.** Capitals and digits at 22 points, lowercase letters at 24.5 points, all
  on one baseline 6.4 points below the key's centre; "123" and "ABC" at 18 points
  and "#+=" at 14. Shift, Delete and the globe are SF Symbols at 19 points, and
  Shift's state shows only in its symbol: `shift`, `shift.fill` or `capslock.fill`.
- **Spacing.** In portrait, 43-point keys with 6-point gaps, 11 points between rows
  and 6.5 points at the sides. Shift and Delete are 1.36 letters wide; the space bar
  starts where the third key of a nine-key row would and Return where the eighth
  would. On the 402-point iPhone every key lands on the same pixels as the system's.
- **Popup.** 25.3 points wider than its key, with 13-point top corners, joined to the
  key by two S-curves; its letter sits where the system's does. In the top row,
  under the toolbar, it shortens to stay inside the keyboard's view, which a
  keyboard extension cannot draw outside.

Landscape keeps its previous spacing, with the new shapes and type. It has not been
checked in the simulator, which could not be rotated for these checks.

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

Every Swift file in the repository is now compiled into a target, and no target
bundles an Interface Builder file (§7.12).

---

## 9. Verification

`./build-verify.sh` runs `Scripts/preflight.py`, then
`Scripts/test_keyboard_layout.sh`, then `xcodebuild`. The pre-flight checks need
only Python and cover:

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
- **Deprecated and legacy API** — the patterns in §5, debug prints, and the
  keyboard mistakes in §7.8 and §7.10, enforced against compiled sources only. The
  rule against reserving room for the top banner (§7.9) is gone now that the
  toolbar fills that room.
- **Keyboard touch routing** — `ForwardingView` still limits itself to controls
  (§7.1).
- **Interface Builder files** — which storyboards and nibs each target bundles.
- **Bundle contents** — the app bundles `vocabulary.json`, and no target bundles a
  design file, a spreadsheet export, an old vocabulary export or Firebase
  configuration (§6.5).
- **Vocabulary** — every entry has the fields the app decodes, no leftover
  flashcard markup, a part of speech the app can spell out and, when it names a
  recording, one the app bundles. `Scripts/test_preflight.py` feeds the check one
  broken vocabulary per mistake.
- **Grammar package** — the app links NaviGrammar, the engine behind the
  translator; its sources import neither UIKit nor SwiftUI; and its bundled lexicon
  is complete, with its source checksum and credits. The translator, its sources and
  its own tests are described in [docs/TRANSLATOR.md](docs/TRANSLATOR.md).

The keyboard layout check compiles the keyboard's layout code for Mac Catalyst,
where UIKit runs without a simulator, and lays the keyboard out at every iPhone
width in portrait and landscape and at iPad sizes, with and without the globe key.
It checks that keys stay inside the keyboard without overlapping, that every popup
stays inside the keyboard's view, that the key caps take the system's sizes and
baseline, and that on the 402-point iPhone each key lands within a pixel of where
the iOS 26 system keyboard puts it (§7.13).

All checks pass. Run against earlier revisions, or with the relevant mistake
reintroduced, the rules report every issue described in §2.5, §7.1, §7.2, §7.8,
§7.10 and the life-cycle and launch-screen section, and every bundled file listed in
§6.5. The project
builds with Xcode 27, and the app runs in the iOS 26.5 simulator; running on a
device has not been performed as part of this change.

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

- **Keyboard on a device.** The iOS 26 styling (§7.13), the toolbar (§7.12) and
  the globe rule (§7.7) were checked in the simulator only, in portrait. Worth a
  look on an iOS 27 iPhone and an iPad, in landscape and with Reduce Transparency
  on.
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

- **Firebase API key.** `GoogleService-Info.plist` (§6.5) was committed to this
  public repository in 2018, so its API key stays in the git history. Firebase is
  not planned, so deleting the key in the Google Cloud console — or the whole
  `the-navi-kit` Firebase project, if nothing else uses it — closes this off more
  completely than rotating it. Deleting the project also retires its Realtime
  Database, which only its security rules protect, with or without a key.
- **Tests.** The project has no test target. A Swift Testing target covering
  dictionary decoding, grouping and `NDDictionary.filtered(_:matching:)` would guard
  the logic in §6.1 and §6.3.
