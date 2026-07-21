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

    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var subtitleLabel: UILabel!
    @IBOutlet weak var definitionLabel: UILabel!

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

    // Lazy blur view for performance optimization
    private lazy var glassBackgroundView: UIVisualEffectView = {
        let blurEffect = UIBlurEffect(style: .systemMaterial)
        let blurView = UIVisualEffectView(effect: blurEffect)
        blurView.alpha = 0.95
        blurView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        return blurView
    }()

    override func awakeFromNib() {
        super.awakeFromNib()
        playAudioButton.imageView?.contentMode = .scaleAspectFit

        // Setup glass background (lazy loaded)
        setupGlassBackground()

        setColoursToInterfaceStyle()
    }

    func setupGlassBackground() {
        // Use lazy-loaded blur view for better performance
        self.backgroundView = glassBackgroundView
        self.backgroundColor = .clear
    }

    override func prepareForReuse() {
        super.prepareForReuse()

        // Reuse blur view instead of recreating
        // Just update frame if needed
        glassBackgroundView.frame = self.bounds
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
        let isDark = traitCollection.userInterfaceStyle == .dark

        // Enhanced glass-appropriate text colors for better readability
        titleLabel.textColor = isDark ?
            UIColor.white.withAlphaComponent(0.95) :
            UIColor.black.withAlphaComponent(0.9)

        subtitleLabel.textColor = isDark ?
            UIColor.white.withAlphaComponent(0.7) :
            UIColor.black.withAlphaComponent(0.6)

        definitionLabel.textColor = isDark ?
            UIColor.white.withAlphaComponent(0.85) :
            UIColor.black.withAlphaComponent(0.75)
    }

    @IBAction func playAudioButtonPressed(_ sender: Any) {
        NDAudioController.shared.play(localFileName: localAudioFileName)
    }
}

/// Single owner of dictionary audio playback: only one pronunciation plays at a
/// time, and the audio session is deactivated when playback ends so it stops
/// ducking the user's background audio.
final class NDAudioController: NSObject, AVAudioPlayerDelegate {
    static let shared = NDAudioController()
    private var player: AVAudioPlayer?

    private override init() { super.init() }

    func play(localFileName: String) {
        guard !localFileName.isEmpty,
              let path = Bundle.main.path(forResource: localFileName, ofType: nil) else {
            return
        }
        stop()   // stop any clip already playing before starting a new one
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback)
            try AVAudioSession.sharedInstance().setActive(true)
            let newPlayer = try AVAudioPlayer(contentsOf: URL(fileURLWithPath: path))
            newPlayer.delegate = self
            player = newPlayer
            newPlayer.play()
        } catch {
            print("NDAudioController: couldn't play \(localFileName): \(error)")
            deactivateSession()
        }
    }

    func stop() {
        player?.stop()
        player = nil
    }

    private func deactivateSession() {
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }

    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        self.player = nil
        deactivateSession()
    }
}
