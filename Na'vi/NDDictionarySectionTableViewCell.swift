//
//  NDDictionarySectionTableViewCell.swift
//  Na'vi
//
//  Created by Chuhan Qin on 2016-06-23.
//  Copyright © 2016 CQ. All rights reserved.
//

import UIKit

/// The section header for the dictionary list. A glass surface, so the entries
/// scrolling underneath stay legible through it.
final class NDDictionarySectionTableViewCell: UITableViewCell {

    @IBOutlet private var sectionLabel: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()

        backgroundColor = .clear
        backgroundView = GlassUIHelper.glassView(.recessed)
        sectionLabel.textColor = .secondaryLabel
    }

    func updateSectionTitle(_ title: String) {
        sectionLabel.text = title.uppercased()
    }
}
