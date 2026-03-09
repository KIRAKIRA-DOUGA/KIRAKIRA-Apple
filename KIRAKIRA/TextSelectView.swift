import SwiftUI
import SwiftUIX

struct TextSelectView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var text: String

    var body: some View {
        NavigationStack {
            ScrollView {
                TextView(text: $text)
                    .editable(false)
                    .font(.body)
                    .frame(maxHeight: .infinity)
                    .scrollDisabled(true)
                    .padding()
            }
            .navigationTitle(.actionSelect)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(.close, systemImage: "xmark", role: .close, action: { dismiss() })
                }
            }
        }
    }
}
