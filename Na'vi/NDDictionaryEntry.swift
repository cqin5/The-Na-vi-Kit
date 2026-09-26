//
//  NDDictionaryEntry.swift
//  Na'vi
//
//  Created by Chuhan Qin on 2016-06-22.
//  Copyright © 2016 CQ. All rights reserved.
//

import Foundation

/// A single vocabulary entry from the bundled Na'vi dictionary.
///
/// A value type, so entries can be decoded off the main thread and handed to the
/// interface without sharing mutable state.
struct NDDictionaryEntry: Decodable, Hashable, Identifiable, Sendable {

    /// A per-launch identity, so entries that share a headword stay distinct.
    let id = UUID()

    let navi: String
    let english: String
    let ipa: String
    let partOfSpeechShort: String

    let audioFileLocation: String
    let localAudioFileName: String

    /// Whether the app bundles a recording of this entry. Entries added from sources
    /// without recordings leave the file name empty.
    var hasRecording: Bool { !localAudioFileName.isEmpty }

    private enum CodingKeys: String, CodingKey {
        case navi = "Na'vi"
        case english = "English"
        case ipa = "IPA"
        case partOfSpeechShort = "Part of speech"
        case audioFileLocation = "Audio URL"
        case localAudioFileName = "Audio local URL"
    }

    /// The abbreviated part of speech from the source data, spelled out.
    ///
    /// A combined code such as `n., adv.` is spelled out one abbreviation at a
    /// time, as "Noun, adverb". A code with an abbreviation this list does not
    /// know is passed through unchanged, so new source data still reads sensibly
    /// before the list catches up with it.
    var partOfSpeech: String {
        let names = partOfSpeechShort
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
            .map { Self.partOfSpeechNames[$0] }

        guard !names.isEmpty, !names.contains(nil) else {
            return partOfSpeechShort
        }

        return names.compactMap { $0 }.enumerated().map { index, name in
            index == 0 ? name : name.prefix(1).lowercased() + name.dropFirst()
        }.joined(separator: ", ")
    }

    private static let partOfSpeechNames: [String: String] = [
        "adj.": "Adjective",
        "adp.": "Adposition",
        "adv.": "Adverb",
        "conj.": "Conjunction",
        "dem.": "Demonstrative",
        "inter": "Interrogative",
        "inter.": "Interrogative",
        "intj.": "Interjection",
        "n.": "Noun",
        "num.": "Numeral",
        "part.": "Particle",
        "ph.": "Phrase",
        "pn.": "Pronoun",
        "pref.": "Prefix",
        "prop.n.": "Proper noun",
        "sbd.": "Subordinator",
        "suff.": "Suffix",
        "svin.": "Stative intransitive verb",
        "v.": "Verb",
        "vim.": "Intransitive modal verb",
        "vin.": "Intransitive verb",
        "vtr.": "Transitive verb",
        "vtrm.": "Transitive modal verb",
    ]
}
