#!/usr/bin/env python3
"""
Pre-flight checks for The Na'vi Kit.

Covers the things that can go wrong without Xcode noticing until an archive is
rejected or a device misbehaves: project file integrity, the scene-based app life
cycle that the iOS 27 SDK requires, the launch screen, App Store property list
keys, privacy manifests, the App Store icon, target membership, deprecated and
legacy API in the sources that are actually compiled, any Interface Builder
files still bundled, and bundle contents — the vocabulary the app cannot work
without, and files that nothing reads at run time.

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
    r"\bAudioServicesPlaySystemSound\b": "a system sound, which needs Full Access the keyboard does not request — use UIDevice.current.playInputClick()",
    r"withTopBanner:\s*true": "room for the top banner, which is never shown, so an empty strip sits above the keys",
    r"\[(\w+)\.index\(before: \1\.endIndex\)\]": "the character before endIndex, which traps on an empty string — use .last",
    r"^\s*print\(": "a debug print in shipping code",
}


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
        str(path) for path in pathlib.Path(".").rglob("*.swift") if "Pods/" not in str(path)
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
    check_deprecated_api(report, compiled)
    check_keyboard_touch_routing(report)
    check_interface_builder_files(report, project)
    check_bundle_contents(report, project)

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
