//
//  NDDictionaryMainViewController.swift
//  Na'vi
//
//  Created by Chuhan Qin on 2016-06-22.
//  Copyright © 2016 CQ. All rights reserved.
//

import UIKit

class NDDictionaryMainViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UISearchBarDelegate {

    @IBOutlet private var tableView: UITableView!
    @IBOutlet private var searchBar: UISearchBar!
    @IBOutlet private weak var searchBarBottomConstraint: NSLayoutConstraint!

    var defaultClassifiedDictionary: [[NDDictionaryEntry]] = NDDictionary().defaultClassifiedDictionary
    var dictionaryItems: [[NDDictionaryEntry]] = [[NDDictionaryEntry]]()
    var sectionTitles: [String] = [String]()
    var categories: [String] = [String]()

    let minimumRowHeight = CGFloat(150)

    var bookmarkedItems: [[NDDictionaryEntry]] = [[NDDictionaryEntry]]()

    // Styling manager to reduce view controller responsibilities
    private lazy var stylingManager = ViewStylingManager(viewController: self)

    override func viewDidLoad() {
        super.viewDidLoad()

        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(_:)), name: UIWindow.keyboardWillShowNotification, object: nil)

        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(_:)), name: UIWindow.keyboardWillHideNotification, object: nil)

        dictionaryItems = defaultClassifiedDictionary
        sectionTitles = NDDictionary.sectionIndices(ofDictionary: dictionaryItems)
//        categories = NDDictionary.categories(ofDictionary: dictionaryItems)

        // Setup glass UI via styling manager
        stylingManager.setupDictionaryGlassUI(
            tableView: tableView,
            searchBar: searchBar,
            navigationController: navigationController
        )
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if let searchText = searchBar.text, !searchText.isEmpty {
            self.searchText(searchText)
        }
        
        setColoursToInterfaceStyle()
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        setColoursToInterfaceStyle()
    }
    
    func setColoursToInterfaceStyle() {
        // Update gradient colors via styling manager
        stylingManager.updateGradientColors(for: traitCollection)

        // Table view should be clear to show gradient
        tableView.backgroundColor = .clear
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        // Update gradient frame via styling manager
        stylingManager.updateGradientFrame(view.bounds)
    }

    deinit {
        stylingManager.cleanup()
    }

    
    // *** Dictionary Data ***
    func loadDefaultDictionary() {
        self.dictionaryItems = defaultClassifiedDictionary
    }
    
    func updateDictionaryData() {
        sectionTitles = NDDictionary.sectionIndices(ofDictionary: dictionaryItems)
//        categories = NDDictionary.categories(ofDictionary: dictionaryItems)
        
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
        
        guard indexPath.section < dictionaryItems.count,
              indexPath.row < dictionaryItems[indexPath.section].count else {
            // In case of an invalid indexPath, return an empty cell
            return cell
        }
        
        let isSearching = !(searchBar.text?.isEmpty ?? true)
        cell.loadData(dictionaryItems[indexPath.section][indexPath.row], isSearchResult: isSearching)
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
        if let searchText = searchBar.text, !searchText.isEmpty {
            self.loadDefaultDictionary()
        }
        return true
    }

    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        self.searchBar.endEditing(true)
        
        if let searchText = searchBar.text, searchText.isEmpty {
            self.loadDefaultDictionary()
        }
    }

    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        if let searchText = searchBar.text {
            self.searchText(searchText)
        }
        
        searchBar.endEditing(true)
    }

    func searchText(_ searchText: String) {
        // If the search text is empty, load the default dictionary and return
        if searchText.isEmpty {
            self.dictionaryItems = defaultClassifiedDictionary
            updateDictionaryData()
            return
        }
        
        // Filter the default dictionary based on the search text
        var filteredDictionaryItems: [[NDDictionaryEntry]] = []
        for section in defaultClassifiedDictionary {
            let filteredSection = section.filter { dictionaryItem in
                dictionaryItem.navi.uppercased().contains(searchText.uppercased()) ||
                dictionaryItem.english.uppercased().contains(searchText.uppercased())
            }
            if !filteredSection.isEmpty {
                filteredDictionaryItems.append(filteredSection)
            }
        }
        
        // Update dictionaryItems with the filtered results and update the UI
        self.dictionaryItems = filteredDictionaryItems
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

