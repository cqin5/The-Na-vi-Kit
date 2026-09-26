//
//  ImageKey.swift
//  TastyImitationKeyboard
//
//  Created by Alexei Baboulevitch on 11/2/14.
//  Copyright (c) 2014 Alexei Baboulevitch ("Archagon"). All rights reserved.
//

import UIKit

/// A key that can show an SF Symbol, such as Shift's arrow, in place of text.
class ImageKey: KeyboardKey {

    /// The system keyboard draws its Shift and Delete symbols at this size.
    static let symbolPointSize: CGFloat = 19

    var symbolName: String? {
        didSet {
            if symbolName != oldValue {
                self.updateSymbol()
            }
        }
    }

    let symbolView = UIImageView()

    private var symbolScale: CGFloat = 0

    override init() {
        super.init()

        self.symbolView.contentMode = UIView.ContentMode.center
        self.symbolView.isUserInteractionEnabled = false
        self.addSubview(self.symbolView)
    }

    required init?(coder: NSCoder) {
        fatalError("NSCoding not supported")
    }

    func updateSymbol() {
        self.symbolScale = self.typeScale

        if let symbolName = self.symbolName {
            let configuration = UIImage.SymbolConfiguration(pointSize: ImageKey.symbolPointSize * self.symbolScale, weight: .regular)
            self.symbolView.image = UIImage(systemName: symbolName, withConfiguration: configuration)
        }
        else {
            self.symbolView.image = nil
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        if self.symbolName != nil && self.symbolScale != self.typeScale {
            self.updateSymbol()
        }
        self.symbolView.frame = self.bounds
    }

    override func updateColors() {
        super.updateColors()
        self.symbolView.tintColor = self.currentTextColor
    }
}
