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
    
    var defaultClassifiedDictionary : [[NDDictionaryEntry]] = NDDictionary().defaultClassifiedDictionary
    var dictionaryItems : [[NDDictionaryEntry]] = [[NDDictionaryEntry]]()
    var sectionTitles : [String] = [String]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        dictionaryItems = defaultClassifiedDictionary
        sectionTitles = NDDictionary.sectionIndices(withDictionary: dictionaryItems)
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        if searchBar.text?.characters.count > 0 {
            self.searchText(searchBar.text!)
        }
    }
    
    // *** Dictionary Data ***
    func updateSectionTitles() {
        sectionTitles = NDDictionary.sectionIndices(withDictionary: dictionaryItems)
    }
    
    func loadDefaultDictionary() {
        self.dictionaryItems = defaultClassifiedDictionary
    }
    
    func updateDictionaryData() {
        updateSectionTitles()
        self.tableView.reloadData()
    }
    
    // *** Table View Data ***
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return dictionaryItems.count
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dictionaryItems[section].count
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
    
    func tableView(tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let headerView : NDDictionarySectionTableViewCell = tableView.dequeueReusableCellWithIdentifier("NDDictionarySectionTableViewCell") as! NDDictionarySectionTableViewCell
        headerView.updateSectionTitle(sectionTitles[section])
        return headerView
    }
    
    func sectionIndexTitlesForTableView(tableView: UITableView) -> [String]? {
        return sectionTitles
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

        for (i,_) in self.dictionaryItems.enumerate() {
            self.dictionaryItems[i] = self.dictionaryItems[i].filter { (dictionaryItem) -> Bool in
                return dictionaryItem.navi.uppercaseString.contains(searchText.uppercaseString)
                    || dictionaryItem.english.uppercaseString.contains(searchText.uppercaseString)
            }
        }
        self.dictionaryItems = self.dictionaryItems.filter{$0.count > 0}
        
        if searchText.characters.count == 0 {
            self.loadDefaultDictionary()
        }
        updateDictionaryData()
    }

}
