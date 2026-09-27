//
//  AppendixATests.swift
//  NaviGrammarTests
//
//  The charts of appendix A of the LearnNavi dictionary (version 16.1.0), "The Number
//  System": the numbers 0 to 63, the multiples of the powers of eight with the units'
//  combining forms, the worked example, and the ordinals 1 to 15.
//

import Testing
@testable import NaviGrammar

@Suite("Appendix A numbers")
struct AppendixATests {

    /// The numbers 0 to 63, in order, from the charts "Na'vi Numbers: 0 – 39" and
    /// "Na'vi Numbers: 40 – 63".
    static let zeroToSixtyThree: [String] = [
        "kew", "'aw", "mune", "pxey", "tsìng", "mrr", "pukap", "kinä",
        "vol", "volaw", "vomun", "vopey", "vosìng", "vomrr", "vofu", "vohin",
        "mevol", "mevolaw", "mevomun", "mevopey", "mevosìng", "mevomrr", "mevofu", "mevohin",
        "pxevol", "pxevolaw", "pxevomun", "pxevopey", "pxevosìng", "pxevomrr", "pxevofu", "pxevohin",
        "tsìvol", "tsìvolaw", "tsìvomun", "tsìvopey", "tsìvosìng", "tsìvomrr", "tsìvofu", "tsìvohin",
        "mrrvol", "mrrvolaw", "mrrvomun", "mrrvopey", "mrrvosìng", "mrrvomrr", "mrrvofu", "mrrvohin",
        "puvol", "puvolaw", "puvomun", "puvopey", "puvosìng", "puvomrr", "puvofu", "puvohin",
        "kivol", "kivolaw", "kivomun", "kivopey", "kivosìng", "kivomrr", "kivofu", "kivohin",
    ]

    /// The chart "More Na'vi Numbers", one row per digit from 1 to 7: the digit, its
    /// combining form, and the digit times 8, 64, 512 and 4,096.
    static let multiples: [(digit: Int, combining: String, times: [Int: String])] = [
        (1, "aw", [8: "vol", 64: "zam", 512: "vozam", 4096: "zazam"]),
        (2, "mun", [8: "mevol", 64: "mezam", 512: "mevozam", 4096: "mezazam"]),
        (3, "pey", [8: "pxevol", 64: "pxezam", 512: "pxevozam", 4096: "pxezazam"]),
        (4, "sìng", [8: "tsìvol", 64: "tsìzam", 512: "tsìvozam", 4096: "tsìzazam"]),
        (5, "mrr", [8: "mrrvol", 64: "mrrzam", 512: "mrrvozam", 4096: "mrrzazam"]),
        (6, "fu", [8: "puvol", 64: "puzam", 512: "puvozam", 4096: "puzazam"]),
        (7, "hin", [8: "kivol", 64: "kizam", 512: "kivozam", 4096: "kizazam"]),
    ]

    /// The chart "Ordinal Numbers": number + -ve, for 1 to 15.
    static let ordinals: [String] = [
        "'awve", "muve", "pxeyve", "tsìve", "mrrve", "puve", "kive",
        "volve", "volawve", "vomuve", "vopeyve", "vosìve", "vomrrve", "vofuve", "vohive",
    ]

    @Test("The numbers 0 to 63, both ways")
    func zeroToSixtyThreeCharts() {
        for (value, word) in Self.zeroToSixtyThree.enumerated() {
            #expect(Numeral(value)?.word == word)
            #expect(Numeral(word: word)?.value == value, "\(word)")
        }
    }

    @Test("The powers of eight times each digit, and the combining forms of the units")
    func multiplesChart() {
        for row in Self.multiples {
            for (place, word) in row.times {
                #expect(Numeral(row.digit * place)?.word == word)
                #expect(Numeral(word: word)?.value == row.digit * place, "\(word)")
            }
            // 9 to 15 end in the combining forms: vol + aw, vo + mun, ...
            #expect(Numeral(8 + row.digit)?.parts.last?.text == row.combining)
        }
    }

    @Test("The worked example: zamtsìvosìng is zam + tsìvo + sìng, 64 + 4 × 8 + 4")
    func workedExample() throws {
        let numeral = try #require(Numeral(100))
        #expect(numeral.word == "zamtsìvosìng")
        #expect(numeral.parts.map(\.text) == ["zam", "tsìvo", "sìng"])
        #expect(numeral.parts.map(\.digit) == [1, 4, 4])
        #expect(numeral.parts.map(\.place) == [64, 8, 1])
        #expect(numeral.octal == "144")
        #expect(Numeral(word: "zamtsìvosìng")?.value == 100)
    }

    @Test("The ordinals 1 to 15, and none where the dictionary gives none")
    func ordinalChart() {
        for (index, ordinal) in Self.ordinals.enumerated() {
            #expect(Numeral(index + 1)?.ordinal == ordinal)
        }
        #expect(Numeral(0)?.ordinal == nil)
        #expect(Numeral(16)?.ordinal == nil)
        #expect(Numeral(64)?.ordinal == "zave")
    }

    @Test("Every number the lexicon lists is read, and every ordinal it lists is given")
    func lexiconNumbers() {
        let numbers = Fixture.lexicon.entries.filter { $0.partsOfSpeech.contains(.number) }
        let ordinals = Set((0...Numeral.largest).compactMap { Numeral($0)?.ordinal })
        #expect(numbers.count == 21)
        for entry in numbers {
            if entry.gloss.contains("ordinal") {
                #expect(ordinals.contains(entry.form), "\(entry.headword)")
            } else {
                #expect(Numeral(word: entry.form) != nil, "\(entry.headword)")
            }
        }
        #expect(Numeral(word: "vozam")?.value == 512)
        #expect(Numeral(word: "zazam")?.value == 4096)
    }

    @Test("Every number up to the largest has one word, which reads back as that number")
    func roundTrip() {
        var words: Set<String> = []
        for value in 0...Numeral.largest {
            guard let numeral = Numeral(value) else {
                Issue.record("no word for \(value)")
                continue
            }
            #expect(numeral.parts.map(\.value).reduce(0, +) == value)
            #expect(Numeral(word: numeral.word)?.value == value, "\(numeral.word)")
            words.insert(numeral.word)
        }
        #expect(words.count == Numeral.largest + 1)
        #expect(Numeral(Numeral.largest)?.word == "kizazamkivozamkizamkivohin")
    }

    @Test("Numbers outside the system have no word", arguments: [-1, Numeral.largest + 1, Int.max, Int.min])
    func outOfRange(_ value: Int) {
        #expect(Numeral(value) == nil)
    }

    @Test("Capitals, typographic apostrophes and surrounding spaces are accepted", arguments: [
        ("’Aw", 1), ("VOMUN", 10), (" vol\n", 8), ("Kinä", 7), ("ZamTsìvosìng", 100),
    ])
    func normalisedSpellings(_ word: String, _ value: Int) {
        #expect(Numeral(word: word)?.value == value)
    }

    @Test("Other spellings are not numbers", arguments: [
        "",
        "vo",           // vol without its units
        "volmun",       // 10 is vomun
        "vomune",       // the units' combining form is -mun
        "volkew",       // zero has no combining form
        "zamzam",       // a place said twice
        "volzam",       // places out of order
        "mevolvol",
        "mezamaw aw",
        "'awvol",       // 8 is vol, not 'awvol
        "kewaw",
        "zamaw'",
        "'awve",        // an ordinal, not a number
        "zave",
        "tsìng mrr",
        "vomrrr",
        "8",
        "eight",
    ])
    func notNumbers(_ word: String) {
        #expect(Numeral(word: word) == nil)
    }

    @Test("Typed text reads as digits or as a Na'vi number word", arguments: [
        ("100", Numeral.Reading.digits(Numeral(100)!)),
        ("0", .digits(Numeral(0)!)),
        ("007", .digits(Numeral(7)!)),
        (" 24\n", .digits(Numeral(24)!)),
        ("4,096", .digits(Numeral(4096)!)),
        ("32767", .digits(Numeral(32_767)!)),
        ("zamtsìvosìng", .word(Numeral(100)!)),
        ("’Aw", .word(Numeral(1)!)),
        ("kew", .word(Numeral(0)!)),
        ("32768", .tooLarge),
        ("99999999999999999999999", .tooLarge),
        ("١٢", .digits(Numeral(12)!)),      // Arabic-Indic digits
        ("１２", .digits(Numeral(12)!)),     // full-width digits
        ("-1", .notANumber),
        ("1.5", .notANumber),
        ("+8", .notANumber),
        ("²", .notANumber),                  // a digit, but not a decimal one
        ("Ⅻ", .notANumber),
        ("½", .notANumber),
        ("1 000", .notANumber),
        (",,,", .notANumber),
        ("vol aw", .notANumber),
        ("eight", .notANumber),
    ])
    func typedText(_ text: String, _ reading: Numeral.Reading) {
        #expect(Numeral.read(text) == reading)
        switch reading {
        case .digits(let numeral), .word(let numeral):
            #expect(Numeral.read(text)?.numeral == numeral)
        case .tooLarge, .notANumber:
            #expect(Numeral.read(text)?.numeral == nil)
        }
    }

    @Test("Empty text reads as nothing", arguments: ["", "   ", "\n\t"])
    func emptyText(_ text: String) {
        #expect(Numeral.read(text) == nil)
    }
}
