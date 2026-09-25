//
//  GlassUIHelper.swift
//  Na'vi
//
//  Liquid Glass styling for the surfaces the app draws itself.
//

import UIKit

/// Builds the system Liquid Glass material for the app's custom views.
///
/// Standard UIKit controls — navigation bars, search bars, tab bars, table views —
/// adopt Liquid Glass on their own once the app is built against the iOS 26 SDK or
/// later, so this helper is deliberately small. It covers only the surfaces the app
/// draws itself, and on releases earlier than iOS 26 it falls back to the closest
/// system material so one view hierarchy serves the whole deployment range.
@MainActor
enum GlassUIHelper {

    /// How prominent a glass surface should be against the content behind it.
    enum Prominence {
        /// A control that floats above scrolling content, such as the search field.
        case floating
        /// A surface that recedes behind its own content, such as a section header.
        case recessed
    }

    // MARK: - Effects

    /// The system glass effect for a surface of the given prominence.
    ///
    /// - Parameters:
    ///   - prominence: How strongly the surface should read against its backdrop.
    ///     On iOS 26 and later the system decides this from context, so the value
    ///     only selects the pre-iOS 26 fallback material.
    ///   - tint: An optional colour blended into the glass.
    ///   - isInteractive: Whether the glass should respond to touches by scaling
    ///     and reflecting light. Ignored before iOS 26.
    static func effect(
        _ prominence: Prominence,
        tint: UIColor? = nil,
        isInteractive: Bool = false
    ) -> UIVisualEffect {
        if #available(iOS 26.0, *) {
            let glass = UIGlassEffect()
            glass.tintColor = tint
            glass.isInteractive = isInteractive
            return glass
        }

        switch prominence {
        case .floating:
            return UIBlurEffect(style: .systemThinMaterial)
        case .recessed:
            return UIBlurEffect(style: .systemUltraThinMaterial)
        }
    }

    // MARK: - Views

    /// A visual effect view configured as a glass surface.
    ///
    /// Pass a `cornerRadius` of `0` to leave the view square; use
    /// ``updateCornerRadius(of:)`` from a layout pass to keep a capsule shape as
    /// the view resizes.
    static func glassView(
        _ prominence: Prominence,
        cornerRadius: CGFloat = 0,
        tint: UIColor? = nil,
        isInteractive: Bool = false
    ) -> UIVisualEffectView {
        let view = UIVisualEffectView(
            effect: effect(prominence, tint: tint, isInteractive: isInteractive)
        )
        view.clipsToBounds = true
        view.layer.cornerCurve = .continuous
        view.layer.cornerRadius = cornerRadius
        return view
    }

    /// Rounds a glass surface to a capsule, capped so wide surfaces stay rectangular
    /// enough to read as a bar rather than a pill.
    static func updateCornerRadius(of view: UIView, maximum: CGFloat = 28) {
        view.layer.cornerRadius = min(view.bounds.height / 2, maximum)
    }
}
