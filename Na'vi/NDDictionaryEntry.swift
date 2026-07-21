//
//  DictionaryEntry.swift
//  Na'vi
//
//  Created by Chuhan Qin on 2016-06-22.
//  Copyright © 2016 CQ. All rights reserved.
//

import UIKit

class NDDictionaryEntry: NSObject {

    
    var isBookmarked = false
    
    var navi:String = ""
    var partOfSpeechShort:String = ""
    // Base part-of-speech abbreviations → full names. Compound codes such as
    // "n., adv." or "vtr., vin." are split on "," and each part expanded, so
    // any combination (present or future) renders without a hardcoded case.
    private static let posNames: [String: String] = [
        "n.": "Noun",
        "adj.": "Adjective",
        "adv.": "Adverb",
        "adp.": "Adposition",
        "conj.": "Conjunction",
        "dem.": "Demonstrative",
        "inter.": "Interrogative",
        "inter": "Interrogative",
        "intj.": "Interjection",
        "num.": "Numeral",
        "part.": "Particle",
        "ph.": "Phrase",
        "pn.": "Pronoun",
        "prop.n.": "Proper noun",
        "sbd.": "Subordinator",
        "v.": "Verb",
        "vin.": "Intransitive verb",
        "svin.": "Stative intransitive verb",
        "vim.": "Intransitive modal verb",
        "vtr.": "Transitive verb",
        "vtrm.": "Transitive modal verb",
    ]

    var partOfSpeech:String {
        let raw = partOfSpeechShort.trimmingCharacters(in: .whitespaces)
        if raw.isEmpty { return "" }

        var expanded: [String] = []
        for part in raw.components(separatedBy: ",") {
            let token = part.trimmingCharacters(in: .whitespaces)
            if token.isEmpty { continue }
            guard let name = NDDictionaryEntry.posNames[token] else {
                return partOfSpeechShort   // unknown token: show the raw code rather than a wrong label
            }
            expanded.append(name)
        }
        if expanded.isEmpty { return partOfSpeechShort }

        // First segment capitalized, later segments lowercased: "Noun, adverb".
        return expanded.enumerated().map { index, name in
            index == 0 ? name : name.prefix(1).lowercased() + name.dropFirst()
        }.joined(separator: ", ")
    }
    var english:String = ""
    var IPA:String = ""

    var audioFileLocation = ""
    var localAudioFileName = ""

    class func createEntry(_ itemDictionary:NSDictionary) -> NDDictionaryEntry {
        let entry = NDDictionaryEntry()
        
        entry.navi = itemDictionary["Na'vi"] as! String
        entry.partOfSpeechShort = itemDictionary["Part of speech"] as! String
        entry.english = itemDictionary["English"] as! String
        entry.IPA = itemDictionary["IPA"] as! String
        
        entry.audioFileLocation = itemDictionary["Audio URL"] as! String
        entry.localAudioFileName = itemDictionary["Audio local URL"] as! String

        return entry
    }

}
