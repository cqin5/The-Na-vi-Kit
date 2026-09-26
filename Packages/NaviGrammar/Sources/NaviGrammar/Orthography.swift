//
//  Orthography.swift
//  NaviGrammar
//

import Foundation

/// The facts about written Na'vi that inflection depends on: how text is
/// normalised for lookup, which letters are vowels, and lenition.
public enum Orthography {

    /// The vowels. é marks a stressed e in a few headwords, such as tuté "woman";
    /// ù is a vowel of the Reef dialect.
    static let vowels: Set<Character> = ["a", "ä", "e", "é", "i", "ì", "o", "u", "ù"]

    /// Every character a normalised Na'vi word can contain. g and x occur only in
    /// ng, kx, px and tx, but loanwords and names are spelled with the same letters.
    static let letters: Set<Character> = Set("aäeéfghiìklmnoprstuùvwxyz'")

    /// Characters typed in place of the tìftang (the apostrophe that spells a glottal
    /// stop): typographic quotes from Smart Punctuation, the modifier letter
    /// apostrophe, and accents typed as quotes.
    static let apostropheVariants: [Character] = ["\u{2019}", "\u{2018}", "\u{02BC}", "`", "\u{00B4}", "\u{2032}"]

    /// `text` in the form the lexicon is indexed by: lower case, composed characters
    /// (so a decomposed ä matches), and the straight apostrophe for the tìftang.
    public static func normalize(_ text: String) -> String {
        let lowered = text.lowercased().precomposedStringWithCanonicalMapping
        return String(lowered.map { apostropheVariants.contains($0) ? "'" : $0 })
    }

    /// The forest-dialect spelling of a word written with the Reef dialect's letters.
    /// The forest dialect, which the dictionary records, has merged the Reef vowel ù
    /// into u, and Reef writers may spell the ejectives px, tx and kx as b, d and g
    /// (https://naviteri.org/2023/01/reef-navi-part-1-phonetics-and-phonology/,
    /// https://naviteri.org/2023/01/2653/). A g in ng is part of that letter.
    static func forestSpelling(_ word: String) -> String {
        var result = ""
        var previous: Character?
        for character in word {
            switch character {
            case "ù": result.append("u")
            case "b": result += "px"
            case "d": result += "tx"
            case "g" where previous != "n": result += "kx"
            default: result.append(character)
            }
            previous = character
        }
        return result
    }

    /// Whether every character of a normalised word belongs to the Na'vi alphabet.
    static func isNaviSpelling(_ word: String) -> Bool {
        !word.isEmpty && word.allSatisfy(letters.contains)
    }

    /// Whether a word ends in a vowel. The case endings have one form after a vowel
    /// and another after a consonant, a diphthong (aw, ay, ew, ey) or a pseudovowel
    /// (ll, rr). Diphthongs and pseudovowels are spelled with a final consonant
    /// letter, so the last letter decides.
    static func endsInVowel(_ word: String) -> Bool {
        word.last.map(vowels.contains) ?? false
    }

    /// Whether a word ends in one of the diphthongs aw, ay, ew and ey.
    static func endsInDiphthong(_ word: String) -> Bool {
        ["aw", "ay", "ew", "ey"].contains { word.hasSuffix($0) }
    }

    /// Whether the genitive is -yä rather than -ä: after a, ä, e, i and ì
    /// (appendix H). é is a stressed e.
    static func takesYäGenitive(_ word: String) -> Bool {
        guard let last = word.last else {
            return false
        }
        return ["a", "ä", "e", "é", "i", "ì"].contains(last)
    }

    // MARK: - Lenition

    /// Lenition softens the first consonant of a word after a leniting boundary,
    /// written + in the dictionary: the ejectives px, tx and kx lose their ejection,
    /// p, t and k become f, s and h, ts becomes s, and the tìftang disappears. This is
    /// Dr. Frommer's table (Language Log, 19 December 2009,
    /// https://languagelog.ldc.upenn.edu/nll/?p=1977); the PDF dictionary assumes it.
    /// Two-letter spellings are listed first so that tx is not read as t.
    private static let lenitions: [(from: String, to: String)] = [
        ("px", "p"), ("tx", "t"), ("kx", "k"), ("ts", "s"),
        ("p", "f"), ("t", "s"), ("k", "h"), ("'", ""),
    ]

    /// The lenited form of a normalised word. Words that begin with any other
    /// sound are unchanged, and so is a tìftang before a pseudovowel: 'llngo "hip"
    /// gives me'llngo (https://naviteri.org/2012/03/spring-vocabulary-part-1/).
    static func lenite(_ word: String) -> String {
        for (from, to) in lenitions where word.hasPrefix(from) {
            let rest = word.dropFirst(from.count)
            if from == "'" && (rest.hasPrefix("ll") || rest.hasPrefix("rr")) {
                return word
            }
            return to + rest
        }
        return word
    }

    /// Every spelling whose lenited form is `word`: `word` itself when it begins
    /// with a sound that does not lenite, and each spelling it could have come from.
    /// A word beginning with p, t or k can only come from px, tx or kx, since p, t
    /// and k themselves lenite.
    static func unlenitedCandidates(_ word: String) -> [String] {
        var candidates = [word]
        for (from, to) in lenitions where !to.isEmpty && word.hasPrefix(to) {
            candidates.append(from + word.dropFirst(to.count))
        }
        if let first = word.first, vowels.contains(first) {
            candidates.append("'" + word)
        }
        return candidates.filter { lenite($0) == word }
    }
}
