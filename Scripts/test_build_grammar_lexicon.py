#!/usr/bin/env python3
"""
Tests for build_grammar_lexicon.py.

Each case feeds the parser a small export with one realistic problem — the kind a
changed export format, a hand edit or a typo upstream leaves behind — and checks
that it is reported, or handled, as intended. The last cases rebuild the real
lexicon when the downloaded source is present.

Run from the project root: python3 Scripts/test_build_grammar_lexicon.py
"""

from __future__ import annotations

import os
import pathlib
import sys
import unittest

ROOT = pathlib.Path(__file__).resolve().parent.parent
sys.path.insert(0, str(ROOT / "Scripts"))
os.chdir(ROOT)

import build_grammar_lexicon as build  # noqa: E402 - needs the project root as the working directory

LANGUAGES = ["de", "en", "es", "et", "fr", "hu", "it", "ko", "nl", "pl", "pt", "ru", "sv", "tr", "uk"]
HEADER = "\t".join(build.SOURCE_COLUMNS + LANGUAGES)


def row(entry_id="4", navi="'ampi", infixes="'<0><1>amp<2>i", pos="vtr.", en="touch") -> str:
    """One export line, with NULL in the columns the lexicon does not use."""
    fields = {"id": entry_id, "navi": navi, "ipa": "NULL", "infixes": infixes, "partOfSpeech": pos,
              "source": "NULL", "stressed": "1", "syllables": "NULL", "infixDots": "NULL"}
    values = [fields[column] for column in build.SOURCE_COLUMNS]
    values += [en if language == "en" else "NULL" for language in LANGUAGES]
    return "\t".join(values)


def parse(*lines: str, header: str = HEADER) -> tuple[list[dict[str, str]], build.Problems]:
    problems = build.Problems()
    entries = build.parse_source("\n".join([header, *lines]) + "\n", problems)
    return entries, problems


class ParseTests(unittest.TestCase):

    def test_valid_entries(self) -> None:
        entries, problems = parse(row(), row("8", "'angtsìk", "NULL", "n.", "hammerhead"))
        self.assertEqual(problems.errors, [])
        self.assertEqual([entry["navi"] for entry in entries], ["'ampi", "'angtsìk"])
        self.assertEqual(entries[1]["infixes"], "")  # NULL becomes empty

    def test_byte_order_mark_and_windows_line_endings(self) -> None:
        problems = build.Problems()
        text = "﻿" + HEADER + "\r\n" + row() + "\r\n\r\n"
        entries = build.parse_source(text, problems)
        self.assertEqual(problems.errors, [])
        self.assertEqual(len(entries), 1)

    def test_entries_are_sorted_by_id(self) -> None:
        entries, _ = parse(row("20", "'awkx", "NULL", "n.", "cliff"), row("4"))
        self.assertEqual([entry["id"] for entry in entries], ["4", "20"])

    def test_changed_header(self) -> None:
        _, problems = parse(row(), header=HEADER.replace("infixes", "infix"))
        self.assertIn("unexpected header", problems.errors[0])

    def test_empty_file(self) -> None:
        problems = build.Problems()
        self.assertEqual(build.parse_source("", problems), [])
        self.assertIn("empty", problems.errors[0])

    def test_missing_column(self) -> None:
        _, problems = parse(row().rsplit("\t", 1)[0])
        self.assertIn("columns instead of", problems.errors[0])

    def test_duplicate_id(self) -> None:
        _, problems = parse(row(), row(navi="'ampi"))
        self.assertIn("appears twice", problems.errors[0])

    def test_id_that_is_not_a_number(self) -> None:
        _, problems = parse(row("4a"))
        self.assertIn("is not a number", problems.errors[0])

    def test_unknown_part_of_speech(self) -> None:
        _, problems = parse(row(pos="verb"))
        self.assertIn("unknown part of speech", problems.errors[0])

    def test_two_parts_of_speech_without_a_space(self) -> None:
        entries, problems = parse(row("12", "fìtseng", "NULL", "adv.,n.", "here"))
        self.assertEqual(problems.errors, [])
        self.assertEqual(entries[0]["pos"], "adv., n.")

    def test_no_english_definition(self) -> None:
        _, problems = parse(row(en="NULL"))
        self.assertIn("no English definition", problems.errors[0])

    def test_headword_outside_the_alphabet(self) -> None:
        _, problems = parse(row(navi="'ampi2", infixes="NULL"))
        self.assertIn("outside the Na'vi alphabet", problems.errors[0])

    def test_curly_apostrophes_are_straightened(self) -> None:
        entries, problems = parse(row(navi="’ampi", infixes="’<0><1>amp<2>i"))
        self.assertEqual(problems.errors, [])
        self.assertEqual(entries[0]["navi"], "'ampi")

    def test_decomposed_letters_are_composed(self) -> None:
        entries, problems = parse(row("9", "tätxaw", "t<0><1>ätx<2>aw", "vin.", "return"))
        self.assertEqual(problems.errors, [])
        self.assertEqual(entries[0]["navi"], "tätxaw")

    def test_template_that_does_not_spell_the_headword(self) -> None:
        _, problems = parse(row(infixes="'<0><1>amp<2>u"))
        self.assertIn("does not spell the headword", problems.errors[0])

    def test_template_with_slots_out_of_order(self) -> None:
        _, problems = parse(row(infixes="'<1><0>amp<2>i"))
        self.assertIn("not <0><1> followed by <2>", problems.errors[0])

    def test_template_that_marks_no_positions(self) -> None:
        entries, problems = parse(row("3", "'ulte", "'ulte", "vin.", "glide"))
        self.assertEqual(problems.errors, [])
        self.assertIn("marks no positions", problems.notes[0])
        self.assertEqual(entries[0]["infixes"], "'ulte")

    def test_verb_without_a_template(self) -> None:
        _, problems = parse(row(infixes="NULL"))
        self.assertIn("no infix template", problems.notes[0])

    def test_known_template_typos_are_corrected(self) -> None:
        entries, problems = parse(row("12962", "'asap si", "asap s<0><1><2>i", "vin.", "be shocked"))
        self.assertEqual(problems.errors, [])
        self.assertEqual(entries[0]["infixes"], "'asap s<0><1><2>i")
        self.assertIn("corrected the infix template", problems.notes[0])

    def test_a_fixed_typo_retires_its_correction(self) -> None:
        entries, problems = parse(row("12962", "'asap si", "'asap s<0><1><2>i", "vin.", "be shocked"))
        self.assertEqual(problems.errors, [])
        self.assertIn("no longer needs", problems.notes[0])

    def test_irregular_genitive_in_the_definition(self) -> None:
        entries, _ = parse(row("4804", "soaia", "NULL", "n.", "family (irregular genitive form soaiä)"))
        self.assertEqual(entries[0]["grammar"], "genitive=soaiä")

    def test_attested_forms_and_loanwords(self) -> None:
        entries, _ = parse(row("1548", "po", "NULL", "pn.", "he, she"), row("11720", "Kelnì", "NULL", "prop.n.", "Cologne"))
        self.assertEqual(entries[0]["grammar"], "genitive=peyä")
        self.assertEqual(entries[1]["grammar"], "loanword")

    def test_a_homograph_of_an_attested_word_is_left_alone(self) -> None:
        entries, _ = parse(row("1549", "po", "NULL", "n.", "something else"))
        self.assertEqual(entries[0]["grammar"], "")

    def test_curated_words_missing_from_the_source(self) -> None:
        entries, problems = parse(row())
        build.check_curated_words(entries, problems)
        self.assertTrue(any("attested form" in error for error in problems.errors))
        self.assertTrue(any("loanword Kelnì" in error for error in problems.errors))

    def test_definitions_are_collapsed_to_one_line(self) -> None:
        entries, _ = parse(row(en="touch,   feel"))
        self.assertEqual(entries[0]["en"], "touch, feel")


class RenderTests(unittest.TestCase):

    def test_header_and_columns(self) -> None:
        entries, _ = parse(row())
        text = build.render(entries, "ab" * 32, "2026-09-26")
        lines = text.splitlines()
        self.assertTrue(lines[0].startswith("# NaviGrammar lexicon"))
        self.assertIn(f"# sha256\t{'ab' * 32}", lines)
        self.assertIn("# entries\t1", lines)
        self.assertIn("Paul Frommer", text)
        self.assertEqual(lines[6], "\t".join(build.LEXICON_COLUMNS))
        self.assertEqual(lines[7].split("\t"), ["4", "'ampi", "vtr.", "'<0><1>amp<2>i", "", "touch"])
        self.assertTrue(text.endswith("\n"))


@unittest.skipUnless(build.SOURCE_FILE.exists(), "the downloaded source is not present; run with --fetch")
class RealSourceTests(unittest.TestCase):

    def test_the_real_source_builds(self) -> None:
        lexicon, problems = build.build()
        self.assertEqual(problems.errors, [])
        self.assertIsNotNone(lexicon)

    def test_the_committed_lexicon_is_current(self) -> None:
        lexicon, _ = build.build()
        committed = build.LEXICON_FILE.read_text(encoding="utf-8")
        strip = lambda text: [line for line in text.splitlines() if not line.startswith("# retrieved")]  # noqa: E731
        self.assertEqual(strip(committed), strip(lexicon))


if __name__ == "__main__":
    unittest.main()
