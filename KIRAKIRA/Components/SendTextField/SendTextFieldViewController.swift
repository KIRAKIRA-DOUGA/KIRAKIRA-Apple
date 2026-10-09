import UIKit

/// The SwiftUI safe-area host owns vertical placement and keyboard avoidance.
final class SendTextFieldViewController: UIViewController {
    let composerView = SendTextInputView()
    private lazy var containerView = SendTextFieldContainerView(composerView: composerView)
    private var isKeyboardVisible = false

    override func loadView() {
        view = containerView
        containerView.onCornerRadiusChange = { [weak self] in
            self?.updateMargins()
        }
        NotificationCenter.default.addObserver(
            self, selector: #selector(keyboardFrameWillChange(_:)),
            name: UIResponder.keyboardWillChangeFrameNotification, object: nil
        )
        NotificationCenter.default.addObserver(
            self, selector: #selector(keyboardWillShow(_:)),
            name: UIResponder.keyboardWillShowNotification, object: nil
        )
        NotificationCenter.default.addObserver(
            self, selector: #selector(keyboardWillHide(_:)),
            name: UIResponder.keyboardWillHideNotification, object: nil
        )
    }

    private func updateMargins(notification: Notification? = nil) {
        let closedPadding = min(32, max(18, containerView.bottomCornerRadius - SendTextInputView.Metrics.cornerRadius))
        let padding: CGFloat = isKeyboardVisible ? 18 : closedPadding
        guard containerView.padding != padding else { return }
        guard let notification, !UIAccessibility.isReduceMotionEnabled else {
            containerView.padding = padding
            return
        }

        containerView.layoutIfNeeded()
        let duration = notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double ?? 0.25
        let curve =
            notification.userInfo?[UIResponder.keyboardAnimationCurveUserInfoKey] as? UInt
            ?? UInt(UIView.AnimationCurve.easeInOut.rawValue)
        let options = UIView.AnimationOptions(rawValue: curve << 16)
            .union([.beginFromCurrentState, .allowUserInteraction])
        UIView.animate(withDuration: duration, delay: 0, options: options) {
            self.containerView.padding = padding
            self.containerView.layoutIfNeeded()
        }
    }

    @objc private func keyboardFrameWillChange(_ notification: Notification) {
        guard let window = view.window, let screen = window.windowScene?.screen,
            let frame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect
        else { return }
        let keyboardFrame = window.convert(frame, from: screen.coordinateSpace)
        // Floating keyboards also use the open-keyboard padding. SwiftUI decides
        // whether the host needs to move; no keyboard height is added here.
        isKeyboardVisible = window.bounds.intersects(keyboardFrame)
        updateMargins(notification: notification)
    }

    @objc private func keyboardWillShow(_ notification: Notification) {
        guard view.window != nil else { return }
        isKeyboardVisible = true
        updateMargins(notification: notification)
    }

    @objc private func keyboardWillHide(_ notification: Notification) {
        isKeyboardVisible = false
        updateMargins(notification: notification)
    }
}
