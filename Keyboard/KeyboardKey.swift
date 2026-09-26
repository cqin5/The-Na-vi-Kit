//
//  KeyboardKey.swift
//  TransliteratingKeyboard
//
//  Created by Alexei Baboulevitch on 6/9/14.
//  Copyright (c) 2014 Alexei Baboulevitch ("Archagon"). All rights reserved.
//

import UIKit

// popup constraints have to be setup with the topmost view in mind; hence these callbacks
protocol KeyboardKeyProtocol: AnyObject {
    func frameForPopup(_ key: KeyboardKey) -> CGRect
    func willShowPopup(_ key: KeyboardKey)
    func willHidePopup(_ key: KeyboardKey)
}

/// How a key sets the text on its cap.
enum KeyCapStyle: Equatable {
    /// A letter. As on the system keyboard, lowercase letters are drawn larger
    /// than capitals, and both sit on the same baseline.
    case letter
    /// A digit or punctuation mark, on the letters' baseline.
    case character
    /// A word or symbol label such as "123", centred, in the given point size.
    case label(CGFloat)
}

class KeyboardKey: UIControl {

    /// The height of a key on the iOS 26 system keyboard in portrait. The type
    /// sizes below are measured at this height and scale down with shorter keys.
    static let referenceHeight: CGFloat = 43

    weak var delegate: KeyboardKeyProtocol?

    var text: String = "" {
        didSet {
            if text != oldValue {
                self.updateLabelText()
            }
        }
    }

    var capStyle: KeyCapStyle = .character {
        didSet {
            if capStyle != oldValue {
                self.updateLabelText()
            }
        }
    }

    var color: UIColor = UIColor.white { didSet { updateColors() }}
    var textColor: UIColor = UIColor.black { didSet { updateColors() }}
    var downColor: UIColor? { didSet { updateColors() }}
    var downTextColor: UIColor? { didSet { updateColors() }}
    var popupColor: UIColor = UIColor.white { didSet { updateColors() }}

    var cornerRadius: CGFloat = 8 { didSet { refreshShape() }}
    var popupCornerRadius: CGFloat = 13 { didSet { refreshShape() }}

    var labelInset: CGFloat = 0 {
        didSet {
            if oldValue != labelInset {
                self.layoutLabel()
            }
        }
    }

    var shouldRasterize: Bool = false {
        didSet {
            let scale = self.traitCollection.displayScale > 0 ? self.traitCollection.displayScale : 1
            self.displayView.layer.shouldRasterize = shouldRasterize
            self.displayView.layer.rasterizationScale = scale
        }
    }

    override var isEnabled: Bool { didSet { updateColors() }}
    override var isSelected: Bool { didSet { updateColors() }}
    override var isHighlighted: Bool { didSet { updateColors() }}

    let label: UILabel
    var popupLabel: UILabel?

    /// The enlarged key shown above a pressed key. It holds only the label: the
    /// popup's fill is drawn together with the key as one shape.
    var popup: UIView?

    /// Draws the key, or the key and its popup as one continuous shape.
    let displayView: ShapeView

    /// The text colour for the key's current state.
    var currentTextColor: UIColor {
        if self.isHighlighted || self.isSelected, let downTextColor = self.downTextColor {
            return downTextColor
        }
        return self.textColor
    }

    private var laidOutHeight: CGFloat = 0

    init() {
        self.displayView = ShapeView()
        self.label = UILabel()

        super.init(frame: CGRect.zero)

        self.displayView.isUserInteractionEnabled = false
        self.addSubview(self.displayView)

        self.label.textAlignment = NSTextAlignment.center
        self.label.baselineAdjustment = UIBaselineAdjustment.alignCenters
        self.label.adjustsFontSizeToFitWidth = true
        self.label.minimumScaleFactor = CGFloat(0.1)
        self.label.isUserInteractionEnabled = false
        self.label.numberOfLines = 1
        self.addSubview(self.label)

        self.updateColors()
    }

    required init?(coder: NSCoder) {
        fatalError("NSCoding not supported")
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        if self.bounds.width == 0 || self.bounds.height == 0 {
            return
        }

        CATransaction.begin()
        CATransaction.setDisableActions(true)

        self.displayView.frame = self.bounds

        // The type sizes depend on the key's height.
        if self.bounds.height != self.laidOutHeight {
            self.laidOutHeight = self.bounds.height
            self.updateLabelText()
        }
        else {
            self.layoutLabel()
        }

        self.refreshShape()

        CATransaction.commit()
    }

    //////////////
    // KEY CAPS //
    //////////////

    /// The factor by which type shrinks on keys shorter than the reference height.
    var typeScale: CGFloat {
        let height = self.bounds.height > 0 ? self.bounds.height : KeyboardKey.referenceHeight
        return max(0.75, min(1, height / KeyboardKey.referenceHeight))
    }

    /// Builds the key cap's text at the given scale of the key's own type size.
    func capText(scale: CGFloat) -> NSAttributedString {
        let font = { (size: CGFloat) in UIFont.systemFont(ofSize: size * scale) }
        let colour = self.currentTextColor

        switch self.capStyle {
        case .label(let size):
            return NSAttributedStringMake(string: self.text, font: font(size), colour: colour)
        case .character:
            return NSAttributedStringMake(string: self.text, font: font(22), colour: colour)
        case .letter:
            let isLowercase = (self.text == self.text.lowercased() && self.text != self.text.uppercased())
            // Na'vi digraphs (kx, ng, ts...) get a smaller size so both letters
            // fit comfortably on one key.
            let isDigraph = self.text.count > 1

            if isLowercase {
                return NSAttributedStringMake(string: self.text, font: font(isDigraph ? 22 : 24.5), colour: colour)
            }
            else if isDigraph {
                let capText = NSMutableAttributedStringMake(string: String(self.text.prefix(1)), font: font(20), colour: colour)
                capText.append(NSAttributedStringMake(string: String(self.text.dropFirst()), font: font(18), colour: colour))
                return capText
            }
            else {
                return NSAttributedStringMake(string: self.text, font: font(22), colour: colour)
            }
        }
    }

    func updateLabelText() {
        self.label.attributedText = self.capText(scale: self.typeScale)
        self.popupLabel?.attributedText = self.popupCapText()
        self.layoutLabel()
        self.layoutPopupLabel()
    }

    /// Places a label so its text sits where the system keyboard puts it.
    ///
    /// Letters and characters share one baseline, a little below the key's
    /// centre; words and symbols such as "123" are centred on their capitals,
    /// slightly above the centre. UILabel centres its line box, so the baseline
    /// lands `(ascender + descender) / 2` below the label's centre, and the label
    /// is moved to correct for that.
    func labelVerticalOffset() -> CGFloat {
        guard let font = self.label.font else {
            return 0
        }

        let baselineBelowLabelCentre = (font.ascender + font.descender) / 2

        switch self.capStyle {
        case .letter, .character:
            return 6.4 * self.typeScale - baselineBelowLabelCentre
        case .label:
            return font.capHeight / 2 - 1 * self.typeScale - baselineBelowLabelCentre
        }
    }

    func layoutLabel() {
        let frame = self.bounds.insetBy(dx: self.labelInset, dy: self.labelInset)
        self.label.frame = frame.offsetBy(dx: 0, dy: self.labelVerticalOffset())
    }

    ///////////
    // SHAPE //
    ///////////

    func refreshShape() {
        if self.bounds.width == 0 || self.bounds.height == 0 {
            return
        }

        CATransaction.begin()
        CATransaction.setDisableActions(true)

        if let popup = self.popup {
            self.displayView.path = KeyboardKeyBackground.path(forKey: self.bounds, cornerRadius: self.cornerRadius, popup: popup.frame, popupCornerRadius: self.popupCornerRadius)
        }
        else {
            self.displayView.path = KeyboardKeyBackground.path(forKey: self.bounds, cornerRadius: self.cornerRadius)
        }

        CATransaction.commit()
    }

    func updateColors() {
        CATransaction.begin()
        CATransaction.setDisableActions(true)

        let isDown = self.isHighlighted || self.isSelected

        if self.popup != nil {
            self.displayView.fillColor = self.popupColor
        }
        else if isDown, let downColor = self.downColor {
            self.displayView.fillColor = downColor
        }
        else {
            self.displayView.fillColor = self.color
        }

        let textColor = self.currentTextColor
        self.label.textColor = textColor
        self.popupLabel?.textColor = textColor

        CATransaction.commit()
    }

    ///////////
    // POPUP //
    ///////////

    /// The popup's text: the key cap enlarged, but never taller than the popup.
    func popupCapText() -> NSAttributedString? {
        guard let popup = self.popup else {
            return nil
        }

        let scale = min(1.55 * self.typeScale, 0.95 * popup.bounds.height / 24.5)
        return self.capText(scale: scale)
    }

    func layoutPopupLabel() {
        guard let popup = self.popup, let popupLabel = self.popupLabel else {
            return
        }

        // The system keyboard sets the baseline at 87% of the popup's height.
        let bounds = popup.bounds
        let baselineBelowLabelCentre = ((popupLabel.font?.ascender ?? 0) + (popupLabel.font?.descender ?? 0)) / 2
        popupLabel.frame = bounds.offsetBy(dx: 0, dy: 0.37 * bounds.height - baselineBelowLabelCentre)
    }

    func showPopup() {
        if self.popup != nil {
            return
        }

        self.layer.zPosition = 1000

        let popup = UIView()
        popup.isUserInteractionEnabled = false
        self.popup = popup
        self.addSubview(popup)

        let popupLabel = UILabel()
        popupLabel.textAlignment = self.label.textAlignment
        popupLabel.baselineAdjustment = self.label.baselineAdjustment
        popupLabel.adjustsFontSizeToFitWidth = true
        popupLabel.minimumScaleFactor = CGFloat(0.1)
        popupLabel.isUserInteractionEnabled = false
        popupLabel.numberOfLines = 1
        popup.addSubview(popupLabel)
        self.popupLabel = popupLabel

        if let delegate = self.delegate {
            popup.frame = delegate.frameForPopup(self)
            delegate.willShowPopup(self)
        }

        popupLabel.attributedText = self.popupCapText()
        self.layoutPopupLabel()

        self.label.isHidden = true

        self.refreshShape()
        self.updateColors()
    }

    // Exposed to Objective-C because it is registered as a control action.
    @objc func hidePopup() {
        if self.popup != nil {
            self.delegate?.willHidePopup(self)

            self.popupLabel?.removeFromSuperview()
            self.popupLabel = nil

            self.popup?.removeFromSuperview()
            self.popup = nil

            self.label.isHidden = false

            self.layer.zPosition = 0

            self.refreshShape()
            self.updateColors()
        }
    }
}

/*
    PERFORMANCE NOTES

    * CAShapeLayer: convenient and low memory usage, but chunky rotations
    * drawRect: fast, but high memory usage (looks like there's a backing store for each of the 3 views)
    * if I set CAShapeLayer to shouldRasterize, perf is *almost* the same as drawRect, while mem usage is the same as before
    * oddly, 3 CAShapeLayers show the same memory usage as 1 CAShapeLayer — where is the backing store?
    * might want to move to drawRect with combined draw calls for performance reasons — not clear yet
*/

/// A view that fills a path with one colour, drawn by its CAShapeLayer.
class ShapeView: UIView {

    override class var layerClass : AnyClass {
        return CAShapeLayer.self
    }

    var shapeLayer: CAShapeLayer {
        return self.layer as! CAShapeLayer
    }

    var path: CGPath? {
        didSet {
            self.shapeLayer.path = path
        }
    }

    var fillColor: UIColor? {
        didSet {
            self.shapeLayer.fillColor = fillColor?.cgColor
        }
    }

    convenience init() {
        self.init(frame: CGRect.zero)
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.isOpaque = false
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
