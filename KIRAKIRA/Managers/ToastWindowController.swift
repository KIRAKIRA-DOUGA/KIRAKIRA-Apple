import SwiftUI
import UIKit

@MainActor
final class ToastWindowController {
    static let shared = ToastWindowController()

    private var window: UIWindow?

    private init() {}

    func prepare(using manager: ToastManager) {
        guard let windowScene = activeWindowScene else { return }

        if window?.windowScene !== windowScene {
            window?.isHidden = true
            window = nil
        }

        if window == nil {
            let hostingController = UIHostingController(rootView: ToastView(manager: manager))
            hostingController.view.backgroundColor = .clear

            let window = UIWindow(windowScene: windowScene)
            window.rootViewController = hostingController
            window.windowLevel = .alert + 1
            window.backgroundColor = .clear
            window.isUserInteractionEnabled = false
            window.overrideUserInterfaceStyle = AppSettings.shared.globalColorScheme.uiColorScheme
            self.window = window
        }

        window?.isHidden = false
    }

    private var activeWindowScene: UIWindowScene? {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first { $0.activationState == .foregroundActive }
    }
}
