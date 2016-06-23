//
//  NDDictionarySectionTableViewCell.swift
//  Na'vi
//
//  Created by Chuhan Qin on 2016-06-23.
//  Copyright © 2016 CQ. All rights reserved.
//

import UIKit

class NDDictionarySectionTableViewCell: UITableViewCell {

    @IBOutlet var sectionLabel : UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    func updateSectionTitle(title:String) {
        sectionLabel.text = title
    }

}
