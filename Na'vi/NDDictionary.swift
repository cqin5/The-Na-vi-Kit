//
//  NDDictionary.swift
//  Na'vi
//
//  Created by Chuhan Qin on 2016-06-23.
//  Copyright © 2016 CQ. All rights reserved.
//

import Foundation

/// The entries that share a first letter.
struct DictionarySection: Identifiable, Hashable, Sendable {

    /// The shared first letter, lowercased as it appears in the headwords.
    let letter: String
    let entries: [NDDictionaryEntry]

    var id: String { letter }

    /// The label for the section header and the section index.
    var indexLabel: String { letter.uppercased() }
}

/// Loads the bundled Na'vi vocabulary, groups it for display, and searches it.
enum NDDictionary {

    /// Every entry, grouped by the first letter of the Na'vi headword. Sections and
    /// the entries inside them are both sorted.
    ///
    /// Reads and decodes about 900 KB of JSON, so call it off the main thread.
    static func loadSections(resourceName: String = "vocabulary", bundle: Bundle = .main) -> [DictionarySection] {
        group(loadEntries(named: resourceName, in: bundle))
    }

    /// The sections, keeping only entries whose Na'vi or English text contains
    /// `query`. Sections left empty are dropped.
    ///
    /// Matching ignores case but not diacritics: ä and ì are separate letters in
    /// Na'vi, not accented forms of a and i.
    static func filtered(_ sections: [DictionarySection], matching query: String) -> [DictionarySection] {
        let query = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else {
            return sections
        }

        return sections.compactMap { section in
            let matches = section.entries.filter {
                $0.navi.localizedCaseInsensitiveContains(query)
                    || $0.english.localizedCaseInsensitiveContains(query)
            }
            return matches.isEmpty ? nil : DictionarySection(letter: section.letter, entries: matches)
        }
    }

    // MARK: - Loading

    private struct VocabularyFile: Decodable {
        let dict: [NDDictionaryEntry]
    }

    private static func loadEntries(named name: String, in bundle: Bundle) -> [NDDictionaryEntry] {
        guard let url = bundle.url(forResource: name, withExtension: "json") else {
            assertionFailure("\(name).json is missing from the app bundle.")
            return []
        }

        do {
            let data = try Data(contentsOf: url)
            return try JSONDecoder().decode(VocabularyFile.self, from: data).dict
        } catch {
            assertionFailure("Could not read \(name).json: \(error)")
            return []
        }
    }

    // MARK: - Grouping

    private static func group(_ entries: [NDDictionaryEntry]) -> [DictionarySection] {
        let grouped = Dictionary(grouping: entries) { entry in
            entry.navi.uppercased().first ?? " "
        }

        return grouped
            .sorted { $0.key < $1.key }
            .map { group in
                let sorted = group.value.sorted { $0.navi.uppercased() < $1.navi.uppercased() }
                let letter = sorted.first?.navi.lowercased().first.map(String.init) ?? " "
                return DictionarySection(letter: letter, entries: sorted)
            }
    }
}
