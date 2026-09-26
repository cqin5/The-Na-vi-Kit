//
//  TextReaderTests.swift
//  NaviGrammarTests
//

import Testing
@testable import NaviGrammar

@Suite("Text reader")
struct TextReaderTests {

    @Test("Words are split at spaces and punctuation, keeping apostrophes and inner hyphens")
    func tokens() {
        let tokens = TextReader.tokens(in: "Kaltxì, ma 'eylan!  Oe t«awn»aron-a — tì'o'.\nIrayo")
        #expect(tokens.map(\.text) == ["Kaltxì", "ma", "'eylan", "Oe", "t", "awn", "aron-a", "tì'o'", "Irayo"])
        #expect(TextReader.tokens(in: "fpom-").map(\.text) == ["fpom"])
        #expect(TextReader.tokens(in: "").isEmpty)
        #expect(TextReader.tokens(in: " \n\t ").isEmpty)
        // Only spaces between two words let them form a phrase.
        let separated = TextReader.tokens(in: "irayo, si")
        #expect(separated.map(\.followsSpaceOnly) == [false, false])
        #expect(TextReader.tokens(in: "irayo si").map(\.followsSpaceOnly) == [false, true])
    }

    @Test("Oel ngati kameie, as a sentence")
    func sentence() {
        let reading = Fixture.reader.read("Oel ngati kameie, ma Jake.")
        #expect(reading.words.map(\.text) == ["Oel", "ngati", "kameie", "ma", "Jake"])
        let greetingIsKnown = reading.words.prefix(4).allSatisfy(\.analysis.isKnown)
        #expect(greetingIsKnown)
        #expect(reading.unknownWords.map(\.text) == ["Jake"])
        #expect(reading.unknownWords.first?.analysis.unknownReason == .notNaviSpelling)
    }

    @Test("A word after a leniting adposition is read unlenited")
    func lenitionAfterAdposition() {
        let reading = Fixture.reader.read("Oe kelku si mì Helutral.")
        #expect(reading.words.last?.analysis.analyses.first?.summary == "Kelutral + lenited")
        // Punctuation between them breaks the link.
        #expect(!Fixture.reader.read("mì. Helutral").words[1].analysis.isKnown)
    }

    @Test("Multi-word entries are found, with the infixes in the right word")
    func phrases() throws {
        let reading = Fixture.reader.read("Oe irayo si ngaru. Rutxe tivìng mikyun!")
        let thank = try #require(reading.phrase(startingAt: 1))
        #expect(thank.wordIndices == 1..<3)
        #expect(thank.analyses.first?.summary == "irayo si")
        let listen = try #require(reading.phrase(startingAt: 5))
        #expect(listen.analyses.first?.summary == "tìng mikyun + «iv» subjunctive")
        #expect(Fixture.reader.read("irayo, si").phrases.isEmpty)
    }

    @Test("Quotation marks around a word do not make it unknown")
    func quotes() {
        let reading = Fixture.reader.read("'Kaltxì' polawm.")
        #expect(reading.words.first?.analysis.isKnown == true)
        // A tìftang that is part of the word is kept.
        #expect(Fixture.reader.read("'eylan").words.first?.analysis.analyses.first?.entry.form == "'eylan")
    }

    @Test("A long passage is read in one pass")
    func longPassage() {
        let passage = Array(repeating: "Oel ngati kameie.", count: 400).joined(separator: " ")
        let reading = Fixture.reader.read(passage)
        #expect(reading.words.count == 1200)
        #expect(reading.unknownWords.isEmpty)
    }
}
