# The Na'vi Kit — Platform Modernization

This document records the work that brings **Eywa** (the Na'vi dictionary app) and
its **Na'vi Keyboard** extension up to the current Apple platform standard.

---

## 1. Platform baseline

| Item | Before | After |
| --- | --- | --- |
| Build SDK | iOS 18 era settings | iOS 26 / 27 SDK (Xcode 26 or later) |
| Deployment target | iOS 18.0 | iOS 18.0 (unchanged) |
| Swift language mode | `5.9` — not a value Xcode accepts | `6.0` (app), `5.0` (keyboard) |
| App life cycle | `UIApplicationDelegate` only | `UIScene` life cycle |
| Design language | Hand-built blur and gradient | System Liquid Glass |
| Dependency managers | CocoaPods + Swift Package Manager | None |

The deployment target stays at iOS 18.0. Apple's SDK requirement governs what the
app is *built with*, not what it runs on, so no existing user loses access.

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

---

## 3. Design: Liquid Glass

Building against the iOS 26 SDK or later makes the system apply Liquid Glass to
standard controls on its own. The previous release worked against that: a
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

**Retained, deliberately**

Two surfaces still use glass, because both float above scrolling content:

- The search field at the bottom of the dictionary, as an interactive capsule.
- The section headers in the dictionary list.

`Na'vi/GlassUIHelper.swift` now builds these with `UIGlassEffect` on iOS 26 and
later and falls back to the closest system material on iOS 18 to 25, so one view
hierarchy serves the whole deployment range.

---

## 4. Deprecated API removed

| API | Replacement | Location |
| --- | --- | --- |
| `@UIApplicationMain` | `@main` | `AppDelegate.swift` |
| `UIAlertView` | `UIAlertController` | `MainViewController.swift` |
| `traitCollectionDidChange(_:)` | Semantic colours (no override needed) | 3 call sites |
| `UIScreen.main` | Window scene, or `traitCollection.displayScale` | `KeyboardLayout.swift`, `KeyboardKey.swift`, `KeyboardViewController.swift` |
| `UIViewController.interfaceOrientation` | `UIWindowScene.interfaceOrientation`, with a size-class fallback | `KeyboardViewController.swift` |
| `willRotate(to:duration:)` / `didRotate(from:)` | `viewWillTransition(to:with:)` | `KeyboardViewController.swift` |
| `UIScreen.displayLink(withTarget:selector:)` | `CADisplayLink(target:selector:)` | `KeyboardInputTraits.swift` |
| `String.substring(from:)` | Range subscripting | Removed with dead helper code |
| `arc4random` / `arc4random_uniform` | Swift's random APIs | Removed with dead helper code |
| `UIActivityIndicatorView.Style.white` | `.medium` | Removed with dead helper code |
| `MPVolumeView.showsRouteButton` | — | Removed with dead helper code |

---

## 5. Code quality

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

### 5.4 Globe key

The keyboard decided whether to draw a globe key by comparing the screen's pixel
height against `2436` — the iPhone X. The comparison has not matched any device
shipped since, and on the iPhone X itself it suppressed the only way to switch
keyboards. Every page now carries a globe key, as a custom keyboard requires.

### 5.5 Build settings

- `SWIFT_VERSION` was `5.9`, which is not one of the values Xcode accepts
  (`4.0`, `4.2`, `5.0`, `6.0`). The app target is now `6.0`; the keyboard is
  `5.0` (see §7).
- `SWIFT_SWIFT3_OBJC_INFERENCE = On` removed — unsupported since Xcode 14.
- `CLANG_CXX_LANGUAGE_STANDARD`: `gnu++0x` → `gnu++20`.
- `GCC_C_LANGUAGE_STANDARD`: `gnu99` → `gnu17`.
- `CODE_SIGN_IDENTITY[sdk=iphoneos*]`: `iPhone Developer` → `Apple Development`.
- Project format: `objectVersion` 54 → 56, `compatibilityVersion` `Xcode 3.2` →
  `Xcode 14.0`.

---

## 6. Dependencies removed

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

## 7. Verification

`./build-verify.sh` runs `Scripts/preflight.py` and then `xcodebuild`. The
pre-flight checks need only Python and cover:

- Project file integrity: balanced delimiters, every object reference resolving,
  no CocoaPods or KeyboardKit remnants, valid `SWIFT_VERSION` values.
- Property lists: all four parse; the scene manifest is present and names a
  delegate that exists; 64-bit device capabilities; export compliance declared;
  matching version strings across app and extension; complete privacy manifests.
- Target membership: every file a target compiles exists on disk, and any Swift
  file belonging to no target is listed.
- Deprecated API: the table in §4 is enforced against compiled sources only.

All pre-flight checks pass. Compiling and running on device requires Xcode 26 or
later and has not been performed as part of this change.

---

## 8. Follow-up work

### 8.1 Files to delete

These files are no longer part of any target. They were left on disk so the
removal can be reviewed before it is made permanent:

| File | Why it is dead |
| --- | --- |
| `Keyboard/Na'vi Keyboard.swift` | The `Catboard` sample class. Never instantiated — the extension's principal class is `KeyboardViewController` — and it injects cat emoji into typed text and writes screenshots to a hard-coded path on a stranger's Mac. |
| `Keyboard/CatboardBanner.swift` | Swift 2 source (`NSUserDefaults`, `UIControlEvents`) that has not compiled for years; it was already outside the build. |
| `Keyboard/CQMPHelper.swift` | An `MPVolumeView` extension with no callers, built on API deprecated in iOS 13. |
| `Keyboard/CQStdHelper.swift` | A `delay(bySeconds:)` helper with no callers. |
| `UIDevice.swift` | The `hasBottom` device check described in §5.4, now unused. |
| `Na'vi Keyboard/KeyboardView.swift`, `KeyboardViewController.swift`, `NSHelper.swift`, `Keyboard.xib`, `Keyboard.storyboard` | An abandoned second keyboard implementation, never referenced by the project. |
| `Podfile`, `Podfile.lock`, `Pods/` | Left behind by the CocoaPods removal in §6. |

`Scripts/preflight.py` lists the Swift files among these on every run, so the
warning disappears once they are removed.

### 8.2 Keyboard extension and Swift 6

The extension is roughly 4,700 lines inherited from the 2014 *tasty-imitation-
keyboard* project, with global mutable state that the Swift 6 language mode
rejects. It is pinned to the Swift 5 language mode with
`SWIFT_STRICT_CONCURRENCY = minimal`, which compiles under the Swift 6 compiler.
Raising it to `complete`, then to the Swift 6 language mode, is a self-contained
follow-up.

### 8.3 Smaller items

- **`GoogleService-Info.plist`** is bundled into both targets, but no Firebase
  SDK is linked and nothing reads it. It ships project identifiers to no purpose
  and should be removed from both Resources build phases.
- **Dictionary loading is synchronous.** Roughly 890 KB of JSON, 2,678 entries,
  is decoded on the main thread while the first view controller initialises.
  Moving it off the main thread would shorten launch.
- **Section headers reuse `dequeueReusableCell`.** The correct API is
  `dequeueReusableHeaderFooterView(withIdentifier:)`, which requires registering
  a header view in the storyboard.
- **The detail screen is unreachable.** `NDDefinitionViewController` is wired into
  `Dictionary.storyboard` but row selection does nothing; the push was commented
  out. It is either worth restoring or worth removing.
