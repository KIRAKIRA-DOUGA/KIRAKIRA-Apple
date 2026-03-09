import SwiftUI
import SwiftUIX

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
                        .frame(height: 35)
                }
                .buttonStyle(.glass)
                .buttonBorderShape(.circle)
                .labelStyle(.iconOnly)
                .font(.system(size: 19))
                .padding(.bottom, -2)
            }
            HStack(alignment: .bottom) {
                TextField(prompt, text: $text, axis: .vertical)
                    .submitLabel(.return)
                    .padding(.leading)
                    .padding(.vertical, 8)
                    .frame(minHeight: 45)
                
//                TextView(text: $text)
//                    .submitLabel(.return)
//                    .padding(.leading)
//                    .padding(.vertical, 8)
//                    .frame(minHeight: 45)
//                    .font(.body)
//                    .scrollDisabled(true)
                
                HStack {
                    Button(action: {}) {
                        Image(systemName: "face.smiling")
                            .foregroundStyle(.tertiary)
                            .font(.system(size: 19))
                            .padding(4)
                    }
                    .buttonStyle(.plain)
                    .buttonBorderShape(.circle)
                    
                    Button(.actionSend, systemImage: "arrow.up", action: { onSend() })
                        .buttonStyle(.borderedProminent)
                        .labelStyle(.iconOnly)
                        .fontWeight(.bold)
                        .disabled(text.isEmpty)
                }.padding(6)
            }
            .glassEffect(.regular.interactive(), in: .rect(cornerRadius: 24))
        }
    }
}
