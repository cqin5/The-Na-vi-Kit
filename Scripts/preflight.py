#!/usr/bin/env python3
"""
Pre-flight checks for The Na'vi Kit.

Covers the things that can go wrong without Xcode noticing until an archive is
rejected or a device misbehaves: project file integrity, the scene life cycle that
the iOS 27 SDK requires, App Store property list keys, privacy manifests, the App
Store icon, target membership, deprecated and legacy API in the sources that are
actually compiled, and legacy layout guides in storyboards.

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
SCENE_DELEGATE = pathlib.Path("Na'vi/SceneDelegate.swift")
APP_ICON_SET = pathlib.Path("Na'vi/Assets.xcassets/AppIcon.appiconset")
INTERFACE_FILES = [
    pathlib.Path("Na'vi/Dictionary.storyboard"),
    pathlib.Path("Na'vi/Base.lproj/Main.storyboard"),
    pathlib.Path("Na'vi/Base.lproj/LaunchScreen.storyboard"),
]

SOURCES_PHASES = {
    "Eywa": "A6AE8AEF1D1AD43E00345E2E",
    "Na'vi Keyboard": "A614201F1D1AD5DC001C0FBD",
}

VALID_SWIFT_VERSIONS = {"4.0", "4.2", "5.0", "6.0"}

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

    manifest = app.get("UIApplicationSceneManifest")
    if not manifest:
        report.fail(
            "UIApplicationSceneManifest is missing — an app built against the "
            "iOS 27 SDK without the scene life cycle will not launch"
        )
    else:
        configurations = manifest.get("UISceneConfigurations", {}).get(
            "UIWindowSceneSessionRoleApplication", []
        )
        if not configurations:
            report.fail("the scene manifest declares no window scene configuration")
        elif not configurations[0].get("UISceneDelegateClassName", "").endswith("SceneDelegate"):
            report.fail("the scene manifest does not name a scene delegate class")
        elif not SCENE_DELEGATE.exists():
            report.fail(f"the scene manifest names a delegate but {SCENE_DELEGATE} is missing")
        else:
            report.ok("scene life cycle is declared and implemented")

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


def check_interface_files(report: Report) -> None:
    report.section("Storyboards")

    legacy = []
    for path in INTERFACE_FILES:
        if path.exists() and "viewControllerLayoutGuide" in path.read_text(encoding="utf-8"):
            legacy.append(path.name)

    if legacy:
        report.warn(
            "still pinned to the top and bottom layout guides deprecated in iOS 11: "
            + ", ".join(legacy)
            + " — enable “Use Safe Area Layout Guides” in Interface Builder"
        )
    else:
        report.ok("all storyboards use safe area layout guides")


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
    check_app_store_icon(report)
    compiled = check_target_membership(report, project)
    check_deprecated_api(report, compiled)
    check_keyboard_touch_routing(report)
    check_interface_files(report)

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
