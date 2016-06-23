//
//  NDDictionaryMainViewController.swift
//  Na'vi
//
//  Created by Chuhan Qin on 2016-06-22.
//  Copyright © 2016 CQ. All rights reserved.
//

import UIKit

class NDDictionaryMainViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UISearchBarDelegate {

    @IBOutlet var tableView : UITableView!
    @IBOutlet var searchBar : UISearchBar!
    
    var defaultDictionaryEntries : [NDDictionaryEntry] = NDDictionary().defaultDictionary
    var defaultClassifiedDictionary : [[NDDictionaryEntry]] = NDDictionary().defaultClassifiedDictionary
    var dictionaryItems : [[NDDictionaryEntry]] = [[NDDictionaryEntry]]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        dictionaryItems = defaultClassifiedDictionary
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        if searchBar.text?.characters.count > 0 {
            self.searchText(searchBar.text!)
        }
    }

    
    // *** Table View Data ***
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return defaultClassifiedDictionary.count
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return defaultClassifiedDictionary[section].count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("MainDictionaryCell", forIndexPath: indexPath) as! NDDictionaryMainTableViewCell
        cell.loadData(dictionaryItems[indexPath.section][indexPath.row])
        return cell
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let storyboard = UIStoryboard(name: "Dictionary", bundle: nil)
        let definitionViewController : NDDefinitionViewController = storyboard.instantiateViewControllerWithIdentifier("NDDefinitionViewController") as! NDDefinitionViewController
        definitionViewController.entry = dictionaryItems[indexPath.section][indexPath.row]
        self.navigationController?.pushViewController(definitionViewController, animated: true)
    }
    
    func sectionIndexTitlesForTableView(tableView: UITableView) -> [String]? {
        return defaultClassifiedDictionary.map{String($0.first!.navi.characters.first!)}
    }
    
    func loadDefaultDictionary() {
        self.dictionaryItems = defaultClassifiedDictionary
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
//        let filteredDictionary = self.dictionaryItems.filter { (dictionaryItem) -> Bool in
//            return dictionaryItems[indexPath.section][indexPath.row].navi.uppercaseString.contains(searchText.uppercaseString)
//                || dictionaryItems[indexPath.section][indexPath.row].category.uppercaseString.contains(searchText.uppercaseString)
//                || dictionaryItems[indexPath.section][indexPath.row].english.uppercaseString.contains(searchText.uppercaseString)
//        }
//        dictionaryItems = filteredDictionary
//        if searchText.characters.count == 0 {
//            self.loadDefaultDictionary()
//        }
//        self.tableView.reloadData()
    }

}
