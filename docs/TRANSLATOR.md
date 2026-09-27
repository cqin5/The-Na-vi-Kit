# The Na'vi Translator

Eywa can read Na'vi as well as look it up. Search recognises inflected words, and the
Translate tab glosses a passage word by word. Both run on a grammar engine,
**NaviGrammar**, that works entirely on the device.

---

## 1. What it does

**Search finds inflected forms.** The dictionary lists base words only, so a search
for *oel*, *ngati* or *kameie* — the words of *Oel ngati kameie*, "I see you" — used
to find nothing. Search now reads the query as an inflected form and shows the entry
it comes from, with a one-line analysis:

| Query | Shown above the entry |
|-|-|
| oel | oel → oe + agentive |
| ngati | ngati → nga + patientive |
| kameie | kameie → kame + «ei» laudative |

**The Translate tab glosses a passage.** Paste or type Na'vi, and each word shows
the word it comes from, that word's English meaning, and the grammar of the form,
each feature labelled and explained in plain English. Multi-word entries such as
*irayo si* "thank" are pointed out. When a word can be read more than one way, every
reading is listed, most likely first. A word the engine cannot account for is marked
**Not in the dictionary**, with the reason, and is never guessed at.

**The Phrasebook tab** opens on a short list: six Basics pages (pronunciation,
numbers, time, times of day, pronouns and questions) and seven topics of everyday
phrases and sayings, each on a screen of its own. Choosing a phrase reads it word by
word. The Numbers page converts between numbers and Na'vi number words, both ways.

Nothing typed or pasted leaves the device.

---

## 2. How it works

### 2.1 Components

| Part | Where | Role |
|-|-|-|
| Lexicon builder | `Scripts/build_grammar_lexicon.py` | Downloads the LearnNavi dictionary data and writes the lexicon |
| Lexicon | `Packages/NaviGrammar/Sources/NaviGrammar/Resources/lexicon.tsv` | 3,045 words: headword, part of speech, infix template, definition, grammar notes |
| `Generator` | NaviGrammar | Inflects a word: case, number, determiners, adpositions, infixes, derivations |
| `Analyser` | NaviGrammar | Takes a word apart and ranks its readings |
| `TextReader` | NaviGrammar | Splits a passage into words, finds multi-word entries, handles lenition across words |
| `GrammarSearch` | `Na'vi/GrammarSearch.swift` | Connects readings to the app's dictionary entries |
| `Numeral` | NaviGrammar | Builds and reads number words by the number system of appendix A |
| Screens | `Na'vi/WordFormRow.swift`, `Na'vi/TranslateView.swift`, `Na'vi/PhrasebookView.swift` | Search results, the Translate screen and the phrasebook |
| Basics pages | `Na'vi/NumbersView.swift`, `Na'vi/PronunciationView.swift`, `Na'vi/PronounsView.swift`, `Na'vi/WordListView.swift` | The phrasebook's numbers, alphabet, pronouns, and word lists |
| Phrasebook | `Na'vi/Phrasebook.swift` | Phrases from appendix F, by topic, with English renderings |
| Basics | `Na'vi/Basics.swift` | Words for the Basics pages, the alphabet of appendix G, and appendix F's phrases about age |

NaviGrammar is a local Swift package with no dependency beyond Foundation, written
in the Swift 6 language mode with value types throughout, for iOS 18 and later. It
imports neither UIKit nor SwiftUI, so the keyboard extension can use it later.

### 2.2 The lexicon

The engine needs each word's part of speech and, for verbs, where the infixes go.
Only the LearnNavi dictionary data records both, so the lexicon is generated from it:

```bash
python3 Scripts/build_grammar_lexicon.py --fetch
```

The script downloads `dictionary-v2.txt` into `SourceData/`, which git ignores, and
writes `lexicon.tsv`. The lexicon's header records the source URL, the date it was
retrieved, the source file's SHA-256 checksum, the number of entries and the credits.
Its columns are the LearnNavi id, the headword, the part of speech, the infix
template (such as `k<0><1>am<2>e` for *kame*), grammar notes and the English
definition.

The script checks every row. It fails on a changed header, a malformed row, a
repeated id, an unknown part of speech, or an infix template that does not spell its
headword. It reports entries the engine treats specially, such as *'ulte*, whose
template marks no infix positions. Two typing errors in the source's templates are
corrected by id (a missing tìftang in *'asap si*, a stray syllable dot in *kxapay
si*); each correction applies only while the source still has the error.

The grammar notes carry facts the data does not:

- irregular genitives that the definitions spell out (*soaiä*, *sneyä*);
- genitives Dr. Frommer has used that the data lacks (*peyä*, *feyä*, *mefeyä*,
  *ayfeyä*, *tseyä*, *Omatikayaä*), each with its source in the script;
- the loanwords from appendix C of the LearnNavi dictionary that end in an added -ì.

The lexicon is a separate file from the app's `vocabulary.json`. Neither refers to
the other. Search matches a reading to vocabulary entries at run time, by headword
and a shared part of speech, so that *tsun* "heel" is not shown for *tsun* "can".
When the vocabulary does not have the base word, the lexicon's own definition is
shown instead.

### 2.3 Generating and analysing

The `Generator` produces every spelling that a word and a set of grammatical features
allow. For example, the patientive of *nga* "you" is both *ngat* and *ngati*. It
produces nothing for a combination that the word's class does not take, such as a
case ending on a verb.

The `Analyser` works in the opposite direction. It removes candidate affixes, undoes
lenition and looks up the stems that remain. It then **keeps a reading only if the
generator, given that reading, produces the word being analysed**. Two properties
follow:

- The analyser never accepts a form that the rules do not produce.
- Any form the generator can produce, the analyser can explain. The round-trip test
  in §4 checks this across the whole lexicon.

Readings are ranked by the number of affixes they need. Readings that depend on an
optional or restricted form rank a little lower.

- **Genuine ambiguity is kept.** *'ur* is both 'ur "sight" and 'u "thing" with the
  dative ending, and both readings are listed.
- **Duplicate readings of one word are folded.** A reading that builds, with a
  word-forming affix, a word the dictionary lists on its own is folded into that
  word. For example, *'itetsyìpit* is read as *'itetsyìp* "little daughter" plus the
  patientive, not as 'ite plus -tsyìp plus the patientive.

A word that no reading explains is reported as unknown, with one of three reasons:
it is empty; it uses letters that Na'vi does not; or no dictionary word, with the
endings, prefixes and infixes the engine knows, makes that form.

### 2.4 The phrasebook

The phrasebook's Na'vi is taken verbatim from appendix F, "Useful Phrases", of the
LearnNavi dictionary, most of which comes from Dr. Frommer's blog. The English
renderings and notes are this app's own. An ellipsis stands where appendix F writes X
for a word the learner puts in: *… nìNa'vi slu pelì'u?* "How do you say … in Na'vi?".
Phrases whose words the engine does not know are left out of the topics. The Numbers
page shows the two about age, *Ngari solalew polpxaya zìsìt?* and *Oeri solalew zìsìt
apxevol*, without linking them to Translate.

The Basics pages draw on the dictionary's other appendices and its word list:

| Page | Source |
|-|-|
| Pronunciation | The 33 letters of appendix G and their names; each letter's example is a word the app has a recording of |
| Numbers | Appendix A, through `Numeral`, and the digit names *'eyt* and *nayn* |
| Time, Times of Day | The days of the week and the parts of the day from appendix B; other time words from the dictionary |
| Pronouns, Questions | Dictionary headwords; each pronoun's case forms come from the generator |

Every word on these pages is a headword of the lexicon or the vocabulary, except
*menga* "you two", which appendix A uses: *Menga lu karyu*, "You two are teachers".
A word's pronunciation and recording come from the vocabulary entry with the same
headword.

The pre-flight checks confirm that every phrase appears in appendix F, that every
Basics word is in the dictionary, and that the alphabet is appendix G's. The engine's
tests check every word of every appendix F phrase.

### 2.5 Reading a passage

`TextReader` splits a passage at spaces and punctuation. Apostrophes (the tìftang)
and hyphens inside a word stay part of it. If a word is not known with a leading or
trailing apostrophe, the reader tries it again without, since the apostrophe may
have been a quotation mark.

A word directly after *mì+* or one of the other leniting adpositions is also read as
lenited: *mì Helutral* gives Kelutral "Hometree". The reader finds multi-word entries
such as *tìng mikyun* "listen", including their inflected forms (*tivìng mikyun*).

---

## 3. Grammar rules and their sources

The primary source is appendix H, "Inflections", of the LearnNavi Na'vi–English
dictionary, version 16.1.0 (12 April 2026). Where appendix H is silent, the engine
follows Dr. Paul Frommer's own usage, cited below. The rules are implemented in the
engine's code and described here in our own words.

### 3.1 From appendix H

| Area | Rule |
|-|-|
| Verb infixes, position 0 | «äp» reflexive, «eyk» causative |
| Verb infixes, position 1 | «am», «ìm», «ay», «ìy», «asy», «ìsy» (tense); «ol», «er» (aspect); «alm», «ìlm», «aly», «ìly», «arm», «ìrm», «ary», «ìry» (both); «iv», «imv», «iyev» or «ìyev», «ilv», «irv» (subjunctive); «us», «awn» (participles) |
| Verb infixes, position 2 | «ei» laudative, «äng» pejorative (optionally «eng» before *i*), «uy» honorific, «ats» inferential |
| Where infixes go | Each verb's position from the dictionary's infix template, including verbs marked irregular (ii) and multi-word verbs |
| Case after a vowel | -l agentive, -t or -ti patientive, -ru or -r dative, -ri topical |
| Case after a consonant, diphthong or pseudovowel | -ìl, -it or -ti, -ur, -ìri |
| Genitive | -yä after a, ä, e, i and ì; -ä otherwise; a pronoun's final *a* becomes *e* (nga → ngeyä); a casual -y for pronouns ending in *a* or *e* (ngey) |
| Vocative | -ya, which appendix H gives for collective nouns |
| Number | me+ dual, pxe+ trial, ay+ plural; each lenites |
| Determiners | fì- this, tsa- that, pe+ which, fra- every, fay+ these, tsay+ those, pay+ which (plural), fray+ all of these, fne- kind of, munsna- pair of |
| Other suffixes | -tsyìp diminutive, -fkeyk state, -o indefinite, -pe interrogative |
| Adjectives | the attributive a before or after (*aean*, *txantsana*); nì- adverbs |
| Derivations | -yu agent noun, -tswo ability, -tseng place, tì- with «us» gerund, tsuk- and ketsuk- able and unable, -ve ordinal |

Affixes that appendix H marks as unproductive, such as le-, sä-, kaw-, -nay and -tu,
are never applied. The words formed with them are in the dictionary.

Appendix H swaps the descriptions of «ìlm» and «ìly». Its derivations (ìm + ol, ìy +
ol) and its examples (*tìlmätxaw* "I just now returned", *hìlyahaw* "I will have
slept soon") agree that «ìlm» is the recent past perfective and «ìly» the near-future
perfective, and the engine follows them.

The dictionary's front matter says that an adposition placed after its noun attaches
to it as a suffix (*kelkumì*), and marks leniting adpositions with +. The dictionary
notes that *sì* "and" can be attached as a suffix, and that *to* "than" behaves like
an adposition.

### 3.2 From Dr. Frommer's usage

| Rule | Example | Source |
|-|-|-|
| Lenition: px, tx, kx → p, t, k; p, t, ts, k → f, s, s, h; the tìftang disappears | tute → aysute | Language Log, 19 December 2009, <https://languagelog.ldc.upenn.edu/nll/?p=1977> |
| A tìftang before ll or rr stays | me'llngo, ay'llngo | <https://naviteri.org/2012/03/spring-vocabulary-part-1/> |
| A vowel doubled across a prefix is written once | pekxinum, meylan | <https://naviteri.org/2012/07/meetings-waterfalls-and-more/> |
| Plural by lenition alone, only when the first sound lenites | sokx | Language Log (above); <https://naviteri.org/2010/09/quick-follow-up/> |
| After a leniting adposition a lenited noun is singular | mì hilvan | <https://naviteri.org/2010/07/thoughts-on-ambiguity/> |
| «äp» and «eyk» combine as «äpeyk» | 'äpeykamrrko | <https://naviteri.org/2015/04/some-new-words-for-may-day/> |
| «ei» becomes «eiy» before i or a pseudovowel | seiyi, veiyll | <https://naviteri.org/2012/06/spring-vocabulary-part-3/>; <https://naviteri.org/2018/11/seiyi-oe-irayo-i-am-thankful/> |
| «ol» absorbs a following ll | vol, poltxe | <https://naviteri.org/2012/06/spring-vocabulary-part-3/> |
| After a diphthong, -t and -r too | wayt, 'etnawr | <https://naviteri.org/2013/01/awvea-posti-zisita-amip-first-post-of-the-new-year/> |
| After a final tìftang, -ru and -ri too | olo'ru, olo'ri | <https://naviteri.org/2026/04/hiia-tisung-postiya-aham-follow-up-to-the-previous-post/> |
| Pronouns in -ng take endings on a stem in -a | oengaru, oengari | <https://naviteri.org/2011/12/one-more-for-2011/>; <https://naviteri.org/2023/07/trr-tsyimawnuniya-lefpom-happy-independence-day/> |
| Irregular pronoun genitives | peyä; feyä, mefeyä; ayfeyä; tseyä | <https://naviteri.org/2020/12/mrra-tipangkxotsyip-five-little-discussions/>; <https://naviteri.org/2023/09/aawa-ayliu-si-aylifyavi-amip-a-few-new-words-and-expressions/>; <https://naviteri.org/2026/06/tskxekeng-a-mikyunfpi-pamrel-listening-exercise-text/>; a reply by Dr. Frommer under <https://naviteri.org/2017/02/ayioang-amip-si-ayu-alahe-new-animals-and-other-things/> |
| Nouns in -ia: genitive -iä | soaiä | <https://naviteri.org/2011/05/some-miscellaneous-vocabulary/> |
| Irregular genitive of Omatikaya | Omatikayaä | <https://naviteri.org/2012/10/mipa-vospxi-mipa-ayliu-new-words-for-the-new-month/> |
| A loanword's added -ì gives way to the case ending | Kelnit, Kelnur, Kelnä | <https://naviteri.org/2022/01/aawa-tipangkxotsyip-a-teri-horen-lifyaya-a-few-little-discussions-about-grammar/> |
| Reef spellings: ù is written u in the forest dialect; b, d and g may spell px, tx and kx | tsùn, adge | <https://naviteri.org/2023/01/reef-navi-part-1-phonetics-and-phonology/>; <https://naviteri.org/2023/01/2653/> |
| The Reef dialect keeps «ei» before i | seii | <https://naviteri.org/2023/01/2653/> |

A reading that uses a Reef spelling or a Reef form is marked as such.

### 3.3 What the engine does not cover

These words and forms are reported as unknown rather than guessed at:

- **Compound numbers in a passage.** `Numeral` builds and reads the numbers of
  appendix A (for example *pxevol* "24"), and the phrasebook's Numbers page uses it,
  but the analyser does not consult it, so Translate reports *pxevol* as unknown.
  Numbers the dictionary lists are known.
- **Time words with -am and -ay.** Appendix H limits these suffixes to time words,
  and the lexicon does not mark which words those are. The common forms, such as
  *trram* and *trray*, are in the dictionary.
- **The group prefix sna-.** It is productive only for living things, which the
  lexicon does not mark.
- **Number or determiner prefixes on names.** Appendix H illustrates fray+ with
  *frayhelutral*, but the dictionary lists *Kelutral* only as a proper noun. The test
  suite records this as a known issue.
- **Forms no source documents:**
  - «er» before rr;
  - adpositions after the pronouns in -ng;
  - genitives of the other pronouns in -o (*frapo*, *fìpo*, *tsapo*, *fko*, …);
  - dual or trial numbers with a determiner;
  - case endings on multi-word nouns;
  - colloquial contractions such as *tsafa*.
- **Reef grammar** beyond the spellings above.

---

## 4. Verification

### 4.1 How to run the checks

```bash
cd Packages/NaviGrammar && swift test
```

```bash
./build-verify.sh
```

```bash
python3 Scripts/test_build_grammar_lexicon.py
```

```bash
python3 Scripts/test_preflight.py
```

`swift test` runs the engine's tests, written with Swift Testing. Setting
`NAVIGRAMMAR_REPORT` to a file path makes the round-trip test list every ambiguous form
in that file. `./build-verify.sh` runs the pre-flight checks and then builds the app.
The two Python files test the lexicon builder and the pre-flight checks.

### 4.2 What the tests cover

| Suite | What it checks |
|-|-|
| Appendix H examples | Every example form in appendix H: generated from its base word, then analysed back, with the book's reading ranked first |
| Appendix F phrases | Every word of the dictionary's 111 useful phrases has a reading, except three documented gaps; 30 readings and 6 multi-word entries checked in detail |
| Appendix A numbers | Every number word in appendix A's charts, both ways; every number from 0 to 32,767 has one word, which reads back as that number; misspellings such as *volmun* rejected; typed digits in any script |
| Dr. Frommer's forms | 47 forms from the posts in §3.2, and forms those posts rule out (*soaiayä*, *oengìl*, *kelnìt*, …) |
| Analyser | *Oel ngati kameie*; normalisation of capitals, curly apostrophes, decomposed letters and hyphens; unknown words and their reasons; ambiguity; each rule |
| Orthography, Lexicon, Text reader | Lenition both ways; malformed lexicon lines rejected with their line number; tokenising, phrases, quotation marks and long passages |
| Round trip | Every case and number of every noun and pronoun, and every combination of infixes on every verb, traced back to its source |

### 4.3 Round-trip results

| | Nouns and pronouns | Verbs |
|-|-|-|
| Forms generated | 48,130 | 312,959 |
| Not traced back to their source | 0 | 0 |
| Read as a word the dictionary lists | 0 | 3,100 |
| Also read as another word | 407 | 69 |
| Read as more than one inflection of the same word | 0 | 31 |

"Read as a word the dictionary lists" covers forms such as *ioi säpami*. It is *ioi
si* with «äp» and «am», and the engine reads it as the listed reflexive *ioi säpi*
with «am».

The remaining ambiguities are real, and the engine lists every reading. Two examples:

- *hilvan* is both *han* with «ilv» and *kilvan* "river" pluralised by lenition.
- *luyu* is both *lu* with «uy» and *lu* + -yu "one who is"; verbs ending in u show
  this systematically.

### 4.4 Pre-flight checks

`Scripts/preflight.py` confirms that every phrasebook phrase comes from appendix F,
that every word on the Basics pages is in the dictionary, that their alphabet is
appendix G's, each letter with its name and a recorded example, and three things about
the package:

- the app links NaviGrammar;
- its sources import neither UIKit nor SwiftUI;
- the bundled lexicon is complete: the column header, a row count that matches its
  header, unique ids, the source checksum and the credits.

The package's sources are also scanned for deprecated API, as the app's are.

---

## 5. For the keyboard extension

The engine is ready for the keyboard, though the keyboard does not use it yet:

- It depends only on Foundation, needs neither Full Access nor a network connection,
  and reads nothing but its bundled lexicon.
- The lexicon is 125 KB of text. On an Apple-silicon Mac, loading it and building
  the analyser's indexes takes about 40 ms in a release build, and analysing a word
  about 0.1 ms. Loading can be deferred until first use. The extension's memory use
  should be measured on a device as part of the keyboard work.
- Words are analysed as they are passed in; nothing is stored or sent anywhere.

---

## 6. Updating the lexicon

When LearnNavi publishes new data:

1. Run `python3 Scripts/build_grammar_lexicon.py --fetch`, and read its notes and
   errors.
2. Run `swift test` in the package, and review any change in the round-trip counts.
3. Commit the new `lexicon.tsv`.

`python3 Scripts/build_grammar_lexicon.py --check` reports whether the committed
lexicon matches the downloaded source.

---

## 7. Sources and credits

- **Vocabulary and grammar:** the LearnNavi Na'vi dictionary
  (<https://tirea.learnnavi.org/dictionarydata/dictionary-v2.txt> and
  <https://files.learnnavi.org/dicts/NaviDictionary.pdf>), compiled by Roland
  "Tìtstewan" R. S. et al. and originally created by Richard Littauer.
- **Clarifications:** Dr. Paul Frommer's posts on naviteri.org and Language Log,
  cited rule by rule in §3.2.
- **The Na'vi language** was created by Dr. Paul Frommer.

The app credits these sources on the Translate screen. Other Na'vi tools, such as
Reykunyu and Fwew, were not used as sources, and no code or data was taken from them.
