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
            self, selector: #selector(keyboardWillShow),
            name: UIResponder.keyboardWillShowNotification, object: nil
        )
        NotificationCenter.default.addObserver(
            self, selector: #selector(keyboardWillHide),
            name: UIResponder.keyboardWillHideNotification, object: nil
        )
    }

    private func updateMargins() {
        let closedPadding = min(32, max(18, containerView.bottomCornerRadius - composerView.cornerRadius))
        containerView.padding = isKeyboardVisible ? 18 : closedPadding
    }

    @objc private func keyboardFrameWillChange(_ notification: Notification) {
        #if !os(visionOS)
            guard let window = view.window, let screen = window.windowScene?.screen,
                let frame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect
            else { return }
            let keyboardFrame = window.convert(frame, from: screen.coordinateSpace)
            // Floating keyboards also use the open-keyboard padding. SwiftUI decides
            // whether the host needs to move; no keyboard height is added here.
            isKeyboardVisible = window.bounds.intersects(keyboardFrame)
            updateMargins()
        #endif
    }

    @objc private func keyboardWillShow() {
        guard view.window != nil else { return }
        isKeyboardVisible = true
        updateMargins()
    }

    @objc private func keyboardWillHide() {
        isKeyboardVisible = false
        updateMargins()
    }
}
