//
//  NDDictionary.swift
//  Na'vi
//
//  Created by Chuhan Qin on 2016-06-23.
//  Copyright © 2016 CQ. All rights reserved.
//

import Foundation

/// Loads the bundled Na'vi vocabulary and groups it for display.
final class NDDictionary {

    /// Every entry, grouped by the first letter of the Na'vi headword. Sections and
    /// the entries inside them are both sorted.
    private(set) var classifiedEntries: [[NDDictionaryEntry]] = []

    init(resourceName: String = "vocabulary", bundle: Bundle = .main) {
        classifiedEntries = Self.group(Self.loadEntries(named: resourceName, in: bundle))
    }

    /// The section index titles for a grouped dictionary.
    static func sectionIndices(ofDictionary entries: [[NDDictionaryEntry]]) -> [String] {
        entries.map { section in
            guard let initial = section.first?.navi.lowercased().first else { return " " }
            return String(initial)
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

    private static func group(_ entries: [NDDictionaryEntry]) -> [[NDDictionaryEntry]] {
        let grouped = Dictionary(grouping: entries) { entry in
            entry.navi.uppercased().first ?? " "
        }

        return grouped
            .sorted { $0.key < $1.key }
            .map { $0.value.sorted { $0.navi.uppercased() < $1.navi.uppercased() } }
    }
}
