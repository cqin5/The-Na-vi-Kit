All nine load-bearing corrections are confirmed against live code:

- **viewWillTransition never fires** — `KeyboardViewController.swift:305-313` bug note "None of the UIContentContainer methods are called for this controller" (so 3.12 must use `viewDidLayoutSubviews`, not `viewWillTransition`).
- **30pt band at both sites** — `:266` and `:281` both pass `withTopBanner: true`; `:233` already `false`.
- **Line 91 is a map** — `sectionIndices` at `:90-95` is `entries.map{…}` over already-sorted sections.
- **Synthetic events** — `ForwardingView.handleControl:53` calls `sendAction(…, for: nil)` (globe long-press picker not implementable via forwarding path).
- **keyboardAppearance not KVO/trait** — `KeyboardInputTraits.swift:25` "KVO doesn't work on textDocumentProxy, so we have to poll".
- **Glass views are locals** — `setupGlassKeyboardBackground:197-208` creates blur/tint locally with `autoresizingMask` already set.
- **defaultKeyboard is a free function** — `DefaultKeyboard.swift:11`, gated on `UIDevice.current.hasBottom` at `:50`, no `self`.
- **Canonical case formula** at `:240` confirmed.
- **findNearestView** strict `<` at `:80`, safe to harden.

Here is the final reconciled plan.

---

# The Navi Kit — iOS 18 Recovery & Ship Plan (Final)

## Summary

The Dec 2025 "glassmorphism" commit (`f07358f`) shipped without a single device run and regressed the app from working to broken. The custom keyboard **types nothing** (a full-bounds blur view inside `forwardingView` intercepts every touch), it **crashes** on two routine gestures (key drag-off, focusing a `.words` field), the main dictionary screen is a **broken light/dark mix**, Na'vi's `ä`/`ì` letters **sort after Z** (misfiling ~33% of within-section words), and the archive would be **rejected at validation** (extension/app version mismatch, alpha-channel marketing icon, missing privacy manifest, `armv7`). The dead Swift-2 `Na'vi Keyboard/*.swift` sources are excluded from the build (verified) but that folder's `Info.plist` **is** the shipping keyboard's `INFOPLIST_FILE`, and a client Firebase API key sits committed in the repo (unused — no SDK, no pods).

The fix is sequenced so the keyboard is made testable first (touch routing), then crashes and validation gates, then re-enabling the features that were commented out, then dark-mode/layout/sort/search correctness, and finally security and dead-code cleanup. No new features — this restores correctness and shippability only.

Repo root for all paths below: `/Users/cqin/dev/The-Na-vi-Kit`.

Per-item format: **Defect / Files / Fix / Verify / Risk / Effort (S·M·L)**.

---

## Phase 0 — Green build + a keyboard that accepts input

Nothing else on the keyboard can be verified until touches reach the keys, so this is first.

### 0.1 Confirm a clean iOS 18 build baseline
- **Defect:** No verified build baseline against the iOS 18 SDK.
- **Files:** `Na-vi.xcodeproj/project.pbxproj`.
- **Fix:** Build the `Eywa` app + keyboard extension scheme against the iOS 18 SDK on a simulator. The dead `Na'vi Keyboard/*.swift` Swift-2 sources are **not** in any Sources build phase (verified), so they are not a compile blocker; leave the folder alone (see 4.2).
- **Verify:** App + keyboard extension build and launch on an iOS 18 simulator with no errors.
- **Risk:** None (read-only baseline).
- **Effort:** S.

### 0.2 Glass background swallows every key touch → keyboard types nothing (MASTER BLOCKER)
- **Defect:** `setupGlassKeyboardBackground` inserts blur (idx 0) + tint (idx 1) **into `forwardingView`**, the same view whose `findNearestView` routes touches. The full-bounds blur yields `distance == 0`, is visited first, and the strict `if distance < closest!.1` (`ForwardingView.swift:80`) never lets the real key (also 0) replace it; `handleControl` only acts on `UIControl`, so no `KeyboardKey` ever fires. The keyboard is 100% dead for input.
- **Files:** `Keyboard/KeyboardViewController.swift:194-209` (`setupGlassKeyboardBackground`, called from `setupLayout`); `Keyboard/ForwardingView.swift:62-95` (`findNearestView`), `:45-59` (`handleControl`).
- **Fix (do both — architecture + defense in depth):**
  1. **Move the glass out of `forwardingView`.** Add blur/tint to `self.view` behind `forwardingView` (`self.view.insertSubview(blurView, at: 0)`), sized to `self.view.bounds` with `[.flexibleWidth,.flexibleHeight]`. **Storage note (critique-corrected):** the blur/tint are created as *locals* today, so choose one of two coherent approaches and do not mix them — either (a) rely solely on `autoresizingMask` (already set) and add no per-frame frame update, or (b) promote blur/tint to stored VC properties and resize them in `viewDidLayoutSubviews`. Do not write "update their frame in `viewDidLayoutSubviews`" while leaving them as locals — that step is impossible without the properties.
  2. **Harden `findNearestView`** to only consider interactable keys: `continue` on `!(view is UIControl)` (or filter to `KeyboardKey`), and change `<` to `<=` so a later real key wins ties. This is safe: after fix (1), `forwardingView`'s only subviews are `KeyboardKey`s (which are `UIControl`s); popups/connectors are children of the key, not of `forwardingView` (verified).
- **Verify:** Install keyboard, tap every key type (letter, `'`, shift, backspace, space, mode-change) in Messages — each inserts/acts; highlight + popup appear on letters.
- **Risk:** Medium — touch routing is central; test all key types and multitouch. Placing glass on `self.view` full-height also naturally covers the 30pt band (3.11) — decide the two together (see hazards).
- **Effort:** M.

---

## Phase 1 — Crashes + App Store validation blockers

### 1.1 `hidePopup` string selector → unrecognized-selector SIGABRT on key drag-off
- **Defect:** `keyView.addTarget(keyView, action: Selector("hidePopup"), …)` targets `KeyboardKey.hidePopup`, which is not `@objc` and the class is not `@objcMembers`; the selector is unresolved at runtime under Swift 5.9.
- **Files:** `Keyboard/KeyboardViewController.swift:349`; target method `Keyboard/KeyboardKey.swift:483`.
- **Fix:** Mark `func hidePopup()` `@objc` at `KeyboardKey.swift:483`, and replace the stringly-typed selector at `:349` with `#selector(KeyboardKey.hidePopup)`. (`ForwardingView.handleControl` re-derives the selector by string, so the `@objc` exposure is the load-bearing change.) Confirmed safe: on drag-exit the key fires exactly one `hidePopup` (the `unHighlightKey`/`hidePopupDelay` targets are disjoint).
- **Verify:** Touch a letter, slide finger off it (drag exit) → no crash, popup dismisses.
- **Risk:** Low.
- **Effort:** S.

### 1.2 `.words` auto-capitalization traps on empty (non-nil) before-context
- **Defect:** In `shouldAutoCapitalize()`'s `.words` branch, `beforeContext.index(before: beforeContext.endIndex)` on `""` forms an index before `startIndex` and fatal-errors. The sibling `.sentences` branch guards via `min(3, count)`; `.words` does not. Reached via `setCapsIfNeeded` on first layout and every keystroke.
- **Files:** `Keyboard/KeyboardViewController.swift:763-766`.
- **Fix:** Add `if beforeContext.isEmpty { return true }` before indexing (mirrors the `nil` case at `:768-770`).
- **Verify:** Focus a `.words` field (e.g. a name field, `autocapitalizationType = .words`) with cursor at start (empty before-context) → keyboard does not crash; shift auto-enables.
- **Risk:** Low.
- **Effort:** S.

### 1.3 Extension version 1.4.1 ≠ app version 1.5.2 → validation rejection
- **Defect:** Keyboard target `MARKETING_VERSION = 1.4.1` vs app `1.5.2`; the extension `CFBundleShortVersionString` will not match the container app.
- **Files:** `Na-vi.xcodeproj/project.pbxproj` — keyboard `MARKETING_VERSION` at `:11335` (Debug) / `:11363` (Release); app `1.5.2` at `:11508`/`:11536`.
- **Fix:** Set the keyboard target's `MARKETING_VERSION` to `1.5.2` in **both** configs. **Critique-corrected:** the "align `CFBundleVersion`" step is a no-op and requires **no action** — `CFBundleVersion` is already `"4"` in both Info.plists (they match), and `CURRENT_PROJECT_VERSION` is unset in build settings. Only the marketing version differs.
- **Verify:** Xcode shows identical marketing + build version for both targets; archive validation passes the extension-version check.
- **Risk:** Low.
- **Effort:** S.

### 1.4 Missing `PrivacyInfo.xcprivacy` despite required-reason `UserDefaults` use (ITMS-91053)
- **Defect:** Neither target ships a Privacy Manifest, but both use the required-reason API `UserDefaults`. Hard upload rejection since the May 2024 enforcement date. (`find -iname '*.xcprivacy'` → empty, verified.)
- **Files:** none exists; `UserDefaults` in `Keyboard/KeyboardViewController.swift:97` (and settings reads) + the app target.
- **Fix:** Add a `PrivacyInfo.xcprivacy` to **both** targets' Copy Bundle Resources declaring `NSPrivacyAccessedAPITypes` → `NSPrivacyAccessedAPICategoryUserDefaults` with reason `CA92.1` (same-app access). Use `1C8F.1` only if an App Group is introduced (see Decisions). The only other required-reason API (`task_info` in `GlassUIHelper.logMemoryUsage`) is inside `#if DEBUG` and never ships (verified) — no further declaration needed.
- **Verify:** Archive → Validate uploads with no "Missing API declaration" email; `find` shows one manifest bundled per target.
- **Risk:** Low.
- **Effort:** S.

### 1.5 Marketing icon has an alpha channel (ITMS-90717)
- **Defect:** The 1024×1024 ios-marketing icon is RGBA with transparency; App Store validation rejects alpha on the marketing icon.
- **Files:** `Na'vi/Assets.xcassets/AppIcon.appiconset/iTunesArtwork@2x.png` (verified `mode = RGBA`, 1024²).
- **Fix:** Re-export/flatten onto an opaque background to 8-bit RGB (no alpha). Confirm `sips -g hasAlpha` → `no`.
- **Verify:** `sips -g hasAlpha … == no`; archive validation passes the icon check.
- **Risk:** Low.
- **Effort:** S.

### 1.6 `armv7` in required device capabilities (64-bit-only era)
- **Defect:** `UIRequiredDeviceCapabilities` lists `armv7`; the modern deployment target is 64-bit only.
- **Files:** `Na'vi/Info.plist:31-33`.
- **Fix:** Remove the `armv7` entry (aligns with the arm64-only deployment-target decision).
- **Verify:** Archive validation raises no capability warning; app installs on an arm64 device.
- **Risk:** Low.
- **Effort:** S.

---

## Phase 2 — Dead / unreachable features (commented-out or trapped)

### 2.1 Next-keyboard (globe) key: absent on 2436-pt phones + no long-press picker
- **Defect:** The globe is added only when `UIDevice.current.hasBottom == false`, but `hasBottom` returns `true` **only** for `nativeBounds.height == 2436` (iPhone X/XS/11 Pro), so those devices ship with **no** globe key — a hard usability trap and a documented rejection reason. On every other device the globe shows even when `needsInputModeSwitchKey` would be false.
- **Files:** `Keyboard/DefaultKeyboard.swift:50, :101, :137` (gate); `UIDevice.swift:14-32` (`hasBottom`); wiring `Keyboard/KeyboardViewController.swift:328` (`advanceTapped` on `.touchUpInside`) → `:658-664` (`advanceToNextInputMode()`).
- **Fix (critique-corrected — scope and mechanism):**
  - `defaultKeyboard()` is a **free function** (`DefaultKeyboard.swift:11`) called from `init` (`KeyboardViewController.swift:104`); it has no `self` and **cannot** read `needsInputModeSwitchKey`. Do **not** write `self.needsInputModeSwitchKey` inside it. Concrete mechanism: add the globe **unconditionally** in `defaultKeyboard()`, then at the VC level rebuild the keyboard model and re-lay-out on `viewWillAppear` / input-mode change, showing or hiding the globe per `self.needsInputModeSwitchKey`. The layout engine has **no** existing show/hide-key path, so this means rebuilding the model (as `init` does) rather than toggling a single key — plan for that.
  - **Long-press picker is not implementable through the existing touch path.** `handleInputModeList(from:with:)` needs the real `UIEvent`, but keys are driven synthetically — `ForwardingView.handleControl` calls `sendAction(selector, to: target, for: nil)` (`ForwardingView.swift:53`), so the event is always `nil`. `advanceToNextInputMode()` works (it ignores the event); the system picker will **not** appear. Choose one: (a) accept **short-tap-only advance** (drop the long-press-picker goal), or (b) special-case the globe so it receives **real** UIKit touches/events outside `ForwardingView` (bypass the forwarding path for that one key) and wire it to `handleInputModeListFromView(_:with:)` for `.allTouchEvents`.
- **Verify:** On a 2436-pt phone (iPhone XS / 11 Pro) running iOS 18 the globe is present; short-tap cycles keyboards; on a single-third-party-keyboard device the globe hides when `needsInputModeSwitchKey == false`. If option (b) is taken, also verify long-press shows the picker.
- **Risk:** Medium-High — touches `UIInputViewController` mode APIs and the model-rebuild path; test with 1 vs many keyboards installed.
- **Effort:** **L** (model rebuild + re-layout, not a one-line gate flip).

### 2.2 Settings gear key commented out → whole settings panel unreachable
- **Defect:** Every `addKey(settings…)` is commented out, so `toggleSettings()` never fires and the `DefaultSettings` panel (auto-cap, period shortcut, clicks, lowercase-caps) cannot be opened.
- **Files:** `Keyboard/DefaultKeyboard.swift:55-56, :106, :142`; handler `KeyboardViewController.swift:340-341` → `toggleSettings()` (`:666`).
- **Fix (critique-corrected):** Two real options — **(a) re-add the gear key** to row 3 (already dense: mode-change, globe, space, return — budget width for it), or **(b) drop the settings feature**. **Removed the "move settings into the container app" option:** both entitlements are empty `<dict/>` (no App Group) and `RequestsOpenAccess=false`, so the sandboxed keyboard's `UserDefaults.standard` is a *separate* container from the app's — the app cannot write settings the keyboard reads without adding an App Group (which requires Full/Open Access). That path is out unless Full Access + App Group is also adopted.
- **Verify:** If (a): tap gear → panel toggles; changing Auto-Capitalization / lowercase-caps takes effect and persists.
- **Risk:** Low-Medium (row-3 layout crowding).
- **Effort:** M.

### 2.3 Tapping a dictionary word does nothing (definition screen dead)
- **Defect:** `didSelectRowAt` returns immediately; the push to `NDDefinitionViewController` is commented out, so the detail view is unreachable.
- **Files:** `Na'vi/NDDictionaryMainViewController.swift:129-135`; target `Na'vi/NDDefinitionViewController.swift`.
- **Fix:** Uncomment the `pushViewController`. **The navigation plumbing is already complete (verified — do not re-scaffold it):** `Dictionary.storyboard` `initialViewController` is the nav controller `J88-PW-P0M`, its `rootViewController` is `NDDictionaryMainViewController` (`:271`), and storyboard ID `"NDDefinitionViewController"` exists (`:196`). The **only** real prerequisite is dark-mode legibility: `NDDefinitionViewController` uses hardcoded black `naviColour`/`definitionColour` (`:20/:22`) and `setupDefinitionGlassUI` leaves `naviLabel`/`categoryLabel` non-adaptive. Gate re-enabling on the dark-mode decision (3.1) so you do not push into a white-on-white screen.
- **Verify:** Tap a word → detail view pushes and is legible in the chosen appearance (both light and dark if adaptive path chosen).
- **Risk:** Medium — depends on the 3.1 decision.
- **Effort:** M.

### 2.4 Keyboard Clicks setting can never make sound
- **Defect:** `playKeySound` uses `AudioServicesPlaySystemSound(1104)`, which **does** require Full Access; the shipping keyboard has `RequestsOpenAccess=false`, so Clicks never produce sound. The `DefaultSettings` note ("limitation of the operating system") is itself wrong.
- **Files:** `Keyboard/KeyboardViewController.swift:814-823` (`playKeySound`); `Na'vi Keyboard/Info.plist` (`RequestsOpenAccess=false`, the target's `INFOPLIST_FILE` per pbxproj `:11328/:11356`); note at `Keyboard/DefaultSettings.swift:55`.
- **Fix (critique-corrected — the plan's "Full Access vs remove toggle" was a false dichotomy):** Switch `playKeySound` to `UIDevice.current.playInputClick()` and conform `KeyboardViewController` to `UIInputViewAudioFeedback` with `enableInputClicksWhenVisible = true`. This plays key clicks **without** Full Access (`RequestsOpenAccess` can stay `false`). Neither API is used today (verified). Also **delete** the false "limitation of the operating system" note at `DefaultSettings.swift:55` — do not preserve it. (Requesting Full Access remains a separate, unrelated decision; it is no longer required for clicks.)
- **Verify:** With `RequestsOpenAccess=false` and Clicks enabled, typing produces the standard input click; the settings panel no longer shows the misleading Full-Access note.
- **Risk:** Low.
- **Effort:** S.

---

## Phase 3 — Dark mode, layout, sort & search correctness

### 3.1 Main dictionary screen broken in Dark Mode (white root under translucent glass)
- **Defect:** The app opts into Dark (no `UIUserInterfaceStyle`, no `overrideUserInterfaceStyle` anywhere — verified), but every root background is hardcoded opaque white and only translucent gradients/materials sit on top, while cell/section text flips to white — producing white regions and near-white-on-near-white section headers.
- **Files:** `Na'vi/Dictionary.storyboard:165` (root opaque white); `Na'vi/ViewStylingManager.swift:35` (`tableView.backgroundColor = .clear`); gradient factory `Na'vi/GlassUIHelper.swift:204-220` (`createGradientBackground`, `systemBlue/systemPurple @0.1–0.3`) — **citation-corrected**: the earlier "`ViewStylingManager.swift:109-118`" is `updateGradientColors`, not the factory; cell text `NDDictionaryMainTableViewCell.swift:112-122`; section header white over `.systemUltraThinMaterial`.
- **Fix (pick one — see Decisions):**
  - **(a) Adaptive:** set root views to `systemBackground` (storyboard + any code) and stop relying on translucent gradients to "darken" white; give section-header + cell text adaptive colors (contrast ≥ 4.5:1).
  - **(b) Light-only (critique-corrected, simpler + more complete):** set `UIUserInterfaceStyle = Light` in `Na'vi/Info.plist`. This is a one-line lock that **also** curbs the dark-mode launch flash (3.10) — which `overrideUserInterfaceStyle = .light` in code does **not** cover (the launch screen renders before code runs). Prefer the Info.plist key over the code override if going light-only.
  - A translucent gradient cannot convert a white base to dark, so "darken with the gradient" is not an option.
- **Verify:** In Dark Mode (adaptive path) root is dark and text legible; light-only path shows consistent light UI in both system modes and no white flash on cold launch.
- **Risk:** Medium — storyboard + styling manager + cells together.
- **Effort:** M.

### 3.2 Nav-bar title color frozen at launch appearance
- **Defect:** `setupGlassNavigationBar` is built once in `viewDidLoad` and snapshots a static title color; a live Light↔Dark switch never re-applies it, so the title stays its launch-time color (invisible after a flip).
- **Files:** `Na'vi/ViewStylingManager.swift:76-86`; `Na'vi/GlassUIHelper.swift:182-197` (`createGlassNavigationAppearance`, static `glassPrimaryTextColor`).
- **Fix:** Re-invoke `setupGlassNavigationBar` from the dictionary's trait-change path (`NDDictionaryMainViewController.swift:58-60` already fires `setColoursToInterfaceStyle`), or build `titleTextAttributes` from a `UIColor(dynamicProvider:)`. If 3.1 chooses light-only, this collapses to a single static light color.
- **Verify:** Toggle iOS Light↔Dark while the dictionary is open → the "Na'vi-English" title stays legible.
- **Risk:** Low.
- **Effort:** S.

### 3.3 iOS 15+ default section-header top padding → empty band above every header
- **Defect:** Plain-style table with custom headers never sets `sectionHeaderTopPadding`, so iOS 15+ inserts ~22pt above all ~23 headers (a gap versus the iOS-11-era design).
- **Files:** `Na'vi/NDDictionaryMainViewController.swift:137-141`.
- **Fix:** Set `tableView.sectionHeaderTopPadding = 0` in `viewDidLoad` (or in `ViewStylingManager.setupDictionaryGlassUI`).
- **Verify:** No ~22pt gap above headers or between the nav bar and the first `a` header.
- **Risk:** Low.
- **Effort:** S.

### 3.4 Na'vi collation: `ä`/`ì` sort after Z at both section and intra-section level
- **Defect:** Section sort and intra-section sort use scalar `navi.uppercased() <`, and `Ä(U+00C4)`/`Ì(U+00CC) > Z(U+005A)`. Section level strands 15 entries; intra-section scatters **872** words (~33% — e.g. all `tì-`/`nì-` blocks land at the end of their section).
- **Files (critique-corrected — two sort sites only):** `Na'vi/NDDictionary.swift:83` (section sort) and `:86` (within-section sort). **Do not touch `:90-95`** — `sectionIndices` is a **derived `map`** over the already-sorted sections, not a sort; fixing `:83` makes it correct automatically, and re-sorting it independently would **desync** the A–Z bar from the section order and can push `sectionTitles[section]` out of range. Note: the live path is `classifyDictionaryV2` (called from `init:31`); `classifyDictionary()` / `:52-68` is dead — ignore it.
- **Fix:** Introduce one Na'vi-aware comparator — build a collation key by mapping each character to its rank in an explicit alphabet (`ä` immediately after `a`, `ì` immediately after `i`) and compare keys, or walk scalar-by-scalar against a rank table. Apply the **same** comparator at `:83` and `:86`. Confirm canonical order + digraph handling in Decisions before writing it.
- **Verify:** `äo/ätxäle/…` appear right after the `a` words and the index reads `…A, Ä…`; inside section T the `tì-` words interleave at "ti", not after `tu-`.
- **Risk:** Medium — `:83` and `:86` must ship **together**; fixing only the section level leaves 872 intra-section words visibly misordered.
- **Effort:** M.

### 3.5 Part-of-speech labels show raw codes for 146 entries
- **Defect:** The `partOfSpeech` switch's compound cases only match trailing-space forms the 2022 `vocabulary.json` never contains; the interrogative case is `"inter"/"inter "` not the data's `"inter."`; `"adp."`/`"dem."` have no case. 146 of 2678 entries fall through to `default` and show the raw code.
- **Files:** `Na'vi/NDDictionaryEntry.swift:18-76`.
- **Fix:** Normalize before switching — `partOfSpeechShort.trimmingCharacters(in: .whitespaces)` — collapsing `.` vs `. ` variants; add missing `"inter."`, `"adp."`, `"dem."` cases and reversed compounds (e.g. `"vin., vtr."`).
- **Verify:** Interrogatives (57), adpositions (48, e.g. `ìlä`), and compound-POS words render full names, not raw codes.
- **Risk:** Low.
- **Effort:** S.

### 3.6 Search fails for apostrophe words (smart quotes vs straight `'`)
- **Defect:** The search field disables autocorrect/spell-check but leaves smart quotes on, so a typed apostrophe becomes `U+2019` and never matches the straight `U+0027` used by 452 entries (16.9%).
- **Files:** `Na'vi/Dictionary.storyboard:159` (`textInputTraits`); matcher `Na'vi/NDDictionaryMainViewController.swift:186-188`.
- **Fix:** Add `smartQuotesType="no"` (and `smartDashesType="no"`) to the search field's `textInputTraits`, **and** normalize curly→straight in `searchText` before matching (`replacingOccurrences(of: "\u{2019}", with: "'")`) as belt-and-suspenders.
- **Verify:** With iOS Smart Punctuation on, typing `'awkx` or `'ä'` returns the entry.
- **Risk:** Low.
- **Effort:** S.

### 3.7 Search state desync on end-editing → latent crash + reload/scroll jank
- **Defect (critique-corrected — severity raised):** `searchBarShouldEndEditing` resets `dictionaryItems` to the full list **without** updating `sectionTitles` or reloading. `numberOfSections` returns `dictionaryItems.count` while `viewForHeaderInSection` reads `sectionTitles[section]` (`:139`) — on the next `reloadData` these lengths disagree and the subscript can **trap**. Portrait-lock (`Na'vi/Info.plist`) masks it today, but it is a **latent crash, not cosmetic**, so the fix is **required, not optional**. Separately, every keystroke does a full `reloadData()` + animated `scrollToRow` (`:87-95`, `:148-150`), causing flicker and scroll-fighting.
- **Files:** `Na'vi/NDDictionaryMainViewController.swift:152-157` (`searchBarShouldEndEditing`), `:87-95` (`updateDictionaryData`), `:148-150` (`textDidChange`).
- **Fix:** Centralize search-state reset into one method that **always** refreshes `sectionTitles` and calls `reloadData()` consistently (call it from `shouldEndEditing`, `cancelButtonClicked`, and the empty-text path). Scroll to top only when the result set actually changes, with `animated: false`; optionally debounce the filter.
- **Verify:** Cancel/blur with text present → list + A–Z index are consistent immediately and no crash on the subsequent reload; typing a multi-letter query shows no flicker or scroll-fighting.
- **Risk:** Medium (latent trap on the cancel/blur path — treat as a crash fix, not polish).
- **Effort:** M.

### 3.8 Audio: overlapping playback + `AVAudioSession` never deactivated
- **Defect:** Each cell owns its own `AVAudioPlayer` with no cross-cell stop, so two visible rows play at once; `setActive(true)` runs on every tap and is never deactivated, so it keeps ducking the user's music.
- **Files:** `Na'vi/NDDictionaryMainTableViewCell.swift:137-142` (`setCategory(.playback)` + `setActive(true)`; per-cell player), `:77-78` (`prepareForReuse` stops).
- **Fix (critique-corrected — ownership):** Route playback through a **shared audio controller** (a singleton/static owner), not the cell. That controller owns the single player, stops the current clip before starting a new one, is the `AVAudioPlayerDelegate`, and on `audioPlayerDidFinishPlaying` calls `setActive(false, options: .notifyOthersOnDeactivation)`. **Do not** make the reused cell the delegate — cells are recycled mid-playback and `prepareForReuse` nils the player (`:77-78`), so a cell-owned delegate is unsafe.
- **Verify:** Tap play on two visible rows → only one plays; with background music playing, music resumes after the clip ends.
- **Risk:** Low-Medium.
- **Effort:** M.

### 3.9 Deprecated `UIAlertView` on the mail-error path (only occurrence in repo)
- **Defect:** `showSendMailErrorAlert` builds a `UIAlertView` (deprecated since iOS 9); its legacy presentation is unreliable over scene-based windows on iOS 18, so the mail-not-configured error may silently fail to appear.
- **Files:** `Na'vi/MainViewController.swift:55-58`. (The catalogue misattributed this to `UIDevice.swift`; `MainViewController.swift:56` is the only `UIAlertView` in the repo.)
- **Fix:** Replace with `UIAlertController(…, preferredStyle: .alert)` + OK action, presented from `self`.
- **Verify:** On a device with Mail unconfigured, tap the feedback/email button → the error alert appears.
- **Risk:** Low.
- **Effort:** S.

### 3.10 Launch screen is a leftover dictionary skeleton (dead white search bar)
- **Defect:** `UILaunchStoryboardName` points at an early dictionary-screen copy: cold launch renders an inert gray "Look up" `UISearchBar` on a hardcoded-white screen with no dark variant (a white flash in Dark Mode).
- **Files:** `Na'vi/Base.lproj/LaunchScreen.storyboard` (search bar id `K44-uK-gKp`, white bg at line ~33, dead outlets); referenced by `Na'vi/Info.plist:27-28`.
- **Fix:** Replace with a minimal branded launch screen (title/logo centered on `systemBackground`), removing the search bar and dead outlets. Note: if 3.1 goes light-only via `UIUserInterfaceStyle = Light` in Info.plist, the flash is already curbed; still remove the stray search bar.
- **Verify:** Cold launch shows a clean branded screen (no white flash in Dark Mode if adaptive, no gray search bar).
- **Risk:** Low.
- **Effort:** S.

### 3.11 Empty 30pt band above the keys (reserved banner never filled)
- **Defect:** `keyboardHeight` is set `withTopBanner: true` (adds `topBanner = 30`), but `forwardingView` — which holds the keys and the glass — is sized `withTopBanner: false` (`:233`) and pinned to the bottom, while the banner is disabled (`createBanner` returns `nil`; `loadView` banner code commented). The top 30pt is never covered.
- **Files (critique-corrected — two call sites):** `Keyboard/KeyboardViewController.swift:266` (`viewWillAppear`) **and** `:281` (`willRotate`) both pass `withTopBanner: true`; `:233` already uses `false`.
- **Fix:** Set `withTopBanner: false` at `:266`. The second site (`:281`) lives in `willRotate`, which iOS 13+ never calls — it is removed and replaced by the 3.12 rotation rewrite, so **fold the band fix into 3.12**: wherever the rewrite recomputes `keyboardHeight` (in `viewDidLayoutSubviews`), pass `withTopBanner: false`. Setting only `:266` and leaving a live `:281` would re-add the band on rotation; here `:281` is dead, so the durable fix is 3.12 using `false`. **Coupling:** if 0.2 places glass on `self.view` full-height, that is an *alternative* way to cover the band visually — pick **one** coherent approach, do not half-apply both.
- **Verify:** No transparent gap between host content and the glass keyboard, all devices/orientations, before and after rotation.
- **Risk:** Low-Medium — changes overall keyboard height; retest sizing after 0.2 and alongside 3.12.
- **Effort:** S.

### 3.12 Deprecated orientation APIs → wrong landscape height / no rotation relayout
- **Defect:** `heightForOrientation` relies on `self.interfaceOrientation` (deprecated, unreliable in extensions), and `willRotate`/`didRotate` are deprecated and **not called on iOS 13+**, so rotation never updates height/relayout.
- **Files:** `Keyboard/KeyboardViewController.swift:233,:266,:281` (`interfaceOrientation`), `:269` (`willRotate`), `:284` (`didRotate`).
- **Fix (critique-corrected — API):** Do **not** use `viewWillTransition(to:with:)`. This controller's own bug note at `:305-313` documents "None of the UIContentContainer methods are called for this controller," and `viewWillTransition` is a `UIContentContainer` method — it will not fire. The reliable signal for a keyboard extension is `viewDidLayoutSubviews` + `self.view.bounds.width` (already used at `:233`). Recompute height/relayout there, derive orientation/size from `self.view.bounds`/trait collection (not `interfaceOrientation`), pass `withTopBanner: false` (see 3.11), and move the `resetTrackedViews`/rasterize logic out of the dead `willRotate`/`didRotate` (which can be deleted). Verify **on-device** that the chosen hook actually fires before trusting it.
- **Verify:** Rotate to landscape → keyboard uses correct landscape height and relays out; rotate back → correct portrait height; no 30pt band in either.
- **Risk:** Medium — sizing path; test both orientations and re-presentation on a real device.
- **Effort:** M.

### 3.13 Letter keycap case computed by three conflicting formulas
- **Defect:** `characterUppercase` is derived three inconsistent ways, so the visible case flips depending on which path last ran (keypress vs relayout).
- **Files:** `Keyboard/KeyboardViewController.swift:240` (correct: `kSmallLowercase ? uppercase : true`), `:636` (buggy: `kSmallLowercase ? !uppercase : uppercase`), `:652` (`= uppercase`, unconditional).
- **Fix:** Use the canonical `kSmallLowercase ? uppercase : true` at all three sites (change `:636` and `:652` to match `:240`). Verified this restores the legacy always-uppercase-when-`kSmallLowercase`-off behavior and is safe at all three sites.
- **Verify:** With default settings, letter caps stay uppercase across first layout, a keypress, a mode switch, and a rotation (no flip); with `kSmallLowercase` on, caps follow shift correctly.
- **Risk:** Low-Medium — verify after 0.2/3.11/3.12 since it rides the same layout path.
- **Effort:** S.

### 3.14 Shift/Backspace glyphs hardcoded white → invisible in light mode
- **Defect:** Shift and Backspace assign glyph color unconditionally to `darkModeTextColor` (pure white), so at rest they render white-on-light-gray and look blank until pressed.
- **Files:** `Keyboard/KeyboardLayout.swift:537` (shift), `:544` (backspace); `darkModeTextColor` white at `:183`.
- **Fix:** Make them conditional like the other cases: `key.textColor = (darkMode ? globalColors.darkModeTextColor : globalColors.lightModeTextColor)` at `:537` and `:544`.
- **Verify:** In default (light) appearance, the shift up-arrow and backspace delete-arrow are dark and visible at rest.
- **Risk:** Low.
- **Effort:** S.

### 3.15 Keyboard dark-mode source-of-truth mismatch (no refresh)
- **Defect:** `setupGlassKeyboardBackground` uses adaptive `.systemThickMaterial` (follows the *system*) while tint + key colors use `darkMode()` = `textDocumentProxy.keyboardAppearance` (host-driven). The two can disagree, and the per-frame poller is the only refresh.
- **Files:** `Keyboard/KeyboardViewController.swift:194-209` (blur), `:212-219` (`darkMode()`); `Keyboard/KeyboardInputTraits.swift:31-40` (`pollTraits`).
- **Fix (critique-corrected — API):** Make `keyboardAppearance` (`darkMode()`) the single source of truth — pick the blur style from `darkMode()` rather than the adaptive material, so background and keys agree. **Refresh is not via `traitCollectionDidChange`/`registerForTraitChanges`:** `keyboardAppearance` is **not** a `UITrait` and is not KVO-able (the code says so at `KeyboardInputTraits.swift:25`), and host-driven changes never fire trait callbacks. Keep detecting it via the (now-fixed, see 3.16) poll, or read it in `viewWillAppear` + `textDidChange`. Pair this with the 3.16 rewrite.
- **Verify:** System Dark + a host that doesn't set `keyboardAppearance` → background and keys agree (no dark blur under light low-contrast keys); switching host appearance updates both.
- **Risk:** Low-Medium.
- **Effort:** M.

### 3.16 Trait-polling `CADisplayLink` leaks the keyboard VC + fires every frame
- **Defect:** A module-global `traitPollingTimer` `CADisplayLink` is created via `UIScreen.main.displayLink(withTarget: self, …)` (strong target, iOS-16-deprecated) and stored globally; `deinit` invalidates only the two backspace timers, so the link retains the VC forever and `pollTraits` runs every frame after dismissal (a leak + battery/jetsam risk in a memory-constrained extension).
- **Files:** `Keyboard/KeyboardInputTraits.swift:20` (global), `:24-29` (creation), `:31-40` (`pollTraits`); `Keyboard/KeyboardViewController.swift:121-126` (`deinit`).
- **Fix (critique-corrected — the plan's fallback becomes the primary fix):** Do **not** replace the poll with `registerForTraitChanges`/`traitCollectionDidChange` — those cannot observe `keyboardAppearance` (see 3.15) and would silently regress host-driven dark keyboards. Instead: make `traitPollingTimer` an **instance** property with a **weak-proxy** target (so the link no longer retains the VC), and `invalidate()` + `nil` it in `deinit`. Keep the poll running while the keyboard is live (or move detection to `viewWillAppear` + `textDidChange` reads if you want to drop the per-frame cost). This keeps host-driven appearance detection working while fixing the leak.
- **Verify:** Instruments (Allocations/Leaks) — open then dismiss the keyboard; `KeyboardViewController` deallocates (`deinit` runs) and `pollTraits` stops; console shows no per-frame activity after dismissal; host-driven dark/light still updates.
- **Risk:** Medium — appearance-refresh path; retest dark/light switching (ties to 3.15).
- **Effort:** M.

---

## Phase 4 — Security, cleanup, hygiene

### 4.1 Committed unused Firebase `GoogleService-Info.plist` (client API key)
- **Defect (critique-corrected — severity/remedy):** `GoogleService-Info.plist` contains an `AIzaSy…` client Firebase key, but **no** Firebase/Google SDK is imported and the `Podfile` declares no pods (verified) — the key is unused. Firebase client API keys are **designed to ship inside client apps**, restricted by bundle ID + security rules; they are not server secrets. This is hygiene, not an emergency.
- **Files:** `GoogleService-Info.plist`; `Podfile` (empty).
- **Fix:**
  1. **Remove the file** from the working tree (no functional loss).
  2. In the Google/Firebase console, **add a bundle-ID application restriction** to the key (or confirm it is not left unrestricted). Rotation is optional given it is an unused, restrictable client key.
  3. **First verify the remote is actually public** (`git remote -v`; the catalogue notes `github.com/cqin5/The-Na-vi-Kit`) before treating exposure as urgent.
  4. A full `git filter-repo`/BFG history rewrite + force-push is **destructive** (breaks clones/forks) and is **likely unwarranted** here — treat it as **optional and maintainer-authorized only**, not a default step. Removing the file from the tree + restricting the key is the proportionate fix.
- **Verify:** File gone from the working tree; key carries a bundle-ID restriction in GCP; if the (optional) history rewrite is authorized, `git log --all -- GoogleService-Info.plist` is empty afterward.
- **Risk:** Low for the tree-removal + restriction; Medium and destructive only if the optional history rewrite is chosen.
- **Effort:** S (tree + restriction) / M (only if history rewrite is authorized).

### 4.2 Orphan `Keyboard/Info.plist` + dead Swift-2 `Na'vi Keyboard/` sources
- **Defect:** `Keyboard/Info.plist` (principal class `${PRODUCT_MODULE_NAME}.Navi_Keyboard` — does not exist) is referenced by **no** target. The `Na'vi Keyboard/*.swift`/`.storyboard` are dead Swift-2 (in no Sources phase — verified). **Hazard:** `Na'vi Keyboard/Info.plist` **is** the shipping keyboard's `INFOPLIST_FILE` (pbxproj `:11328/:11356`).
- **Files:** `Keyboard/Info.plist` (orphan), `Na'vi Keyboard/*.swift` + `Keyboard.storyboard` (dead), `Na'vi Keyboard/Info.plist` (**live — keep**).
- **Fix (critique-corrected — minimal, low-risk; relocation removed):** Delete **only** the true orphan `Keyboard/Info.plist` and the dead `Na'vi Keyboard/*.swift`. **Leave the `Na'vi Keyboard/` folder and its shipping `Info.plist` in place** — do **not** relocate it or repoint `INFOPLIST_FILE` (fiddly, high-risk, near-zero benefit). Drop `Keyboard.storyboard`/`.xib` **only after** confirming they are in no build phase. Prune the corresponding stale `PBXFileReference`/`PBXBuildFile` group entries for the files you delete.
- **Verify:** App + keyboard still build and archive; `git grep Navi_Keyboard` returns nothing; the keyboard's `INFOPLIST_FILE` path still resolves.
- **Risk:** Low (with relocation removed — the shipping plist is untouched).
- **Effort:** S.

### 4.3 Dead "performance" helpers from the Dec 2025 commit
- **Defect:** Unused glass/perf helpers with zero call sites; `IMPROVEMENTS.md` perf claims are unmeasured.
- **Files (critique-corrected — split by ship status):** `Na'vi/GlassUIHelper.swift`. **Release-shipping dead helpers** (delete these): `createGlassCard`, `applyGlassEffect`, `optimizeForPerformance`, `removePerformanceOptimizations`, `reduceBlurDuringScroll`, `restoreBlurAfterScroll`, `createGlassBackground`, `glassAccent`. **`#if DEBUG`-only (never ship, safe to delete too):** `measureFPS`/`countFrame`, `logMemoryUsage`, `start|endPerformanceTimer` (`measureFPS` captures its counter by value and always reports ~0).
- **Fix:** Delete the unused helpers; do not wire `measureFPS`.
- **Verify:** Build succeeds after deletion (confirms no hidden call sites).
- **Risk:** Low.
- **Effort:** S.

### 4.4 Debug `print("🦁🦁🦁🦁")` on every shift-key cap update
- **Defect:** An unconditional `print` in the shift branch runs on every layout, mode change, shift toggle, and `setCapsIfNeeded` (i.e. every keystroke), on the main thread in the latency-sensitive keypress path.
- **Files:** `Keyboard/KeyboardLayout.swift:474`.
- **Fix:** Delete the `print`.
- **Verify:** Device console shows no lion emoji during typing.
- **Risk:** None.
- **Effort:** S.

---

## Decisions the maintainer must make

- **Light-only vs full Dark support (3.1 → 3.2, 2.3, 3.10).** Fast path: `UIUserInterfaceStyle = Light` in `Na'vi/Info.plist` (one line; also kills the launch flash in 3.10 and de-risks re-enabling the definition screen; prefer this over the code-only `overrideUserInterfaceStyle`). Correct path: adaptive `systemBackground` roots + legible dark colors. Pick one before touching the storyboard/cells — it is the parent of 3.2 and the cell/nav colors.
- **Restore the definition detail screen (2.3) vs stay inline-only.** Nav plumbing already works; the only prerequisite is making `NDDefinitionViewController` legible in the chosen appearance. If the inline cell already shows everything, deleting the dead `didSelectRowAt` code + `NDDefinitionViewController` is a valid alternative.
- **Settings panel (2.2).** Two options only: **re-add the gear key** to the crowded row 3, or **drop the settings feature**. (Moving settings into the container app is **not** viable without an App Group + Full/Open Access.)
- **Globe long-press picker (2.1).** Accept **short-tap-only** advance (simple, works today), or invest in routing the globe's real UIKit events outside `ForwardingView` to enable the system picker. The absent-globe fix (add unconditionally + rebuild/show-hide at the VC level) is required either way and is **L** effort.
- **Full Access (yes/no).** No longer required for key clicks (2.4 uses `playInputClick()` without it). Full Access is now only relevant if you want an App Group to sync keyboard settings with the container app (which would also change the 1.4 privacy reason code from `CA92.1` to `1C8F.1`). Default recommendation: keep `RequestsOpenAccess=false`.
- **Na'vi collation order (3.4).** Confirm the canonical sequence (plan assumes `ä` immediately after `a`, `ì` immediately after `i`) and whether digraphs (`kx, tx, ng, px, ts`) need special ordering, before writing the comparator applied at `:83`/`:86`.
- **Firebase key (4.1).** Approve removing the file + adding a bundle-ID restriction (proportionate). Separately decide whether the destructive history rewrite/force-push is warranted — default is **no** for an unused, restrictable client key.
- **Minimum iOS deployment target.** Dropping `armv7` (1.6) implies arm64-only. The target gates API choices used above: `sectionHeaderTopPadding` (iOS 15), `UIInputViewAudioFeedback`/`playInputClick` (long-available). Commit history says "iOS 18.0+"; confirm.
- **Catboard easter egg.** `Keyboard/Na'vi Keyboard.swift` defines `class Catboard: KeyboardViewController` (compiled but **not** the principal class — `NSExtensionPrincipalClass = KeyboardViewController`). Keep as a dormant curiosity or delete with Phase 4.

---

## Test & release checklist

- **Build/validate (all validation-time only — verify together at archive):** archive the `Eywa` app + keyboard; run Xcode **Validate**. Confirm extension and app `MARKETING_VERSION` match (1.3); marketing icon `hasAlpha == no` (1.5); a `PrivacyInfo.xcprivacy` is bundled in each target (1.4); no `armv7` capability (1.6). None of these block the simulator build.
- **Device matrix:** a **2436-pt phone** (iPhone XS / 11 Pro) for the globe key (2.1); a newer notched phone (non-2436); an older/SE-class phone; an iPad; plus an iOS 18 simulator for quick loops. Rotation tests (3.12) must be **on-device** (confirm the hook fires).
- **Keyboard functional pass (after 0.2):** in Messages, Safari address bar, and a `.words` name field — type every key type; drag a finger off a letter (1.1, no crash); focus an empty `.words` field with cursor at start (1.2, no crash); backspace tap + hold-repeat; globe short-tap cycles keyboards (2.1); gear opens settings if restored (2.2); Clicks make sound with `RequestsOpenAccess=false` (2.4). Confirm no lion emoji in console (4.4).
- **Keyboard appearance/layout:** Light and Dark hosts + live host toggle (3.15/3.16); shift + backspace glyphs visible at rest in light (3.14); no 30pt band before **and after** rotation (3.11/3.12); keycap case stable across keypress/mode/rotation (3.13).
- **Dictionary:** Dark and Light + live toggle — legible roots, section headers, nav title (3.1/3.2); no header top-gap (3.3); `ä/ì` words and the A–Z index in correct order (3.4); POS labels expanded, spot-check `inter.`/`adp.`/compound (3.5); search apostrophe words with Smart Punctuation on (3.6); **cancel/blur search with text present does not crash** and leaves a consistent list/index, and typing is jank-free (3.7); play two rows → no overlap and background music resumes (3.8); mail-unconfigured error alert shows (3.9); cold-launch screen is clean, no white flash in Dark (3.10).
- **Memory:** Instruments Leaks/Allocations — keyboard `deinit` runs on dismissal, polling stops, and host-driven dark/light still updates (3.16/3.15).
- **Security/cleanup:** `GoogleService-Info.plist` removed from tree and the key restricted (4.1); app + keyboard still build/archive after dead-file cleanup with the shipping `Na'vi Keyboard/Info.plist` untouched (4.2/4.3).

---

## Interactions & ordering hazards

- **0.2 gates all keyboard testing.** Until the glass overlay stops swallowing touches, none of 1.1, 1.2, 2.1, 2.2, 3.11, 3.13, 3.14, or key sounds can be verified — no key fires. Do 0.2 first.
- **Crashes before exploratory keyboard testing.** Fix 1.1 (drag-off) and 1.2 (`.words` empty context) before the manual keyboard pass.
- **0.2 ↔ 3.11 ↔ 3.12 ↔ 3.15 are one design.** Where the glass lives (`self.view` full-height vs behind keys), whether the 30pt band exists, how rotation recomputes height, and which appearance source drives the blur are coupled. Decide glass placement once (0.2), pass `withTopBanner: false` in the 3.12 rotation rewrite (which subsumes the dead `:281` band site), and let the blur follow `keyboardAppearance` (3.15). Do not half-apply the band fix.
- **3.12 must not use `viewWillTransition`.** The controller's bug note (`:305-313`) confirms `UIContentContainer` methods never fire; recompute in `viewDidLayoutSubviews` and verify on-device.
- **3.15/3.16 must keep the poll (or explicit reads).** `keyboardAppearance` is not a trait/KVO; `registerForTraitChanges` would regress host-driven dark keyboards. The 3.16 fix is instance-property + weak-proxy + `deinit` invalidation, not a trait-callback swap. (`registerForTraitChanges` **is** correct for the dictionary app's 3.1/3.2, where the signal is the real system `userInterfaceStyle` trait; note `traitCollectionDidChange` is soft-deprecated on iOS 17+, prefer `registerForTraitChanges` there.)
- **3.4 fixes exactly two sites.** Section sort (`:83`) and within-section sort (`:86`) share the broken scalar comparator and must ship together; `:90-95` is a derived map — leave it untouched, or the A–Z index desyncs and can trap.
- **2.3 depends on the 3.1 decision.** Don't re-enable `didSelectRowAt` navigation until `NDDefinitionViewController` is legible in the chosen appearance; the nav plumbing itself is already complete.
- **3.1 is the parent of 3.2 and the cell colors.** Choose adaptive-`systemBackground` vs light-only first; light-only (via the Info.plist key) collapses much of 3.2/3.10.
- **2.1 needs re-evaluation, not a one-shot check, and is L not M.** `defaultKeyboard()` is a free function built once in `init` and cannot read `needsInputModeSwitchKey`; add the globe unconditionally and rebuild/show-hide at the VC level on `viewWillAppear`/input-mode change.
- **2.4 removes a Full-Access dependency.** Switching to `playInputClick()` means clicks no longer force the Full-Access decision; keep `RequestsOpenAccess=false` unless an App Group is separately wanted.
- **4.2 plist hazard.** `Na'vi Keyboard/Info.plist` is the shipping `INFOPLIST_FILE`. Delete only the orphan `Keyboard/Info.plist` and the dead `.swift`; leave the `Na'vi Keyboard/` folder and its plist in place (no relocation).
- **1.3–1.6 batch at archive.** Version parity, privacy manifest, icon alpha, and armv7 surface only at validation — fix and verify them in one archive pass.
- **4.1 is hygiene, not an emergency.** Remove the unused client key file + restrict by bundle ID; treat the history rewrite/force-push as optional and maintainer-authorized only.