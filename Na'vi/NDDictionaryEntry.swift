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
    var category:String = ""
    var english:String = ""
    var IPA:String = ""
    
    class func createEntry(_ itemDictionary:NSDictionary) -> NDDictionaryEntry {
        let entry = NDDictionaryEntry()
        
        entry.navi = itemDictionary["Na'vi"] as! String
        entry.category = itemDictionary["Category"] as! String
        entry.english = itemDictionary["English"] as! String
        entry.IPA = itemDictionary["IPA"] as! String
        return entry
    }

}
