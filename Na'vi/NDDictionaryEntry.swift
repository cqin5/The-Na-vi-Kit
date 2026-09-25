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
    /// Unrecognised abbreviations are passed through unchanged so new source data
    /// still reads sensibly before this list catches up with it.
    var partOfSpeech: String {
        switch partOfSpeechShort.trimmingCharacters(in: .whitespaces) {
        case "adj.":
            return "Adjective"
        case "adv.":
            return "Adverb"
        case "conj.":
            return "Conjunction"
        case "inter":
            return "Interrogative"
        case "inter., intj.":
            return "Interrogative, interjection"
        case "intj.":
            return "Interjection"
        case "n.":
            return "Noun"
        case "n., adv.":
            return "Noun, adverb"
        case "n., intj.":
            return "Noun, interjection"
        case "num.":
            return "Number"
        case "part.":
            return "Particle"
        case "part., intj.":
            return "Particle, interjection"
        case "ph.":
            return "Phrase"
        case "pn.":
            return "Pronoun"
        case "pn., adv.":
            return "Pronoun, adverb"
        case "pn., sbd.":
            return "Pronoun, subordinator"
        case "prop.n.":
            return "Proper noun"
        case "sbd.":
            return "Subordinator"
        case "svin.", "vin.":
            return "Intransitive verb"
        case "v.":
            return "Verb"
        case "vim.":
            return "Intransitive modal verb"
        case "vtr.":
            return "Transitive verb"
        case "vtr., vin.":
            return "Transitive verb, intransitive verb"
        case "vtrm.":
            return "Transitive modal verb"
        case "vtrm., vtr.":
            return "Transitive modal verb, transitive verb"
        default:
            return partOfSpeechShort
        }
    }
}
