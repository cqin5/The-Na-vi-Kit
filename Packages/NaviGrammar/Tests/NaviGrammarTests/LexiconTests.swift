//
//  LexiconTests.swift
//  NaviGrammarTests
//

import Testing
@testable import NaviGrammar

@Suite("Lexicon")
struct LexiconTests {

    static let header = "id\tnavi\tpos\tinfixes\tgrammar\ten"

    @Test("The bundled lexicon loads with its provenance")
    func bundled() {
        let lexicon = Fixture.lexicon
        #expect(lexicon.entries.count == 3045)
        #expect(lexicon.metadata["source"] == "https://tirea.learnnavi.org/dictionarydata/dictionary-v2.txt")
        #expect(lexicon.metadata["sha256"]?.count == 64)
        #expect(lexicon.metadata["credit"]?.contains("Paul Frommer") == true)
        #expect(lexicon.metadata["credit"]?.contains("Richard Littauer") == true)
        #expect(Set(lexicon.entries.map(\.id)).count == lexicon.entries.count)
    }

    @Test("Every verb has an infix template that spells it, except 'ulte")
    func verbTemplates() {
        let verbs = Fixture.lexicon.entries.filter { $0.partsOfSpeech.contains { $0.wordClass == .verb } }
        let untemplated = verbs.filter { $0.infixTemplate == nil }.map(\.headword)
        #expect(untemplated == ["'ulte"])
        for verb in verbs {
            if let template = verb.infixTemplate {
                #expect(template.bare == verb.form)
            }
        }
    }

    @Test("Leniting adpositions are marked, and + is not part of the form")
    func adpositions() throws {
        let mi = try #require(Fixture.lexicon.entries(withForm: "mì").first)
        #expect(mi.headword == "mì+")
        #expect(mi.lenitesFollowingWord)
        #expect(Fixture.lexicon.entries(withForm: "hu").first?.lenitesFollowingWord == false)
    }

    @Test("Line endings, a byte-order mark and blank lines are tolerated")
    func tolerantParsing() throws {
        let text = "\u{FEFF}# source\tx\r\n\(Self.header)\r\n\r\n4\t'ampi\tvtr.\t'<0><1>amp<2>i\t\ttouch\r\n"
        let lexicon = try Lexicon(tsv: text)
        #expect(lexicon.entries.count == 1)
        #expect(lexicon.metadata["source"] == "x")
        #expect(lexicon.entries.first?.infixTemplate?.bare == "'ampi")
    }

    @Test("Damaged lexicon lines fail loudly", arguments: [
        ("4\t'ampi\tvtr.\t'<0><1>amp<2>i\ttouch", "columns"),                 // a column missing
        ("x4\t'ampi\tvtr.\t\t\ttouch", "not a number"),
        ("4\t\tvtr.\t\t\ttouch", "headword"),
        ("4\t'ampi\t\t\t\ttouch", "part of speech"),
        ("4\t'ampi\tvtr.\t'<0><1>amp<2>u\t\ttouch", "does not spell"),       // template of another word
        ("4\t'ampi\tvtr.\t'<0><1>ampi\t\ttouch", "malformed"),              // no position 2
        ("4\t'ampi\tvtr.\t'<1><0>amp<2>i\t\ttouch", "malformed"),           // positions out of order
    ])
    func malformed(_ line: String, _ reason: String) {
        #expect {
            try Lexicon(tsv: "\(Self.header)\n\(line)\n")
        } throws: { error in
            "\(error)".contains(reason)
        }
    }

    @Test("A lexicon without the column header is rejected")
    func missingHeader() {
        #expect(throws: LexiconError.missingHeader) {
            try Lexicon(tsv: "4\t'ampi\tvtr.\t\t\ttouch\n")
        }
        #expect(throws: LexiconError.missingHeader) {
            try Lexicon(tsv: "")
        }
    }

    @Test("An unknown part of speech loads, but takes no inflections")
    func unknownPartOfSpeech() throws {
        let lexicon = try Lexicon(tsv: "\(Self.header)\n1\tzam\tnewpos.\t\t\tsomething\n")
        let entry = try #require(lexicon.entries.first)
        #expect(entry.wordClasses == [.other])
        #expect(Generator().forms(of: entry, as: .other, .case(.agentive)).isEmpty)
    }

    @Test("Templates")
    func templates() throws {
        let kame = try #require(InfixTemplate("k<0><1>am<2>e"))
        #expect(kame.filled(preFirst: "", first: "ìyev", second: "", inWord: 0) == "kìyevame")
        let thank = try #require(InfixTemplate("irayo s<0><1><2>i"))
        #expect(thank.slottedWordIndices == [1])
        #expect(thank.filled(preFirst: "", first: "am", second: "", inWord: 1) == "irayo sami")
        #expect(InfixTemplate("k<0><1>ame") == nil)
        #expect(InfixTemplate("'ulte") == nil)
        #expect(InfixTemplate("") == nil)
    }
}
