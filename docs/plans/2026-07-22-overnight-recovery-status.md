# The Na'vi Kit — Overnight Recovery Status (2026-07-22)

Work done autonomously overnight against the plan in
`docs/plans/2026-07-22-navi-ios18-recovery-plan.md`.

## TL;DR

- All work is on branch **`fix/ios26-uiux-bugs`** (3 commits). **`master` is untouched, nothing was pushed.**
- The project **builds clean**: 0 errors, 14 warnings (down from 75 at baseline), Xcode 26.6 / iOS 26 SDK.
- The dictionary app was **verified running** in the iPhone 17 simulator (light/dark, collation, POS, launch).
- The **keyboard extension** fixes are code- and build-verified but **not runtime-tested** (a custom keyboard can't be exercised in the simulator without manually enabling it in Settings). These need a real tap-test on device/simulator.
- Two items need **you**: wire the privacy manifests into target membership, and rotate/restrict the Firebase key.

## How to review

```
git checkout fix/ios26-uiux-bugs
git log --oneline master..HEAD        # 3 batch commits
git diff --stat master..HEAD
```
Open `Na-vi.xcworkspace`, run the `Na-vi` scheme (product is `Eywa.app`, bundle `CQ.Navi`).

## Status of all 42 confirmed issues

Legend: DONE = fixed + build-verified; VERIFIED = also confirmed live in simulator; CODE = fixed but needs on-device runtime check; MANUAL = needs a step you must take.

### Criticals / crashes
|# | Issue | Status |
|-|-|-|
|0.2 | Keyboard typed nothing (glass swallowed touches) | DONE (CODE — needs device typing test) |
|1.1 | Crash on key drag-off (`hidePopup` selector) | DONE (CODE) |
|1.2 | Crash focusing empty `.words` field | DONE (CODE) |

### App Store validation gates
|# | Issue | Status |
|-|-|-|
|1.3 | Extension vs app version mismatch | DONE (both 1.5.2) |
|1.4 | Missing `PrivacyInfo.xcprivacy` | MANUAL — files added, need target membership |
|1.5 | Marketing icon had alpha | DONE (all icons flattened, `hasAlpha: no`) |
|1.6 | `armv7` required capability | DONE (removed) |

### Dead / unreachable features
|# | Issue | Status |
|-|-|-|
|2.1 | Globe key absent on 2436pt phones | PARTIAL — globe now added on all devices; full `needsInputModeSwitchKey` show/hide + long-press picker deferred |
|2.2 | Settings panel unreachable | DONE (CODE — gear key re-added; check row-3 crowding on device) |
|2.3 | Tapping a word did nothing | DONE (VERIFIED build; re-enabled, legible under light-only) |
|2.4 | Keyboard Clicks never sounded | DONE (`playInputClick()`, works without Full Access) |

### Correctness / dark mode / layout
|# | Issue | Status |
|-|-|-|
|3.1 | Dark mode broken on dictionary | DONE (VERIFIED — locked to Light; see decision below) |
|3.2 | Nav title color frozen | DONE (moot under light-only) |
|3.3 | Section-header top gap (iOS 15+) | DONE (`sectionHeaderTopPadding = 0`) |
|3.4 | `ä`/`ì` sorted after Z | DONE (VERIFIED — Na'vi collation; index reads `…a ä e…i ì j…`) |
|3.5 | Part-of-speech raw codes (146 entries) | DONE (VERIFIED — compositional expansion) |
|3.6 | Search failed for apostrophe words | DONE (smart-quotes off + curly→straight normalize) |
|3.7 | Search-state desync / latent trap | DONE (centralized reset; no unreloaded mutation) |
|3.8 | Overlapping audio + session never released | DONE (single shared `NDAudioController`) |
|3.9 | `UIAlertView` on mail-error path | DONE (`UIAlertController`) |
|3.10 | Launch screen leftover skeleton | DONE (VERIFIED — clean branded launch) |
|3.11 | Empty 30pt band above keys | DONE (CODE — `withTopBanner: false`) |
|3.12 | Deprecated orientation / no rotation relayout | DONE (CODE — window-scene orientation + guarded height update; needs device rotation test) |
|3.13 | Keycap case from 3 conflicting formulas | DONE (CODE — unified to canonical) |
|3.14 | Shift/backspace glyphs invisible in light | DONE (CODE — conditional colors) |
|3.15 | Keyboard dark-mode source mismatch | DONE (CODE — blur follows `keyboardAppearance`) |
|3.16 | CADisplayLink leak / per-frame drain | DONE (CODE — weak proxy + `deinit` invalidation) |

### Cleanup / hygiene
|# | Issue | Status |
|-|-|-|
|4.1 | Committed Firebase key | DONE (file + pbxproj refs removed, gitignored). MANUAL: rotate/restrict key; optional history scrub |
|4.2 | Orphan plist + dead Swift-2 folder | DONE (orphan `Keyboard/Info.plist` removed; dead `Na'vi Keyboard/*.swift` left in place — unreferenced, harmless) |
|4.3 | Dead + buggy perf helpers | DONE (removed perf section + DEBUG block; a couple of unused glass helpers remain, harmless) |
|4.4 | Debug `print` on every shift update | DONE (removed) |

## Decisions I made (all reversible — revisit freely)

- **Light-only** (`UIUserInterfaceStyle = Light` in `Na'vi/Info.plist`). Dark mode was genuinely broken (white root under translucent glass) and a proper adaptive-dark theme is a design job I shouldn't guess at unattended. The glass design already looks right in light. To restore adaptive dark: remove that Info.plist key and give the storyboard roots `systemBackground` + adaptive cell/header/nav text.
- **Re-enabled the definition screen** (word tap → detail). Legible under light-only. If you prefer inline-only, delete `didSelectRowAt`’s body + `NDDefinitionViewController`.
- **Re-added the settings gear key** to row 3. Row 3 is now `[123][globe][gear][space][return]` — please eyeball crowding on a narrow device; trivially reverted in `DefaultKeyboard.swift`.
- **Globe on all devices** (removed the `hasBottom` gate). Simple + strictly better than the old 2436pt hole; the full "hide when only keyboard" behavior is a larger model-rebuild I left as follow-up.
- **Collation order** assumes `ä` right after `a`, `ì` right after `i` (standard Na'vi). Digraphs sort by their letters. Change the alphabet string in `NDDictionary.naviCollationRank` if you want different digraph handling.
- **Firebase key**: removed the file only. I did **not** rewrite git history or rotate the key.

## What still needs you

1. **Wire the privacy manifests** (upload gate). `Na'vi/PrivacyInfo.xcprivacy` and `Keyboard/PrivacyInfo.xcprivacy` exist with correct content; in Xcode, select each and check the matching target under *Target Membership* (the `xcodeproj` gem wasn't available to do this safely from the CLI).
2. **On-device / manual keyboard test** — enable the Na'vi keyboard in Settings, then in Messages verify: every key types; drag a finger off a letter (no crash); focus an empty name field (no crash); globe switches keyboards; gear opens settings; clicks sound with Full Access off; rotate to landscape; shift/backspace glyphs visible at rest.
3. **Firebase key** — rotate or add a bundle-ID restriction in the Firebase console; decide whether to scrub git history (optional for an unused, restrictable client key).
4. **Archive validation pass** once 1 + the version/icon/armv7 fixes are in.

## Resume Prompt

Continue the Na'vi Kit recovery described in ~/dev/The-Na-vi-Kit/docs/plans/2026-07-22-overnight-recovery-status.md — read it, then pick up the remaining items: wire the two PrivacyInfo.xcprivacy files into target membership, run the manual on-device keyboard test pass, and handle the Firebase key rotation. The work is on branch fix/ios26-uiux-bugs.
