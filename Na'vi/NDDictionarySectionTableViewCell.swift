//
//  NDDictionarySectionTableViewCell.swift
//  Na'vi
//
//  Created by Chuhan Qin on 2016-06-23.
//  Copyright © 2016 CQ. All rights reserved.
//

import UIKit

class NDDictionarySectionTableViewCell: UITableViewCell {

    @IBOutlet private var sectionLabel: UILabel!

    // Lazy blur view for performance optimization
    private lazy var glassBackgroundView: UIVisualEffectView = {
        let blurEffect = UIBlurEffect(style: .systemUltraThinMaterial)
        let blurView = UIVisualEffectView(effect: blurEffect)
        blurView.alpha = 1.0
        blurView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        return blurView
    }()

    override func awakeFromNib() {
        super.awakeFromNib()
        setColoursToInterfaceStyle()

        // Setup glass background (lazy loaded)
        setupGlassBackground()
    }

    func setupGlassBackground() {
        // Add subtle tint based on interface style
        glassBackgroundView.backgroundColor = traitCollection.userInterfaceStyle == .dark ?
            UIColor.systemBlue.withAlphaComponent(0.05) :
            UIColor.systemBlue.withAlphaComponent(0.02)

        glassBackgroundView.frame = self.bounds
        addSubview(glassBackgroundView)
        sendSubviewToBack(glassBackgroundView)
    }

    override func prepareForReuse() {
        super.prepareForReuse()

        // Reuse blur view, just update frame
        glassBackgroundView.frame = self.bounds
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    func updateSectionTitle(_ title:String) {
        sectionLabel.text = title.uppercased()
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        setColoursToInterfaceStyle()
    }
    
    func setColoursToInterfaceStyle() {
        // Remove solid background - rely on glass blur effect
        backgroundColor = .clear

        // High contrast text for glass backgrounds
        sectionLabel.textColor = traitCollection.userInterfaceStyle == .dark ?
            UIColor.white.withAlphaComponent(1.0) :
            UIColor.black.withAlphaComponent(0.9)
    }
    
}
