//
//  CQUIHelper.swift
//
//
//  Created by Chuhan Qin on 2015-07-10.
//
//

import UIKit

extension UIViewController {

    /// Runs `animations` alongside the system keyboard animation, matching the
    /// duration and curve carried by a `keyboardWillShow` or `keyboardWillHide`
    /// notification.
    func animateWithKeyboard(
        notification: Notification,
        animations: ((_ keyboardFrame: CGRect) -> Void)?
    ) {
        let userInfo = notification.userInfo

        let duration = userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double ?? 0.25

        let keyboardFrame = (userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?
            .cgRectValue ?? .zero

        let curve = (userInfo?[UIResponder.keyboardAnimationCurveUserInfoKey] as? Int)
            .flatMap(UIView.AnimationCurve.init(rawValue:)) ?? .easeInOut

        let animator = UIViewPropertyAnimator(duration: duration, curve: curve) {
            animations?(keyboardFrame)

            // Required for constraint changes made inside `animations` to animate.
            self.view?.layoutIfNeeded()
        }

        animator.startAnimation()
    }
}
