//
//  AppendixHTests.swift
//  NaviGrammarTests
//
//  Every example form in appendix H of the LearnNavi dictionary (version 16.1.0),
//  generated from its base word and analysed back. The sentence each example comes
//  from is in the comment beside it.
//

import Testing
@testable import NaviGrammar

@Suite("Appendix H examples")
struct AppendixHTests {

    struct VerbExample: CustomTestStringConvertible, Sendable {
        let verb: String
        let infixes: Inflection
        let form: String
        var testDescription: String { form }
    }

    static let verbalInfixes: [VerbExample] = [
        VerbExample(verb: "tsngawvìk", infixes: .verb(nil, .pastPerfective), form: "tsngalmawvìk"),           // Oe tsng«alm»awvìk.
        VerbExample(verb: "hangham", infixes: .verb(nil, .futurePerfective), form: "halyangham"),             // Oe h«aly»angham.
        VerbExample(verb: "tswayon", infixes: .verb(nil, .past), form: "tswamayon"),                          // Oe tsw«am»ayon.
        VerbExample(verb: "srew", infixes: .verb(nil, nil, .pejorative), form: "srängew"),                    // Oe sr«äng»ew.
        VerbExample(verb: "si", infixes: .verb(nil, nil, .pejorative), form: "sengi"),                        // ... s«eng»i oe.
        VerbExample(verb: "steftxaw", infixes: .verb(.reflexive), form: "stäpeftxaw"),                        // Oe st«äp»eftxaw.
        VerbExample(verb: "tsngawvìk", infixes: .verb(nil, .pastImperfective), form: "tsngarmawvìk"),         // Oe tsng«arm»awvìk.
        VerbExample(verb: "hangham", infixes: .verb(nil, .futureImperfective), form: "haryangham"),           // Oe h«ary»angham.
        VerbExample(verb: "tspang", infixes: .verb(nil, .intendedFuture), form: "tspasyang"),                 // Oel tsp«asy»ang palulukanit.
        VerbExample(verb: "tspang", infixes: .verb(nil, nil, .inferential), form: "tspatsang"),               // Oel tsp«ats»ang poanit.
        VerbExample(verb: "taron", infixes: .verb(nil, .passiveParticiple), form: "tawnaron"),                // Oe t«awn»aron-a túte lu.
        VerbExample(verb: "taron", infixes: .verb(nil, .future), form: "tayaron"),                            // Oel yerikit t«ay»aron.
        VerbExample(verb: "srew", infixes: .verb(nil, nil, .laudative), form: "sreiew"),                      // Oe sr«ei»ew.
        VerbExample(verb: "tìran", infixes: .verb(nil, .imperfective), form: "terìran"),                      // Oe t«er»ìran.
        VerbExample(verb: "terkup", infixes: .verb(.causative), form: "teykerkup"),                           // Oel t«eyk»erkup pot.
        // Appendix H swaps the descriptions of «ìlm» and «ìly»; its derivations and
        // examples agree that «ìly» is the near future and «ìlm» the recent past.
        VerbExample(verb: "hahaw", infixes: .verb(nil, .nearFuturePerfective), form: "hìlyahaw"),             // Oe h«ìly»ahaw.
        VerbExample(verb: "tslam", infixes: .verb(nil, .perfectiveSubjunctive), form: "tslilvam"),            // Oe new tsl«ilv»am.
        VerbExample(verb: "tätxaw", infixes: .verb(nil, .recentPastPerfective), form: "tìlmätxaw"),           // Oe t«ìlm»ätxaw.
        VerbExample(verb: "tswayon", infixes: .verb(nil, .recentPast), form: "tswìmayon"),                    // Oe tsw«ìm»ayon.
        VerbExample(verb: "takuk", infixes: .verb(nil, .pastSubjunctive), form: "timvakuk"),                  // ... nìngay timvakuk.
        VerbExample(verb: "tätxaw", infixes: .verb(nil, .recentPastImperfective), form: "tìrmätxaw"),         // Oe t«ìrm»ätxaw.
        VerbExample(verb: "tslam", infixes: .verb(nil, .imperfectiveSubjunctive), form: "tslirvam"),          // Oe new tsl«irv»am.
        VerbExample(verb: "hahaw", infixes: .verb(nil, .nearFutureImperfective), form: "hìryahaw"),           // Oe h«ìry»ahaw.
        VerbExample(verb: "tspang", infixes: .verb(nil, .intendedNearFuture), form: "tspìsyang"),             // Oel tsp«ìsy»ang palulukanit.
        VerbExample(verb: "wem", infixes: .verb(nil, .subjunctive), form: "wivem"),                           // ... oe w«iv»em.
        VerbExample(verb: "taron", infixes: .verb(nil, .nearFuture), form: "tìyaron"),                        // Oel yerikit t«ìy»aron.
        VerbExample(verb: "kame", infixes: .verb(nil, .futureSubjunctive), form: "kiyevame"),                 // Oel k«iyev»ame ngati.
        VerbExample(verb: "kame", infixes: .verb(nil, .futureSubjunctive), form: "kìyevame"),                 // Oel k«ìyev»ame ngati.
        VerbExample(verb: "tìran", infixes: .verb(nil, .perfective), form: "tolìran"),                        // Oe t«ol»ìran.
        VerbExample(verb: "taron", infixes: .verb(nil, .activeParticiple), form: "tusaron"),                  // Oe t«us»aron-a túte lu.
        VerbExample(verb: "lu", infixes: .verb(nil, nil, .honorific), form: "luyu"),                          // Na'viyä, l«uy»u hapxì.
        VerbExample(verb: "tspang", infixes: .verb(nil, .past), form: "tspamang"),                            // Tsawkeyit tspamang.
        VerbExample(verb: "kame", infixes: .verb(nil, .past), form: "kamame"),                                // Oel kamame frapot.
    ]

    @Test("Verbal infixes", arguments: verbalInfixes)
    func verbalInfix(_ example: VerbExample) throws {
        #expect(Fixture.forms(example.verb, .verb, example.infixes).contains(example.form))

        let readings = Fixture.analyser.analyse(example.form).analyses
        let reading = try #require(readings.first { $0.entry.form == example.verb && $0.inflection == example.infixes })
        // The book's reading ranks first, unless the dictionary lists the form as a
        // word of its own (kìyevame "goodbye").
        let first = try #require(readings.first)
        #expect(first.id == reading.id || first.isBareWord, "readings were \(readings.map(\.summary))")
    }

    struct NounExample: CustomTestStringConvertible, Sendable {
        let word: String
        let wordClass: WordClass
        let inflection: Inflection
        let form: String
        var testDescription: String { form }
    }

    static let nounInflections: [NounExample] = [
        NounExample(word: "ikran", wordClass: .noun, inflection: .case(.genitive), form: "ikranä"),           // Oel yom ikranä yerikit.
        NounExample(word: "ikran", wordClass: .noun, inflection: .case(.agentive), form: "ikranìl"),          // Ikranìl taron yerikit.
        NounExample(word: "yerik", wordClass: .noun, inflection: .case(.patientive), form: "yerikit"),        // Oel taron yerikit.
        NounExample(word: "oe", wordClass: .pronoun, inflection: .case(.agentive), form: "oel"),              // Oel taron yerikit.
        NounExample(word: "eltu", wordClass: .noun, inflection: .case(.dative), form: "eltur"),               // eltur tìtxen si
        NounExample(word: "aynga", wordClass: .pronoun, inflection: .case(.topical), form: "ayngari"),        // Ayngari zene hivum.
        NounExample(word: "nga", wordClass: .pronoun, inflection: .case(.dative), form: "ngaru"),             // Oel syuvet ngaru tìng.
        NounExample(word: "nga", wordClass: .pronoun, inflection: .case(.patientive), form: "ngat"),          // Oel ngat kame.
        NounExample(word: "nga", wordClass: .pronoun, inflection: .case(.patientive), form: "ngati"),         // Ngati taron torukìl.
        NounExample(word: "toruk", wordClass: .noun, inflection: .case(.agentive), form: "torukìl"),          // Ngati taron torukìl.
        NounExample(word: "'eylan", wordClass: .noun, inflection: .case(.dative, prefix: .plural), form: "ayeylanur"), // Ayeylanur oeyä.
        NounExample(word: "oe", wordClass: .pronoun, inflection: .case(.genitive), form: "oeyä"),             // Ayeylanur oeyä.
        NounExample(word: "nga", wordClass: .pronoun, inflection: .case(.genitive), form: "ngey"),            // Ngey toruk sìltsan lu.
        NounExample(word: "nga", wordClass: .pronoun, inflection: .case(.genitive), form: "ngeyä"),           // vowel fronting, -eyä
        NounExample(word: "Na'vi", wordClass: .properNoun, inflection: .case(.vocative), form: "na'viya"),    // Mawey, Na'viya.
        NounExample(word: "skxawng", wordClass: .noun, inflection: Inflection(prefix: .this, ending: .case(.topical)), form: "fìskxawngìri"), // Fìskxawngìri tsap'alute sengi oe.
        NounExample(word: "koren", wordClass: .noun, inflection: .case(.subjective, prefix: .plural), form: "ayhoren"),     // Ay+horen flä.
        NounExample(word: "'awkx", wordClass: .noun, inflection: .case(.subjective, prefix: .these), form: "fayawkx"),       // Fayawkx tsawl lu.
        NounExample(word: "nantang", wordClass: .noun, inflection: Inflection(prefix: .this, ending: .case(.patientive)), form: "fìnantangit"), // Oel kame fìnantangit.
        NounExample(word: "utral", wordClass: .noun, inflection: Inflection(prefix: .kindOf, suffix: .interrogative), form: "fneutralpe"), // Fneutralpe tsa'u lu?
        NounExample(word: "frapo", wordClass: .pronoun, inflection: .case(.patientive), form: "frapot"),      // Oel kamame frapot.
        NounExample(word: "'ora", wordClass: .noun, inflection: .case(.patientive, prefix: .dual), form: "meorati"),        // Oel new me+orati.
        NounExample(word: "hawnven", wordClass: .noun, inflection: .case(.subjective, prefix: .pairOf), form: "munsnahawnven"),
        NounExample(word: "tstal", wordClass: .noun, inflection: .case(.patientive, prefix: .whichPlural), form: "paystalit"), // Paystalit ngal tsrame'i?
        NounExample(word: "'eveng", wordClass: .noun, inflection: .case(.subjective, prefix: .trial), form: "pxeveng"),      // Pxoeng Pxe+veng lu.
        NounExample(word: "nantang", wordClass: .noun, inflection: Inflection(prefix: .that, ending: .case(.patientive)), form: "tsanantangit"), // Oel tse'a tsanantangit.
        NounExample(word: "'ora", wordClass: .noun, inflection: .case(.subjective, prefix: .those), form: "tsayora"),       // Tsayora txukx lu.
        NounExample(word: "tute", wordClass: .noun, inflection: Inflection(suffix: .indefinite, ending: .case(.patientive)), form: "tuteot"), // Oel kalmame tuteot ayzìsìto.
        NounExample(word: "zìsìt", wordClass: .noun, inflection: Inflection(prefix: .plural, suffix: .indefinite), form: "ayzìsìto"),
        NounExample(word: "krr", wordClass: .noun, inflection: .case(.subjective, prefix: .which), form: "pehrr"),          // pe+hrr nga lrrtok sayi.
        NounExample(word: "kilvan", wordClass: .noun, inflection: Inflection(suffix: .state), form: "kilvanfkeyk"),         // Kilvanfkeyk lu fyape fìtrr?
        NounExample(word: "po", wordClass: .pronoun, inflection: .case(.topical), form: "pori"),              // Pori wemtswo ...
    ]

    @Test("Noun inflections", arguments: nounInflections)
    func nounInflection(_ example: NounExample) throws {
        #expect(Fixture.forms(example.word, example.wordClass, example.inflection).contains(example.form))

        // The book's reading, or the listed word it builds: tuteot is read as tuteo
        // "somebody" + patientive, and pehrr as the interrogative pehrr "when".
        let analysis = Fixture.analyser.analyse(example.form)
        let isBooks = { (reading: Analysis) in
            reading.entry.form == Orthography.normalize(example.word) && reading.inflection == example.inflection
        }
        #expect(analysis.analyses.contains(where: isBooks) || analysis.folded.contains(where: isBooks),
                "readings were \(analysis.analyses.map(\.summary))")
    }

    /// Appendix H illustrates fray+ with Frayhelutral lor lu "All of these houses are
    /// beautiful", using kelutral as a common noun. The dictionary lists it only as
    /// the proper noun Kelutral "Hometree", and names take no number or determiner
    /// prefixes, so the engine does not produce the form.
    @Test("fray+ on kelutral, which the dictionary lists only as a name")
    func frayhelutral() {
        let kelutral = Fixture.entry("Kelutral", .properNoun)
        #expect(Fixture.generator.strings(of: kelutral, as: .properNoun, .case(.subjective, prefix: .allOfThese)).isEmpty)
        withKnownIssue("kelutral is only a proper noun in the dictionary") {
            #expect(Fixture.analyser.analyse("frayhelutral").isKnown)
        }
    }

    struct DerivationExample: CustomTestStringConvertible, Sendable {
        let word: String
        let wordClass: WordClass
        let inflection: Inflection
        let form: String
        var testDescription: String { form }
    }

    static let derivations: [DerivationExample] = [
        DerivationExample(word: "txantsan", wordClass: .adjective, inflection: Inflection(attributive: .after), form: "txantsana"), // Oel txantsana ikranit aean tswayon.
        DerivationExample(word: "ean", wordClass: .adjective, inflection: Inflection(attributive: .before), form: "aean"),
        DerivationExample(word: "taron", wordClass: .verb, inflection: Inflection(infixes: VerbInfixes(first: .passiveParticiple), attributive: .after), form: "tawnarona"), // t«awn»aron-a
        DerivationExample(word: "wem", wordClass: .verb, inflection: Inflection(derivation: .abilityNoun), form: "wemtswo"),       // Pori wemtswo ...
        DerivationExample(word: "ska'a", wordClass: .verb, inflection: Inflection(derivation: .agentNoun), form: "ska'ayu"),       // Oe kea ska'ayu ke lu.
        DerivationExample(word: "tswa'", wordClass: .verb, inflection: Inflection(derivation: .unable), form: "ketsuktswa'"),      // Swaw lamu ketsuktswa'
        DerivationExample(word: "yom", wordClass: .verb, inflection: Inflection(derivation: .able), form: "tsukyom"),              // Fìioang lu tsukyom.
        DerivationExample(word: "kar", wordClass: .verb, inflection: Inflection(derivation: .gerund), form: "tìkusar"),            // Tìkusar eltur tìtxen si.
        DerivationExample(word: "'aw", wordClass: .number, inflection: Inflection(derivation: .ordinal, attributive: .before), form: "a'awve"), // Koren a'awve ...
    ]

    @Test("Derivations and attribution", arguments: derivations)
    func derivation(_ example: DerivationExample) throws {
        #expect(Fixture.forms(example.word, example.wordClass, example.inflection).contains(example.form))
        #expect(Fixture.analyser.analyse(example.form).isKnown)
    }
}
