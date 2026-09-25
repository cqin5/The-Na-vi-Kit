//
//  NDDefinitionViewController.swift
//  Na'vi
//
//  Created by Chuhan Qin on 2016-06-23.
//  Copyright © 2016 CQ. All rights reserved.
//

import UIKit

final class NDDefinitionViewController: UIViewController {

    @IBOutlet private var naviLabel: UILabel!
    @IBOutlet private var categoryLabel: UILabel!
    @IBOutlet private var definitionView: UITextView!

    var entry: NDDictionaryEntry!

    private let naviFont = UIFont.preferredFont(forTextStyle: .title3)
    private let ipaFont = UIFont.preferredFont(forTextStyle: .subheadline)
    private let definitionFont = UIFont.preferredFont(forTextStyle: .body)

    private lazy var stylingManager = ViewStylingManager(viewController: self)

    override func viewDidLoad() {
        super.viewDidLoad()
        stylingManager.setupDefinitionGlassUI(textView: definitionView)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        stylingManager.updateLayout()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        loadEntry()
    }

    private func loadEntry() {
        guard let entry else { return }

        let headword = NSMutableAttributedStringMake(
            string: entry.navi,
            font: naviFont,
            colour: .label
        )
        headword.append(
            NSMutableAttributedStringMake(
                string: " \t|" + entry.ipa + "| ",
                font: ipaFont,
                colour: .secondaryLabel
            )
        )

        naviLabel.attributedText = headword
        categoryLabel.text = entry.partOfSpeech

        definitionView.attributedText = NSAttributedStringMake(
            string: entry.english,
            font: definitionFont,
            colour: .label
        )
    }

    @IBAction func backButtonTapped(_ sender: AnyObject?) {
        if let navigationController, navigationController.viewControllers.count > 1 {
            navigationController.popViewController(animated: true)
        } else {
            dismiss(animated: true)
        }
    }
}
