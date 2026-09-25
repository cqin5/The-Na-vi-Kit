//
//  CQNSHelper.swift
//
//
//  Created by Chuhan Qin on 2015-07-13.
//
//

import Foundation
import UIKit

func NSAttributedStringMake(string: String, font: UIFont, colour: UIColor) -> NSAttributedString {
    NSAttributedString(
        string: string,
        attributes: [.font: font, .foregroundColor: colour]
    )
}

func NSMutableAttributedStringMake(string: String, font: UIFont, colour: UIColor) -> NSMutableAttributedString {
    NSMutableAttributedString(
        string: string,
        attributes: [.font: font, .foregroundColor: colour]
    )
}

extension String {

    /// The string with its first character capitalised and the rest left as it is.
    var stringWithCapitalizedFirstLetter: String {
        let first = String(prefix(1)).capitalized
        let rest = String(dropFirst())
        return first + rest
    }
}
