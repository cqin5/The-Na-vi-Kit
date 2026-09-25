//
//  NDDictionaryMainViewController.swift
//  Na'vi
//
//  Created by Chuhan Qin on 2016-06-22.
//  Copyright © 2016 CQ. All rights reserved.
//

import UIKit

final class NDDictionaryMainViewController: UIViewController {

    @IBOutlet private var tableView: UITableView!
    @IBOutlet private var searchBar: UISearchBar!

    /// The storyboard's constraint from the search bar to the bottom layout guide.
    /// It is replaced at load time by one to the keyboard layout guide.
    @IBOutlet private weak var searchBarBottomConstraint: NSLayoutConstraint!

    private let minimumRowHeight: CGFloat = 150

    /// Every entry, grouped by first letter. The search results are filtered from this.
    private let allSections: [[NDDictionaryEntry]] = NDDictionary().classifiedEntries

    /// The sections currently on screen.
    private var sections: [[NDDictionaryEntry]] = []
    private var sectionTitles: [String] = []

    private lazy var stylingManager = ViewStylingManager(viewController: self)

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

        // The keyboard layout guide sits on the safe area when no keyboard is
        // showing and on top of the keyboard when one is, animating with it. It
        // accounts for the home indicator, floating and hardware keyboards, and
        // resizable windows, none of which a fixed offset can.
        searchBarBottomConstraint?.isActive = false
        searchBar.bottomAnchor.constraint(equalTo: view.keyboardLayoutGuide.topAnchor).isActive = true

        sections = allSections
        sectionTitles = NDDictionary.sectionIndices(ofDictionary: sections)

        stylingManager.setupDictionaryGlassUI(tableView: tableView, searchBar: searchBar)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        if let searchText = searchBar.text, !searchText.isEmpty {
            self.searchText(searchText)
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        stylingManager.updateLayout()
    }

    // MARK: - Data

    private func reloadSections() {
        sectionTitles = NDDictionary.sectionIndices(ofDictionary: sections)

        tableView.reloadData()

        if tableView.numberOfSections > 0, tableView.numberOfRows(inSection: 0) > 0 {
            tableView.scrollToRow(at: IndexPath(row: 0, section: 0), at: .top, animated: true)
        }
    }

    private func searchText(_ searchText: String) {
        guard !searchText.isEmpty else {
            sections = allSections
            reloadSections()
            return
        }

        sections = allSections.compactMap { section in
            let matches = section.filter {
                $0.navi.localizedCaseInsensitiveContains(searchText)
                    || $0.english.localizedCaseInsensitiveContains(searchText)
            }
            return matches.isEmpty ? nil : matches
        }

        reloadSections()
    }
}

// MARK: - UITableViewDataSource

extension NDDictionaryMainViewController: UITableViewDataSource {

    func numberOfSections(in tableView: UITableView) -> Int {
        sections.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        sections[section].count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(
            withIdentifier: "MainDictionaryCell",
            for: indexPath
        ) as! NDDictionaryMainTableViewCell

        guard indexPath.section < sections.count,
              indexPath.row < sections[indexPath.section].count else {
            return cell
        }

        let isSearching = !(searchBar.text?.isEmpty ?? true)
        cell.loadData(sections[indexPath.section][indexPath.row], isSearchResult: isSearching)
        return cell
    }

    func sectionIndexTitles(for tableView: UITableView) -> [String]? {
        sectionTitles
    }
}

// MARK: - UITableViewDelegate

extension NDDictionaryMainViewController: UITableViewDelegate {

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        UITableView.automaticDimension
    }

    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        minimumRowHeight
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // Entries are read in place; the row is only a container.
        tableView.deselectRow(at: indexPath, animated: true)
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard let headerView = tableView.dequeueReusableCell(
            withIdentifier: "NDDictionarySectionTableViewCell"
        ) as? NDDictionarySectionTableViewCell else {
            return nil
        }

        headerView.updateSectionTitle(sectionTitles[section])
        return headerView
    }
}

// MARK: - UISearchBarDelegate

extension NDDictionaryMainViewController: UISearchBarDelegate {

    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        self.searchText(searchText)
    }

    func searchBarShouldEndEditing(_ searchBar: UISearchBar) -> Bool {
        true
    }

    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchBar.endEditing(true)

        if searchBar.text?.isEmpty ?? true {
            sections = allSections
            reloadSections()
        }
    }

    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        if let searchText = searchBar.text {
            self.searchText(searchText)
        }
        searchBar.endEditing(true)
    }
}
