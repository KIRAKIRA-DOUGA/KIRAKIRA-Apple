import SwiftUI

/// A self-sizing input bar for `.safeAreaBar` or `.safeAreaInset`.
/// The host handles keyboard avoidance; the bar measures only its content and margins.
struct SendTextField: UIViewControllerRepresentable {
    @Binding var text: String
    let prompt: LocalizedStringResource
    let onSend: () -> Void
    let showAddButton: Bool

    init(
        text: Binding<String>,
        prompt: LocalizedStringResource,
        onSend: @escaping () -> Void,
        showAddButton: Bool = false
    ) {
        self._text = text
        self.prompt = prompt
        self.onSend = onSend
        self.showAddButton = showAddButton
    }

    func makeUIViewController(context: Context) -> SendTextFieldViewController {
        SendTextFieldViewController()
    }

    func updateUIViewController(_ controller: SendTextFieldViewController, context: Context) {
        controller.loadViewIfNeeded()
        controller.composerView.update(
            text: text,
            prompt: String(localized: prompt),
            showAddButton: showAddButton,
            onTextChange: { text = $0 },
            onSend: onSend
        )
    }

    func sizeThatFits(
        _ proposal: ProposedViewSize,
        uiViewController: SendTextFieldViewController,
        context: Context
    ) -> CGSize? {
        guard let width = proposal.width, width.isFinite else { return nil }
        uiViewController.loadViewIfNeeded()
        return uiViewController.view.sizeThatFits(CGSize(width: width, height: .greatestFiniteMagnitude))
    }
}
