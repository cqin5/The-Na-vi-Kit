#!/usr/bin/env python3
"""
Tests for the vocabulary check in preflight.py.

Each case feeds the check a vocabulary with one realistic mistake — the kind a
hand-merged export or a flashcard import leaves behind — and asserts that the check
names it. The last case runs the check against the real vocabulary and project.

Run from the project root: python3 Scripts/test_preflight.py
"""

from __future__ import annotations

import contextlib
import io
import json
import os
import pathlib
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


if __name__ == "__main__":
    unittest.main()
