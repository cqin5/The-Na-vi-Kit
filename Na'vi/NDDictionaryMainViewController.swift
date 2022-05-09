//
//  NDDictionaryMainViewController.swift
//  Na'vi
//
//  Created by Chuhan Qin on 2016-06-22.
//  Copyright © 2016 CQ. All rights reserved.
//

import UIKit
// FIXME: comparison operators with optionals were removed from the Swift Standard Libary.
// Consider refactoring the code to use the non-optional operators.
fileprivate func < <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l < r
  case (nil, _?):
    return true
  default:
    return false
  }
}

// FIXME: comparison operators with optionals were removed from the Swift Standard Libary.
// Consider refactoring the code to use the non-optional operators.
fileprivate func > <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l > r
  default:
    return rhs < lhs
  }
}


class NDDictionaryMainViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UISearchBarDelegate {

    @IBOutlet var tableView: UITableView!
    @IBOutlet var searchBar: UISearchBar!
    
    @IBOutlet weak var searchBarBottomConstraint: NSLayoutConstraint!
    
    var defaultClassifiedDictionary: [[NDDictionaryEntry]] = NDDictionary().defaultClassifiedDictionary
    var dictionaryItems: [[NDDictionaryEntry]] = [[NDDictionaryEntry]]()
    var sectionTitles: [String] = [String]()
    var categories: [String] = [String]()
    
    let minimumRowHeight = CGFloat(140)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(_:)), name: UIWindow.keyboardWillShowNotification, object: nil)

        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(_:)), name: UIWindow.keyboardWillHideNotification, object: nil)

        dictionaryItems = defaultClassifiedDictionary
        sectionTitles = NDDictionary.sectionIndices(ofDictionary: dictionaryItems)
        categories = NDDictionary.categories(ofDictionary: dictionaryItems)
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if searchBar.text?.count > 0 {
            self.searchText(searchBar.text!)
        }
        setColoursToInterfaceStyle()
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        setColoursToInterfaceStyle()
    }
    
    func setColoursToInterfaceStyle() {
        view.backgroundColor        = traitCollection.userInterfaceStyle == .dark ? UIColor(hex: "#000000", alpha: 1.0) : UIColor(hex: "#ffffff", alpha: 1.0)
        tableView.backgroundColor   = traitCollection.userInterfaceStyle == .dark ? UIColor(hex: "#000000", alpha: 1.0) : UIColor(hex: "#ffffff", alpha: 1.0)
    }

    
    // *** Dictionary Data ***
    func loadDefaultDictionary() {
        self.dictionaryItems = defaultClassifiedDictionary
    }
    
    func updateDictionaryData() {
        sectionTitles = NDDictionary.sectionIndices(ofDictionary: dictionaryItems)
        categories = NDDictionary.categories(ofDictionary: dictionaryItems)
        
        self.tableView.reloadData()
        if self.tableView.numberOfSections != 0 {
            self.tableView.scrollToRow(at: IndexPath(row: 0, section: 0), at: UITableView.ScrollPosition.top, animated: true)
        }
    }
    
    // *** Table View Data ***
    func numberOfSections(in tableView: UITableView) -> Int {
        return dictionaryItems.count
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
        
    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return minimumRowHeight
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dictionaryItems[section].count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "MainDictionaryCell", for: indexPath) as! NDDictionaryMainTableViewCell
        cell.loadData(dictionaryItems[indexPath.section][indexPath.row])
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        return
//        let storyboard = UIStoryboard(name: "Dictionary", bundle: nil)
//        let definitionViewController : NDDefinitionViewController = storyboard.instantiateViewController(withIdentifier: "NDDefinitionViewController") as! NDDefinitionViewController
//        definitionViewController.entry = dictionaryItems[indexPath.section][indexPath.row]
//        self.navigationController?.pushViewController(definitionViewController, animated: true)
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let headerView : NDDictionarySectionTableViewCell = tableView.dequeueReusableCell(withIdentifier: "NDDictionarySectionTableViewCell") as! NDDictionarySectionTableViewCell
        headerView.updateSectionTitle(sectionTitles[section])
        return headerView
    }
    
    func sectionIndexTitles(for tableView: UITableView) -> [String]? {
        return sectionTitles
    }
    
    // *** Search Bar Actions ****
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        self.searchText(searchText)
    }
    
    func searchBarShouldEndEditing(_ searchBar: UISearchBar) -> Bool {
        if searchBar.text?.count > 0 {
            self.loadDefaultDictionary()
        }
        return true
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        self.searchBar.endEditing(true)
        if searchBar.text!.count == 0 {
            self.loadDefaultDictionary()
        }
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        self.searchText(searchBar.text!)
        searchBar.endEditing(true)
    }
    
    func searchText(_ searchText:String) {
        self.loadDefaultDictionary()

        for (i,_) in self.dictionaryItems.enumerated() {
            self.dictionaryItems[i] = self.dictionaryItems[i].filter { (dictionaryItem) -> Bool in
                return dictionaryItem.navi.uppercased().contains(searchText.uppercased())
                    || dictionaryItem.english.uppercased().contains(searchText.uppercased())
            }
        }
        self.dictionaryItems = self.dictionaryItems.filter{$0.count > 0}
        
        if searchText.count == 0 {
            self.loadDefaultDictionary()
        }
        updateDictionaryData()
    }

    @objc func keyboardWillShow(_ notification: NSNotification) {
        
        if let keyboardFrame: NSValue = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue {
                let keyboardRectangle = keyboardFrame.cgRectValue
                let keyboardHeight = keyboardRectangle.height
            
                animateWithKeyboard(notification: notification) { keyboardFrame in
                    self.searchBarBottomConstraint.constant = keyboardHeight - 40
                }
            }
        
        
        
    }
    
    @objc func keyboardWillHide(_ notification: NSNotification) {
        
        animateWithKeyboard(notification: notification) { keyboardFrame in
            self.searchBarBottomConstraint.constant = 0
        }
        
    }
    
}

