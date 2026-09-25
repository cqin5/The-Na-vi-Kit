//
//  MainViewController.swift
//  Na'vi
//
//  Created by Chuhan Qin on 2016-06-22.
//  Copyright © 2016 CQ. All rights reserved.
//

import MessageUI
import UIKit

final class MainViewController: UIViewController {

    private let supportAddress = "cqin@me.com"
    private let supportSubject = "Na'vi App: "

    override var preferredStatusBarStyle: UIStatusBarStyle {
        .lightContent
    }

    @IBAction func dismissViewController() {
        dismiss(animated: true)
    }

    @IBAction func sendEmailButtonTapped(_ sender: AnyObject) {
        if MFMailComposeViewController.canSendMail() {
            present(makeMailComposeViewController(), animated: true)
            return
        }

        // Mail isn't set up here, but the reader may use another app as their
        // default mail app; hand the message to whichever one that is.
        guard let url = supportMailURL else {
            presentMailUnavailableAlert()
            return
        }

        Task {
            let opened = await UIApplication.shared.open(url, options: [:])
            if !opened {
                presentMailUnavailableAlert()
            }
        }
    }

    // MARK: - Mail

    private func makeMailComposeViewController() -> MFMailComposeViewController {
        let composer = MFMailComposeViewController()
        // The compose delegate is a separate property from `delegate`; setting the
        // wrong one leaves the composer with no way to dismiss itself.
        composer.mailComposeDelegate = self
        composer.setToRecipients([supportAddress])
        composer.setSubject(supportSubject)
        return composer
    }

    private var supportMailURL: URL? {
        var components = URLComponents()
        components.scheme = "mailto"
        components.path = supportAddress
        components.queryItems = [URLQueryItem(name: "subject", value: supportSubject)]
        return components.url
    }

    private func presentMailUnavailableAlert() {
        let alert = UIAlertController(
            title: "Could Not Send Email",
            message: "No mail app is set up on this device. Add a mail account and try again.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}

// MARK: - MFMailComposeViewControllerDelegate

// MessageUI's delegate protocol predates Swift concurrency and is not isolated to
// the main actor, though UIKit only ever calls it there. `@preconcurrency` lets a
// main-actor view controller conform without a Swift 6 isolation error.
extension MainViewController: @preconcurrency MFMailComposeViewControllerDelegate {

    func mailComposeController(
        _ controller: MFMailComposeViewController,
        didFinishWith result: MFMailComposeResult,
        error: Error?
    ) {
        controller.dismiss(animated: true)
    }
}
