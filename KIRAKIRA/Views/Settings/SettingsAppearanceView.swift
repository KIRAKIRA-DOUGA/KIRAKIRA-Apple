import SwiftUI

struct SettingsAppearanceView: View {
    @AppSetting(\.videoDisplayStyle) private var videoDisplayStyle

    var body: some View {
        Form {
            Picker("Video Display Style", selection: $videoDisplayStyle) {
                ForEach(ViewStyle.allCases) { style in
                    Text(style.displayName)
                        .tag(style)
                }
            }
        }
        .formStyle(.grouped)
        .navigationTitle("Appearance")
    }
}

#Preview {
    SettingsAppearanceView()
}
