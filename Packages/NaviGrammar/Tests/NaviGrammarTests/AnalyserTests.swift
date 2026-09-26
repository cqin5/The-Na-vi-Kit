//
//  AnalyserTests.swift
//  NaviGrammarTests
//

import Testing
@testable import NaviGrammar

@Suite("Analyser")
struct AnalyserTests {

    // MARK: - The acceptance case

    /// Oel ngati kameie "I see you". Appendix H gives each rule used: -l is the
    /// agentive after a vowel, -ti the patientive of pronouns and nouns, and «ei» the
    /// laudative infix of position 2, which kame's template k<0><1>am<2>e puts before
    /// the final e.
    @Test("Oel ngati kameie")
    func oelNgatiKameie() throws {
        let expected = [
            ("oel", "oe", Inflection.case(.agentive), "oe + agentive"),
            ("ngati", "nga", Inflection.case(.patientive), "nga + patientive"),
            ("kameie", "kame", Inflection.verb(nil, nil, .laudative), "kame + «ei» laudative"),
        ]
        for (word, base, inflection, summary) in expected {
            let best = try #require(Fixture.analyser.analyse(word).analyses.first, "\(word) is unknown")
            #expect(best.entry.form == base)
            #expect(best.inflection == inflection)
            #expect(best.summary == summary)
        }
    }

    @Test("Capitals, curly apostrophes, decomposed letters and hyphens are normalised")
    func normalisation() {
        for spelling in ["Oel", "OEL", " oel\n", "oel"] {
            #expect(Fixture.summaries(spelling).first == "oe + agentive", "\(spelling.debugDescription)")
        }
        // Smart Punctuation's apostrophe, and the modifier letter apostrophe.
        #expect(Fixture.analyser.analyse("\u{2019}eylan").analyses.first?.entry.form == "'eylan")
        #expect(Fixture.analyser.analyse("\u{02BC}eylan").analyses.first?.entry.form == "'eylan")
        // ä written as a + combining diaeresis.
        #expect(Fixture.analyser.analyse("ta\u{0308}txaw").analyses.first?.entry.form == "tätxaw")
        // A hyphen marking a suffix: t«awn»aron-a.
        #expect(Fixture.summaries("tawnaron-a").first == "taron + «awn» passive participle + -a attributive")
    }

    // MARK: - Unknown words are reported, never guessed

    @Test("Unknown words", arguments: [
        ("", UnknownReason.empty),
        ("   ", .empty),
        ("Jake", .notNaviSpelling),
        ("blorp", .notNaviSpelling),
        ("🙂", .notNaviSpelling),
        ("oep", .notFound),          // one letter from oe + agentive
        ("tstststs", .notFound),
        ("ngayä", .notFound),        // a pronoun ending in a fronts it: ngeyä
        ("soaiayä", .notFound),      // the dictionary gives soaiä instead
        ("tsawìl", .notFound),       // tsaw's agentive is the separate word tsal
        ("ayoel", .notFound),        // pronouns take no number prefix... and ayoe + l is below
    ])
    func unknown(_ word: String, _ reason: UnknownReason) {
        let analysis = Fixture.analyser.analyse(word)
        if word == "ayoel" {
            // ayoel is known — as ayoe "we" + agentive, not as ay+ oe.
            #expect(analysis.analyses.map(\.summary) == ["ayoe + agentive"])
            return
        }
        #expect(!analysis.isKnown, "readings were \(analysis.analyses.map(\.summary))")
        #expect(analysis.unknownReason == reason)
    }

    @Test("A word of whitespace or punctuation only has no readings")
    func punctuationOnly() {
        #expect(!Fixture.analyser.analyse("\u{00A0}").isKnown)
        #expect(!Fixture.analyser.analyse("?!").isKnown)
    }

    // MARK: - Ambiguity is shown

    @Test("Every reading is kept when a form has several")
    func ambiguity() {
        // han + «ilv», or kilvan "river" pluralised by lenition alone.
        let hilvan = Fixture.summaries("hilvan")
        #expect(hilvan.contains("han + «ilv» perfective subjunctive"))
        #expect(hilvan.contains("kilvan + plural (by lenition)"))

        // 'ur "sight", and 'u "thing" + dative: two different words.
        let ur = Fixture.summaries("'ur")
        #expect(ur.first == "'ur")
        #expect(ur.contains("'u + dative"))

        // lu + «uy» honorific, and lu + -yu "one who is": the inflection ranks first.
        #expect(Fixture.summaries("luyu").prefix(2) == ["lu + «uy» honorific", "lu + -yu agent noun"])
    }

    @Test("A word the dictionary lists is read as that word, not rebuilt from its parts")
    func lexicalisedWords() {
        let analysis = Fixture.analyser.analyse("'itetsyìpit")
        #expect(analysis.analyses.map(\.summary) == ["'itetsyìp + patientive"])
        #expect(analysis.folded.map(\.summary) == ["'ite + -tsyìp diminutive + patientive"])
    }

    // MARK: - Individual rules

    @Test("Irregular genitives come from the dictionary")
    func irregularGenitive() {
        #expect(Fixture.summaries("soaiä").contains("soaia + genitive (irregular)"))
        #expect(Fixture.summaries("sneyä").contains("sno + genitive (irregular)"))
    }

    @Test("Pronoun genitives front a final a, and pronouns ending in a or e have a casual -y")
    func pronounGenitives() {
        #expect(Fixture.summaries("ngeyä").first == "nga + genitive")
        #expect(Fixture.summaries("ngey").first == "nga + genitive (casual)")
        #expect(Fixture.summaries("oey").first == "oe + genitive (casual)")
        #expect(Fixture.summaries("oeyä").first == "oe + genitive")
    }

    @Test("Case endings follow the last sound: vowel, consonant, diphthong or pseudovowel")
    func caseAllomorphs() {
        // Vowel: -l, -t/-ti, -ru/-r, -yä, -ri.
        #expect(Fixture.forms("tute", .noun, .case(.agentive)) == ["tutel"])
        #expect(Fixture.forms("tute", .noun, .case(.patientive)) == ["tutet", "tuteti"])
        #expect(Fixture.forms("tute", .noun, .case(.dative)) == ["tuteru", "tuter"])
        #expect(Fixture.forms("tute", .noun, .case(.genitive)) == ["tuteyä"])
        // Consonant: -ìl, -it/-ti, -ur, -ä, -ìri.
        #expect(Fixture.forms("ikran", .noun, .case(.agentive)) == ["ikranìl"])
        #expect(Fixture.forms("ikran", .noun, .case(.patientive)) == ["ikranit", "ikranti"])
        #expect(Fixture.forms("ikran", .noun, .case(.topical)) == ["ikranìri"])
        // Diphthong (ew) and pseudovowel (ll) take the consonant forms.
        #expect(Fixture.forms("swizaw", .noun, .case(.agentive)) == ["swizawìl"])
        #expect(Fixture.forms("'ewll", .noun, .case(.dative)) == ["'ewllur"])
        // o and u take -ä, not -yä.
        #expect(Fixture.forms("'u", .noun, .case(.genitive)) == ["'uä"])
    }

    @Test("Leniting prefixes soften the first consonant; e + e is elided")
    func lenitingPrefixes() {
        #expect(Fixture.forms("tute", .noun, .case(.subjective, prefix: .plural)) == ["aysute"])
        #expect(Fixture.forms("tute", .noun, .case(.subjective, prefix: .shortPlural)) == ["sute"])
        #expect(Fixture.forms("'eylan", .noun, .case(.subjective, prefix: .dual)) == ["meylan"])
        #expect(Fixture.forms("'eylan", .noun, .case(.subjective, prefix: .plural)) == ["ayeylan"])
        // fì- does not lenite.
        #expect(Fixture.forms("tute", .noun, .case(.subjective, prefix: .this)) == ["fìtute"])
        // A noun whose first sound does not lenite has no short plural.
        #expect(Fixture.forms("ikran", .noun, .case(.subjective, prefix: .shortPlural)).isEmpty)
    }

    @Test("Classes take only their own inflections")
    func classRestrictions() {
        // No case ending on a verb, no infix on a noun, no number prefix on a pronoun or name.
        #expect(Fixture.forms("taron", .verb, .case(.agentive)).isEmpty)
        #expect(Fixture.forms("tute", .noun, .verb(nil, .past)).isEmpty)
        #expect(Fixture.forms("oe", .pronoun, .case(.subjective, prefix: .plural)).isEmpty)
        #expect(Fixture.forms("Eywa", .properNoun, .case(.subjective, prefix: .dual)).isEmpty)
        // An entry is only inflected as a class it belongs to.
        #expect(Fixture.generator.forms(of: Fixture.entry("tute", .noun), as: .verb, .none).isEmpty)
    }

    @Test("A word after a leniting adposition is read unlenited")
    func contextLenition() {
        let lenited = Fixture.analyser.analyse("Helutral", afterLenitingWord: true)
        #expect(lenited.analyses.first?.summary == "Kelutral + lenited")
        // Without the adposition there is nothing to explain the h.
        #expect(!Fixture.analyser.analyse("Helutral").isKnown)
    }

    @Test("Multi-word verbs take their infixes in the word the template marks")
    func multiwordVerbs() {
        #expect(Fixture.summaries("irayo sivi").first == "irayo si + «iv» subjunctive")
        #expect(Fixture.summaries("tolìng mikyun").first == "tìng mikyun + «ol» perfective")
        #expect(Fixture.forms("irayo si", .verb, .verb(nil, .past)) == ["irayo sami"])
    }

    @Test("Derived words are recognised")
    func derivations() {
        #expect(Fixture.summaries("tìkusar").first == "kar + tì- «us» gerund")
        // tsukyom "edible" is listed, so it is read as itself; tsuktaron is not.
        #expect(Fixture.summaries("tsukyom") == ["tsukyom"])
        #expect(Fixture.summaries("tsuktaron").first == "taron + tsuk- able to be")
        #expect(Fixture.summaries("aysaronyu").contains("taronyu + ay+ plural"))
        #expect(Fixture.summaries("nìtxan").first == "nìtxan")
    }
}
