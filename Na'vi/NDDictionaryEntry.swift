//
//  DictionaryEntry.swift
//  Na'vi
//
//  Created by Chuhan Qin on 2016-06-22.
//  Copyright © 2016 CQ. All rights reserved.
//

import UIKit

class NDDictionaryEntry: NSObject {

    var navi:String = ""
    var partOfSpeechShort:String = ""
    var partOfSpeech:String {
        switch partOfSpeechShort {
        case "adj.", "adj. ":
            return "Adjective"
        case "adv.", "adv. ":
            return "Adverb"
        case "conj.", "conj. ":
            return "Conjunction"
        case "inter", "inter ":
            return "Interrogative"
        case "inter., intj. ":
            return "Interrogative, interjection"
        case "intj.", "intj. ":
            return "Interjection"
        case "n.", "n. ":
            return "Noun"
        case "n., adv. ":
            return "Noun, adverb"
        case "n., intj. ":
            return "Noun, interjection"
        case "num.", "num. ":
            return "Number"
        case "part.", "part. ":
            return "Particle"
        case "part., intj. ":
            return "Particle, interjection"
        case "ph.", "ph. ":
            return "Phrase"
        case "pn.", "pn. ":
            return "Pronoun"
        case "pn., adv. ":
            return "Pronoun, adverb"
        case "pn., sbd. ":
            return "Pronoun, subordinator"
        case "prop.n.", "prop.n. ":
            return "Proper noun"
        case "sbd.", "sbd. ":
            return "Subordinator"
        case "svin.", "svin. ":
            return "Intransitive verb" // TODO
        case "v.", "v. ":
            return "Verb"
        case "vim.", "vim. ":
            return "Intransitive modal verb"
        case "vin.", "vin. ":
            return "Intransitive verb"
        case "vtr.", "vtr. ":
            return "Transitive verb"
        case "vtr., vin. ":
            return "Transitive verb, intransitive verb"
        case "vtrm.", "vtrm. ":
            return "Transitive modal verb"
        case "vtrm., vtr. ":
            return "Transitive modal verb, transitive verb"

        default:
            return partOfSpeechShort
        }
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
