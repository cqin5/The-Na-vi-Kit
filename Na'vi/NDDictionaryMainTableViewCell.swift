//
//  NDDictionaryMainTableViewCell.swift
//  Na'vi
//
//  Created by Chuhan Qin on 2016-06-22.
//  Copyright © 2016 CQ. All rights reserved.
//

import UIKit

class NDDictionaryMainTableViewCell: UITableViewCell {

    @IBOutlet var naviLabel : UILabel!
    @IBOutlet var englishLabel : UILabel!
    
    let naviFont : UIFont = UIFont.systemFont(ofSize: 18)
    let categoryFont : UIFont = UIFont.systemFont(ofSize: 14)
    let naviColour : UIColor = UIColor(white: 0.0, alpha: 1.0)
    let categoryColour : UIColor = UIColor(white: 0.2, alpha: 1.0)
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    func loadData(_ dictionaryItem:NDDictionaryEntry) {
        
        let firstLine = NSMutableAttributedStringMake(string: dictionaryItem.navi, font:naviFont, colour: naviColour)
        let firstLineSecondPart = NSMutableAttributedStringMake(string: " | " + dictionaryItem.category, font:categoryFont, colour: categoryColour)
        
        firstLine.append(firstLineSecondPart)
        
        naviLabel.attributedText = firstLine
        englishLabel.text = dictionaryItem.english
        
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
