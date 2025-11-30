import SwiftUI

struct SettingsAppearanceView: View {
    @EnvironmentObject private var settingsManager: SettingsManager

    var body: some View {
        Form {
            Picker("Video Display Style", selection: $settingsManager.videoDisplayStyle) {
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
