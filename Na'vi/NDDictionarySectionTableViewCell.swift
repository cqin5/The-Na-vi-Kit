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
        setColoursToInterfaceStyle()
        
        let blurEffect = UIBlurEffect(style: .systemChromeMaterial)
        let blurEffectView = UIVisualEffectView(effect: blurEffect)
        
        blurEffectView.alpha = 0.95
        //always fill the view
        blurEffectView.frame = self.bounds
        blurEffectView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        
        addSubview(blurEffectView)
        sendSubviewToBack(blurEffectView)
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    func updateSectionTitle(_ title:String) {
        sectionLabel.text = title
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        setColoursToInterfaceStyle()
    }
    
    func setColoursToInterfaceStyle() {
        backgroundColor         = traitCollection.userInterfaceStyle == .dark ? UIColor(hex: "#242424", alpha: 0.6) : UIColor(white: 0.8, alpha: 1.0)
        sectionLabel.textColor  = traitCollection.userInterfaceStyle == .dark ? UIColor(hex: "#ffffff", alpha: 1.0) : UIColor(white: 0.0, alpha: 1.0)
    }
    
}
