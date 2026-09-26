//
//  AppendixFTests.swift
//  NaviGrammarTests
//
//  The Na'vi of every phrase in appendix F of the LearnNavi dictionary (version
//  16.1.0), "Useful Phrases", most of which come from Dr. Paul Frommer's blog. The
//  dictionary's placeholder notation (X, parentheses, ellipses) is removed. The
//  English translations are the dictionary's and are not reproduced here.
//

import Testing
@testable import NaviGrammar

@Suite("Appendix F phrases")
struct AppendixFTests {

    static let phrases: [String] = [
        "'awa swawtsyìp",
        "'efu ohakx",
        "'ìn nga fyape nìfkrr",
        "'ivong nìk'ong",
        "ätxäle palulukanur",
        "aytele a ngeyä hapxìmì kifkeyä lu fyape?",
        "eltut heykahaw",
        "etrìpa syayvi",
        "Eywa ngahu",
        "fìpor syaw fko Ìstaw",
        "fnu, ma 'evi. Sa'nur leru hawtsyìp. Tsivurokx ko.",
        "ftia oel lì'fyati leNa'vi nì'o' nìwotx",
        "ftxey fuke",
        "fwa kan ke tam; zene swizawit livonu.",
        "fwäkì ke fwefwi",
        "fyape fko syaw ngar?",
        "hayalo ta oe oeta",
        "irayo",
        "ka wotx",
        "kaltxì",
        "kaltxì sivi, ma Ìstaw",
        "ke pxan",
        "ke tare",
        "ke tslolam",
        "ke zene win säpivi",
        "ke kaw'it",
        "kea tìkin",
        "kefya srak",
        "kem amuiä, kum afe'",
        "kìyevame",
        "krro krro",
        "kunsìpìri txana tìmeyp lu tsyal a mìn.",
        "kxetse sì mikyun kop plltxe",
        "loreyu 'awnampi",
        "ma frapo, ayngaru oeyä tsmukit alu Newey",
        "maitan",
        "maite",
        "makto zong",
        "ne kllte",
        "nga läpivawk nì'it nì'ul ko",
        "nga läpivawk nìno ko",
        "nga pesuhu käteng nìtrrtrr",
        "nga yawne lu oer",
        "nga zola'u ftu peseng",
        "ngari solalew polpxaya zìsìt",
        "ngari txe'lan mawey livu",
        "ngaru lu pefnetxintìn nìtrrtrr",
        "ngaru oeyä lertut",
        "ngaru tsulfä",
        "ngaru tut",
        "ngenga lu tupe",
        "ngeyä kxetse lu oeru",
        "nìlun ayioi a'eoio ayeyktanä lu lor frato",
        "nìprrte'",
        "oe 'olongokx mì sray a txampayìri sim, slä set kelku si mì Helutral",
        "oe irayo si ngaru",
        "oe tskxekeng si säsulìnur alu tsko swizaw",
        "oel ngati kameie",
        "oeri solalew zìsìt apxevol",
        "oeru meuia",
        "oeru syaw fko Txewì",
        "oeru txoa livu",
        "oeyä txintìn lu fwa stä'nì fayoangit",
        "pefya nga fpìl",
        "plltxe räptum",
        "pum ngeyä",
        "renu ngampamä",
        "rutxe läpivawk nì'it",
        "rutxe liveyn",
        "rutxe tivìng mikyun, ma frapo",
        "säfpìl asteng tìkan ateng",
        "Sasya!",
        "seykxel sì nitram",
        "Siva ko!",
        "sivako",
        "smon nìprrte'",
        "Soleia!",
        "srake fnan ngal lì'fyati leNa'vi",
        "srefereiey nìprrte'",
        "srefwa sngap zize'",
        "stum ke",
        "taronyut yom smarìl",
        "tì'efumì oeyä",
        "tì'i'avay krrä",
        "tì'o'ìri peu sunu ngar frato",
        "tìk'ìnìri kempe si nga",
        "tìkangkemìri varmrrìn oe nìwotx",
        "tìkxey ngaru",
        "tìomummì oeyä",
        "tìyawr ngaru",
        "tokx eo tokx",
        "tolätxaw nìprrte'",
        "tsalì'uri alu, ral lu 'upe",
        "tstunwi",
        "tsun miväkxu hìkrr srak",
        "tsun nga law sivi nì'it srak",
        "Tsun pehem?",
        "txawnulsrung a tswayon",
        "txìm a'aw ke tsun hiveyn mì tal mefa'liyä.",
        "txo ke nìyo' tsakrr nìyol",
        "txon lefpom",
        "nìNa'vi slu pelì'u",
        "peral",
        "Yewla!",
        "za'u nì'eng",
        "zola'u nìprrte'",
    ]

    /// The words of appendix F the engine does not know, and why:
    ///
    /// - apxevol: a + pxevol "24"; numbers above the lexicon's own are built by the
    ///   number system of appendix A, which the engine does not implement.
    /// - kefya: part of the set phrase kefya srak "isn't that so?", which the lexicon
    ///   does not list.
    /// - polpxaya: polpxay "how many" with the attributive a. The engine gives the
    ///   attributive to adjectives, participles and numbers only.
    static let expectedUnknown: Set<String> = ["apxevol", "kefya", "polpxaya"]

    @Test("Every other word of every phrase has a reading")
    func coverage() {
        var unknown: Set<String> = []
        for phrase in Self.phrases {
            for word in Fixture.reader.read(phrase).unknownWords {
                unknown.insert(word.analysis.normalized)
            }
        }
        #expect(unknown == Self.expectedUnknown)
    }

    /// Words whose best reading is checked, one or more per phrase.
    @Test("Readings", arguments: [
        ("Oel ngati kameie", "oel", "oe + agentive"),
        ("Oel ngati kameie", "ngati", "nga + patientive"),
        ("Oel ngati kameie", "kameie", "kame + «ei» laudative"),
        ("Eywa ngahu", "ngahu", "nga + hu (with)"),
        ("Nga yawne lu oer", "oer", "oe + dative"),
        ("Ngaru lu fpom srak?", "ngaru", "nga + dative"),
        ("Ngeyä kxetse lu oeru", "ngeyä", "nga + genitive"),
        ("Hayalo ta oe oeta", "oeta", "oe + ta (from)"),
        ("Fìpor syaw fko Ìstaw", "fìpor", "fìpo + dative"),
        ("Oeri solalew zìsìt", "solalew", "salew + «ol» perfective"),
        ("Srake smon ngar oeyä meylan", "meylan", "'eylan + me+ dual"),
        ("Oeyä txintìn lu fwa stä'nì fayoangit", "fayoangit", "payoang + plural (by lenition) + patientive"),
        ("Txìm a'aw ke tsun hiveyn mì tal mefa'liyä", "mefa'liyä", "pa'li + me+ dual + genitive"),
        ("Txìm a'aw ke tsun hiveyn mì tal mefa'liyä", "tal", "txal + lenited"),
        ("Txìm a'aw ke tsun hiveyn mì tal mefa'liyä", "a'aw", "'aw + a- attributive"),
        ("Oe 'olongokx mì sray a txampayìri sim", "sray", "tsray + lenited"),
        ("Oe 'olongokx mì sray a txampayìri sim", "'olongokx", "'ongokx + «ol» perfective"),
        ("Nìlun ayioi a'eoio ayeyktanä lu lor frato", "ayeyktanä", "eyktan + ay+ plural + genitive"),
        ("Ngaru lu pefnetxintìn nìtrrtrr", "pefnetxintìn", "txintìn + pe+ fne- which kind of"),
        ("Nga pesuhu käteng nìtrrtrr", "pesuhu", "pesu + hu (with)"),
        ("Tìkangkemìri varmrrìn oe nìwotx", "varmrrìn", "vrrìn + «arm» past imperfective"),
        ("Taronyut yom smarìl", "taronyut", "taronyu + patientive"),
        ("Tsalì'uri alu, ral lu 'upe", "tsalì'uri", "lì'u + tsa- that + topical"),
        ("Ke zene win säpivi", "säpivi", "si + «äp» reflexive + «iv» subjunctive"),
        ("Nga läpivawk nì'it", "läpivawk", "lawk + «äp» reflexive + «iv» subjunctive"),
        ("Eltut heykahaw", "heykahaw", "hahaw + «eyk» causative"),
        ("Fnu, ma 'evi. Sa'nur leru hawtsyìp.", "leru", "lu + «er» imperfective"),
        ("Loreyu 'awnampi", "'awnampi", "'ampi + «awn» passive participle"),
        ("Siva ko!", "siva", "sa + «iv» subjunctive"),
        ("Kem amuiä, kum afe'", "afe'", "fe' + a- attributive"),
    ])
    func reading(_ phrase: String, _ word: String, _ summary: String) throws {
        let reading = Fixture.reader.read(phrase)
        let match = try #require(reading.words.first { Orthography.normalize($0.text) == word })
        #expect(match.analysis.analyses.first?.summary == summary,
                "readings were \(match.analysis.analyses.map(\.summary))")
    }

    @Test("Multi-word entries in the phrases", arguments: [
        ("Oe irayo si ngaru", "irayo si"),
        ("Kaltxì sivi, ma Ìstaw", "kaltxì si + «iv» subjunctive"),
        ("Rutxe tivìng mikyun, ma frapo", "tìng mikyun + «iv» subjunctive"),
        ("Oe tskxekeng si säsulìnur alu tsko swizaw", "tskxekeng si"),
        ("Tsun nga law sivi nì'it srak", "law si + «iv» subjunctive"),
        ("Plltxe räptum", "plltxe räptum"),
    ])
    func phrase(_ phrase: String, _ summary: String) {
        let summaries = Fixture.reader.read(phrase).phrases.flatMap { $0.analyses.map(\.summary) }
        #expect(summaries.contains(summary), "phrases were \(summaries)")
    }
}
