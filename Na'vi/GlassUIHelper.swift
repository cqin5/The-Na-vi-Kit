//
//  GlassUIHelper.swift
//  Na'vi
//
//  Created for iOS 18.0+ glassmorphism design
//

import UIKit

/// Glass styling levels for different UI components
enum GlassStyle {
    case ultraLight  // Search bars, modals
    case light       // Dictionary cells
    case medium      // Section headers
    case heavy       // Navigation bars
    case ultraHeavy  // Keyboard background
}

/// Centralized helper for consistent glassmorphism styling across the app
class GlassUIHelper {

    // MARK: - Blur Effects

    /// Primary blur effect based on trait collection and style
    static func primaryBlurEffect(for traitCollection: UITraitCollection, style: GlassStyle = .medium) -> UIBlurEffect {
        let blurStyle: UIBlurEffect.Style

        switch style {
        case .ultraLight:
            blurStyle = .systemUltraThinMaterial
        case .light:
            blurStyle = .systemThinMaterial
        case .medium:
            blurStyle = .systemMaterial
        case .heavy:
            blurStyle = .systemThickMaterial
        case .ultraHeavy:
            blurStyle = .systemChromeMaterial
        }

        return UIBlurEffect(style: blurStyle)
    }

    /// Secondary blur effect for layered glass effects
    static func secondaryBlurEffect(for traitCollection: UITraitCollection) -> UIBlurEffect {
        return UIBlurEffect(style: .systemThinMaterial)
    }

    /// Strong blur effect for backgrounds
    static func strongBlurEffect(for traitCollection: UITraitCollection) -> UIBlurEffect {
        return UIBlurEffect(style: .systemThickMaterial)
    }

    // MARK: - Vibrancy Effects

    /// Primary vibrancy effect for text and labels
    static func primaryVibrancy(for traitCollection: UITraitCollection, blurEffect: UIBlurEffect) -> UIVibrancyEffect {
        return UIVibrancyEffect(blurEffect: blurEffect, style: .label)
    }

    /// Secondary vibrancy effect for secondary text
    static func secondaryVibrancy(for traitCollection: UITraitCollection, blurEffect: UIBlurEffect) -> UIVibrancyEffect {
        return UIVibrancyEffect(blurEffect: blurEffect, style: .secondaryLabel)
    }

    // MARK: - Glass Background Views

    /// Creates a pre-configured glass background view
    static func createGlassBackground(frame: CGRect, style: GlassStyle, traitCollection: UITraitCollection) -> UIVisualEffectView {
        let blurEffect = primaryBlurEffect(for: traitCollection, style: style)
        let blurView = UIVisualEffectView(effect: blurEffect)
        blurView.frame = frame
        blurView.autoresizingMask = [.flexibleWidth, .flexibleHeight]

        // Add subtle tint based on style
        let tintColor = glassTint(for: traitCollection, style: style)
        blurView.backgroundColor = tintColor

        return blurView
    }

    /// Creates a glass card with blur and vibrancy
    static func createGlassCard(frame: CGRect, traitCollection: UITraitCollection) -> UIVisualEffectView {
        let blurEffect = UIBlurEffect(style: .systemMaterial)
        let blurView = UIVisualEffectView(effect: blurEffect)
        blurView.frame = frame
        blurView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        blurView.layer.cornerRadius = 12
        blurView.clipsToBounds = true

        // Add subtle tint
        blurView.backgroundColor = glassTint(for: traitCollection, style: .light)

        return blurView
    }

    // MARK: - Glass Colors

    /// Glass tint color based on trait collection and style
    static func glassTint(for traitCollection: UITraitCollection, style: GlassStyle = .medium) -> UIColor {
        let isDark = traitCollection.userInterfaceStyle == .dark

        switch style {
        case .ultraLight:
            return isDark ?
                UIColor.systemBlue.withAlphaComponent(0.02) :
                UIColor.systemBlue.withAlphaComponent(0.01)
        case .light:
            return isDark ?
                UIColor.systemBlue.withAlphaComponent(0.05) :
                UIColor.systemBlue.withAlphaComponent(0.02)
        case .medium:
            return isDark ?
                UIColor.systemBlue.withAlphaComponent(0.08) :
                UIColor.systemBlue.withAlphaComponent(0.03)
        case .heavy:
            return isDark ?
                UIColor.systemBlue.withAlphaComponent(0.12) :
                UIColor.systemBlue.withAlphaComponent(0.05)
        case .ultraHeavy:
            return isDark ?
                UIColor.black.withAlphaComponent(0.2) :
                UIColor.white.withAlphaComponent(0.3)
        }
    }

    /// Glass accent color for highlights
    static func glassAccent(for traitCollection: UITraitCollection) -> UIColor {
        let isDark = traitCollection.userInterfaceStyle == .dark
        return isDark ?
            UIColor.systemBlue.withAlphaComponent(0.6) :
            UIColor.systemBlue.withAlphaComponent(0.8)
    }

    /// Glass text colors with appropriate alpha for readability
    static func glassPrimaryTextColor(for traitCollection: UITraitCollection) -> UIColor {
        let isDark = traitCollection.userInterfaceStyle == .dark
        return isDark ?
            UIColor.white.withAlphaComponent(0.95) :
            UIColor.black.withAlphaComponent(0.9)
    }

    static func glassSecondaryTextColor(for traitCollection: UITraitCollection) -> UIColor {
        let isDark = traitCollection.userInterfaceStyle == .dark
        return isDark ?
            UIColor.white.withAlphaComponent(0.7) :
            UIColor.black.withAlphaComponent(0.6)
    }

    static func glassTertiaryTextColor(for traitCollection: UITraitCollection) -> UIColor {
        let isDark = traitCollection.userInterfaceStyle == .dark
        return isDark ?
            UIColor.white.withAlphaComponent(0.85) :
            UIColor.black.withAlphaComponent(0.75)
    }

    // MARK: - Apply Glass Effect

    /// Applies glass effect to an existing view
    static func applyGlassEffect(to view: UIView, style: GlassStyle, traitCollection: UITraitCollection, animated: Bool = false) {
        let blurEffect = primaryBlurEffect(for: traitCollection, style: style)
        let blurView = UIVisualEffectView(effect: blurEffect)
        blurView.frame = view.bounds
        blurView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        blurView.alpha = animated ? 0 : 1

        // Add tint
        blurView.backgroundColor = glassTint(for: traitCollection, style: style)

        view.insertSubview(blurView, at: 0)

        if animated {
            UIView.animate(withDuration: 0.3) {
                blurView.alpha = 1
            }
        }
    }

    // MARK: - Navigation Bar Appearance

    /// Creates a glass navigation bar appearance
    static func createGlassNavigationAppearance(for traitCollection: UITraitCollection) -> UINavigationBarAppearance {
        let appearance = UINavigationBarAppearance()
        appearance.configureWithTransparentBackground()

        // Apply blur effect
        let blurEffect = UIBlurEffect(style: .systemUltraThinMaterial)
        appearance.backgroundEffect = blurEffect

        // Adjust colors for glass effect
        appearance.titleTextAttributes = [
            .foregroundColor: glassPrimaryTextColor(for: traitCollection)
        ]
        appearance.largeTitleTextAttributes = [
            .foregroundColor: glassPrimaryTextColor(for: traitCollection)
        ]

        return appearance
    }

    // MARK: - Gradient Backgrounds

    /// Creates a gradient background layer for glass to work against
    static func createGradientBackground(for bounds: CGRect, traitCollection: UITraitCollection) -> CAGradientLayer {
        let gradientLayer = CAGradientLayer()
        let isDark = traitCollection.userInterfaceStyle == .dark

        gradientLayer.colors = isDark ?
            [UIColor.systemBlue.withAlphaComponent(0.3).cgColor,
             UIColor.systemPurple.withAlphaComponent(0.3).cgColor] :
            [UIColor.systemBlue.withAlphaComponent(0.1).cgColor,
             UIColor.systemPurple.withAlphaComponent(0.1).cgColor]

        gradientLayer.locations = [0.0, 1.0]
        gradientLayer.startPoint = CGPoint(x: 0.5, y: 0.0)
        gradientLayer.endPoint = CGPoint(x: 0.5, y: 1.0)
        gradientLayer.frame = bounds

        return gradientLayer
    }

}
