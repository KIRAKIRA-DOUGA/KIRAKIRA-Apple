import SwiftUI

struct WizardSection<Content: View>: View {
    @ViewBuilder let content: () -> Content
    
    @Environment(\.colorScheme) private var colorScheme
    private let horizontalPadding: CGFloat = 34

    var body: some View {
        Section {
            content()
        }
        .listSectionMargins(.horizontal, horizontalPadding)
        .listRowBackground(colorScheme == .dark ? Color(UIColor.tertiarySystemGroupedBackground) : Color(UIColor.systemGroupedBackground))
    }
}

#Preview {
    WizardSection() {
        Text("测试")
    }
}
