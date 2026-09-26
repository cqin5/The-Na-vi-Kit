//
//  Analysis.swift
//  NaviGrammar
//

import Foundation

/// A grammatical feature of an analysis, labelled for display: "agentive",
/// "«am» past", "ay+ plural".
public struct GrammarFeature: Hashable, Sendable {
    public let label: String
    public let explanation: String
}

/// One reading of a word: the lexicon entry it comes from, and how it is inflected.
public struct Analysis: Hashable, Sendable, Identifiable {

    /// The normalised word this reading explains.
    public let word: String
    public let entry: LexiconEntry
    /// The class the entry is read as, for entries with several parts of speech.
    public let wordClass: WordClass
    public let inflection: Inflection
    public let notes: Set<FormNote>
    /// Whether the word is lenited because the word before it lenites, as after the
    /// adposition mì+ (mì Helutral, from Kelutral).
    public let isLenitedByPrecedingWord: Bool
    /// The adposition the word ends in, if any.
    public let adposition: LexiconEntry?
    /// Lower is more likely: roughly the number of affixes. Used for ranking.
    public let cost: Double

    /// Readings of an entry through different parts of speech that inflect alike
    /// share an identity, so the entry is listed once.
    public var id: String {
        "\(entry.id) \(inflection) \(isLenitedByPrecedingWord)"
    }

    /// The class of the word as inflected: a derived noun is a noun, a participle an
    /// adjective.
    var resultClass: WordClass {
        if let derivation = inflection.derivation {
            return derivation.result
        }
        if let first = inflection.infixes?.first, first.isParticiple {
            return .adjective
        }
        return wordClass
    }

    /// The headword without the dictionary's + marker.
    public var baseWord: String {
        entry.headword.replacingOccurrences(of: "+", with: "")
    }

    /// Whether the word is the headword itself, uninflected.
    public var isBareWord: Bool {
        inflection.isEmpty && !isLenitedByPrecedingWord
    }

    /// The features, in the order the word is built: derivation, infixes, prefix,
    /// suffixes, ending, attribution.
    public var features: [GrammarFeature] {
        var features: [GrammarFeature] = []
        let inflection = inflection

        if let derivation = inflection.derivation {
            features.append(GrammarFeature(label: "\(derivation.rawValue) \(derivation.name)", explanation: derivation.explanation))
        }
        if let infixes = inflection.infixes {
            if let preFirst = infixes.preFirst {
                features.append(GrammarFeature(label: "«\(preFirst.rawValue)» \(preFirst.name)", explanation: preFirst.explanation))
            }
            if let first = infixes.first {
                let spelling = first.spellings.count > 1 && word.contains("ìyev") ? "ìyev" : first.rawValue
                features.append(GrammarFeature(label: "«\(spelling)» \(first.name)", explanation: first.explanation))
            }
            if let second = infixes.second {
                let spelling = notes.contains(.raisedPejorative) ? "eng" : second.rawValue
                features.append(GrammarFeature(label: "«\(spelling)» \(second.name)", explanation: second.explanation))
            }
        }
        if let prefix = inflection.prefix {
            let label = prefix == .shortPlural ? "plural (by lenition)" : "\(prefix.notation) \(prefix.name)"
            features.append(GrammarFeature(label: label, explanation: prefix.explanation))
        }
        if let suffix = inflection.suffix {
            features.append(GrammarFeature(label: "-\(suffix.rawValue) \(suffix.name)", explanation: suffix.explanation))
        }
        switch inflection.ending {
        case .case(let nounCase):
            var label = nounCase.rawValue
            if notes.contains(.casualGenitive) {
                label += " (casual)"
            } else if notes.contains(.irregularGenitive) {
                label += " (irregular)"
            }
            features.append(GrammarFeature(label: label, explanation: nounCase.explanation))
        case .adposition(let form):
            let gloss = adposition.map { Self.firstSense(of: $0.gloss) } ?? ""
            features.append(GrammarFeature(label: gloss.isEmpty ? form : "\(form) (\(gloss))", explanation: adposition?.gloss ?? ""))
        case nil:
            break
        }
        switch inflection.attributive {
        case .before:
            features.append(GrammarFeature(label: "a- attributive", explanation: "describes the noun it is joined to"))
        case .after:
            features.append(GrammarFeature(label: "-a attributive", explanation: "describes the noun it is joined to"))
        case nil:
            break
        }
        if inflection.conjunction {
            features.append(GrammarFeature(label: "-sì and", explanation: "joins this word to the one before it"))
        }
        if isLenitedByPrecedingWord {
            features.append(GrammarFeature(label: "lenited", explanation: "the first sound is softened by the word before it"))
        }
        return features
    }

    /// Remarks about the form that its features do not show: a Reef-dialect
    /// spelling, or a suffix limited to some nouns.
    public var remarks: [String] {
        [FormNote.reefSpelling, .reefForm, .collectiveVocative, .raisedPejorative]
            .filter(notes.contains)
            .map(\.explanation)
    }

    /// The analysis on one line: "oe + agentive".
    public var summary: String {
        ([baseWord] + features.map(\.label)).joined(separator: " + ")
    }

    /// The first sense of a definition, for a short label: "in, on" → "in".
    static func firstSense(of gloss: String) -> String {
        let end = gloss.firstIndex(where: { $0 == "," || $0 == ";" || $0 == "(" }) ?? gloss.endIndex
        return gloss[..<end].trimmingCharacters(in: .whitespaces)
    }
}

/// Why a word could not be analysed.
public enum UnknownReason: String, Hashable, Sendable {
    /// Nothing to analyse.
    case empty
    /// The word uses letters Na'vi does not, as a name in another language might.
    case notNaviSpelling
    /// No lexicon entry, inflected by the known rules, produces the word.
    case notFound
}

/// Everything the analyser found for one word.
public struct WordAnalysis: Hashable, Sendable {

    /// The word as given.
    public let word: String
    /// The word as analysed: normalised, without hyphens.
    public let normalized: String
    /// The readings, most likely first. Empty when the word is unknown.
    public let analyses: [Analysis]
    /// Readings left out because they build, with a productive affix, a word the
    /// dictionary lists on its own, which is read instead: 'ite + -tsyìp for
    /// 'itetsyìp "little daughter".
    public let folded: [Analysis]

    public init(word: String, normalized: String, analyses: [Analysis], folded: [Analysis] = []) {
        self.word = word
        self.normalized = normalized
        self.analyses = analyses
        self.folded = folded
    }

    public var isKnown: Bool {
        !analyses.isEmpty
    }

    public var unknownReason: UnknownReason? {
        guard analyses.isEmpty else {
            return nil
        }
        if normalized.isEmpty {
            return .empty
        }
        let foreign = normalized.contains { $0 != " " && !Orthography.letters.contains($0) }
        return foreign ? .notNaviSpelling : .notFound
    }
}
