//
//  NDDictionary.swift
//  Na'vi
//
//  Created by Chuhan Qin on 2016-06-23.
//  Copyright © 2016 CQ. All rights reserved.
//

import UIKit

class NDDictionary: NSObject {
    
//    static var savedEntries: [NDDictionaryEntry] {
//        set {
//            let data = try? NSKeyedArchiver.archivedData(withRootObject: newValue, requiringSecureCoding: false)
//            UserDefaults.standard.set(data, forKey: "savedEntries")
//        }
//        
//        get {
//            NSKeyedUnarchiver.unarchivedObject(ofClass: <#T##NSCoding.Protocol#>, from: <#T##Data#>)
//        }
//    }
    
    var defaultDictionary: [NDDictionaryEntry] = [NDDictionaryEntry]()
    var defaultClassifiedDictionary: [[NDDictionaryEntry]] = [[NDDictionaryEntry]]()
    var defaultSectionIndices: [String] = [String]()
    
    override init(){
        super.init()
        loadDictionaryFile()
        classifyDictionaryV2()
        defaultSectionIndices = NDDictionary.sectionIndices(ofDictionary: defaultClassifiedDictionary)
    }

    // *** Na'vi Dictionary Data ***
    func loadDictionaryFile() {
        defaultDictionary.removeAll()
        do {
            let path = Bundle.main.url(forResource: "vocabulary", withExtension: "json")
            let jsonData = try? Data(contentsOf: path!)
            let jsonResult: NSDictionary = try JSONSerialization.jsonObject(with: jsonData!, options: JSONSerialization.ReadingOptions.mutableContainers) as! NSDictionary
            
            for jsonItem in (jsonResult["dict"]! as AnyObject).allObjects {
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
            if !dictionaryEntry.navi.uppercased().contains(currentFirstLetter) { // if the current first letter has been scanned before, skip
                currentFirstLetter = dictionaryEntry.navi.uppercased().first ?? Character(" ")
                let entry : [NDDictionaryEntry] = defaultDictionary.filter{ $0.navi.uppercased().first == currentFirstLetter }
                defaultClassifiedDictionary.append(entry)
            }
        }
        defaultClassifiedDictionary = NSSet(array: defaultClassifiedDictionary).allObjects as! [[NDDictionaryEntry]]
        defaultClassifiedDictionary.sort{ NDDictionary.naviIsOrderedBefore($0.first!.navi, $1.first!.navi) }
        
        for (i,_) in defaultClassifiedDictionary.enumerated() {
            defaultClassifiedDictionary[i].sort{ NDDictionary.naviIsOrderedBefore($0.navi, $1.navi) }
        }
    }
    
    func classifyDictionaryV2() {
        defaultClassifiedDictionary.removeAll()
        var firstLettersScanned : [Character] = [Character]()
        
        for dictionaryEntry in defaultDictionary {
            let currentFirstLetter : Character = dictionaryEntry.navi.uppercased().first ?? Character(" ")
            if !firstLettersScanned.contains(currentFirstLetter) {
                firstLettersScanned.append(currentFirstLetter)
                let entry : [NDDictionaryEntry] = defaultDictionary.filter{ $0.navi.uppercased().first == currentFirstLetter }
                defaultClassifiedDictionary.append(entry)
            }
        }
        defaultClassifiedDictionary = NSSet(array: defaultClassifiedDictionary).allObjects as! [[NDDictionaryEntry]]
        defaultClassifiedDictionary.sort{ NDDictionary.naviIsOrderedBefore($0.first!.navi, $1.first!.navi) }
        
        for (i,_) in defaultClassifiedDictionary.enumerated() {
            defaultClassifiedDictionary[i].sort{ NDDictionary.naviIsOrderedBefore($0.navi, $1.navi) }
        }
    }
    
    // MARK: - Na'vi collation
    // Orders by the Na'vi alphabet: apostrophe first, then `ä` immediately after
    // `a` and `ì` immediately after `i`. Plain scalar `<` wrongly sorts Ä (U+00C4)
    // and Ì (U+00CC) after Z, misfiling ~1/3 of within-section words.
    private static let naviCollationRank: [Character: Int] = {
        var map: [Character: Int] = [:]
        for (i, ch) in Array("'aäbcdefghiìjklmnopqrstuvwxyz").enumerated() { map[ch] = i }
        return map
    }()

    static func naviIsOrderedBefore(_ lhs: String, _ rhs: String) -> Bool {
        let a = Array(lhs.lowercased())
        let b = Array(rhs.lowercased())
        let count = min(a.count, b.count)
        for i in 0..<count {
            let ra = naviCollationRank[a[i]] ?? (100 + Int(a[i].unicodeScalars.first?.value ?? 0))
            let rb = naviCollationRank[b[i]] ?? (100 + Int(b[i].unicodeScalars.first?.value ?? 0))
            if ra != rb { return ra < rb }
        }
        return a.count < b.count
    }

    class func sectionIndices(ofDictionary entries:[[NDDictionaryEntry]]) -> [String] {
        let indices: [String] = entries.map{String($0.first!.navi.lowercased().first ?? Character(" "))}
        
        
        return indices
    }
    
    class func categories(ofDictionary entries:[[NDDictionaryEntry]]) -> [String] {
        let returnValue = NSSet(array: entries.map{$0.first!.partOfSpeech.lowercased()}).allObjects as! [String]
        return returnValue
    }
    
}



extension NDDictionary {
    
    
    
    
    
}
