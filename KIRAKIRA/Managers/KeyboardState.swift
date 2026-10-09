import SwiftUI

@Observable
final class KeyboardState {
    private(set) var isVisible = false

    private var observers: [NSObjectProtocol] = []

    init() {
        let center = NotificationCenter.default

        observers.append(
            center.addObserver(
                forName: UIResponder.keyboardWillShowNotification,
                object: nil,
                queue: .main
            ) { [weak self] _ in
                self?.isVisible = true
            }
        )

        observers.append(
            center.addObserver(
                forName: UIResponder.keyboardWillHideNotification,
                object: nil,
                queue: .main
            ) { [weak self] _ in
                self?.isVisible = false
            }
        )
    }

    deinit {
        observers.forEach(NotificationCenter.default.removeObserver)
    }
}
