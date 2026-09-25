//
//  NDDictionaryMainTableViewCell.swift
//  Na'vi
//
//  Created by Chuhan Qin on 2016-06-22.
//  Copyright © 2016 CQ. All rights reserved.
//

import UIKit

final class NDDictionaryMainTableViewCell: UITableViewCell {

    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var subtitleLabel: UILabel!
    @IBOutlet private weak var definitionLabel: UILabel!

    @IBOutlet private weak var playAudioButton: UIButton!
    @IBOutlet private weak var bookmarkImageView: UIImageView!

    @IBOutlet private weak var bottomConstraint: NSLayoutConstraint!

    private let defaultBottomConstraint: CGFloat = -40
    private let searchingBottomConstraint: CGFloat = 0

    private var localAudioFileName = ""

    override func awakeFromNib() {
        super.awakeFromNib()

        playAudioButton.imageView?.contentMode = .scaleAspectFit

        // The list itself carries the material, so the row stays transparent.
        backgroundColor = .clear
        backgroundView = nil
        selectionStyle = .none

        // Semantic colours track Dark Mode, Increase Contrast and Reduce
        // Transparency without any per-trait bookkeeping.
        titleLabel.textColor = .label
        subtitleLabel.textColor = .secondaryLabel
        definitionLabel.textColor = .label
    }

    func loadData(_ entry: NDDictionaryEntry, isSearchResult: Bool) {
        bookmarkImageView.isHidden = !entry.isBookmarked

        titleLabel.text = entry.navi
        subtitleLabel.text = entry.ipa + "  " + entry.partOfSpeech
        definitionLabel.text = entry.english

        localAudioFileName = entry.localAudioFileName
        playAudioButton.accessibilityLabel = "Play pronunciation of \(entry.navi)"

        bottomConstraint.constant = isSearchResult ? searchingBottomConstraint : defaultBottomConstraint
    }

    @IBAction func playAudioButtonPressed(_ sender: Any) {
        PronunciationPlayer.shared.play(fileNamed: localAudioFileName)
    }
}
