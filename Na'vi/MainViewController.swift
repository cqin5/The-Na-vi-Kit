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

    override var preferredStatusBarStyle: UIStatusBarStyle {
        .lightContent
    }

    @IBAction func dismissViewController() {
        dismiss(animated: true)
    }

    @IBAction func sendEmailButtonTapped(_ sender: AnyObject) {
        guard MFMailComposeViewController.canSendMail() else {
            presentMailUnavailableAlert()
            return
        }

        present(makeMailComposeViewController(), animated: true)
    }

    // MARK: - Mail

    private func makeMailComposeViewController() -> MFMailComposeViewController {
        let composer = MFMailComposeViewController()
        // The compose delegate is a separate property from `delegate`; setting the
        // wrong one leaves the composer with no way to dismiss itself.
        composer.mailComposeDelegate = self
        composer.setToRecipients([supportAddress])
        composer.setSubject("Na'vi App: ")
        return composer
    }

    private func presentMailUnavailableAlert() {
        let alert = UIAlertController(
            title: "Could Not Send Email",
            message: "This device is not set up to send email. Check your mail account and try again.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}

// MARK: - MFMailComposeViewControllerDelegate

extension MainViewController: MFMailComposeViewControllerDelegate {

    func mailComposeController(
        _ controller: MFMailComposeViewController,
        didFinishWith result: MFMailComposeResult,
        error: Error?
    ) {
        controller.dismiss(animated: true)
    }
}
