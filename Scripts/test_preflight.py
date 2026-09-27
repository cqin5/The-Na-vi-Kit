#!/usr/bin/env python3
"""
Tests for the vocabulary, grammar package, phrasebook, Basics, keyboard privacy and
shared settings checks in preflight.py.

Each case feeds a check one realistic mistake — the kind a hand-merged export, a
flashcard import or a hand edit to the project leaves behind — and asserts that the
check names it. The last case of each class runs the check against the real project.

Run from the project root: python3 Scripts/test_preflight.py
"""

from __future__ import annotations

import contextlib
import io
import json
import os
import pathlib
import plistlib
import sys
import tempfile
import unittest

ROOT = pathlib.Path(__file__).resolve().parent.parent
sys.path.insert(0, str(ROOT / "Scripts"))
os.chdir(ROOT)

import preflight  # noqa: E402 - needs the project root as the working directory

BUNDLED = ["vocabulary.json", "7964.mp3", "6224.mp3"]


def entry(**overrides: str) -> dict:
    """A valid entry with a bundled recording, as the Learn Na'vi export writes them."""
    value = {
        "Na'vi": "'ak",
        "IPA": "[ʔak̚]",
        "Part of speech": "intj.",
        "English": "ow, ouch",
        "Audio URL": "https://s.learnnavi.org/audio/vocab/7964.mp3",
        "Audio local URL": "7964.mp3",
        "Source": "Learn Na’vi",
        "Source URL": "https://learnnavi.org",
        "Last Updated": "2022-01-06",
    }
    value.update(overrides)
    return value


class VocabularyCheckTests(unittest.TestCase):

    def run_check(self, text: str) -> tuple[int, str]:
        """Runs the check on `text` as the vocabulary file; returns failures and output."""
        with tempfile.TemporaryDirectory() as directory:
            path = pathlib.Path(directory) / "vocabulary.json"
            path.write_text(text, encoding="utf-8")
            report = preflight.Report()
            output = io.StringIO()
            original_file, original_names = preflight.VOCABULARY_FILE, preflight.resource_names
            preflight.VOCABULARY_FILE = path
            preflight.resource_names = lambda project, phase_id: BUNDLED
            try:
                with contextlib.redirect_stdout(output):
                    preflight.check_vocabulary(report, project=None)
            finally:
                preflight.VOCABULARY_FILE, preflight.resource_names = original_file, original_names
        return report.failures, output.getvalue()

    def check_entries(self, *entries: object) -> tuple[int, str]:
        return self.run_check(json.dumps({"dict": list(entries)}, ensure_ascii=False))

    def test_valid_entries_pass(self) -> None:
        failures, output = self.check_entries(
            entry(),
            # An imported word: no written pronunciation and no recording.
            entry(**{"Na'vi": "tulkun", "IPA": "", "Part of speech": "n.", "Audio URL": "",
                     "Audio local URL": "", "English": "sentient whale-like Pandoran sea creature"}),
            # Two parts of speech, written without the space after the comma.
            entry(**{"Na'vi": "rewonay", "Part of speech": "adv.,n.", "Audio local URL": "6224.mp3"}),
            # Square brackets are allowed in meanings: the export uses them for pronunciation.
            entry(**{"Na'vi": "nìayoeng", "English": "like us (casual speech [naj.wEN])"}),
            # A decomposed ä, as some exports write it.
            entry(**{"Na'vi": "'ä'o", "English": "pitcher plant"}),
        )
        self.assertEqual(failures, 0, output)
        self.assertIn("all 5 entries decode, 4 with a bundled recording", output)

    def test_missing_field_fails_whole_file_decoding(self) -> None:
        broken = entry()
        del broken["Audio local URL"]
        failures, output = self.check_entries(entry(), broken)
        self.assertEqual(failures, 1)
        self.assertIn("lack fields the app decodes", output)
        self.assertIn("Audio local URL", output)

    def test_null_field(self) -> None:
        failures, output = self.check_entries(entry(IPA=None))
        self.assertEqual(failures, 1)
        self.assertIn("lack fields the app decodes", output)

    def test_flashcard_stress_markup(self) -> None:
        failures, output = self.check_entries(entry(**{"Na'vi": "<u>'a</u>ku"}))
        self.assertEqual(failures, 1)
        self.assertIn("contain flashcard markup", output)

    def test_flashcard_sense_separator(self) -> None:
        failures, output = self.check_entries(entry(English="remove | take away | take off"))
        self.assertEqual(failures, 1)
        self.assertIn("contain flashcard markup", output)

    def test_flashcard_category_label_is_not_a_part_of_speech(self) -> None:
        failures, output = self.check_entries(entry(**{"Part of speech": "substantive (noun)"}))
        self.assertEqual(failures, 1)
        self.assertIn("cannot spell out", output)

    def test_empty_part_of_speech(self) -> None:
        failures, output = self.check_entries(entry(**{"Part of speech": " , "}))
        self.assertEqual(failures, 1)
        self.assertIn("cannot spell out", output)

    def test_blank_meaning(self) -> None:
        failures, output = self.check_entries(entry(English="   "))
        self.assertEqual(failures, 1)
        self.assertIn("empty headword or meaning", output)

    def test_recording_the_app_does_not_bundle(self) -> None:
        failures, output = self.check_entries(entry(**{"Audio local URL": "99999.mp3"}))
        self.assertEqual(failures, 1)
        self.assertIn("does not bundle", output)
        self.assertIn("99999.mp3", output)

    def test_exact_duplicate_from_a_repeated_merge(self) -> None:
        failures, output = self.check_entries(entry(), entry())
        self.assertEqual(failures, 1)
        self.assertIn("exact duplicates", output)

    def test_homographs_are_not_duplicates(self) -> None:
        failures, output = self.check_entries(
            entry(**{"Na'vi": "ken", "Part of speech": "adp.", "English": "despite"}),
            entry(**{"Na'vi": "ken", "Part of speech": "vin.", "English": "behave assertively"}),
        )
        self.assertEqual(failures, 0, output)

    def test_many_problems_are_summarised(self) -> None:
        failures, output = self.check_entries(*[entry(English="") for _ in range(8)])
        self.assertEqual(failures, 2)  # blank meanings, and exact duplicates of each other
        self.assertIn("8 entries have an empty headword or meaning", output)
        self.assertIn("and 3 more", output)

    def test_entry_that_is_not_an_object(self) -> None:
        failures, output = self.check_entries(entry(), "'ak")
        self.assertEqual(failures, 1)
        self.assertIn("are not objects", output)

    def test_truncated_file(self) -> None:
        text = json.dumps({"dict": [entry()]}, ensure_ascii=False)
        failures, output = self.run_check(text[: len(text) // 2])
        self.assertEqual(failures, 1)
        self.assertIn("does not parse", output)

    def test_dict_that_is_not_a_list(self) -> None:
        failures, output = self.run_check(json.dumps({"dict": entry()}, ensure_ascii=False))
        self.assertEqual(failures, 1)
        self.assertIn('no "dict" list', output)

    def test_top_level_list(self) -> None:
        failures, output = self.run_check(json.dumps([entry()], ensure_ascii=False))
        self.assertEqual(failures, 1)
        self.assertIn('no "dict" list', output)

    def test_empty_dictionary(self) -> None:
        failures, output = self.run_check('{"dict": []}')
        self.assertEqual(failures, 1)
        self.assertIn('no "dict" list', output)

    def test_real_vocabulary_passes(self) -> None:
        report = preflight.Report()
        output = io.StringIO()
        project = preflight.ProjectFile(preflight.PROJECT.read_text(encoding="utf-8"))
        with contextlib.redirect_stdout(output):
            preflight.check_vocabulary(report, project)
        self.assertEqual(report.failures, 0, output.getvalue())
        self.assertEqual(report.warnings, 0, output.getvalue())


LEXICON_HEADER = "\n".join([
    "# NaviGrammar lexicon. Generated by Scripts/build_grammar_lexicon.py; do not edit by hand.",
    "# source\thttps://tirea.learnnavi.org/dictionarydata/dictionary-v2.txt",
    "# sha256\t" + "ab" * 32,
    "# entries\t{entries}",
    "# credit\tLearnNavi Na'vi dictionary, originally created by Richard Littauer. "
    "The Na'vi language was created by Dr. Paul Frommer.",
    "id\tnavi\tpos\tinfixes\tgrammar\ten",
])
LEXICON_ROWS = ["4\t'ampi\tvtr.\t'<0><1>amp<2>i\t\ttouch", "8\t'angtsìk\tn.\t\t\thammerhead"]
MANIFEST = 'let package = Package(targets: [.target(name: "NaviGrammar", resources: [.copy("Resources/lexicon.tsv")])])\n'


def linked_project(package: str, framework: bool = True, dependency: bool = True) -> str:
    """The parts of a project file that link a local package into the app target."""
    return "\n".join([
        "\t\tA1 /* NaviGrammar in Frameworks */ = {isa = PBXBuildFile; productRef = A2 /* NaviGrammar */; };"
        if framework else "",
        '\t\t\tname = "Na-vi";',
        "\t\t\tpackageProductDependencies = (\n\t\t\t\tA2 /* NaviGrammar */,\n\t\t\t);" if dependency else "",
        f"\t\tA3 = {{\n\t\t\tisa = XCLocalSwiftPackageReference;\n\t\t\trelativePath = {package};\n\t\t}};",
        "\t\tA2 = {\n\t\t\tisa = XCSwiftPackageProductDependency;\n\t\t\tproductName = NaviGrammar;\n\t\t};",
    ])


class GrammarPackageCheckTests(unittest.TestCase):

    def run_check(self, *, manifest: str | None = MANIFEST, source: str = "import Foundation\n",
                  lexicon: str | bytes | None = None, reference: str | None = None,
                  framework: bool = True, dependency: bool = True) -> tuple[int, str]:
        """Runs the check on a package built in a temporary directory."""
        with tempfile.TemporaryDirectory() as directory:
            package = pathlib.Path(directory) / "Packages" / "NaviGrammar"
            resources = package / "Sources" / "NaviGrammar" / "Resources"
            resources.mkdir(parents=True)
            if manifest is not None:
                (package / "Package.swift").write_text(manifest, encoding="utf-8")
            (package / "Sources" / "NaviGrammar" / "Analyser.swift").write_text(source, encoding="utf-8")
            if lexicon is None:
                lexicon = LEXICON_HEADER.format(entries=len(LEXICON_ROWS)) + "\n" + "\n".join(LEXICON_ROWS) + "\n"
            if isinstance(lexicon, bytes):
                (resources / "lexicon.tsv").write_bytes(lexicon)
            else:
                (resources / "lexicon.tsv").write_text(lexicon, encoding="utf-8")

            report = preflight.Report()
            output = io.StringIO()
            originals = preflight.GRAMMAR_PACKAGE, preflight.GRAMMAR_LEXICON
            preflight.GRAMMAR_PACKAGE = package
            preflight.GRAMMAR_LEXICON = resources / "lexicon.tsv"
            try:
                with contextlib.redirect_stdout(output):
                    project = linked_project(reference or str(package), framework, dependency)
                    preflight.check_grammar_package(report, preflight.ProjectFile(project))
            finally:
                preflight.GRAMMAR_PACKAGE, preflight.GRAMMAR_LEXICON = originals
        return report.failures, output.getvalue()

    def test_valid_package_passes(self) -> None:
        failures, output = self.run_check()
        self.assertEqual(failures, 0, output)
        self.assertIn("lexicon.tsv has 2 entries", output)

    def test_missing_manifest(self) -> None:
        failures, output = self.run_check(manifest=None)
        self.assertEqual(failures, 1)
        self.assertIn("Package.swift is missing", output)

    def test_package_not_referenced_by_the_project(self) -> None:
        failures, output = self.run_check(reference="Packages/Elsewhere")
        self.assertEqual(failures, 1)
        self.assertIn("does not reference the local package", output)

    def test_package_referenced_but_not_a_dependency_of_the_app(self) -> None:
        failures, output = self.run_check(dependency=False)
        self.assertEqual(failures, 1)
        self.assertIn("does not depend on", output)

    def test_product_not_linked(self) -> None:
        failures, output = self.run_check(framework=False)
        self.assertEqual(failures, 1)
        self.assertIn("does not link", output)

    def test_ui_framework_imported(self) -> None:
        failures, output = self.run_check(source="import Foundation\nimport UIKit\n")
        self.assertEqual(failures, 1)
        self.assertIn("imports UIKit", output)

    def test_swiftui_imported_with_testable(self) -> None:
        failures, output = self.run_check(source="@testable import SwiftUI\n")
        self.assertEqual(failures, 1)
        self.assertIn("imports SwiftUI", output)

    def test_ui_framework_named_in_a_comment_is_fine(self) -> None:
        failures, output = self.run_check(source="// Unlike the app, this does not import UIKit.\n")
        self.assertEqual(failures, 0, output)

    def test_lexicon_not_bundled(self) -> None:
        failures, output = self.run_check(manifest="let package = Package(targets: [.target(name: \"NaviGrammar\")])\n")
        self.assertEqual(failures, 1)
        self.assertIn("does not bundle", output)

    def test_truncated_row(self) -> None:
        lexicon = LEXICON_HEADER.format(entries=2) + "\n" + LEXICON_ROWS[0] + "\n8\t'angtsìk\tn.\n"
        failures, output = self.run_check(lexicon=lexicon)
        self.assertEqual(failures, 1)
        self.assertIn("rows do not have 6 columns", output)

    def test_entry_count_does_not_match_the_header(self) -> None:
        lexicon = LEXICON_HEADER.format(entries=3045) + "\n" + "\n".join(LEXICON_ROWS) + "\n"
        failures, output = self.run_check(lexicon=lexicon)
        self.assertEqual(failures, 1)
        self.assertIn("says 3045 entries but there are 2", output)

    def test_repeated_id(self) -> None:
        lexicon = LEXICON_HEADER.format(entries=2) + "\n" + LEXICON_ROWS[0] + "\n" + LEXICON_ROWS[0] + "\n"
        failures, output = self.run_check(lexicon=lexicon)
        self.assertEqual(failures, 1)
        self.assertIn("ids repeat", output)

    def test_credit_removed(self) -> None:
        lexicon = "\n".join(line for line in LEXICON_HEADER.splitlines() if "credit" not in line)
        lexicon = lexicon.format(entries=2) + "\n" + "\n".join(LEXICON_ROWS) + "\n"
        failures, output = self.run_check(lexicon=lexicon)
        self.assertEqual(failures, 1)
        self.assertIn("credit line", output)

    def test_changed_column_header(self) -> None:
        lexicon = LEXICON_HEADER.replace("\tgrammar\t", "\tforms\t").format(entries=2) + "\n" + "\n".join(LEXICON_ROWS)
        failures, output = self.run_check(lexicon=lexicon)
        self.assertEqual(failures, 1)
        self.assertIn("column header", output)

    def test_lexicon_that_is_not_utf8(self) -> None:
        failures, output = self.run_check(lexicon=b"\xff\xfe# not text\n")
        self.assertEqual(failures, 1)
        self.assertIn("cannot be read", output)

    def test_real_project_passes(self) -> None:
        report = preflight.Report()
        output = io.StringIO()
        project = preflight.ProjectFile(preflight.PROJECT.read_text(encoding="utf-8"))
        with contextlib.redirect_stdout(output):
            sources = preflight.check_grammar_package(report, project)
            preflight.check_target_membership(report, project)
        self.assertEqual(report.failures, 0, output.getvalue())
        # Package sources are built by SwiftPM, not listed as files in no target.
        self.assertEqual(report.warnings, 0, output.getvalue())
        self.assertTrue(any(path.endswith("Analyser.swift") for path in sources))


class PhrasebookCheckTests(unittest.TestCase):

    APPENDIX = (
        'static let phrases: [String] = [\n'
        '        "kaltxì",\n'
        '        "oel ngati kameie",\n'
        '        "tsalì\'uri alu, ral lu \'upe",\n'
        '        "nìNa\'vi slu pelì\'u",\n'
        '    ]\n'
    )

    def run_check(self, phrasebook: str, basics: str = "enum Basics {}") -> tuple[int, str]:
        with tempfile.TemporaryDirectory() as directory:
            book = pathlib.Path(directory) / "Phrasebook.swift"
            basics_file = pathlib.Path(directory) / "Basics.swift"
            appendix = pathlib.Path(directory) / "AppendixFTests.swift"
            book.write_text(phrasebook, encoding="utf-8")
            basics_file.write_text(basics, encoding="utf-8")
            appendix.write_text(self.APPENDIX, encoding="utf-8")
            report = preflight.Report()
            output = io.StringIO()
            originals = preflight.PHRASEBOOK, preflight.BASICS, preflight.APPENDIX_F_TESTS
            preflight.PHRASEBOOK, preflight.BASICS, preflight.APPENDIX_F_TESTS = book, basics_file, appendix
            try:
                with contextlib.redirect_stdout(output):
                    preflight.check_phrasebook(report)
            finally:
                preflight.PHRASEBOOK, preflight.BASICS, preflight.APPENDIX_F_TESTS = originals
        return report.failures, output.getvalue()

    def test_an_ellipsis_stands_for_the_word_appendix_f_writes_as_x(self) -> None:
        failures, output = self.run_check(
            'Phrase(navi: "Tsalì\'uri alu …, ral lu \'upe?", english: "What does the word … mean?")\n'
            'Phrase(navi: "… nìNa\'vi slu pelì\'u?", english: "How do you say … in Na\'vi?")'
        )
        self.assertEqual(failures, 0, output)
        self.assertIn("all 2 phrases", output)

    def test_an_ellipsis_does_not_excuse_other_words(self) -> None:
        failures, output = self.run_check('Phrase(navi: "… nìNa\'vi pelì\'u?", english: "How do you say …?")')
        self.assertEqual(failures, 1)
        self.assertIn("is not an appendix F phrase", output)

    def test_phrases_on_the_basics_pages_are_checked_too(self) -> None:
        failures, output = self.run_check(
            'Phrase(navi: "Kaltxì", english: "Hello")',
            basics='Phrase(navi: "Oeri solalew zìsìt amevol", english: "I\'m 16")',
        )
        self.assertEqual(failures, 1)
        self.assertIn("Basics.swift: 'Oeri solalew zìsìt amevol' is not an appendix F phrase", output)

    def test_a_phrase_in_both_files_appears_more_than_once(self) -> None:
        failures, output = self.run_check(
            'Phrase(navi: "Kaltxì", english: "Hello")',
            basics='Phrase(navi: "Kaltxì", english: "Hi")',
        )
        self.assertEqual(failures, 1)
        self.assertIn("more than once", output)

    def test_phrases_from_appendix_f_pass_whatever_their_capitals_and_final_punctuation(self) -> None:
        failures, output = self.run_check('Phrase(navi: "Kaltxì!", english: "Hello")\nPhrase(navi: "Oel ngati kameie", english: "I see you")')
        self.assertEqual(failures, 0, output)
        self.assertIn("all 2 phrases", output)

    def test_invented_phrase(self) -> None:
        failures, output = self.run_check('Phrase(navi: "Oel ngati tsun kameie", english: "I can see you")')
        self.assertEqual(failures, 1)
        self.assertIn("is not an appendix F phrase", output)

    def test_misspelled_phrase(self) -> None:
        failures, output = self.run_check('Phrase(navi: "Kaltxi", english: "Hello")')
        self.assertEqual(failures, 1)

    def test_repeated_phrase(self) -> None:
        failures, output = self.run_check('Phrase(navi: "Kaltxì", english: "Hi")\nPhrase(navi: "kaltxì", english: "Hello")')
        self.assertEqual(failures, 0, output)
        failures, output = self.run_check('Phrase(navi: "Kaltxì", english: "Hi")\nPhrase(navi: "Kaltxì", english: "Hello")')
        self.assertEqual(failures, 1)
        self.assertIn("more than once", output)

    def test_empty_phrasebook(self) -> None:
        failures, output = self.run_check("enum Phrasebook {}")
        self.assertEqual(failures, 1)
        self.assertIn("no phrases found", output)

    def test_real_phrasebook_passes(self) -> None:
        report = preflight.Report()
        output = io.StringIO()
        with contextlib.redirect_stdout(output):
            preflight.check_phrasebook(report)
        self.assertEqual(report.failures, 0, output.getvalue())


class KeyboardPrivacyCheckTests(unittest.TestCase):

    # What the keyboard legitimately does: types, reads its settings, plays clicks
    # and haptics.
    CLEAN = (
        "import UIKit\n"
        "let clicks = UserDefaults.standard.bool(forKey: kKeyboardClicks)\n"
        "UIDevice.current.playInputClick()\n"
        "self.textDocumentProxy.insertText(\"kaltxì\")\n"
    )

    def run_check(self, *sources: str) -> tuple[int, str]:
        """Runs the check on each source as a keyboard file, plus a clean one."""
        with tempfile.TemporaryDirectory() as directory:
            paths = []
            for number, source in enumerate((self.CLEAN, *sources)):
                path = pathlib.Path(directory) / f"Keyboard{number}.swift"
                path.write_text(source, encoding="utf-8")
                paths.append(str(path))
            report = preflight.Report()
            output = io.StringIO()
            with contextlib.redirect_stdout(output):
                preflight.check_keyboard_privacy(report, paths)
        return report.failures, output.getvalue()

    def test_keyboard_code_passes(self) -> None:
        failures, output = self.run_check()
        self.assertEqual(failures, 0, output)
        self.assertIn("across 1 keyboard sources", output)

    def test_url_session(self) -> None:
        failures, output = self.run_check("let task = URLSession.shared.dataTask(with: url)\n")
        self.assertEqual(failures, 1)
        self.assertIn("Keyboard1.swift:1  URLSession", output)

    def test_request_built_for_later(self) -> None:
        failures, output = self.run_check("var request = URLRequest(url: endpoint)\n")
        self.assertEqual(failures, 1)
        self.assertIn("URLRequest", output)

    def test_network_framework_imported_with_an_attribute(self) -> None:
        failures, output = self.run_check("import UIKit\n@preconcurrency import Network\n")
        self.assertEqual(failures, 1)
        self.assertIn("Keyboard1.swift:2  a networking framework", output)

    def test_network_extension_imported(self) -> None:
        failures, output = self.run_check("import NetworkExtension\n")
        self.assertEqual(failures, 1)

    def test_connection_without_an_import_line(self) -> None:
        failures, output = self.run_check("let connection = Network.NWConnection(host: host, port: 443, using: .tls)\n")
        self.assertEqual(failures, 1)
        self.assertIn("connection", output)

    def test_socket_stream(self) -> None:
        failures, output = self.run_check(
            "Stream.getStreamsToHost(withName: host, port: 80, inputStream: &input, outputStream: &output)\n"
        )
        self.assertEqual(failures, 1)
        self.assertIn("socket stream", output)

    def test_reading_the_pasteboard(self) -> None:
        failures, output = self.run_check("    let copied = UIPasteboard.general.string\n")
        self.assertEqual(failures, 1)
        self.assertIn("pasteboard", output)

    def test_every_use_is_reported(self) -> None:
        failures, output = self.run_check("URLSession.shared\n", "UIPasteboard.general\n\nURLSession.shared\n")
        self.assertEqual(failures, 3)
        self.assertIn("Keyboard2.swift:3", output)

    def test_names_in_comments_are_fine(self) -> None:
        failures, output = self.run_check("// Never use URLSession or UIPasteboard here.\n    // import Network\n")
        self.assertEqual(failures, 0, output)

    def test_similar_names_are_fine(self) -> None:
        failures, output = self.run_check("let networkStatus = 0\nlet pasteboardLike = \"URLSessionless\"\nlet requestCount = 1\nimport NaviGrammar\n")
        self.assertEqual(failures, 0, output)

    def test_missing_sources_phase(self) -> None:
        report = preflight.Report()
        output = io.StringIO()
        with contextlib.redirect_stdout(output):
            preflight.check_keyboard_privacy(report, None)
        self.assertEqual(report.failures, 1)
        self.assertIn("no sources build phase", output.getvalue())

    def test_real_keyboard_passes(self) -> None:
        report = preflight.Report()
        output = io.StringIO()
        project = preflight.ProjectFile(preflight.PROJECT.read_text(encoding="utf-8"))
        sources = project.compiled_sources(preflight.SOURCES_PHASES["Na'vi Keyboard"])
        with contextlib.redirect_stdout(output):
            preflight.check_keyboard_privacy(report, sources)
        self.assertEqual(report.failures, 0, output.getvalue())
        self.assertIn("Keyboard/KeyboardHaptics.swift", sources)
        self.assertIn("Keyboard/KeyboardViewController.swift", sources)



def entitlements(*groups: str) -> bytes:
    return plistlib.dumps({"com.apple.security.application-groups": list(groups)} if groups else {})


def manifest(*reasons: str) -> bytes:
    return plistlib.dumps({
        "NSPrivacyTracking": False,
        "NSPrivacyTrackingDomains": [],
        "NSPrivacyCollectedDataTypes": [],
        "NSPrivacyAccessedAPITypes": [{
            "NSPrivacyAccessedAPIType": "NSPrivacyAccessedAPICategoryUserDefaults",
            "NSPrivacyAccessedAPITypeReasons": list(reasons),
        }] if reasons else [],
    })


class SharedSettingsCheckTests(unittest.TestCase):

    GROUP = "group.live.moquan.eywa"
    SIGNED = 'CODE_SIGN_ENTITLEMENTS = "{app}";\nCODE_SIGN_ENTITLEMENTS = "{keyboard}";\n'

    def run_check(self, *, app: bytes | None = None, keyboard: bytes | None = None,
                  settings: str | None = None, manifests: tuple[bytes, bytes] | None = None,
                  signed: str | None = None) -> tuple[int, str]:
        """Runs the check on entitlements, settings code and manifests written to a
        temporary directory; each defaults to a correct one."""
        with tempfile.TemporaryDirectory() as directory:
            root = pathlib.Path(directory)
            app_path, keyboard_path = root / "Na-vi.entitlements", root / "Na-vi Keyboard.entitlements"
            app_path.write_bytes(entitlements(self.GROUP) if app is None else app)
            keyboard_path.write_bytes(entitlements(self.GROUP) if keyboard is None else keyboard)
            settings_path = root / "KeyboardSettings.swift"
            settings_path.write_text(
                f'struct KeyboardSettings {{\n    static let appGroup = "{self.GROUP}"\n}}\n' if settings is None else settings,
                encoding="utf-8",
            )
            manifest_paths = [root / "App.xcprivacy", root / "Keyboard.xcprivacy"]
            for path, content in zip(manifest_paths, manifests or (manifest("1C8F.1"), manifest("1C8F.1"))):
                path.write_bytes(content)
            project_text = (signed or self.SIGNED).format(app=app_path, keyboard=keyboard_path)

            report = preflight.Report()
            output = io.StringIO()
            originals = preflight.ENTITLEMENTS, preflight.KEYBOARD_SETTINGS, preflight.PRIVACY_MANIFESTS
            preflight.ENTITLEMENTS = {"Eywa": app_path, "Na'vi Keyboard": keyboard_path}
            preflight.KEYBOARD_SETTINGS = settings_path
            preflight.PRIVACY_MANIFESTS = manifest_paths
            try:
                with contextlib.redirect_stdout(output):
                    preflight.check_shared_settings(report, preflight.ProjectFile(project_text))
            finally:
                preflight.ENTITLEMENTS, preflight.KEYBOARD_SETTINGS, preflight.PRIVACY_MANIFESTS = originals
        return report.failures, output.getvalue()

    def test_shared_group_passes(self) -> None:
        failures, output = self.run_check()
        self.assertEqual(failures, 0, output)
        self.assertIn("share group.live.moquan.eywa", output)

    def test_keyboard_without_the_group(self) -> None:
        failures, output = self.run_check(keyboard=entitlements())
        self.assertEqual(failures, 1)
        self.assertIn("Na-vi Keyboard.entitlements does not declare group.live.moquan.eywa", output)

    def test_app_still_on_the_old_group(self) -> None:
        failures, output = self.run_check(app=entitlements("group.CQ.Navi"))
        self.assertEqual(failures, 1)
        self.assertIn("Na-vi.entitlements does not declare", output)

    def test_group_named_in_code_differs_from_both(self) -> None:
        failures, output = self.run_check(settings='static let appGroup = "group.live.moquan.Eywa"\n')
        self.assertEqual(failures, 2)

    def test_code_names_no_group(self) -> None:
        failures, output = self.run_check(settings="struct KeyboardSettings {}\n")
        self.assertEqual(failures, 1)
        self.assertIn("does not name the App Group", output)

    def test_entitlements_that_are_not_a_property_list(self) -> None:
        failures, output = self.run_check(keyboard=b"<?xml version=\"1.0\"?><plist><dict>")
        self.assertEqual(failures, 1)
        self.assertIn("cannot be read", output)

    def test_manifest_without_the_app_group_reason(self) -> None:
        failures, output = self.run_check(manifests=(manifest("1C8F.1"), manifest("CA92.1")))
        self.assertEqual(failures, 1)
        self.assertIn("does not give 1C8F.1", output)

    def test_manifest_without_any_user_defaults_entry(self) -> None:
        failures, output = self.run_check(manifests=(manifest(), manifest("1C8F.1")))
        self.assertEqual(failures, 1)

    def test_target_signed_with_other_entitlements(self) -> None:
        failures, output = self.run_check(signed='CODE_SIGN_ENTITLEMENTS = "{app}";\nCODE_SIGN_ENTITLEMENTS = "Other.entitlements";\n')
        self.assertEqual(failures, 1)
        self.assertIn("Na'vi Keyboard is not signed with", output)

    def test_real_project_passes(self) -> None:
        report = preflight.Report()
        output = io.StringIO()
        project = preflight.ProjectFile(preflight.PROJECT.read_text(encoding="utf-8"))
        with contextlib.redirect_stdout(output):
            preflight.check_shared_settings(report, project)
        self.assertEqual(report.failures, 0, output.getvalue())


class BasicsCheckTests(unittest.TestCase):

    LEXICON = (
        "# NaviGrammar lexicon.\n"
        "id\tnavi\tpos\tinfixes\tgrammar\ten\n"
        "12\t'aw\tnum.\t\t\tone\n"
        "1348\tnga\tpn.\t\t\tyou\n"
        "4072\tsre+\tadp.\t\t\tbefore (time)\n"
        "4320\tkinä\tnum.\t\t\tseven\n"
    )
    VOCABULARY = [
        entry(**{"Na'vi": "'aw", "English": "one", "Audio local URL": "12.mp3"}),
        entry(**{"Na'vi": "nga", "English": "you", "Audio local URL": "1348.mp3"}),
        entry(**{"Na'vi": "kinä", "English": "seven", "Audio local URL": "4320.mp3"}),
        entry(**{"Na'vi": "pxenga", "English": "you three", "Audio local URL": ""}),
    ]
    # A two-letter alphabet, so that each case need list only what it is about.
    ALPHABET = {"'": "tìftang", "ng": "ngeng"}
    LETTERS = (
        'NaviLetter(letter: "\'", name: "tìftang", ipa: "ʔ", sound: "uh-oh",\n'
        '           example: BasicWord(navi: "\'aw", english: "one")),\n'
        'NaviLetter(letter: "ng", name: "ngeng", ipa: "ŋ", sound: "sing",\n'
        '           example: BasicWord(navi: "nga", english: "you")),\n'
    )

    def run_check(self, basics: str, vocabulary: object | None = None) -> tuple[int, int, str]:
        with tempfile.TemporaryDirectory() as directory:
            basics_file = pathlib.Path(directory) / "Basics.swift"
            lexicon = pathlib.Path(directory) / "lexicon.tsv"
            vocabulary_file = pathlib.Path(directory) / "vocabulary.json"
            basics_file.write_text(basics, encoding="utf-8")
            lexicon.write_text(self.LEXICON, encoding="utf-8")
            vocabulary_file.write_text(
                json.dumps({"dict": self.VOCABULARY} if vocabulary is None else vocabulary, ensure_ascii=False),
                encoding="utf-8",
            )
            report = preflight.Report()
            output = io.StringIO()
            originals = preflight.BASICS, preflight.GRAMMAR_LEXICON, preflight.VOCABULARY_FILE, preflight.APPENDIX_G
            preflight.BASICS, preflight.GRAMMAR_LEXICON, preflight.VOCABULARY_FILE = basics_file, lexicon, vocabulary_file
            preflight.APPENDIX_G = self.ALPHABET
            try:
                with contextlib.redirect_stdout(output):
                    preflight.check_basics(report)
            finally:
                preflight.BASICS, preflight.GRAMMAR_LEXICON, preflight.VOCABULARY_FILE, preflight.APPENDIX_G = originals
        return report.failures, report.warnings, output.getvalue()

    def test_words_from_the_lexicon_or_the_vocabulary_pass(self) -> None:
        failures, warnings, output = self.run_check(
            self.LETTERS + 'BasicWord(navi: "kinä", english: "seven")\nBasicWord(navi: "pxenga", english: "you three")'
        )
        self.assertEqual((failures, warnings), (0, 0), output)
        self.assertIn("all 4 words", output)
        self.assertIn("2 letters", output)

    def test_misspelled_word(self) -> None:
        failures, _, output = self.run_check(self.LETTERS + 'BasicWord(navi: "kina", english: "seven")')
        self.assertEqual(failures, 1)
        self.assertIn("'kina' is in neither the lexicon nor the vocabulary", output)

    def test_word_attested_only_in_an_appendix(self) -> None:
        failures, _, output = self.run_check(self.LETTERS + 'BasicWord(navi: "menga", english: "you two")')
        self.assertEqual(failures, 0, output)

    def test_capitals_curly_apostrophes_decomposed_letters_and_lenition_marks_match(self) -> None:
        failures, _, output = self.run_check(
            self.LETTERS
            + 'BasicWord(navi: "Nga", english: "you")\n'
            + 'BasicWord(navi: "’aw", english: "one")\n'
            + 'BasicWord(navi: "kinä", english: "seven")\n'
            + 'BasicWord(navi: "sre", english: "before")'
        )
        self.assertEqual(failures, 0, output)

    def test_letter_left_out(self) -> None:
        failures, _, output = self.run_check(self.LETTERS.split("NaviLetter(letter: \"ng\"")[0])
        self.assertEqual(failures, 1)
        self.assertIn("the alphabet leaves out 'ng'", output)

    def test_letter_appendix_g_does_not_have(self) -> None:
        failures, _, output = self.run_check(
            self.LETTERS + 'NaviLetter(letter: "b", ipa: "b", sound: "b", example: BasicWord(navi: "nga", english: "you"))'
        )
        self.assertIn("'b' is not a letter of appendix G", output)
        self.assertGreaterEqual(failures, 1)

    def test_letter_listed_twice(self) -> None:
        failures, _, output = self.run_check(self.LETTERS + self.LETTERS.split("),\n")[0] + ")")
        self.assertIn("\"'\" is listed more than once", output)
        self.assertEqual(failures, 1)

    def test_wrong_name(self) -> None:
        failures, _, output = self.run_check(self.LETTERS.replace('name: "ngeng"', 'name: "nga"'))
        self.assertEqual(failures, 1)
        self.assertIn("appendix G names it 'ngeng'", output)

    def test_names_differing_only_in_capitals_match(self) -> None:
        failures, _, output = self.run_check(self.LETTERS.replace('name: "ngeng"', 'name: "NgeNg"'))
        self.assertEqual(failures, 0, output)

    def test_example_without_its_letter(self) -> None:
        failures, _, output = self.run_check(self.LETTERS.replace('navi: "nga"', 'navi: "kinä"'))
        self.assertEqual(failures, 1)
        self.assertIn("'kinä', does not have that letter", output)

    def test_example_without_a_recording(self) -> None:
        failures, _, output = self.run_check(self.LETTERS.replace('navi: "nga"', 'navi: "pxenga"'))
        self.assertEqual(failures, 1)
        self.assertIn("'pxenga', has no recording", output)

    def test_empty_basics(self) -> None:
        failures, _, output = self.run_check("enum Basics {}")
        self.assertIn("no words found", output)
        self.assertIn("the alphabet leaves out", output)
        self.assertGreaterEqual(failures, 3)

    def test_vocabulary_without_its_list(self) -> None:
        failures, _, output = self.run_check(self.LETTERS, vocabulary={"entries": []})
        self.assertEqual(failures, 1)
        self.assertIn("cannot read", output)

    def test_an_exception_the_dictionary_has_caught_up_with_is_reported(self) -> None:
        vocabulary = {"dict": self.VOCABULARY + [entry(**{"Na'vi": "menga", "English": "you two"})]}
        failures, warnings, output = self.run_check(self.LETTERS, vocabulary=vocabulary)
        self.assertEqual((failures, warnings), (0, 1), output)
        self.assertIn("ATTESTED_ELSEWHERE no longer needs it", output)

    def test_real_basics_pass(self) -> None:
        report = preflight.Report()
        output = io.StringIO()
        with contextlib.redirect_stdout(output):
            preflight.check_basics(report)
        self.assertEqual((report.failures, report.warnings), (0, 0), output.getvalue())
        self.assertIn("33 letters", output.getvalue())


if __name__ == "__main__":
    unittest.main()
