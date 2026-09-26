//
//  KeyboardKeyBackground.swift
//  TransliteratingKeyboard
//
//  Created by Alexei Baboulevitch on 7/19/14.
//  Copyright (c) 2014 Alexei Baboulevitch ("Archagon"). All rights reserved.
//

import UIKit

/// The outlines a key fills: the key alone, or the key joined to its popup.
///
/// Both follow the iOS 26 system keyboard. Corners use the continuous curve that
/// `UIBezierPath(roundedRect:cornerRadius:)` draws, and the popup narrows into its
/// key through two S-curves rather than meeting it at a corner.
enum KeyboardKeyBackground {

    /// How far down the key's sides the popup's neck ends, as on the system keyboard.
    static let neckDepth: CGFloat = 5

    static func path(forKey key: CGRect, cornerRadius: CGFloat) -> CGPath {
        return UIBezierPath(roundedRect: key, cornerRadius: cornerRadius).cgPath
    }

    /// - Parameters:
    ///   - key: The key's bounds.
    ///   - popup: The popup's frame in the key's coordinates. It lies above the
    ///     key, but near the top of the keyboard it may reach down over the key.
    static func path(forKey key: CGRect, cornerRadius: CGFloat, popup: CGRect, popupCornerRadius: CGFloat) -> CGPath {
        let keyPath = self.path(forKey: key, cornerRadius: cornerRadius)

        // The popup's top corners are rounded. Its bottom corners are squared off,
        // because the neck below carries its sides on down to the key.
        let radius = min(popupCornerRadius, popup.height / 2, popup.width / 2)
        let roundedBody = UIBezierPath(roundedRect: popup, cornerRadius: radius).cgPath
        let squareBottom = CGPath(rect: CGRect(x: popup.minX, y: popup.maxY - radius, width: popup.width, height: radius), transform: nil)
        let body = roundedBody.union(squareBottom)

        let neckTop = popup.maxY
        let neckBottom = min(max(key.minY + self.neckDepth, neckTop + 2), key.maxY - cornerRadius)
        if neckBottom <= neckTop {
            return body.union(keyPath)
        }

        // Each side of the neck leaves the popup and meets the key vertically.
        let middle = (neckTop + neckBottom) / 2
        let neck = CGMutablePath()
        neck.move(to: CGPoint(x: popup.minX, y: neckTop - 1))
        neck.addLine(to: CGPoint(x: popup.minX, y: neckTop))
        neck.addCurve(to: CGPoint(x: key.minX, y: neckBottom),
                      control1: CGPoint(x: popup.minX, y: middle),
                      control2: CGPoint(x: key.minX, y: middle))
        neck.addLine(to: CGPoint(x: key.maxX, y: neckBottom))
        neck.addCurve(to: CGPoint(x: popup.maxX, y: neckTop),
                      control1: CGPoint(x: key.maxX, y: middle),
                      control2: CGPoint(x: popup.maxX, y: middle))
        neck.addLine(to: CGPoint(x: popup.maxX, y: neckTop - 1))
        neck.closeSubpath()

        return body.union(neck).union(keyPath)
    }
}
