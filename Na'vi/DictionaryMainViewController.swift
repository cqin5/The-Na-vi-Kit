//
//  DictionaryMainViewController.swift
//  Na'vi
//
//  Created by Chuhan Qin on 2016-06-22.
//  Copyright © 2016 CQ. All rights reserved.
//

import UIKit

class DictionaryMainViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UISearchBarDelegate {

    @IBOutlet var tableView : UITableView!
    @IBOutlet var searchBar : UISearchBar!
    
    var defaultDictionaryEntries : [NDDictionaryEntry] = [NDDictionaryEntry]()
    var dictionaryItems : [NDDictionaryEntry] = [NDDictionaryEntry]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        loadDictionaryFile()
        dictionaryItems = defaultDictionaryEntries
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        if searchBar.text?.characters.count > 0 {
            self.searchText(searchBar.text!)
        }
    }

    
    // *** Table View Data ***
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dictionaryItems.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("MainDictionaryCell", forIndexPath: indexPath) as! NDDictionaryMainTableViewCell
        cell.loadData(dictionaryItems[indexPath.row])
        return cell
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let storyboard = UIStoryboard(name: "Dictionary", bundle: nil)
        let definitionViewController : NDDefinitionViewController = storyboard.instantiateViewControllerWithIdentifier("NDDefinitionViewController") as! NDDefinitionViewController
        definitionViewController.entry = dictionaryItems[indexPath.row]
        self.navigationController?.pushViewController(definitionViewController, animated: true)
    }
    
    
    // *** Na'vi Dictionary Data ***
    func loadDictionaryFile() {
        dictionaryItems.removeAll()
        if let path = NSBundle.mainBundle().URLForResource("DictionaryFile", withExtension: "json") {
            
            if let jsonData = NSData(contentsOfURL:path) {
                
                do {
                    
                    let jsonResult: NSDictionary = try NSJSONSerialization.JSONObjectWithData(jsonData, options: NSJSONReadingOptions.MutableContainers) as! NSDictionary
                    
                    for jsonItem in jsonResult["dict"]!.allObjects {
                        defaultDictionaryEntries.append(NDDictionaryEntry.createEntry((jsonItem as! NSDictionary)))
                    }
                    
                    self.tableView.reloadData()
                    
                } catch let error as NSError {
                    print(error)
                }
                
                
            }
        }
    }
    
    func loadDefaultDictionary() {
        self.dictionaryItems = defaultDictionaryEntries
    }
    
    
    // *** Search Bar Actions ****
    func searchBar(searchBar: UISearchBar, textDidChange searchText: String) {
        self.searchText(searchText)
    }
    
    func searchBarShouldEndEditing(searchBar: UISearchBar) -> Bool {
        if searchBar.text?.characters.count > 0 {
            self.loadDefaultDictionary()
        }
        return true
    }
    
    func searchBarCancelButtonClicked(searchBar: UISearchBar) {
        self.searchBar.endEditing(true)
        if searchBar.text!.characters.count == 0 {
            self.loadDefaultDictionary()
        }
    }
    
    func searchBarSearchButtonClicked(searchBar: UISearchBar) {
        self.searchText(searchBar.text!)
        searchBar.endEditing(true)
    }
    
    func searchText(searchText:String) {
        self.loadDefaultDictionary()
        let filteredDictionary = self.dictionaryItems.filter { (dictionaryItem) -> Bool in
            return dictionaryItem.navi.uppercaseString.contains(searchText.uppercaseString)
                || dictionaryItem.category.uppercaseString.contains(searchText.uppercaseString)
                || dictionaryItem.english.uppercaseString.contains(searchText.uppercaseString)
        }
        dictionaryItems = filteredDictionary
        if searchText.characters.count == 0 {
            self.loadDefaultDictionary()
        }
        self.tableView.reloadData()
    }

}
