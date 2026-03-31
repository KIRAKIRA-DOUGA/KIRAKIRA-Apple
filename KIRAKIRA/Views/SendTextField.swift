import SwiftUI
import SwiftUIIntrospect

struct SendTextField: View {
    @Binding var text: String
    let prompt: LocalizedStringResource
    let onSend: () -> Void
    let showAddButton: Bool?

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

    var body: some View {
        HStack(alignment: .bottom) {
            if showAddButton ?? false {
                Button(action: {}) {
                    Label(.menuMore, systemImage: "plus")
                        .frame(height: 26)
                }
                .buttonStyle(.glass)
                .buttonBorderShape(.circle)
                .labelStyle(.iconOnly)
                .font(.system(size: 19))
            }
            HStack(alignment: .bottom) {
                TextField(prompt, text: $text, axis: .vertical)
                    .introspect(.textField(axis: .vertical), on: .iOS(.v26)) { textField in
                        textField.clipsToBounds = false
                        textField.textContainerInset = UIEdgeInsets(top: 9, left: 0, bottom: 9, right: 0)
                        textField.showsVerticalScrollIndicator = true
                    }
                    .lineHeight(.normal)
                    .submitLabel(.return)
                    .padding(.leading)
                    .lineLimit(12)

                HStack(spacing: 0) {
                    Button(action: {}) {
                        Image(systemName: "face.smiling")
                            .foregroundStyle(.tertiary)
                            .frame(width: 38, height: 28)
                    }
                    .buttonStyle(.plain)
                    .buttonBorderShape(.capsule)

                    if !text.isEmpty {
                        Button(action: { onSend() }) {
                            Image(systemName: "arrow.up")
                                .font(.system(size: 17))
                        }
                        .buttonStyle(.borderedProminent)
                        .labelStyle(.iconOnly)
                        .fontWeight(.bold)
                        .frame(width: 38, height: 28)
                    }
                }
                .controlSize(.small)
                .padding(6)
            }
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .glassEffect(.regular.interactive(), in: .rect(cornerRadius: 20))
        }
    }
}
