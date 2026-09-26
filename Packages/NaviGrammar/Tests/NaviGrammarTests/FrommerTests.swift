//
//  FrommerTests.swift
//  NaviGrammarTests
//
//  Forms Dr. Paul Frommer has written, for the rules that appendix H of the
//  LearnNavi dictionary leaves out or states only in part. Each case names the post
//  on https://naviteri.org (NT) or Language Log (LL) it comes from.
//

import Testing
@testable import NaviGrammar

@Suite("Dr. Frommer's forms")
struct FrommerTests {

    struct Example: CustomTestStringConvertible, Sendable {
        let form: String
        let summary: String
        let source: String
        var testDescription: String { form }
    }

    static let examples: [Example] = [
        // Lenition (LL 19 Dec 2009) and the tìftang before a pseudovowel (NT 2012/03/28).
        Example(form: "aysokx", summary: "tokx + ay+ plural", source: "LL 2009-12-19"),
        Example(form: "sokx", summary: "tokx + plural (by lenition)", source: "LL 2009-12-19"),
        Example(form: "me'llngo", summary: "'llngo + me+ dual", source: "NT 2012/03/spring-vocabulary-part-1"),
        Example(form: "ay'llngo", summary: "'llngo + ay+ plural", source: "NT 2012/03/spring-vocabulary-part-1"),
        Example(form: "ayewll", summary: "'ewll + ay+ plural", source: "NT 2010/09/getting-to-know-you-part-2"),
        // Doubled vowels simplify across a prefix (NT 2012/07/05).
        Example(form: "pekxinum", summary: "'ekxinum + pe+ which", source: "NT 2012/07/meetings-waterfalls-and-more"),
        Example(form: "meveng", summary: "'eveng + me+ dual", source: "NT 2023/01/2653"),
        // ay+ before i and y is unchanged; -pe precedes the case ending.
        Example(form: "ayioang", summary: "ioang + ay+ plural", source: "NT 2017/02/ayioang-amip-si-ayu-alahe"),
        Example(form: "fayioangìri", summary: "ioang + fay+ these + topical", source: "NT 2017/02 (comment)"),
        Example(form: "ayioangpel", summary: "ioang + ay+ plural + -pe which + agentive", source: "NT 2026/04/hiia-tisung-postiya-aham"),
        // Position 0 combined, reflexive first (NT 2015/04/30).
        Example(form: "'äpeykamrrko", summary: "'rrko + «äpeyk» reflexive causative + «am» past", source: "NT 2015/04/some-new-words-for-may-day"),
        Example(form: "'olrrko", summary: "'rrko + «ol» perfective", source: "NT 2015/04/some-new-words-for-may-day"),
        // «ei» before i or a pseudovowel, and «ol» before ll (NT 2012/06/19).
        Example(form: "seiyi", summary: "si + «ei» laudative", source: "NT 2012/06/spring-vocabulary-part-3"),
        Example(form: "veiyll", summary: "vll + «ei» laudative", source: "NT 2012/06/spring-vocabulary-part-3"),
        Example(form: "vol", summary: "vll + «ol» perfective", source: "NT 2012/06/spring-vocabulary-part-3"),
        Example(form: "poltxe", summary: "plltxe + «ol» perfective", source: "NT 2012/06/spring-vocabulary-part-3"),
        Example(form: "leiu", summary: "lu + «ei» laudative", source: "NT 2020/05/ulte-ayyoratu-leiu"),
        // The Reef dialect keeps «ei» before i (NT 2023/01/13).
        Example(form: "seii", summary: "si + «ei» laudative", source: "NT 2023/01/2653"),
        // Diphthong-final nouns (NT 2013/01/25).
        Example(form: "wayt", summary: "way + patientive", source: "NT 2013/01/awvea-posti-zisita-amip"),
        Example(form: "wayit", summary: "way + patientive", source: "NT 2013/01/awvea-posti-zisita-amip"),
        Example(form: "'etnawr", summary: "'etnaw + dative", source: "NT 2013/01/awvea-posti-zisita-amip"),
        Example(form: "'etnawur", summary: "'etnaw + dative", source: "NT 2013/01/awvea-posti-zisita-amip"),
        // A final tìftang (NT 2026/04/14).
        Example(form: "olo'ru", summary: "olo' + dative", source: "NT 2026/04/hiia-tisung-postiya-aham"),
        Example(form: "olo'ri", summary: "olo' + topical", source: "NT 2026/04/hiia-tisung-postiya-aham"),
        Example(form: "olo'ìri", summary: "olo' + topical", source: "NT 2026/04/hiia-tisung-postiya-aham"),
        // Genitives.
        Example(form: "soaiä", summary: "soaia + genitive (irregular)", source: "NT 2011/05/some-miscellaneous-vocabulary"),
        Example(form: "tskoä", summary: "tsko + genitive", source: "NT 2015/11/vomuna-liu-amip-ten-new-words"),
        Example(form: "omatikayaä", summary: "Omatikaya + genitive (irregular)", source: "NT 2012/10/mipa-vospxi-mipa-ayliu"),
        Example(form: "kelnit", summary: "Kelnì + patientive", source: "NT 2022/01/aawa-tipangkxotsyip"),
        Example(form: "kelnur", summary: "Kelnì + dative", source: "NT 2022/01/aawa-tipangkxotsyip"),
        Example(form: "kelnä", summary: "Kelnì + genitive", source: "NT 2022/01/aawa-tipangkxotsyip"),
        Example(form: "kelnìl", summary: "Kelnì + agentive", source: "NT 2022/01/aawa-tipangkxotsyip"),
        // Pronouns.
        Example(form: "peyä", summary: "po + genitive (irregular)", source: "NT 2020/12/mrra-tipangkxotsyip"),
        Example(form: "feyä", summary: "fo + genitive (irregular)", source: "NT 2023/09/aawa-ayliu-si-aylifyavi-amip"),
        Example(form: "mefeyä", summary: "mefo + genitive (irregular)", source: "NT 2023/09/aawa-ayliu-si-aylifyavi-amip"),
        Example(form: "ayfeyä", summary: "ayfo + genitive (irregular)", source: "NT 2026/06/tskxekeng-a-mikyunfpi-pamrel"),
        Example(form: "tseyä", summary: "tsaw + genitive (irregular)", source: "NT 2017/02 (comment)"),
        Example(form: "oengaru", summary: "oeng + dative", source: "NT 2011/12/one-more-for-2011"),
        Example(form: "oengari", summary: "oeng + topical", source: "NT 2023/07/trr-tsyimawnuniya-lefpom"),
        Example(form: "moeru", summary: "moe + dative", source: "NT 2011/12/one-more-for-2011"),
        Example(form: "awngal", summary: "awnga + agentive", source: "NT 2020/06/mi-tanlokxe-oeya-srr-afpxamo"),
        Example(form: "awngeyä", summary: "awnga + genitive", source: "NT 2010/09/getting-to-know-you-part-1"),
        Example(form: "ngengeyä", summary: "ngenga + genitive", source: "NT 2022/02/lifyengteri"),
        Example(form: "frapol", summary: "frapo + agentive", source: "NT 2012/06/spring-vocabulary-part-3"),
        Example(form: "ayleyä", summary: "ayla + genitive", source: "NT 2023/05/reef-navi-part-2"),
        Example(form: "aylaheyä", summary: "aylahe + genitive", source: "NT 2023/05/reef-navi-part-2"),
        // Adpositions attach without leniting.
        Example(form: "kilvanmì", summary: "kilvan + mì (in)", source: "NT 2023/09/aawa-ayliu-si-aylifyavi-amip"),
    ]

    @Test("Forms Dr. Frommer has written", arguments: examples)
    func attested(_ example: Example) {
        // The reading, or one folded into a word the dictionary lists (pekxinum).
        let analysis = Fixture.analyser.analyse(example.form)
        #expect((analysis.analyses + analysis.folded).contains { $0.summary == example.summary },
                "\(example.source): readings were \(analysis.analyses.map(\.summary))")
    }

    @Test("Forms the rules would otherwise produce, which Dr. Frommer's forms rule out", arguments: [
        "soaiayä",      // soaiä
        "poä",          // peyä
        "tsawìl",       // tsal is a word of its own
        "oengìl",       // oengal: the -ng pronouns take a stem in -a
        "oengur",
        "kelnìt",       // Kelnit
        "kelnìyä",      // Kelnä
        "ayllngo",      // the tìftang before a pseudovowel stays: ay'llngo
        "pollltxe",     // poltxe
        "ferrrfen",     // «er» before rr: undocumented, so not produced
    ])
    func ruledOut(_ form: String) {
        let readings = Fixture.analyser.analyse(form).analyses
        #expect(readings.isEmpty, "readings were \(readings.map(\.summary))")
    }

    @Test("After a leniting adposition, a lenited noun is singular")
    func noShortPluralAfterAdposition() {
        // mì hilvan "in the river"; the plural is mì ayhilvan (NT 2010/07/thoughts-on-ambiguity).
        let afterMi = Fixture.reader.read("mì hilvan").words[1].analysis.analyses.map(\.summary)
        #expect(afterMi.contains("kilvan + lenited"))
        #expect(!afterMi.contains { $0.contains("plural") })
        // On its own, hilvan can be the short plural.
        #expect(Fixture.summaries("hilvan").contains("kilvan + plural (by lenition)"))
    }

    @Test("Reef spellings are read with the forest dialect's letters, and marked")
    func reef() {
        // tsùn "can" and tsun "heel" are one spelling in the forest dialect.
        let tsun = Fixture.analyser.analyse("tsùn")
        #expect(tsun.analyses.count == 2)
        #expect(tsun.analyses.allSatisfy { $0.notes.contains(.reefSpelling) })
        // adge is the Reef spelling of atxkxe "land" (NT 2023/01/2653).
        #expect(Fixture.analyser.analyse("adge").analyses.first?.entry.form == "atxkxe")
        // The Reef dialect keeps «ei» before i: seii for the forest dialect's seiyi.
        #expect(Fixture.analyser.analyse("seii").analyses.first?.notes.contains(.reefForm) == true)
        // A word that is not Na'vi in either spelling stays unknown.
        #expect(Fixture.analyser.analyse("blorp").unknownReason == .notNaviSpelling)
        #expect(!Fixture.analyser.analyse("ngange").analyses.contains { $0.notes.contains(.reefSpelling) })
    }
}
