//
//  DictionaryItem.swift
//  Na'vi
//
//  Created by Chuhan Qin on 2016-06-22.
//  Copyright © 2016 CQ. All rights reserved.
//

import UIKit

class DictionaryItem: NSObject {

    var navi:String = ""
    var category:String = ""
    var english:String = ""
    
    class func createItem(itemDictionary:NSDictionary) -> DictionaryItem {
        let item = DictionaryItem()
        
        item.navi = itemDictionary["Na'vi"] as! String
        item.category = itemDictionary["Category"] as! String
        item.english = itemDictionary["English"] as! String
        
        return item
    }

}
