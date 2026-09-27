#!/usr/bin/env python3
"""
Pre-flight checks for The Na'vi Kit.

Covers the things that can go wrong without Xcode noticing until an archive is
rejected or a device misbehaves: project file integrity, the scene-based app life
cycle that the iOS 27 SDK requires, the launch screen, App Store property list
keys, privacy manifests, the App Store icon, target membership, deprecated and
legacy API in the sources that are actually compiled, any Interface Builder
files still bundled, bundle contents — the vocabulary the app cannot work
without, and files that nothing reads at run time — and the vocabulary entries
themselves. It also checks the NaviGrammar package: that the app links it, that it
stays free of UIKit and SwiftUI, and that its lexicon is intact.

Run from the project root, or via ./build-verify.sh.
"""

from __future__ import annotations

import pathlib
import plistlib
import re
import sys

PROJECT = pathlib.Path("Na-vi.xcodeproj/project.pbxproj")
APP_INFO = pathlib.Path("Na'vi/Info.plist")
KEYBOARD_INFO = pathlib.Path("Na'vi Keyboard/Info.plist")
PRIVACY_MANIFESTS = [
    pathlib.Path("Na'vi/PrivacyInfo.xcprivacy"),
    pathlib.Path("Na'vi Keyboard/PrivacyInfo.xcprivacy"),
]
APP_ICON_SET = pathlib.Path("Na'vi/Assets.xcassets/AppIcon.appiconset")

# The app saves the keyboard's settings in an App Group, and the keyboard reads
# them from it. If the two targets' entitlements, or the group the code names,
# differ, the keyboard keeps its defaults and nothing says why.
ENTITLEMENTS = {
    "Eywa": pathlib.Path("Na-vi.entitlements"),
    "Na'vi Keyboard": pathlib.Path("Na-vi Keyboard.entitlements"),
}
KEYBOARD_SETTINGS = pathlib.Path("Keyboard/KeyboardSettings.swift")
APP_GROUPS_KEY = "com.apple.security.application-groups"
# The required reason for reading user defaults that an App Group shares.
APP_GROUP_DEFAULTS_REASON = "1C8F.1"

SOURCES_PHASES = {
    "Eywa": "A6AE8AEF1D1AD43E00345E2E",
    "Na'vi Keyboard": "A614201F1D1AD5DC001C0FBD",
}
RESOURCES_PHASES = {
    "Eywa": "A6AE8AF11D1AD43E00345E2E",
    "Na'vi Keyboard": "A61420211D1AD5DC001C0FBD",
}

VALID_SWIFT_VERSIONS = {"4.0", "4.2", "5.0", "6.0"}

# NDDictionary reads this at launch. A release build without it shows an empty
# dictionary instead of crashing, so nothing else would notice it had gone.
APP_VOCABULARY = "vocabulary.json"
VOCABULARY_FILE = pathlib.Path("Resources") / APP_VOCABULARY

# The keys NDDictionaryEntry decodes. One entry without them fails the whole file,
# and a release build then shows an empty dictionary.
VOCABULARY_FIELDS = ("Na'vi", "IPA", "Part of speech", "English", "Audio URL", "Audio local URL")
DICTIONARY_ENTRY = pathlib.Path("Na'vi/NDDictionaryEntry.swift")

# Stress underlining and sense separators from a flashcard export, which the app
# would show as literal text.
VOCABULARY_MARKUP = re.compile(r"</?u>|\s\|\s")

# Files no target reads at run time. The design file and the exports stay in the
# repository as source material; bundling them only adds to the download.
NEVER_BUNDLED = {
    r"\.sketch$": "a Sketch design file",
    r"\.csv$": "a spreadsheet export",
    r"^vocabulary-.+\.json$": "an old vocabulary export; the app reads only vocabulary.json",
    r"^GoogleService-Info\.plist$": "Firebase configuration, but no Firebase SDK is linked",
}

# Patterns that must not appear in a source file that is compiled into a target.
DEPRECATED_API = {
    r"\bUIAlertView\b": "UIAlertView — use UIAlertController",
    r"@UIApplicationMain\b": "@UIApplicationMain — use @main",
    r"\bUIScreen\.main\b": "UIScreen.main — use the window scene or trait collection",
    r"\bfunc traitCollectionDidChange\b": "traitCollectionDidChange — use registerForTraitChanges",
    r"\bself\.interfaceOrientation\b": "UIViewController.interfaceOrientation — removed in iOS 8",
    r"\barc4random": "arc4random — use Swift's random APIs",
    r"\.substring\(": "String.substring — use range subscripting",
    r"UIActivityIndicatorView\.Style\.white\b": "UIActivityIndicatorView.Style.white",
    r"\bshowsRouteButton\b": "MPVolumeView.showsRouteButton",
    r"\bfunc willRotate\(to": "willRotate(to:duration:) — use viewWillTransition(to:with:)",
    r"\bfunc didRotate\(from": "didRotate(from:) — use viewWillTransition(to:with:)",
    r"\bfunc didReceiveMemoryWarning\b": "an empty didReceiveMemoryWarning override",
    r"UIGraphicsBeginImageContext": "UIGraphicsBeginImageContext — use UIGraphicsImageRenderer",
    r"\bSelector\(\"": "a string Selector — use #selector so the compiler checks the method is @objc",
    r"\bprotocol\s+\w+\s*:\s*class\b": "a ': class' protocol constraint — use AnyObject",
    r"\bvar hashValue\b": "a hashValue requirement — implement hash(into:)",
    r"\bUIDevice\.current\.userInterfaceIdiom\b": "UIDevice idiom — use the trait collection",
    r"\bkeyboardFrameEndUserInfoKey\b": "manual keyboard frame handling — use view.keyboardLayoutGuide",
    r"\bAudioServicesPlaySystemSound\b": "a system sound, which plays only with Full Access, an option most people leave off — use UIDevice.current.playInputClick()",
    r"\[(\w+)\.index\(before: \1\.endIndex\)\]": "the character before endIndex, which traps on an empty string — use .last",
    r"^\s*print\(": "a debug print in shipping code",
}


# The keyboard asks for Full Access only to play haptics, and the app tells people
# that nothing they type leaves their device. Full Access would let the keyboard
# reach the network and read the pasteboard, so no keyboard source may do either.
KEYBOARD_PRIVACY = {
    r"^\s*(?:@\w+\s+)*import\s+(Network\w*|CFNetwork|WebKit|SafariServices|MultipeerConnectivity)\b": "a networking framework",
    r"\bURLSession\b": "URLSession",
    r"\bURLRequest\b": "URLRequest",
    r"\bNW(?:Connection|Listener|Browser|PathMonitor)\b": "a Network framework connection",
    r"\bCFStream\w*\b|\bgetStreamsToHost\b": "a socket stream",
    r"\bUIPasteboard\b": "the pasteboard",
}

# The grammar engine, a local Swift package the app links. It must stay free of
# UIKit and SwiftUI so that the keyboard extension can use it too.
GRAMMAR_PACKAGE = pathlib.Path("Packages/NaviGrammar")
GRAMMAR_PRODUCT = "NaviGrammar"
GRAMMAR_LEXICON = GRAMMAR_PACKAGE / "Sources/NaviGrammar/Resources/lexicon.tsv"
GRAMMAR_LEXICON_COLUMNS = ["id", "navi", "pos", "infixes", "grammar", "en"]
INTERFACE_IMPORTS = re.compile(r"^\s*(?:@testable\s+)?import\s+(UIKit|SwiftUI)\b", re.MULTILINE)

# The phrasebook's phrases must come from appendix F of the LearnNavi dictionary,
# whose phrases the grammar package's tests check word by word.
PHRASEBOOK = pathlib.Path("Na'vi/Phrasebook.swift")
APPENDIX_F_TESTS = GRAMMAR_PACKAGE / "Tests/NaviGrammarTests/AppendixFTests.swift"

# The phrasebook's Basics pages. Their words must be ones the dictionary lists, their
# alphabet that of appendix G, and their phrases, like the phrasebook's, must come
# from appendix F.
BASICS = pathlib.Path("Na'vi/Basics.swift")

# Words the Basics pages use that neither the lexicon nor the vocabulary lists, and
# where the dictionary uses them.
ATTESTED_ELSEWHERE = {
    "menga": "appendix A of the LearnNavi dictionary: Menga lu karyu, you two are teachers",
}

# Appendix G of the LearnNavi dictionary, "The Alphabet": the 33 letters and the name
# it gives each. Vowels and diphthongs are named by themselves.
APPENDIX_G = {
    "'": "tìftang", "a": "a", "aw": "aw", "ay": "ay", "ä": "ä", "e": "e", "ew": "ew",
    "ey": "ey", "f": "fä", "h": "hä", "i": "i", "ì": "ì", "k": "kek", "kx": "kxekx",
    "l": "lel", "ll": "'ll", "m": "mem", "n": "nen", "ng": "ngeng", "o": "o", "p": "pep",
    "px": "pxepx", "r": "rer", "rr": "'rr", "s": "sä", "t": "tet", "tx": "txetx",
    "ts": "tsä", "u": "u", "v": "vä", "w": "wä", "y": "yä", "z": "zä",
}

# Directories whose Swift files are not Xcode target members: dependency managers,
# Swift packages (built by SwiftPM), test code in Scripts/ that is compiled on its
# own, downloaded source data, and tool worktrees.
NOT_TARGET_SOURCES = {"Pods", "Packages", "Scripts", "SourceData", ".build", ".swiftpm", ".claude"}


class Report:
    """Collects check results and prints them grouped by section."""

    BOLD, GREEN, YELLOW, RED, RESET = "\033[1m", "\033[0;32m", "\033[1;33m", "\033[0;31m", "\033[0m"

    def __init__(self) -> None:
        self.failures = 0
        self.warnings = 0

    def section(self, title: str) -> None:
        print(f"\n{self.BOLD}{title}{self.RESET}")

    def ok(self, message: str) -> None:
        print(f"  {self.GREEN}✓{self.RESET} {message}")

    def warn(self, message: str) -> None:
        self.warnings += 1
        print(f"  {self.YELLOW}!{self.RESET} {message}")

    def fail(self, message: str) -> None:
        self.failures += 1
        print(f"  {self.RED}✗{self.RESET} {message}")


class ProjectFile:
    """Just enough of the pbxproj format to resolve what each target compiles."""

    def __init__(self, text: str) -> None:
        self.text = text
        self._file_paths = self._read_file_references()
        self._build_files = dict(
            re.findall(
                r"\t\t([0-9A-F]{24}) /\* .*? \*/ = \{isa = PBXBuildFile; fileRef = ([0-9A-F]{24})",
                text,
            )
        )
        self._group_paths, self._parent = self._read_groups()

    def _read_file_references(self) -> dict[str, str]:
        paths = {}
        pattern = r"\t\t([0-9A-F]{24}) /\* .*? \*/ = \{isa = PBXFileReference;(.*?)\};"
        for match in re.finditer(pattern, self.text):
            path = re.search(r'path = (?:"([^"]+)"|([^;\s]+));', match.group(2))
            if path:
                paths[match.group(1)] = path.group(1) or path.group(2)
        return paths

    def _read_groups(self) -> tuple[dict[str, str], dict[str, str]]:
        section = re.search(
            r"/\* Begin PBXGroup section \*/(.*?)/\* End PBXGroup section \*/",
            self.text,
            re.DOTALL,
        )
        group_paths: dict[str, str] = {}
        parent: dict[str, str] = {}
        if section is None:
            return group_paths, parent

        pattern = re.compile(
            r"\n\t\t([0-9A-F]{24})(?: /\* .*? \*/)? = \{\n"
            r"\t\t\tisa = PBXGroup;\n"
            r"\t\t\tchildren = \((.*?)\n\t\t\t\);\n(.*?)\n\t\t\};",
            re.DOTALL,
        )
        for match in pattern.finditer(section.group(1)):
            group_id, children, tail = match.groups()
            path = re.search(r'\n\t\t\tpath = (?:"([^"]+)"|([^;\s]+));', tail)
            group_paths[group_id] = (path.group(1) or path.group(2)) if path else ""
            for child in re.findall(r"([0-9A-F]{24})", children):
                parent[child] = group_id
        return group_paths, parent

    def path(self, file_id: str) -> str:
        """The on-disk path of a file reference, via its chain of parent groups."""
        parts = [self._file_paths.get(file_id, "")]
        current = file_id
        while current in self._parent:
            current = self._parent[current]
            if self._group_paths.get(current):
                parts.insert(0, self._group_paths[current])
        return "/".join(part for part in parts if part)

    def compiled_sources(self, phase_id: str) -> list[str] | None:
        block = re.search(
            r"\n\t\t" + phase_id + r" /\* \w+ \*/ = \{.*?\n\t\t\};", self.text, re.DOTALL
        )
        if block is None:
            return None

        paths = []
        for build_id in re.findall(r"([0-9A-F]{24}) /\*", block.group(0))[1:]:
            file_id = self._build_files.get(build_id)
            if file_id:
                paths.append(self.path(file_id))
        return paths


def check_project_file(report: Report, project: ProjectFile) -> None:
    report.section("Project file")
    text = project.text

    stripped = re.sub(r'"(?:[^"\\]|\\.)*"', '""', text)
    stripped = re.sub(r"/\*.*?\*/", "", stripped, flags=re.DOTALL)
    balanced = True
    for opener, closer in (("{", "}"), ("(", ")")):
        if stripped.count(opener) != stripped.count(closer):
            report.fail(f"unbalanced {opener}{closer} in the project file")
            balanced = False
    if balanced:
        report.ok("delimiters are balanced")

    defined = set(re.findall(r"^\t\t([0-9A-F]{24}) ", text, re.MULTILINE))
    referenced = set(re.findall(r"\b([0-9A-F]{24})\b", text))
    dangling = sorted(referenced - defined)
    if dangling:
        for object_id in dangling[:5]:
            report.fail(f"reference to undefined object {object_id}")
    else:
        report.ok(f"all {len(referenced)} object references resolve")

    if re.findall(r"/\* Begin (\w+) section \*/", text) != re.findall(
        r"/\* End (\w+) section \*/", text
    ):
        report.fail("section markers are not balanced")

    for needle, label in (("Pods", "CocoaPods"), ("KeyboardKit", "KeyboardKit")):
        if needle in text:
            report.fail(f"{label} references remain in the project file")
        else:
            report.ok(f"no {label} references")

    if "SWIFT_SWIFT3_OBJC_INFERENCE" in text:
        report.fail(
            "SWIFT_SWIFT3_OBJC_INFERENCE is set, but the current Xcode build system no longer "
            "defines it, so it has no effect; mark Objective-C entry points @objc instead"
        )
    else:
        report.ok("no Swift 3 @objc inference setting")

    versions = set(re.findall(r"SWIFT_VERSION = ([^;]+);", text))
    invalid = sorted(versions - VALID_SWIFT_VERSIONS)
    if invalid:
        report.fail(f"SWIFT_VERSION values Xcode does not accept: {', '.join(invalid)}")
    else:
        report.ok(f"Swift language mode(s): {', '.join(sorted(versions))}")


def check_property_lists(report: Report) -> None:
    report.section("Property lists and privacy manifests")

    loaded: dict[pathlib.Path, dict] = {}
    for path in [APP_INFO, KEYBOARD_INFO, *PRIVACY_MANIFESTS]:
        if not path.exists():
            report.fail(f"{path} is missing")
            continue
        try:
            loaded[path] = plistlib.loads(path.read_bytes())
        except Exception as error:  # noqa: BLE001 - report whatever plistlib raises
            report.fail(f"{path} is not a valid property list: {error}")
    if len(loaded) == 4:
        report.ok("all four property lists parse")

    app = loaded.get(APP_INFO, {})
    keyboard = loaded.get(KEYBOARD_INFO, {})

    if "armv7" in app.get("UIRequiredDeviceCapabilities", []):
        report.fail("UIRequiredDeviceCapabilities asks for armv7; iOS has been 64-bit only since iOS 11")
    else:
        report.ok("device capabilities are 64-bit")

    for key, reason in (
        ("CFBundleSignature", "a Carbon-era key with no meaning on iOS"),
        ("UIRequiresFullScreen", "no longer honoured on iPadOS 26 and later"),
    ):
        if key in app:
            report.warn(f"{key} is still set in the app Info.plist — {reason}")

    if app.get("ITSAppUsesNonExemptEncryption") is None:
        report.warn("ITSAppUsesNonExemptEncryption is unset; App Store Connect asks on every upload")
    else:
        report.ok("export compliance is declared")

    app_version = app.get("CFBundleShortVersionString")
    if app_version != keyboard.get("CFBundleShortVersionString"):
        report.fail("the app and the keyboard declare different CFBundleShortVersionString values")
    else:
        report.ok("the app and the keyboard share a version string")

    required = ("NSPrivacyTracking", "NSPrivacyCollectedDataTypes", "NSPrivacyAccessedAPITypes")
    for path in PRIVACY_MANIFESTS:
        manifest = loaded.get(path)
        if manifest is None:
            continue
        missing = [key for key in required if key not in manifest]
        if missing:
            report.fail(f"{path} is missing {', '.join(missing)}")
        else:
            report.ok(f"{path} is complete")


def check_target_membership(report: Report, project: ProjectFile) -> set[str]:
    report.section("Target membership")

    compiled: set[str] = set()
    for target, phase_id in SOURCES_PHASES.items():
        paths = project.compiled_sources(phase_id)
        if paths is None:
            report.fail(f"no sources build phase found for {target}")
            continue

        sources = [path for path in paths if path.endswith(".swift")]
        missing = [path for path in sources if not pathlib.Path(path).exists()]
        if missing:
            report.fail(f"{target} compiles files that are not on disk: {', '.join(missing)}")
        else:
            report.ok(f"{target} compiles {len(sources)} Swift files, all present")
        compiled.update(sources)

    on_disk = {
        str(path) for path in pathlib.Path(".").rglob("*.swift")
        if not NOT_TARGET_SOURCES.intersection(path.parts)
    }
    orphans = sorted(on_disk - compiled)
    if orphans:
        report.warn(f"{len(orphans)} Swift files are in no target and can be deleted:")
        for path in orphans:
            print(f"      {path}")

    return compiled


def check_deprecated_api(report: Report, compiled: set[str]) -> None:
    report.section("Deprecated and legacy API in compiled sources")

    hits = []
    for path in sorted(compiled):
        file = pathlib.Path(path)
        if not file.exists():
            continue
        for number, line in enumerate(file.read_text(encoding="utf-8").splitlines(), 1):
            if line.lstrip().startswith("//"):
                continue
            for pattern, label in DEPRECATED_API.items():
                if re.search(pattern, line, re.MULTILINE):
                    hits.append(f"{path}:{number}  {label}")

    if hits:
        for hit in hits:
            report.fail(hit)
    else:
        report.ok(f"none found across {len(compiled)} compiled sources")


def check_app_store_icon(report: Report) -> None:
    report.section("App Store icon")

    contents = APP_ICON_SET / "Contents.json"
    if not contents.exists():
        report.fail(f"{contents} is missing")
        return

    import json

    images = json.loads(contents.read_text(encoding="utf-8")).get("images", [])
    marketing = [
        image for image in images
        if image.get("idiom") in ("ios-marketing", "universal") and image.get("size") == "1024x1024"
    ]
    if not marketing or not marketing[0].get("filename"):
        report.fail("no 1024×1024 App Store icon is assigned in AppIcon")
        return

    icon = APP_ICON_SET / marketing[0]["filename"]
    data = icon.read_bytes()
    if data[:8] != b"\x89PNG\r\n\x1a\n":
        report.fail(f"{icon.name} is not a PNG")
        return

    color_type = data[25]
    has_transparency_chunk = b"tRNS" in data[: data.find(b"IDAT")]
    if color_type in (4, 6) or has_transparency_chunk:
        report.fail(
            f"{icon.name} has an alpha channel; App Store Connect rejects it (ITMS-90717)"
        )
    else:
        report.ok(f"{icon.name} is 1024×1024 with no alpha channel")


def resource_names(project: ProjectFile, phase_id: str) -> list[str]:
    block = re.search(
        r"\n\t\t" + phase_id + r" /\* \w+ \*/ = \{.*?\n\t\t\};", project.text, re.DOTALL
    )
    return re.findall(r"/\* ([^*]+?) in Resources \*/", block.group(0)) if block else []


def check_app_life_cycle(report: Report, project: ProjectFile) -> None:
    report.section("App life cycle and launch screen")

    try:
        app = plistlib.loads(APP_INFO.read_bytes())
    except Exception:  # noqa: BLE001 - reported by check_property_lists
        return

    sources = {
        path: pathlib.Path(path).read_text(encoding="utf-8")
        for path in project.compiled_sources(SOURCES_PHASES["Eywa"]) or []
        if path.endswith(".swift") and pathlib.Path(path).exists()
    }

    # An app built against the iOS 27 SDK must use the scene-based life cycle,
    # either through SwiftUI's App protocol or a UIKit scene delegate.
    manifest = app.get("UIApplicationSceneManifest")
    configurations = (manifest or {}).get("UISceneConfigurations", {}).get(
        "UIWindowSceneSessionRoleApplication", []
    )
    swiftui_apps = [
        match.group(1)
        for text in sources.values()
        for match in re.finditer(
            r"@main\s+(?:\w+\s+)*struct\s+(\w+)\s*:\s*(?:\w+\s*,\s*)*App\b", text
        )
    ]

    if manifest is None:
        report.fail(
            "UIApplicationSceneManifest is missing — an app built against the "
            "iOS 27 SDK without the scene life cycle will not launch"
        )
    elif configurations:
        for configuration in configurations:
            class_name = configuration.get("UISceneDelegateClassName", "").split(".")[-1]
            if not class_name:
                report.fail("a scene configuration names no delegate class")
            elif not any(
                re.search(r"\bclass\s+" + re.escape(class_name) + r"\b", text)
                for text in sources.values()
            ):
                report.fail(f"the scene manifest names {class_name}, which the app does not compile")
            else:
                report.ok(f"scene life cycle is provided by {class_name}")
    elif swiftui_apps:
        report.ok(f"scene life cycle is provided by the SwiftUI app {swiftui_apps[0]}")
    else:
        report.fail("no scene delegate is configured and there is no SwiftUI App entry point")

    # Without a launch screen the app runs letterboxed on every modern iPhone.
    if "UILaunchScreen" in app or "UILaunchScreens" in app:
        report.ok("the launch screen is declared in Info.plist")
    elif "UILaunchStoryboardName" in app:
        report.ok("the launch screen is a storyboard")
    else:
        report.fail("no launch screen is declared; the app would run letterboxed")

    # Any storyboard that Info.plist names has to be bundled, or launch fails.
    bundled = set(resource_names(project, RESOURCES_PHASES["Eywa"]))
    named = [app.get("UIMainStoryboardFile"), app.get("UILaunchStoryboardName")]
    named += [configuration.get("UISceneStoryboardFile") for configuration in configurations]
    for name in filter(None, named):
        if f"{name}.storyboard" not in bundled:
            report.fail(f"Info.plist names {name}.storyboard, which the app does not bundle")


def check_interface_builder_files(report: Report, project: ProjectFile) -> None:
    report.section("Interface Builder files")

    for target, phase_id in RESOURCES_PHASES.items():
        files = sorted(
            name for name in resource_names(project, phase_id)
            if name.endswith((".storyboard", ".xib"))
        )
        if not files:
            report.ok(f"{target} bundles no storyboards or nibs")
            continue

        report.warn(f"{target} still bundles {', '.join(files)}")
        legacy = sorted({
            path.name
            for path in pathlib.Path(".").rglob("*")
            if path.name in files
            and "Pods/" not in str(path)
            and "viewControllerLayoutGuide" in path.read_text(encoding="utf-8", errors="ignore")
        })
        if legacy:
            report.warn(
                "pinned to the top and bottom layout guides deprecated in iOS 11: "
                + ", ".join(legacy)
            )


def check_bundle_contents(report: Report, project: ProjectFile) -> None:
    report.section("Bundle contents")

    if APP_VOCABULARY in resource_names(project, RESOURCES_PHASES["Eywa"]):
        report.ok(f"Eywa bundles {APP_VOCABULARY}")
    else:
        report.fail(f"Eywa does not bundle {APP_VOCABULARY}, so the dictionary would load empty")

    for target, phase_id in RESOURCES_PHASES.items():
        unread = [
            f"{name} — {reason}"
            for name in resource_names(project, phase_id)
            for pattern, reason in NEVER_BUNDLED.items()
            if re.search(pattern, name)
        ]
        for item in unread:
            report.warn(f"{target} bundles {item}")
        if not unread:
            report.ok(f"{target} bundles no design files, exports or Firebase configuration")


def check_vocabulary(report: Report, project: ProjectFile) -> None:
    report.section("Vocabulary")

    import json

    try:
        data = json.loads(VOCABULARY_FILE.read_text(encoding="utf-8"))
    except (OSError, ValueError) as error:
        report.fail(f"{VOCABULARY_FILE} does not parse: {error}")
        return
    entries = data.get("dict") if isinstance(data, dict) else None
    if not isinstance(entries, list) or not entries:
        report.fail(f"{VOCABULARY_FILE} has no \"dict\" list of entries")
        return

    names = re.search(
        r"partOfSpeechNames: \[String: String\] = \[(.*?)\n    \]",
        DICTIONARY_ENTRY.read_text(encoding="utf-8") if DICTIONARY_ENTRY.exists() else "",
        re.DOTALL,
    )
    known_codes = set(re.findall(r'"([^"]+)":', names.group(1))) if names else None
    if known_codes is None:
        report.warn(f"could not read the part-of-speech names in {DICTIONARY_ENTRY}")

    bundled = set(resource_names(project, RESOURCES_PHASES["Eywa"]))
    problems: dict[str, list[str]] = {}

    def note(kind: str, detail: str) -> None:
        problems.setdefault(kind, []).append(detail)

    seen: set[tuple[str, ...]] = set()
    recordings = 0
    for number, entry in enumerate(entries, 1):
        if not isinstance(entry, dict):
            note("are not objects", f"entry {number}")
            continue
        label = repr(entry.get("Na'vi", f"entry {number}"))
        missing = [field for field in VOCABULARY_FIELDS if not isinstance(entry.get(field), str)]
        if missing:
            note("lack fields the app decodes", f"{label} ({', '.join(missing)})")
            continue
        if not entry["Na'vi"].strip() or not entry["English"].strip():
            note("have an empty headword or meaning", label)
        if VOCABULARY_MARKUP.search(entry["Na'vi"] + entry["English"]):
            note("contain flashcard markup", label)
        codes = [code.strip() for code in entry["Part of speech"].split(",") if code.strip()]
        if known_codes is not None and (not codes or any(code not in known_codes for code in codes)):
            note("have a part of speech the app cannot spell out", f"{label} ({entry['Part of speech']!r})")
        recording = entry["Audio local URL"]
        if recording:
            recordings += 1
            if recording not in bundled:
                note("name a recording the app does not bundle", f"{label} ({recording})")
        signature = (entry["Na'vi"], entry["Part of speech"], entry["English"])
        if signature in seen:
            note("are exact duplicates", label)
        seen.add(signature)

    for kind, details in problems.items():
        shown = ", ".join(details[:5]) + (f" and {len(details) - 5} more" if len(details) > 5 else "")
        report.fail(f"{len(details)} entries {kind}: {shown}")
    if not problems:
        report.ok(
            f"all {len(entries)} entries decode, {recordings} with a bundled recording "
            "and every part of speech spelled out"
        )


def check_grammar_package(report: Report, project: ProjectFile) -> set[str]:
    """Checks the NaviGrammar package and returns its sources, which the deprecated
    API check then covers as it does the app's."""
    report.section("Grammar package")

    if not (GRAMMAR_PACKAGE / "Package.swift").exists():
        report.fail(f"{GRAMMAR_PACKAGE}/Package.swift is missing")
        return set()

    text = project.text
    references = re.findall(r"isa = XCLocalSwiftPackageReference;\s*relativePath = \"?([^;\"]+)\"?;", text)
    products = re.findall(r"isa = XCSwiftPackageProductDependency;[^}]*?productName = (\w+);", text)
    app_target = re.search(r'name = "Na-vi";\s*packageProductDependencies = \((.*?)\);', text, re.DOTALL)
    if str(GRAMMAR_PACKAGE) not in references:
        report.fail(f"the project does not reference the local package {GRAMMAR_PACKAGE}")
    elif GRAMMAR_PRODUCT not in products or app_target is None or GRAMMAR_PRODUCT not in app_target.group(1):
        report.fail(f"Eywa does not depend on the {GRAMMAR_PRODUCT} product")
    elif f"{GRAMMAR_PRODUCT} in Frameworks" not in text:
        report.fail(f"Eywa does not link {GRAMMAR_PRODUCT}")
    else:
        report.ok(f"Eywa links {GRAMMAR_PRODUCT} from {GRAMMAR_PACKAGE}")

    sources = sorted((GRAMMAR_PACKAGE / "Sources").rglob("*.swift"))
    interface = [
        f"{path} imports {match.group(1)}"
        for path in sources
        for match in INTERFACE_IMPORTS.finditer(path.read_text(encoding="utf-8"))
    ]
    if interface:
        for item in interface:
            report.fail(f"{item}; the package must stay usable from the keyboard extension")
    else:
        report.ok(f"{len(sources)} package sources import neither UIKit nor SwiftUI")

    check_grammar_lexicon(report)
    return {str(path) for path in sources}


def check_grammar_lexicon(report: Report) -> None:
    """The lexicon the analyser loads: a damaged file would make every word unknown
    in a release build, with nothing else to show for it."""
    manifest = (GRAMMAR_PACKAGE / "Package.swift").read_text(encoding="utf-8")
    relative = GRAMMAR_LEXICON.relative_to(GRAMMAR_PACKAGE / "Sources/NaviGrammar")
    if f'"{relative}"' not in manifest:
        report.fail(f"Package.swift does not bundle {relative}")

    try:
        lines = GRAMMAR_LEXICON.read_text(encoding="utf-8").splitlines()
    except (OSError, UnicodeDecodeError) as error:
        report.fail(f"{GRAMMAR_LEXICON} cannot be read: {error}")
        return

    metadata = dict(
        line[2:].split("\t", 1) for line in lines if line.startswith("# ") and "\t" in line
    )
    body = [line for line in lines if line and not line.startswith("#")]
    problems = []
    if not body or body[0].split("\t") != GRAMMAR_LEXICON_COLUMNS:
        problems.append("the column header is missing or changed")
    rows = [line.split("\t") for line in body[1:]]
    malformed = [number for number, row in enumerate(rows, 1) if len(row) != len(GRAMMAR_LEXICON_COLUMNS)]
    if malformed:
        problems.append(f"{len(malformed)} rows do not have {len(GRAMMAR_LEXICON_COLUMNS)} columns")
    ids = [row[0] for row in rows]
    if len(set(ids)) != len(ids):
        problems.append("ids repeat")
    if metadata.get("entries") != str(len(rows)):
        problems.append(f"the header says {metadata.get('entries')} entries but there are {len(rows)}")
    credit = metadata.get("credit", "")
    if "Paul Frommer" not in credit or "Littauer" not in credit:
        problems.append("the credit line is missing or incomplete")
    if len(metadata.get("sha256", "")) != 64:
        problems.append("the source checksum is missing")

    if problems:
        for problem in problems:
            report.fail(f"{GRAMMAR_LEXICON.name}: {problem}")
    else:
        report.ok(f"{GRAMMAR_LEXICON.name} has {len(rows)} entries, its source checksum and credits")


def check_phrasebook(report: Report) -> None:
    report.section("Phrasebook")

    def key(phrase: str) -> str:
        # An ellipsis stands where the learner puts a word in, as X does in appendix F,
        # whose phrases the tests list without it: "tsalì'uri alu, ral lu 'upe".
        text = re.sub(r"\s*…\s*", " ", phrase)
        text = re.sub(r"\s+([,;])", r"\1", text)
        return " ".join(text.lower().rstrip(".!?").split())

    try:
        books = {path: path.read_text(encoding="utf-8") for path in (PHRASEBOOK, BASICS)}
        appendix = APPENDIX_F_TESTS.read_text(encoding="utf-8")
    except OSError as error:
        report.fail(f"cannot read the phrasebook or the appendix F phrases: {error}")
        return

    phrases = [
        (path, phrase)
        for path, text in books.items()
        for phrase in re.findall(r'Phrase\(navi: "((?:[^"\\]|\\.)*)"', text)
    ]
    listed = re.search(r"static let phrases: \[String\] = \[(.*?)\n    \]", appendix, re.DOTALL)
    sources = {key(phrase) for phrase in re.findall(r'"((?:[^"\\]|\\.)*)"', listed.group(1))} if listed else set()

    problems = [f"{path.name}: {phrase!r} is not an appendix F phrase" for path, phrase in phrases if key(phrase) not in sources]
    texts = [phrase for _, phrase in phrases]
    repeated = sorted({phrase for phrase in texts if texts.count(phrase) > 1})
    problems += [f"{phrase!r} appears more than once" for phrase in repeated]
    if not phrases:
        problems.append(f"{PHRASEBOOK.name}: no phrases found")

    for problem in problems:
        report.fail(problem)
    if not problems:
        report.ok(f"all {len(phrases)} phrases are from appendix F, each once")


def check_basics(report: Report) -> None:
    """The Basics pages: every word is one the dictionary lists, and the alphabet is
    appendix G's, each letter with its name and an example the app has a recording of."""
    report.section("Phrasebook basics")

    import json
    import unicodedata

    def key(word: str) -> str:
        # As the app compares headwords: composed letters, the straight apostrophe, no
        # + for lenition, any case.
        composed = unicodedata.normalize("NFC", word.replace("’", "'").replace("+", ""))
        return composed.lower().strip()

    try:
        basics = BASICS.read_text(encoding="utf-8")
        rows = [line.split("\t") for line in GRAMMAR_LEXICON.read_text(encoding="utf-8").splitlines()]
        vocabulary = json.loads(VOCABULARY_FILE.read_text(encoding="utf-8"))["dict"]
        recorded = {key(entry["Na'vi"]) for entry in vocabulary if entry["Audio local URL"]}
        listed = {key(entry["Na'vi"]) for entry in vocabulary}
    except (OSError, UnicodeDecodeError, ValueError, KeyError, TypeError) as error:
        report.fail(f"cannot read the basics, the lexicon or the vocabulary: {error}")
        return
    listed |= {key(row[1]) for row in rows if len(row) == len(GRAMMAR_LEXICON_COLUMNS) and row[0].isdigit()}

    problems = []
    words = re.findall(r'BasicWord\(navi: "((?:[^"\\]|\\.)*)"', basics)
    for word in words:
        if key(word) not in listed and key(word) not in ATTESTED_ELSEWHERE:
            problems.append(f"{word!r} is in neither the lexicon nor the vocabulary")
    for word in sorted(ATTESTED_ELSEWHERE):
        if word in listed:
            report.warn(f"{word!r} is now in the dictionary; ATTESTED_ELSEWHERE no longer needs it")
    if not words:
        problems.append("no words found")

    letters = re.findall(
        r'NaviLetter\(letter: "((?:[^"\\]|\\.)*)"(?:, name: "((?:[^"\\]|\\.)*)")?.*?example: BasicWord\(navi: "((?:[^"\\]|\\.)*)"',
        basics,
        re.DOTALL,
    )
    spelled = [letter for letter, _, _ in letters]
    for letter in sorted(set(APPENDIX_G) - set(spelled)):
        problems.append(f"the alphabet leaves out {letter!r}")
    for letter in sorted(set(spelled) - set(APPENDIX_G)):
        problems.append(f"{letter!r} is not a letter of appendix G")
    for letter in sorted({letter for letter in spelled if spelled.count(letter) > 1}):
        problems.append(f"{letter!r} is listed more than once")
    for letter, name, example in letters:
        expected = APPENDIX_G.get(letter)
        if expected is not None and key(name or letter) != expected:
            problems.append(f"{letter!r} is named {name or letter!r}, but appendix G names it {expected!r}")
        if letter not in key(example):
            problems.append(f"the example for {letter!r}, {example!r}, does not have that letter")
        if key(example) not in recorded:
            problems.append(f"the example for {letter!r}, {example!r}, has no recording")

    for problem in problems:
        report.fail(f"{BASICS.name}: {problem}")
    if not problems:
        report.ok(f"all {len(words)} words are in the dictionary, and the alphabet is appendix G's {len(letters)} letters")


def check_keyboard_touch_routing(report: Report) -> None:
    report.section("Keyboard touch routing")

    # ForwardingView hands every touch to the nearest subview. If it considers
    # views that are not controls, a full-size background view claims every touch
    # and the keyboard stops responding, with nothing to show for it but a device.
    source = pathlib.Path("Keyboard/ForwardingView.swift")
    if not source.exists():
        report.fail(f"{source} is missing")
        return

    if re.search(r"for case let \w+ as UIControl in self\.subviews", source.read_text(encoding="utf-8")):
        report.ok("touches are forwarded to controls only")
    else:
        report.fail(
            "ForwardingView.findNearestView no longer limits itself to UIControl subviews; "
            "a decorative subview can capture every touch"
        )


def check_keyboard_privacy(report: Report, sources: list[str] | None) -> None:
    report.section("Keyboard privacy")

    if sources is None:
        report.fail("no sources build phase found for Na'vi Keyboard")
        return

    swift = [pathlib.Path(path) for path in sorted(sources) if path.endswith(".swift")]
    hits = []
    for file in swift:
        if not file.exists():
            continue
        for number, line in enumerate(file.read_text(encoding="utf-8").splitlines(), 1):
            if line.lstrip().startswith("//"):
                continue
            for pattern, label in KEYBOARD_PRIVACY.items():
                if re.search(pattern, line):
                    hits.append(f"{file}:{number}  {label}")

    if hits:
        for hit in hits:
            report.fail(f"{hit} — the keyboard has Full Access only for haptics, and nothing typed may leave the device")
    else:
        report.ok(f"no network or pasteboard access across {len(swift)} keyboard sources")


def check_shared_settings(report: Report, project: ProjectFile) -> None:
    report.section("Shared settings")

    match = re.search(r'static let appGroup = "([^"]+)"', KEYBOARD_SETTINGS.read_text(encoding="utf-8")) \
        if KEYBOARD_SETTINGS.exists() else None
    if match is None:
        report.fail(f"{KEYBOARD_SETTINGS} does not name the App Group the settings live in")
        return
    group = match.group(1)

    problems = []
    for target, path in ENTITLEMENTS.items():
        if f'CODE_SIGN_ENTITLEMENTS = "{path}";' not in project.text:
            problems.append(f"{target} is not signed with {path}")
        try:
            groups = plistlib.loads(path.read_bytes()).get(APP_GROUPS_KEY, [])
        except Exception as error:  # noqa: BLE001 - report whatever plistlib raises
            problems.append(f"{path} cannot be read: {error}")
            continue
        if group not in groups:
            problems.append(f"{path} does not declare {group}, the group {KEYBOARD_SETTINGS.name} reads")

    for path in PRIVACY_MANIFESTS:
        try:
            manifest = plistlib.loads(path.read_bytes())
        except Exception:  # noqa: BLE001 - check_property_lists reports it
            continue
        reasons = [
            reason
            for entry in manifest.get("NSPrivacyAccessedAPITypes", [])
            if entry.get("NSPrivacyAccessedAPIType") == "NSPrivacyAccessedAPICategoryUserDefaults"
            for reason in entry.get("NSPrivacyAccessedAPITypeReasons", [])
        ]
        if APP_GROUP_DEFAULTS_REASON not in reasons:
            problems.append(f"{path} does not give {APP_GROUP_DEFAULTS_REASON} as its reason for App Group defaults")

    for problem in problems:
        report.fail(problem)
    if not problems:
        report.ok(f"the app and the keyboard share {group}, and both manifests give {APP_GROUP_DEFAULTS_REASON}")


def main() -> int:
    if not PROJECT.exists():
        print(f"{PROJECT} not found. Run this from the project root.", file=sys.stderr)
        return 1

    report = Report()
    project = ProjectFile(PROJECT.read_text(encoding="utf-8"))

    check_project_file(report, project)
    check_property_lists(report)
    check_app_life_cycle(report, project)
    check_app_store_icon(report)
    compiled = check_target_membership(report, project)
    compiled |= check_grammar_package(report, project)
    check_deprecated_api(report, compiled)
    check_keyboard_touch_routing(report)
    check_keyboard_privacy(report, project.compiled_sources(SOURCES_PHASES["Na'vi Keyboard"]))
    check_shared_settings(report, project)
    check_interface_builder_files(report, project)
    check_bundle_contents(report, project)
    check_vocabulary(report, project)
    check_phrasebook(report)
    check_basics(report)

    report.section("Result")
    if report.failures:
        print(f"  {Report.RED}{report.failures} check(s) failed.{Report.RESET}")
        return 1

    summary = "All checks passed."
    if report.warnings:
        summary += f" {report.warnings} warning(s)."
    print(f"  {Report.GREEN}{summary}{Report.RESET}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
