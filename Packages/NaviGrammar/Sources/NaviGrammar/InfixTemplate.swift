//
//  InfixTemplate.swift
//  NaviGrammar
//

/// Where a verb's infixes go, as the LearnNavi dictionary records it: `k<0><1>am<2>e`
/// for kame "see". Position 0 (pre-first) and position 1 (first) sit together before
/// the vowel of the verb's first syllable, and position 2 (second) before the vowel
/// of its last. The positions come from the dictionary rather than a syllable rule,
/// because verbs marked irregular (ii) and compounds put them elsewhere.
///
/// A multi-word verb, such as `irayo s<0><1><2>i` "thank", takes its infixes in one
/// word only; the others stay as they are.
public struct InfixTemplate: Hashable, Sendable {

    public enum Word: Hashable, Sendable {
        /// A word that takes no infixes.
        case fixed(String)
        /// A word that does: `onset` + positions 0 and 1 + `middle` + position 2 + `coda`.
        case slotted(onset: String, middle: String, coda: String)

        /// The word with no infixes.
        var bare: String {
            switch self {
            case .fixed(let text): text
            case .slotted(let onset, let middle, let coda): onset + middle + coda
            }
        }
    }

    public let words: [Word]

    /// Parses a template, normalised as the lexicon is. Returns `nil` for a template
    /// that is malformed or marks no infix positions.
    public init?(_ template: String) {
        var words: [Word] = []
        for part in template.split(separator: " ", omittingEmptySubsequences: false) {
            let text = String(part)
            guard let firstSlots = text.range(of: "<0><1>") else {
                guard !text.isEmpty, !text.contains("<"), !text.contains(">") else {
                    return nil
                }
                words.append(.fixed(text))
                continue
            }
            let rest = text[firstSlots.upperBound...]
            guard let secondSlot = rest.range(of: "<2>") else {
                return nil
            }
            let onset = String(text[..<firstSlots.lowerBound])
            let middle = String(rest[..<secondSlot.lowerBound])
            let coda = String(rest[secondSlot.upperBound...])
            guard !(onset + middle + coda).contains("<") else {
                return nil
            }
            words.append(.slotted(onset: onset, middle: middle, coda: coda))
        }
        guard words.contains(where: { if case .slotted = $0 { true } else { false } }) else {
            return nil
        }
        self.words = words
    }

    /// The indices of the words that can take infixes. Almost always one.
    public var slottedWordIndices: [Int] {
        words.indices.filter { if case .slotted = words[$0] { true } else { false } }
    }

    /// The verb with no infixes, which is its headword.
    public var bare: String {
        words.map(\.bare).joined(separator: " ")
    }

    /// The verb with the given infix strings in the word at `wordIndex`.
    func filled(preFirst: String, first: String, second: String, inWord wordIndex: Int) -> String {
        words.enumerated().map { index, word in
            guard index == wordIndex, case .slotted(let onset, let middle, let coda) = word else {
                return word.bare
            }
            return onset + preFirst + first + middle + second + coda
        }.joined(separator: " ")
    }
}
