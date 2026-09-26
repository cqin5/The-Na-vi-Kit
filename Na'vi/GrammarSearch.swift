//
//  GrammarSearch.swift
//  Na'vi
//
//  Copyright © 2016 CQ. All rights reserved.
//

import Foundation
import NaviGrammar

/// An inflected form found by search: how the word is built, and the dictionary
/// entries for the word it is built from.
struct WordFormMatch: Identifiable, Hashable, Sendable {

    /// The search text the analysis reads.
    let word: String
    let analysis: Analysis
    /// The app dictionary's entries for the base word. Empty when the app's
    /// vocabulary does not have the word, and the grammar lexicon's definition is
    /// shown instead.
    let entries: [NDDictionaryEntry]

    var id: String { analysis.id }

    /// The analysis on one line, as "oel → oe + agentive".
    var line: String {
        "\(word) → \(analysis.summary)"
    }

    /// The same, in words, for VoiceOver.
    var spokenLine: String {
        let features = analysis.features.map(\.label).joined(separator: ", ")
        return "\(word): \(analysis.baseWord), \(features)"
    }
}

/// Connects the grammar engine to the app's dictionary: reads the search text as
/// an inflected Na'vi word and finds the entries of the word it comes from.
///
/// The grammar lexicon and the app's vocabulary are separate files. An analysis is
/// matched to vocabulary entries at run time by headword and part of speech; neither
/// file refers to the other.
struct GrammarSearch: Sendable {

    let analyser: Analyser
    let reader: TextReader
    private let entriesByHeadword: [String: [NDDictionaryEntry]]

    init(analyser: Analyser, sections: [DictionarySection]) {
        self.analyser = analyser
        reader = TextReader(analyser: analyser)
        entriesByHeadword = Dictionary(grouping: sections.flatMap(\.entries)) { Self.key($0.navi) }
    }

    /// Loads the grammar lexicon bundled with NaviGrammar. It takes tens of
    /// milliseconds, so call it off the main thread along with the vocabulary.
    static func load(sections: [DictionarySection]) -> GrammarSearch? {
        do {
            return GrammarSearch(analyser: try Analyser.bundled(), sections: sections)
        } catch {
            assertionFailure("Could not load the grammar lexicon: \(error)")
            return nil
        }
    }

    /// The inflected readings of `query`, most likely first. Empty when the query is
    /// not a Na'vi word form the rules produce, or is a headword itself, which the
    /// ordinary search already finds.
    func wordForms(matching query: String) -> [WordFormMatch] {
        let word = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !word.isEmpty, word.count <= 60 else {
            return []
        }
        return analyser.analyse(word).analyses
            .filter { !$0.isBareWord }
            .prefix(6)
            .map { WordFormMatch(word: word, analysis: $0, entries: dictionaryEntries(for: $0)) }
    }

    /// The vocabulary entries for an analysis's base word: same headword, and a
    /// part of speech in common with the lexicon entry, so that a homograph such as
    /// tsun "heel" is not shown for tsun "can".
    func dictionaryEntries(for analysis: Analysis) -> [NDDictionaryEntry] {
        let lexiconCodes = Set(analysis.entry.partsOfSpeech.map(\.rawValue))
        return entriesByHeadword[Self.key(analysis.entry.headword), default: []].filter { entry in
            !lexiconCodes.isDisjoint(with: entry.partOfSpeechShort
                .split(separator: ",")
                .map { $0.trimmingCharacters(in: .whitespaces) })
        }
    }

    /// Headwords compared as the grammar engine compares them, without the + that
    /// marks a leniting adposition.
    private static func key(_ headword: String) -> String {
        Orthography.normalize(headword.replacingOccurrences(of: "+", with: ""))
    }
}

/// The grammar engine as the app loads it, after the vocabulary.
enum GrammarState {
    case loading
    case ready(GrammarSearch)
    /// The grammar lexicon could not be loaded. Words can still be looked up, but
    /// not read.
    case unavailable

    /// The engine, once it has loaded.
    var search: GrammarSearch? {
        switch self {
        case .ready(let search):
            search
        case .loading, .unavailable:
            nil
        }
    }
}
