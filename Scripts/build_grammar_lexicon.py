#!/usr/bin/env python3
"""
Builds the lexicon that the NaviGrammar package reads.

The grammar engine needs each word's part of speech and, for verbs, where the
infixes go. Only the LearnNavi dictionary data records both, so the engine's
lexicon is generated from that data. It is a separate resource from the app's own
vocabulary.json, which this script neither reads nor writes.

Source: the LearnNavi dictionary data, a tab-separated export of the LearnNavi
Na'vi dictionary, compiled by Roland "Tìtstewan" R. S. et al. and originally
created by Richard Littauer. The Na'vi language was created by Dr. Paul Frommer.

Usage, from the project root:

    python3 Scripts/build_grammar_lexicon.py --fetch   # download the source, then build
    python3 Scripts/build_grammar_lexicon.py           # build from the downloaded copy
    python3 Scripts/build_grammar_lexicon.py --check   # fail if the lexicon is out of date

The download is kept in SourceData/, which git ignores. The lexicon keeps the
columns the engine uses — headword, part of speech, infix template and English
definition — and a grammar column: irregular forms that the definitions spell
out, and the few facts the data does not carry, listed below with their sources.
"""

from __future__ import annotations

import argparse
import datetime
import hashlib
import pathlib
import re
import sys
import unicodedata
import urllib.request

ROOT = pathlib.Path(__file__).resolve().parent.parent
SOURCE_URL = "https://tirea.learnnavi.org/dictionarydata/dictionary-v2.txt"
SOURCE_FILE = ROOT / "SourceData" / "learnnavi" / "dictionary-v2.txt"
LEXICON_FILE = ROOT / "Packages" / "NaviGrammar" / "Sources" / "NaviGrammar" / "Resources" / "lexicon.tsv"

CREDIT = (
    "LearnNavi Na'vi dictionary, compiled by Roland \"Tìtstewan\" R. S. et al., "
    "originally created by Richard Littauer. The Na'vi language was created by Dr. Paul Frommer."
)

SOURCE_COLUMNS = [
    "id", "navi", "ipa", "infixes", "partOfSpeech", "source", "stressed", "syllables", "infixDots",
]
LEXICON_COLUMNS = ["id", "navi", "pos", "infixes", "grammar", "en"]

# Every part-of-speech abbreviation the source uses, as listed in the dictionary's
# front matter. An abbreviation outside this list means the export changed format.
PARTS_OF_SPEECH = {
    "adj.", "adp.", "adv.", "conj.", "inter.", "intj.", "n.", "num.", "part.", "ph.", "pn.",
    "prop.n.", "sbd.", "v.", "vim.", "vin.", "vtr.", "vtrm.",
}

SLOT = re.compile(r"<([012])>")
NAVI_LETTERS = re.compile(r"^[a-zäìéù' +A-ZÄÌÉÙ]+$")

# Irregular forms the definitions spell out, such as "(irregular genitive form
# soaiä)" or "(reflexive, genitive form sneyä)". The engine uses them instead of
# the regular ending.
IRREGULAR_FORM = re.compile(r"\bgenitive form ([^\s),;]+)")

APOSTROPHES = str.maketrans({"’": "'", "‘": "'", "ʼ": "'", "`": "'", "´": "'"})

NAVITERI = "https://naviteri.org/"

# Irregular forms that Dr. Frommer has used and the dictionary data does not record,
# by headword and part of speech. The engine uses them in place of the regular form,
# which for these words would be wrong.
ATTESTED_FORMS = {
    ("po", "pn."): ("genitive=peyä", NAVITERI + "2020/12/mrra-tipangkxotsyip-five-little-discussions/"),
    ("fo", "pn."): ("genitive=feyä", NAVITERI + "2023/09/aawa-ayliu-si-aylifyavi-amip-a-few-new-words-and-expressions/"),
    ("mefo", "pn."): ("genitive=mefeyä", NAVITERI + "2023/09/aawa-ayliu-si-aylifyavi-amip-a-few-new-words-and-expressions/"),
    ("ayfo", "pn."): ("genitive=ayfeyä", NAVITERI + "2026/06/tskxekeng-a-mikyunfpi-pamrel-listening-exercise-text/"),
    ("tsaw", "pn."): ("genitive=tseyä", NAVITERI + "2017/02/ayioang-amip-si-ayu-alahe-new-animals-and-other-things/ (comment of 1 March 2017)"),
    ("Omatikaya", "prop.n."): ("genitive=omatikayaä", NAVITERI + "2012/10/mipa-vospxi-mipa-ayliu-new-words-for-the-new-month/"),
}

# Loanwords ending in an added -ì, from appendix C of the LearnNavi dictionary PDF.
# Dr. Frommer drops that -ì before a case ending (Kelnì: Kelnit, Kelnur, Kelnä):
# https://naviteri.org/2022/01/aawa-tipangkxotsyip-a-teri-horen-lifyaya-a-few-little-discussions-about-grammar/
LOANWORDS_ENDING_IN_I = {
    "'Ìnglìsì", "hametsì", "Kelnì", "Kerìsmìsì", "LosÄntsyelesì", "Nìyu Yorkì", "pätsì", "postì", "tsyìräfì",
}

# Typing errors in the source's infix templates, by entry id: the value in the
# source, the corrected value, and why. A correction applies only while the source
# still has the value it corrects, so a fix upstream retires it.
TEMPLATE_CORRECTIONS = {
    12962: ("asap s<0><1><2>i", "'asap s<0><1><2>i", "the template drops the leading tìftang"),
    13609: ("kxa.pay s<0><1><2>i", "kxapay s<0><1><2>i", "the template contains a syllable dot"),
}


class Problems:
    """Errors stop the build; notes describe entries the engine treats specially."""

    def __init__(self) -> None:
        self.errors: list[str] = []
        self.notes: list[str] = []

    def error(self, message: str) -> None:
        self.errors.append(message)

    def note(self, message: str) -> None:
        self.notes.append(message)


def clean(field: str) -> str:
    """NFC, straight apostrophes, no surrounding space, and the export's NULL as empty."""
    field = unicodedata.normalize("NFC", field).strip()
    return "" if field == "NULL" else field


def check_template(navi: str, template: str, label: str, problems: Problems) -> None:
    """A template must spell its headword once the slot markers are removed, and
    each word that takes infixes must have slots 0 and 1 together, then slot 2."""
    if SLOT.sub("", template) != navi:
        problems.error(f"{label}: infix template {template!r} does not spell the headword")
        return
    slotted = [word for word in template.split(" ") if SLOT.search(word)]
    if not slotted:
        problems.note(f"{label}: the infix template marks no positions, so the verb is never inflected")
        return
    if len(slotted) > 1:
        problems.note(f"{label}: infixes can go in more than one word ({template!r})")
    for word in slotted:
        slots = SLOT.findall(word)
        if slots != ["0", "1", "2"] or "<0><1>" not in word:
            problems.error(f"{label}: slots in {word!r} are not <0><1> followed by <2>")


def parse_source(text: str, problems: Problems) -> list[dict[str, str]]:
    """The entries of a dictionary-v2.txt export, checked and reduced to the lexicon columns."""
    text = text.lstrip("﻿").replace("\r\n", "\n").replace("\r", "\n")
    lines = [line for line in text.split("\n") if line.strip()]
    if not lines:
        problems.error("the source file is empty")
        return []

    header = lines[0].split("\t")
    if header[: len(SOURCE_COLUMNS)] != SOURCE_COLUMNS or "en" not in header:
        problems.error(f"unexpected header: {header[:12]}")
        return []
    english = header.index("en")

    entries: list[dict[str, str]] = []
    seen_ids: set[int] = set()
    for number, line in enumerate(lines[1:], start=2):
        fields = line.split("\t")
        if len(fields) != len(header):
            problems.error(f"line {number}: {len(fields)} columns instead of {len(header)}")
            continue

        raw_id, navi, template, pos, definition = (
            clean(fields[0]), clean(fields[1]).translate(APOSTROPHES),
            clean(fields[3]).translate(APOSTROPHES), clean(fields[4]), clean(fields[english]),
        )
        label = f"line {number} ({navi or 'no headword'})"

        if not raw_id.isdigit():
            problems.error(f"{label}: id {raw_id!r} is not a number")
            continue
        entry_id = int(raw_id)
        if entry_id in seen_ids:
            problems.error(f"{label}: id {entry_id} appears twice")
            continue
        seen_ids.add(entry_id)

        if entry_id in TEMPLATE_CORRECTIONS:
            wrong, right, reason = TEMPLATE_CORRECTIONS[entry_id]
            if template == wrong:
                template = right
                problems.note(f"{label}: corrected the infix template; {reason}")
            else:
                problems.note(f"{label}: the source no longer needs its template correction")

        if not navi or not NAVI_LETTERS.match(navi):
            problems.error(f"{label}: headword contains characters outside the Na'vi alphabet")
            continue
        if not definition:
            problems.error(f"{label}: no English definition")
            continue

        codes = [code.strip() for code in pos.split(",") if code.strip()]
        unknown = [code for code in codes if code not in PARTS_OF_SPEECH]
        if not codes or unknown:
            problems.error(f"{label}: unknown part of speech {pos!r}")
            continue

        is_verb = any(code.startswith("v") for code in codes)
        if template:
            check_template(navi, template, label, problems)
            if not is_verb:
                problems.note(f"{label}: a {pos} with an infix template; it is inflected like a verb")
        elif is_verb:
            problems.note(f"{label}: a verb with no infix template, so it is never inflected")

        grammar = [f"genitive={form}" for form in IRREGULAR_FORM.findall(definition)]
        attested = ATTESTED_FORMS.get((navi, ", ".join(codes)))
        if attested:
            grammar.append(attested[0])
        if navi in LOANWORDS_ENDING_IN_I:
            grammar.append("loanword")
        entries.append({
            "id": str(entry_id),
            "navi": navi,
            "pos": ", ".join(codes),
            "infixes": template,
            "grammar": ";".join(grammar),
            "en": " ".join(definition.split()),
        })

    entries.sort(key=lambda entry: int(entry["id"]))
    return entries


def check_curated_words(entries: list[dict[str, str]], problems: Problems) -> None:
    """Every word the curated tables name must still be in the source, or its grammar
    would silently stop applying."""
    found = {(entry["navi"], entry["pos"]) for entry in entries}
    for navi, pos in ATTESTED_FORMS:
        if (navi, pos) not in found:
            problems.error(f"{navi} ({pos}), which has an attested form, is no longer in the source")
    names = {entry["navi"] for entry in entries}
    for word in sorted(LOANWORDS_ENDING_IN_I - names):
        problems.error(f"the loanword {word} is no longer in the source")


def render(entries: list[dict[str, str]], digest: str, retrieved: str) -> str:
    lines = [
        "# NaviGrammar lexicon. Generated by Scripts/build_grammar_lexicon.py; do not edit by hand.",
        f"# source\t{SOURCE_URL}",
        f"# retrieved\t{retrieved}",
        f"# sha256\t{digest}",
        f"# entries\t{len(entries)}",
        f"# credit\t{CREDIT}",
        "\t".join(LEXICON_COLUMNS),
    ]
    lines += ["\t".join(entry[column] for column in LEXICON_COLUMNS) for entry in entries]
    return "\n".join(lines) + "\n"


def fetch() -> None:
    SOURCE_FILE.parent.mkdir(parents=True, exist_ok=True)
    print(f"Downloading {SOURCE_URL}")
    with urllib.request.urlopen(SOURCE_URL, timeout=60) as response:  # noqa: S310 - fixed https URL
        SOURCE_FILE.write_bytes(response.read())


def build() -> tuple[str | None, Problems]:
    problems = Problems()
    if not SOURCE_FILE.exists():
        problems.error(f"{SOURCE_FILE.relative_to(ROOT)} is missing; run with --fetch")
        return None, problems

    data = SOURCE_FILE.read_bytes()
    retrieved = datetime.datetime.fromtimestamp(
        SOURCE_FILE.stat().st_mtime, tz=datetime.timezone.utc
    ).date().isoformat()
    entries = parse_source(data.decode("utf-8"), problems)
    check_curated_words(entries, problems)
    if problems.errors:
        return None, problems
    return render(entries, hashlib.sha256(data).hexdigest(), retrieved), problems


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__.strip().splitlines()[0])
    parser.add_argument("--fetch", action="store_true", help="download the source data first")
    parser.add_argument("--check", action="store_true", help="fail if the lexicon is out of date")
    arguments = parser.parse_args()

    if arguments.fetch:
        fetch()
    lexicon, problems = build()

    for note in problems.notes:
        print(f"  note: {note}")
    for error in problems.errors:
        print(f"  error: {error}", file=sys.stderr)
    if lexicon is None:
        return 1

    count = lexicon.count("\n") - 7
    if arguments.check:
        current = LEXICON_FILE.read_text(encoding="utf-8") if LEXICON_FILE.exists() else ""
        # The retrieval date follows the download, so it is not part of the comparison.
        strip = lambda text: re.sub(r"^# retrieved\t.*$", "", text, flags=re.MULTILINE)  # noqa: E731
        if strip(current) != strip(lexicon):
            print(f"{LEXICON_FILE.relative_to(ROOT)} is out of date; rebuild it", file=sys.stderr)
            return 1
        print(f"{LEXICON_FILE.relative_to(ROOT)} is up to date ({count} entries)")
        return 0

    LEXICON_FILE.parent.mkdir(parents=True, exist_ok=True)
    LEXICON_FILE.write_text(lexicon, encoding="utf-8")
    print(f"Wrote {count} entries to {LEXICON_FILE.relative_to(ROOT)}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
