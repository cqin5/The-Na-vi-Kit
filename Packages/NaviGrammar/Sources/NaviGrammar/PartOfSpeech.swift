//
//  PartOfSpeech.swift
//  NaviGrammar
//

/// A part of speech as the LearnNavi dictionary abbreviates it, such as `vtr.`.
///
/// A struct rather than an enumeration, so a lexicon that introduces a new
/// abbreviation still loads; the new part of speech simply takes no inflections.
public struct PartOfSpeech: RawRepresentable, Hashable, Sendable {

    public let rawValue: String

    public init(rawValue: String) {
        self.rawValue = rawValue
    }

    public static let noun = PartOfSpeech(rawValue: "n.")
    public static let properNoun = PartOfSpeech(rawValue: "prop.n.")
    public static let pronoun = PartOfSpeech(rawValue: "pn.")
    public static let adjective = PartOfSpeech(rawValue: "adj.")
    public static let adverb = PartOfSpeech(rawValue: "adv.")
    public static let adposition = PartOfSpeech(rawValue: "adp.")
    public static let number = PartOfSpeech(rawValue: "num.")
    public static let intransitiveVerb = PartOfSpeech(rawValue: "vin.")
    public static let transitiveVerb = PartOfSpeech(rawValue: "vtr.")

    /// The inflectional class this part of speech belongs to.
    public var wordClass: WordClass {
        switch rawValue {
        case "n.": .noun
        case "pn.": .pronoun
        case "prop.n.": .properNoun
        case "adj.": .adjective
        case "adv.": .adverb
        case "num.": .number
        case "adp.": .adposition
        case "v.", "vin.", "vtr.", "vim.", "vtrm.": .verb
        default: .other
        }
    }

    /// The part of speech spelled out, in lower case: "transitive verb".
    public var name: String {
        Self.names[rawValue] ?? rawValue
    }

    private static let names: [String: String] = [
        "adj.": "adjective", "adp.": "adposition", "adv.": "adverb", "conj.": "conjunction",
        "inter.": "interrogative", "intj.": "interjection", "n.": "noun", "num.": "number",
        "part.": "particle", "ph.": "phrase", "pn.": "pronoun", "prop.n.": "proper noun",
        "sbd.": "subordinator", "v.": "verb", "vim.": "intransitive modal verb",
        "vin.": "intransitive verb", "vtr.": "transitive verb", "vtrm.": "transitive modal verb",
    ]
}

/// The classes of words that inflect alike.
public enum WordClass: String, Hashable, Sendable, CaseIterable {
    case noun
    case pronoun
    case properNoun
    case verb
    case adjective
    case adverb
    case number
    case adposition
    case other

    /// Classes that take case endings.
    var isNominal: Bool {
        self == .noun || self == .pronoun || self == .properNoun
    }
}
