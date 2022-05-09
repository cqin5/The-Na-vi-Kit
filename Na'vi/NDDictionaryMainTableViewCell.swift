//
//  NDDictionaryMainTableViewCell.swift
//  Na'vi
//
//  Created by Chuhan Qin on 2016-06-22.
//  Copyright © 2016 CQ. All rights reserved.
//

import UIKit

class NDDictionaryMainTableViewCell: UITableViewCell {

    @IBOutlet weak var titleLabel : UILabel!
    @IBOutlet weak var subtitleLabel: UILabel!
    @IBOutlet weak var definitionLabel : UILabel!
    
    let titleFont : UIFont = UIFont.boldSystemFont(ofSize: 18)
    let subtitleFont : UIFont = UIFont.systemFont(ofSize: 14)
    var titleLabelColourLightMode : UIColor = UIColor(white: 0.0, alpha: 1.0)
    var subtitleLabelColourLightMode : UIColor = UIColor(white: 0.2, alpha: 0.5)
        
    override func awakeFromNib() {
        super.awakeFromNib()
        setColoursToInterfaceStyle()
    }
    
    func loadData(_ dictionaryItem:NDDictionaryEntry) {
        
        
        titleLabel.text = dictionaryItem.navi
        subtitleLabel.text = dictionaryItem.IPA
        
        let titleLabelAttributedString = NSMutableAttributedStringMake(string: dictionaryItem.navi, font:titleFont, colour: titleLabelColourLightMode)
        let subtitleLabelAttributedString = NSMutableAttributedStringMake(string: "" + dictionaryItem.IPA + "  " + dictionaryItem.partOfSpeech, font:subtitleFont, colour: subtitleLabelColourLightMode)
        
        titleLabel.attributedText = titleLabelAttributedString
        subtitleLabel.attributedText = subtitleLabelAttributedString
        definitionLabel.text = dictionaryItem.english
        
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        setColoursToInterfaceStyle()
    }
    
    
    func setColoursToInterfaceStyle() {
        titleLabelColourLightMode      = traitCollection.userInterfaceStyle == .dark ? UIColor(white: 1.0, alpha: 1.0) : titleLabelColourLightMode
        subtitleLabelColourLightMode  = traitCollection.userInterfaceStyle == .dark ? UIColor(white: 0.6, alpha: 0.0) : subtitleLabelColourLightMode
        
        definitionLabel.textColor = traitCollection.userInterfaceStyle == .dark ? UIColor(white: 0.6, alpha: 1.0) : UIColor(white: 0.2, alpha: 1.0)
    }

}
