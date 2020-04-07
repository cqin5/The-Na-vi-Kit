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
    var naviColour : UIColor = UIColor(white: 0.0, alpha: 1.0)
    var categoryColour : UIColor = UIColor(white: 0.2, alpha: 1.0)
        
    override func awakeFromNib() {
        super.awakeFromNib()
        setColoursToInterfaceStyle()
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
    
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        setColoursToInterfaceStyle()
    }
    
    
    func setColoursToInterfaceStyle() {
        naviColour      = traitCollection.userInterfaceStyle == .dark ? UIColor(white: 1.0, alpha: 1.0) : UIColor(white: 0.0, alpha: 1.0)
        categoryColour  = traitCollection.userInterfaceStyle == .dark ? UIColor(white: 0.6, alpha: 1.0) : UIColor(white: 0.2, alpha: 1.0)
        
        englishLabel.textColor = traitCollection.userInterfaceStyle == .dark ? UIColor(white: 0.6, alpha: 1.0) : UIColor(white: 0.2, alpha: 1.0)
    }

}
