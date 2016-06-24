//
//  NDDictionary.swift
//  Na'vi
//
//  Created by Chuhan Qin on 2016-06-23.
//  Copyright © 2016 CQ. All rights reserved.
//

import UIKit

class NDDictionary: NSObject {
    
    var defaultDictionary: [NDDictionaryEntry] = [NDDictionaryEntry]()
    var defaultClassifiedDictionary: [[NDDictionaryEntry]] = [[NDDictionaryEntry]]()
    var defaultSectionIndices: [String] = [String]()
    
    override init(){
        super.init()
        loadDictionaryFile()
        classifyDictionaryV2()
        defaultSectionIndices = NDDictionary.sectionIndices(withDictionary: defaultClassifiedDictionary)
    }

    // *** Na'vi Dictionary Data ***
    func loadDictionaryFile() {
        defaultDictionary.removeAll()
        do {
            let path = NSBundle.mainBundle().URLForResource("DictionaryFile", withExtension: "json")
            let jsonData = NSData(contentsOfURL:path!)
            let jsonResult: NSDictionary = try NSJSONSerialization.JSONObjectWithData(jsonData!, options: NSJSONReadingOptions.MutableContainers) as! NSDictionary
            
            for jsonItem in jsonResult["dict"]!.allObjects {
                defaultDictionary.append(NDDictionaryEntry.createEntry((jsonItem as! NSDictionary)))
            }
            
        } catch let error as NSError {
            print(error)
        }
    }
    
    func classifyDictionary() {
        defaultClassifiedDictionary.removeAll()
        var currentFirstLetter : Character = Character(" ")
        for dictionaryEntry in defaultDictionary {
            if !dictionaryEntry.navi.uppercaseString.characters.contains(currentFirstLetter) { // if the current first letter has been scanned before, skip
                currentFirstLetter = dictionaryEntry.navi.uppercaseString.characters.first!
                let entry : [NDDictionaryEntry] = defaultDictionary.filter{ $0.navi.uppercaseString.characters.first! == currentFirstLetter }
                defaultClassifiedDictionary.append(entry)
            }
        }
        defaultClassifiedDictionary = NSSet(array: defaultClassifiedDictionary).allObjects as! [[NDDictionaryEntry]]
        defaultClassifiedDictionary.sortInPlace{$0.first!.navi < $1.first!.navi}
        
        for (i,_) in defaultClassifiedDictionary.enumerate() {
            defaultClassifiedDictionary[i].sortInPlace{$0.navi < $1.navi}
        }
    }
    
    func classifyDictionaryV2() {
        defaultClassifiedDictionary.removeAll()
        var firstLettersScanned : [Character] = [Character]()
        
        for dictionaryEntry in defaultDictionary {
            let currentFirstLetter : Character = dictionaryEntry.navi.uppercaseString.characters.first!
            if !firstLettersScanned.contains(currentFirstLetter) {
                firstLettersScanned.append(currentFirstLetter)
                let entry : [NDDictionaryEntry] = defaultDictionary.filter{ $0.navi.uppercaseString.characters.first! == currentFirstLetter }
                defaultClassifiedDictionary.append(entry)
            }
        }
        defaultClassifiedDictionary = NSSet(array: defaultClassifiedDictionary).allObjects as! [[NDDictionaryEntry]]
        defaultClassifiedDictionary.sortInPlace{$0.first!.navi < $1.first!.navi}
        
        for (i,_) in defaultClassifiedDictionary.enumerate() {
            defaultClassifiedDictionary[i].sortInPlace{$0.navi < $1.navi}
        }
    }
    
    class func sectionIndices(withDictionary entries:[[NDDictionaryEntry]]) -> [String] {
        let indices: [String] = entries.map{String($0.first!.navi.lowercaseString.characters.first!)}
        return indices
    }
    
}
