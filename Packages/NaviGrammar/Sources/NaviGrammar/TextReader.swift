//
//  TextReader.swift
//  NaviGrammar
//

/// A word of a passage, with its analysis.
public struct ReadingWord: Hashable, Sendable, Identifiable {

    /// The word's position in the passage, counting words only.
    public let id: Int
    /// The word as written.
    public let text: String
    public let analysis: WordAnalysis
}

/// A multi-word dictionary entry found in a passage, such as irayo si "thank".
public struct PhraseMatch: Hashable, Sendable {

    /// The positions of the phrase's words in `Reading.words`.
    public let wordIndices: Range<Int>
    /// Its readings, most likely first.
    public let analyses: [Analysis]
}

/// A passage taken apart word by word.
public struct Reading: Hashable, Sendable {

    public let words: [ReadingWord]
    public let phrases: [PhraseMatch]

    /// The words no reading explains.
    public var unknownWords: [ReadingWord] {
        words.filter { !$0.analysis.isKnown }
    }

    /// The phrase that starts at the word at `index`, if any.
    public func phrase(startingAt index: Int) -> PhraseMatch? {
        phrases.first { $0.wordIndices.lowerBound == index }
    }
}

/// Glosses a passage of Na'vi: splits it into words, analyses each, and finds the
/// dictionary's multi-word entries. Runs entirely on the device.
public struct TextReader: Sendable {

    public let analyser: Analyser

    /// The most words any multi-word entry has.
    private let longestPhrase: Int

    public init(analyser: Analyser) {
        self.analyser = analyser
        longestPhrase = analyser.lexicon.entries.map { $0.form.split(separator: " ").count }.max() ?? 1
    }

    public func read(_ text: String) -> Reading {
        let tokens = Self.tokens(in: text)

        var words: [ReadingWord] = []
        for (index, token) in tokens.enumerated() {
            let afterLenitingWord = index > 0 && token.followsSpaceOnly && words.last.map(Self.lenitesNextWord) == true
            words.append(ReadingWord(id: index, text: token.text, analysis: analyse(token.text, afterLenitingWord: afterLenitingWord)))
        }

        var phrases: [PhraseMatch] = []
        var start = 0
        while start < tokens.count {
            var matched = false
            // The longest phrase starting here wins; its words are not reused.
            for length in stride(from: min(longestPhrase, tokens.count - start), through: 2, by: -1) {
                let range = start..<(start + length)
                guard tokens[range].dropFirst().allSatisfy(\.followsSpaceOnly) else {
                    continue
                }
                let joined = tokens[range].map(\.text).joined(separator: " ")
                let analyses = analyser.analyse(joined).analyses.filter(\.entry.isMultiword)
                if !analyses.isEmpty {
                    phrases.append(PhraseMatch(wordIndices: range, analyses: analyses))
                    start += length
                    matched = true
                    break
                }
            }
            if !matched {
                start += 1
            }
        }
        return Reading(words: words, phrases: phrases)
    }

    /// Analyses a word. A word the analyser does not know is tried again without a
    /// leading or trailing apostrophe, which may be a quotation mark rather than a
    /// tìftang.
    private func analyse(_ word: String, afterLenitingWord: Bool) -> WordAnalysis {
        let analysis = analyser.analyse(word, afterLenitingWord: afterLenitingWord)
        guard !analysis.isKnown else {
            return analysis
        }
        let quotes: Set<Character> = ["'", "\u{2019}", "\u{2018}"]
        var trimmed = Substring(word)
        while let first = trimmed.first, quotes.contains(first) { trimmed = trimmed.dropFirst() }
        while let last = trimmed.last, quotes.contains(last) { trimmed = trimmed.dropLast() }
        guard !trimmed.isEmpty, trimmed.count != word.count else {
            return analysis
        }
        let retry = analyser.analyse(String(trimmed), afterLenitingWord: afterLenitingWord)
        return retry.isKnown ? WordAnalysis(word: word, normalized: retry.normalized, analyses: retry.analyses) : analysis
    }

    /// Whether a word lenites the next one: its best reading is a leniting
    /// adposition such as mì+, uninflected.
    private static func lenitesNextWord(_ word: ReadingWord) -> Bool {
        guard let best = word.analysis.analyses.first else {
            return false
        }
        return best.isBareWord && best.entry.lenitesFollowingWord
    }

    // MARK: - Tokens

    struct Token: Equatable {
        let text: String
        /// Whether only spaces separate the token from the one before it, so that the
        /// two can form a phrase and the first can lenite the second.
        let followsSpaceOnly: Bool
    }

    /// The words of `text`. Letters, apostrophes (which spell the tìftang) and
    /// hyphens inside a word belong to the word; everything else separates words.
    static func tokens(in text: String) -> [Token] {
        let apostrophes: Set<Character> = ["'", "\u{2019}", "\u{2018}", "\u{02BC}"]
        let hyphens: Set<Character> = ["-", "\u{2010}", "\u{2011}"]
        var tokens: [Token] = []
        var current = ""
        var separator = ""

        func finish() {
            // A hyphen that ends a word is punctuation, not part of it.
            while let last = current.last, hyphens.contains(last) {
                current.removeLast()
            }
            if !current.isEmpty {
                let spaceOnly = !tokens.isEmpty && separator.allSatisfy(\.isWhitespace)
                tokens.append(Token(text: current, followsSpaceOnly: spaceOnly))
                separator = ""
            }
            current = ""
        }

        for character in text {
            if character.isLetter || character.isNumber || apostrophes.contains(character) {
                current.append(character)
            } else if hyphens.contains(character) && !current.isEmpty {
                current.append(character)
            } else {
                finish()
                separator.append(character)
            }
        }
        finish()
        return tokens
    }
}
