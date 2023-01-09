//
//  NDDictionaryMainTableViewCell.swift
//  Na'vi
//
//  Created by Chuhan Qin on 2016-06-22.
//  Copyright © 2016 CQ. All rights reserved.
//

import UIKit
import AVFAudio
import AVFoundation

class NDDictionaryMainTableViewCell: UITableViewCell {

    @IBOutlet weak var titleLabel : UILabel!
    @IBOutlet weak var subtitleLabel: UILabel!
    @IBOutlet weak var definitionLabel : UILabel!
    
    @IBOutlet weak var playAudioButton: UIButton!
    @IBOutlet weak var bookmarkImageView: UIImageView!
    
    @IBOutlet weak var bottomConstraint: NSLayoutConstraint!
    
    let defaultBottomConstraint = CGFloat(-40)
    let searchingBottomConstraint = CGFloat(0)

    
    let titleFont : UIFont = UIFont.boldSystemFont(ofSize: 18)
    let subtitleFont : UIFont = UIFont.systemFont(ofSize: 14)
    
    var titleLabelColourLightMode : UIColor = UIColor(white: 0.0, alpha: 1.0)
    var subtitleLabelColourLightMode : UIColor = UIColor(white: 0.2, alpha: 0.5)
    var definitionLabelColourLightMode : UIColor = UIColor(white: 0.2, alpha: 0.5)

    var titleLabelColourDarkMode : UIColor = UIColor(white: 1.0, alpha: 1.0)
    var subtitleLabelColourDarkMode : UIColor = UIColor(white: 1.0, alpha: 0.5)
    var definitionLabelColourDarkMode : UIColor = UIColor(white: 1.0, alpha: 0.8)

    var audioFileLocation = ""
    var localAudioFileName = ""
    
    var audioPlayer: AVAudioPlayer?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        playAudioButton.imageView?.contentMode = .scaleAspectFit
        setColoursToInterfaceStyle()
    }
    
    func loadData(_ dictionaryItem:NDDictionaryEntry, isSearchResult: Bool) {
        
        bookmarkImageView.isHidden = !dictionaryItem.isBookmarked
        
        titleLabel.text = dictionaryItem.navi
        subtitleLabel.text = dictionaryItem.IPA + "  " + dictionaryItem.partOfSpeech
        
        definitionLabel.text = dictionaryItem.english
        
        audioFileLocation = dictionaryItem.audioFileLocation
        localAudioFileName = dictionaryItem.localAudioFileName
        
        bottomConstraint.constant = isSearchResult ? searchingBottomConstraint : defaultBottomConstraint
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        setColoursToInterfaceStyle()
    }
    
    
    func setColoursToInterfaceStyle() {
        titleLabel.textColor = traitCollection.userInterfaceStyle == .dark ? titleLabelColourDarkMode : titleLabelColourLightMode
        subtitleLabel.textColor = traitCollection.userInterfaceStyle == .dark ? subtitleLabelColourDarkMode : subtitleLabelColourLightMode
        definitionLabel.textColor = traitCollection.userInterfaceStyle == .dark ? definitionLabelColourDarkMode : definitionLabelColourLightMode
        
    }

    @IBAction func playAudioButtonPressed(_ sender: Any) {
        
        
        guard let path = Bundle.main.path(forResource: localAudioFileName, ofType: nil) else {
            return
        }


        let url = URL(fileURLWithPath: path)

        do {
            
            try AVAudioSession.sharedInstance().setCategory(.playback)
            try AVAudioSession.sharedInstance().setActive(true)
            
            audioPlayer = try AVAudioPlayer(contentsOf: url)
                        
            audioPlayer?.play()
        } catch {
            // couldn't load file :(
            print("couldn't load file :(")
        }
            
       
    }
}
