//
//  ViewStylingManager.swift
//  Na'vi
//
//  Created for iOS 18.0+ glassmorphism design
//  Manages view styling to reduce view controller responsibilities
//

import UIKit

/// Manages glass UI styling for view controllers, reducing their responsibilities
class ViewStylingManager {

    private weak var viewController: UIViewController?
    private var gradientLayer: CAGradientLayer?

    init(viewController: UIViewController) {
        self.viewController = viewController
    }

    // MARK: - Dictionary View Styling

    /// Applies complete glass UI setup to dictionary main view controller
    func setupDictionaryGlassUI(
        tableView: UITableView,
        searchBar: UISearchBar,
        navigationController: UINavigationController?
    ) {
        guard let viewController = viewController else { return }

        // Add gradient background
        setupGradientBackground(for: viewController.view)

        // Clear table view background to show gradient
        tableView.backgroundColor = .clear

        // Apply glass effect to navigation bar
        setupGlassNavigationBar(navigationController)

        // Apply glass styling to search bar
        setupGlassSearchBar(searchBar)
    }

    /// Applies glass UI setup to definition view controller
    func setupDefinitionGlassUI(textView: UITextView) {
        guard let viewController = viewController else { return }

        // Add gradient background
        setupGradientBackground(for: viewController.view)

        // Apply glass blur to entire view
        let blurEffect = UIBlurEffect(style: .systemMaterial)
        let blurView = UIVisualEffectView(effect: blurEffect)
        blurView.frame = viewController.view.bounds
        blurView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        viewController.view.insertSubview(blurView, at: 0)

        // Update text view for glass background
        textView.backgroundColor = .clear
        textView.textColor = GlassUIHelper.glassPrimaryTextColor(for: viewController.traitCollection)
    }

    // MARK: - Individual Components

    private func setupGradientBackground(for view: UIView) {
        guard let viewController = viewController else { return }

        let gradient = GlassUIHelper.createGradientBackground(
            for: view.bounds,
            traitCollection: viewController.traitCollection
        )
        gradientLayer = gradient
        view.layer.insertSublayer(gradient, at: 0)
    }

    private func setupGlassNavigationBar(_ navigationController: UINavigationController?) {
        guard let viewController = viewController,
              let navigationBar = navigationController?.navigationBar else { return }

        let appearance = GlassUIHelper.createGlassNavigationAppearance(
            for: viewController.traitCollection
        )
        navigationBar.standardAppearance = appearance
        navigationBar.scrollEdgeAppearance = appearance
        navigationBar.compactAppearance = appearance
    }

    private func setupGlassSearchBar(_ searchBar: UISearchBar) {
        // Remove default background
        searchBar.backgroundImage = UIImage()
        searchBar.backgroundColor = .clear

        // Apply glass blur to search bar
        let blurEffect = UIBlurEffect(style: .systemThinMaterial)
        let blurView = UIVisualEffectView(effect: blurEffect)
        blurView.frame = searchBar.bounds
        blurView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        searchBar.insertSubview(blurView, at: 0)

        // Style search text field
        if let textField = searchBar.searchTextField as UITextField? {
            textField.backgroundColor = UIColor.systemGray6.withAlphaComponent(0.5)
        }
    }

    // MARK: - Trait Collection Updates

    /// Updates gradient colors when trait collection changes
    func updateGradientColors(for traitCollection: UITraitCollection) {
        guard let gradient = gradientLayer else { return }

        let isDark = traitCollection.userInterfaceStyle == .dark
        gradient.colors = isDark ?
            [UIColor.systemBlue.withAlphaComponent(0.3).cgColor,
             UIColor.systemPurple.withAlphaComponent(0.3).cgColor] :
            [UIColor.systemBlue.withAlphaComponent(0.1).cgColor,
             UIColor.systemPurple.withAlphaComponent(0.1).cgColor]
    }

    /// Updates gradient frame when view bounds change
    func updateGradientFrame(_ bounds: CGRect) {
        gradientLayer?.frame = bounds
    }

    // MARK: - Cleanup

    func cleanup() {
        gradientLayer?.removeFromSuperlayer()
        gradientLayer = nil
        viewController = nil
    }
}
