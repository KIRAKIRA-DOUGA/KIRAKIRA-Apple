import SwiftUI
import UIKit

@MainActor
@Observable
final class ToastManager {
    static let shared = ToastManager()

    private(set) var toast: ToastConfiguration?
    private var dismissalTask: Task<Void, Never>?

    private init() {}

    func show(
        _ message: String,
        style: ToastStyle = .standard,
        duration: TimeInterval = 3
    ) {
        let toast = ToastConfiguration(
            message: message,
            systemImage: style.systemImage,
            tint: style.tint
        )

        ToastWindowController.shared.prepare(using: self)
        dismissalTask?.cancel()
        self.toast = toast
        style.triggerFeedback()

        dismissalTask = Task { [weak self] in
            do {
                try await Task.sleep(for: .seconds(duration))
            } catch {
                return
            }
            self?.dismiss(id: toast.id)
        }
    }

    func dismiss() {
        dismissalTask?.cancel()
        dismissalTask = nil
        toast = nil
    }

    private func dismiss(id: UUID) {
        guard toast?.id == id else { return }
        dismissalTask = nil
        toast = nil
    }
}

struct ToastConfiguration: Identifiable {
    let id = UUID()
    let message: String
    let systemImage: String?
    let tint: Color?
}

enum ToastStyle {
    case standard
    case success
    case warning
    case error

    fileprivate var systemImage: String? {
        switch self {
        case .standard: nil
        case .success: "checkmark.circle.fill"
        case .warning: "exclamationmark.triangle.fill"
        case .error: "xmark.circle.fill"
        }
    }

    fileprivate var tint: Color? {
        switch self {
        case .standard: nil
        case .success: .green
        case .warning: .orange
        case .error: .red
        }
    }

    fileprivate func triggerFeedback() {
        let feedbackType: UINotificationFeedbackGenerator.FeedbackType? = switch self {
        case .standard: nil
        case .success: .success
        case .warning: .warning
        case .error: .error
        }

        guard let feedbackType else { return }
        UINotificationFeedbackGenerator().notificationOccurred(feedbackType)
    }
}
