//
//  OrthographyTests.swift
//  NaviGrammarTests
//

import Testing
@testable import NaviGrammar

@Suite("Orthography")
struct OrthographyTests {

    @Test("Normalisation", arguments: [
        ("Kaltxì", "kaltxì"),
        ("KALTXÌ", "kaltxì"),
        ("Tätxaw", "tätxaw"),
        ("ta\u{0308}txaw", "tätxaw"),          // decomposed ä
        ("kaltxi\u{0300}", "kaltxì"),          // decomposed ì
        ("\u{2019}eylan", "'eylan"),           // Smart Punctuation
        ("\u{2018}eylan", "'eylan"),
        ("\u{02BC}eylan", "'eylan"),           // modifier letter apostrophe
        ("`eylan", "'eylan"),
        ("tì\u{2019}o\u{2019}", "tì'o'"),
    ])
    func normalize(_ input: String, _ expected: String) {
        #expect(Orthography.normalize(input) == expected)
    }

    @Test("Lenition", arguments: [
        ("pxen", "pen"), ("txep", "tep"), ("kxetse", "ketse"),
        ("tsray", "sray"), ("pa'li", "fa'li"), ("tute", "sute"), ("koren", "horen"),
        ("'eylan", "eylan"), ("'ora", "ora"),
        // Sounds that do not lenite.
        ("fpom", "fpom"), ("sute", "sute"), ("ikran", "ikran"), ("nantang", "nantang"),
        ("lu", "lu"), ("mikyun", "mikyun"), ("ngenga", "ngenga"), ("rol", "rol"),
        ("wem", "wem"), ("yom", "yom"), ("zong", "zong"), ("vul", "vul"), ("hrr", "hrr"),
    ])
    func lenite(_ word: String, _ lenited: String) {
        #expect(Orthography.lenite(word) == lenited)
    }

    @Test("Undoing lenition proposes every source, and only real ones")
    func unlenite() {
        #expect(Set(Orthography.unlenitedCandidates("sute")) == ["sute", "tute", "tsute"])
        #expect(Set(Orthography.unlenitedCandidates("horen")) == ["horen", "koren"])
        #expect(Set(Orthography.unlenitedCandidates("eylan")) == ["eylan", "'eylan"])
        // p lenites to f, so a lenited word beginning with p can only come from px.
        #expect(Orthography.unlenitedCandidates("pen") == ["pxen"])
        #expect(Orthography.unlenitedCandidates("mikyun") == ["mikyun"])
        #expect(Orthography.unlenitedCandidates("") == [""])
    }

    @Test("Final sounds that decide the case endings")
    func finalSounds() {
        for word in ["tute", "nga", "'u", "tuté", "Na'vi".lowercased(), "ioi"] {
            #expect(Orthography.endsInVowel(word), "\(word)")
        }
        // Consonants, diphthongs and pseudovowels.
        for word in ["ikran", "swizaw", "tsray", "fkew", "'eylan", "'ewll", "trr", "'awkx", ""] {
            #expect(!Orthography.endsInVowel(word), "\(word)")
        }
        #expect(Orthography.takesYäGenitive("tute"))
        #expect(Orthography.takesYäGenitive("nga"))
        #expect(!Orthography.takesYäGenitive("'u"))
        #expect(!Orthography.takesYäGenitive("po"))
        #expect(!Orthography.takesYäGenitive("ikran"))
    }

    @Test("Na'vi spelling")
    func spelling() {
        #expect(Orthography.isNaviSpelling("kaltxì"))
        #expect(Orthography.isNaviSpelling("tì'o'"))
        #expect(!Orthography.isNaviSpelling("jake"))
        #expect(!Orthography.isNaviSpelling("kaltxì!"))
        #expect(!Orthography.isNaviSpelling(""))
    }
}
