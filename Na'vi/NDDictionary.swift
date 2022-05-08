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
        defaultClassifiedDictionary.sort{$0.first!.navi.uppercased() < $1.first!.navi.uppercased()}
        
        for (i,_) in defaultClassifiedDictionary.enumerated() {
            defaultClassifiedDictionary[i].sort{$0.navi.uppercased() < $1.navi.uppercased()}
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
        defaultClassifiedDictionary.sort{$0.first!.navi.uppercased() < $1.first!.navi.uppercased()}
        
        for (i,_) in defaultClassifiedDictionary.enumerated() {
            defaultClassifiedDictionary[i].sort{$0.navi.uppercased() < $1.navi.uppercased()}
        }
    }
    
    class func sectionIndices(ofDictionary entries:[[NDDictionaryEntry]]) -> [String] {
        let indices: [String] = entries.map{String($0.first!.navi.lowercased().first ?? Character(" "))}
        
        
        return indices
    }
    
    class func categories(ofDictionary entries:[[NDDictionaryEntry]]) -> [String] {
        return NSSet(array: entries.map{$0.first!.category.lowercased()}).allObjects as! [String]
    }
    
}
