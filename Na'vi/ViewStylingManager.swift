//
//  ViewStylingManager.swift
//  Na'vi
//
//  Keeps appearance work out of the view controllers.
//

import UIKit

/// Applies the app's shared appearance to a view controller's subviews.
///
/// The app leans on the system appearance rather than re-creating it: navigation
/// bars, table views and search fields take on Liquid Glass by themselves once the
/// app is built against the iOS 26 SDK or later, and semantic colours track Dark
/// Mode, Increase Contrast and Reduce Transparency without any help. What remains
/// here is the one surface the app styles deliberately — the search field that
/// floats above the dictionary list.
@MainActor
final class ViewStylingManager {

    private weak var viewController: UIViewController?
    private weak var searchFieldGlass: UIVisualEffectView?

    init(viewController: UIViewController) {
        self.viewController = viewController
    }

    // MARK: - Dictionary list

    /// Prepares the dictionary list: system background, transparent table so the
    /// background reads through, and a floating glass search field.
    func setupDictionaryGlassUI(tableView: UITableView, searchBar: UISearchBar) {
        viewController?.view.backgroundColor = .systemBackground

        tableView.backgroundColor = .clear
        tableView.backgroundView = nil
        tableView.sectionHeaderTopPadding = 0

        applyFloatingGlass(to: searchBar)
    }

    // MARK: - Definition

    /// Prepares the definition screen.
    func setupDefinitionGlassUI(textView: UITextView) {
        viewController?.view.backgroundColor = .systemBackground

        textView.backgroundColor = .clear
        textView.textColor = .label
    }

    // MARK: - Layout

    /// Keeps glass surfaces matched to their current bounds. Call from
    /// `viewDidLayoutSubviews`.
    func updateLayout() {
        guard let glass = searchFieldGlass else { return }
        GlassUIHelper.updateCornerRadius(of: glass)
    }

    // MARK: - Search field

    private func applyFloatingGlass(to searchBar: UISearchBar) {
        // Clear the search bar's own chrome so the glass behind it is what shows.
        searchBar.backgroundImage = UIImage()
        searchBar.backgroundColor = .clear
        searchBar.searchTextField.backgroundColor = .clear

        guard searchFieldGlass == nil else { return }

        let glass = GlassUIHelper.glassView(.floating, isInteractive: true)
        glass.frame = searchBar.bounds
        glass.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        searchBar.insertSubview(glass, at: 0)
        searchFieldGlass = glass
    }
}
