//
//  Numeral.swift
//  NaviGrammar
//

import Foundation

/// A Na'vi number word, and how it is built.
///
/// Na'vi counts in eights. The words and the way they combine are those of appendix A
/// of the LearnNavi dictionary, "The Number System":
///
/// - kew, 'aw, mune, pxey, tsìng, mrr, pukap and kinä are zero to seven;
/// - vol, zam, vozam and zazam are 8, 64, 512 and 4,096, and me-, pxe-, tsì-, mrr-,
///   pu- and ki- multiply them by two to seven: mevol is 16, pxezam 192;
/// - a number that ends in units ends in their combining form, -aw, -mun, -pey, -sìng,
///   -mrr, -fu or -hin, and vol drops its l before a form that begins with a
///   consonant: volaw is 9, vomun 10.
///
/// A number is said from its largest power of eight down: zamtsìvosìng is zam + tsìvo
/// + sìng, 64 + 4 × 8 + 4, which is 100. The appendix names no power above 4,096, so
/// the largest number is 77777 in base eight, 32,767.
public struct Numeral: Hashable, Sendable {

    /// One place of a number: a digit, and the power of eight it counts.
    public struct Part: Hashable, Sendable {
        /// How the place is spelled in the number word: tsìvo, sìng.
        public let text: String
        /// The digit, from 0 to 7.
        public let digit: Int
        /// The power of eight the digit counts: 1, 8, 64, 512 or 4,096.
        public let place: Int

        /// What the place adds to the number.
        public var value: Int {
            digit * place
        }
    }

    /// The largest number the words of appendix A can say.
    public static let largest = 32_767

    public let value: Int
    /// The number word, spelled as the dictionary spells it.
    public let word: String
    /// The places the word is built from, largest first. A number below eight is one
    /// part, the word itself.
    public let parts: [Part]

    /// The words for zero to seven.
    private static let units = ["kew", "'aw", "mune", "pxey", "tsìng", "mrr", "pukap", "kinä"]
    /// The forms of one to seven that end a larger number.
    private static let combiningUnits = ["", "aw", "mun", "pey", "sìng", "mrr", "fu", "hin"]
    /// The prefixes that multiply a power of eight by two to seven.
    private static let multipliers = ["", "", "me", "pxe", "tsì", "mrr", "pu", "ki"]
    /// The powers of eight, largest first.
    private static let powers: [(place: Int, word: String)] = [(4096, "zazam"), (512, "vozam"), (64, "zam"), (8, "vol")]

    /// The ordinals appendix A gives, for 1 to 15, and zave "sixty-fourth", which
    /// the dictionary lists.
    private static let ordinals: [Int: String] = [
        1: "'awve", 2: "muve", 3: "pxeyve", 4: "tsìve", 5: "mrrve", 6: "puve", 7: "kive",
        8: "volve", 9: "volawve", 10: "vomuve", 11: "vopeyve", 12: "vosìve", 13: "vomrrve",
        14: "vofuve", 15: "vohive", 64: "zave",
    ]

    /// The Na'vi for `value`, or nil if it is negative or above `largest`.
    public init?(_ value: Int) {
        guard (0...Self.largest).contains(value) else {
            return nil
        }
        self.value = value

        if value < 8 {
            parts = [Part(text: Self.units[value], digit: value, place: 1)]
        } else {
            let unit = value % 8
            let unitForm = Self.combiningUnits[unit]
            var parts: [Part] = []
            for (place, power) in Self.powers {
                let digit = value / place % 8
                guard digit > 0 else {
                    continue
                }
                var text = Self.multipliers[digit] + power
                if place == 8, let first = unitForm.first, !Orthography.vowels.contains(first) {
                    text.removeLast()
                }
                parts.append(Part(text: text, digit: digit, place: place))
            }
            if unit > 0 {
                parts.append(Part(text: unitForm, digit: unit, place: 1))
            }
            self.parts = parts
        }
        word = parts.map(\.text).joined()
    }

    /// The number a Na'vi number word stands for, or nil if `word` is not one.
    /// Capitals and typographic apostrophes are accepted, so ’Aw is 1, but any other
    /// spelling than the dictionary's is not: vomun is 10, volmun nothing.
    public init?(word: String) {
        let text = Orthography.normalize(word.trimmingCharacters(in: .whitespacesAndNewlines))
        if let unit = Self.units.firstIndex(of: text) {
            self.init(unit)
            return
        }

        // Read the places from the largest down, then the units, and accept the
        // result only if it spells the word exactly as the number is spelled.
        var rest = Substring(text)
        var value = 0
        for (place, power) in Self.powers {
            for digit in 1...7 {
                let spelling = Self.multipliers[digit] + power
                let spellings = place == 8 ? [spelling, String(spelling.dropLast())] : [spelling]
                if let match = spellings.first(where: { rest.hasPrefix($0) }) {
                    value += digit * place
                    rest = rest.dropFirst(match.count)
                    break
                }
            }
        }
        if !rest.isEmpty {
            guard let unit = Self.combiningUnits.firstIndex(of: String(rest)), unit > 0 else {
                return nil
            }
            value += unit
        }

        guard value > 0, let numeral = Numeral(value), numeral.word == text else {
            return nil
        }
        self = numeral
    }

    /// The ordinal, "first", "second" and so on, where the dictionary gives it: for
    /// 1 to 15, and for 64. Nil for every other number.
    public var ordinal: String? {
        Self.ordinals[value]
    }

    /// The number as Na'vi counts it, in base eight: 144 for 100.
    public var octal: String {
        String(value, radix: 8)
    }
}

extension Numeral {

    /// What a line of text says as a number: a number in digits, such as 100, or a
    /// Na'vi number word, such as zamtsìvosìng.
    public enum Reading: Hashable, Sendable {
        /// A number in digits, with its Na'vi word.
        case digits(Numeral)
        /// A Na'vi number word, with its value.
        case word(Numeral)
        /// A whole number in digits above `Numeral.largest`, which has no Na'vi word.
        case tooLarge
        /// Neither a whole number in digits nor a Na'vi number word.
        case notANumber

        /// The number read, if there is one.
        public var numeral: Numeral? {
            switch self {
            case .digits(let numeral), .word(let numeral):
                numeral
            case .tooLarge, .notANumber:
                nil
            }
        }
    }

    /// Reads `text` as a number in digits or as a Na'vi number word; nil when there
    /// is nothing to read. Digits may be those of any script, as a keyboard set to
    /// Arabic types them, and commas between them are ignored, so 4,096 is 4096. A
    /// minus sign or a decimal point makes the text not a number.
    public static func read(_ text: String) -> Reading? {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            return nil
        }

        let digits = trimmed.filter { $0 != "," }.map(decimalDigit)
        guard !digits.isEmpty, !digits.contains(nil) else {
            return Numeral(word: trimmed).map(Reading.word) ?? .notANumber
        }
        var value = 0
        for case let digit? in digits {
            value = value * 10 + digit
            // Stopping here also keeps a long run of digits from overflowing.
            if value > largest {
                return .tooLarge
            }
        }
        return Numeral(value).map(Reading.digits) ?? .tooLarge
    }

    /// The value of a decimal digit in any script; nil for anything else, including
    /// numerals that are not digits, such as ² and Ⅻ.
    private static func decimalDigit(_ character: Character) -> Int? {
        guard character.unicodeScalars.count == 1,
              character.unicodeScalars.first?.properties.numericType == .decimal else {
            return nil
        }
        return character.wholeNumberValue
    }
}
