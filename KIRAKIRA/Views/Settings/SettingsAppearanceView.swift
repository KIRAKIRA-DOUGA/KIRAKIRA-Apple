import SwiftUI

struct SettingsAppearanceView: View {
    @AppSetting(\.videoDisplayStyle) private var videoDisplayStyle
    @AppSetting(\.globalColorScheme) private var globalColorScheme

    var body: some View {
        Form {
            Section(header: Text("SETTINGS_APPEARANCE_COLOR_SCHEME")) {
                Picker("SETTINGS_APPEARANCE_COLOR_SCHEME", selection: $globalColorScheme) {
                    Text(verbatim: "AUTO").tag(GlobalColorScheme.auto)
                    Image(systemName: "sun.max.fill").tag(GlobalColorScheme.light)
                    Image(systemName: "moon.fill").tag(GlobalColorScheme.dark)
                }
                .pickerStyle(.segmented)
                .controlSize(.large)
            }
            
            Section(header: Text("SETTINGS_APPEARANCE_VIDEO_DISPLAY_STYLE")) {
                Picker("SETTINGS_APPEARANCE_VIDEO_DISPLAY_STYLE", selection: $videoDisplayStyle) {
                    Image(systemName: "rectangle.fill").tag(ViewStyle.card)
                    Image(systemName: "rectangle.grid.1x3.fill").tag(ViewStyle.row)
                    Image(systemName: "square.grid.2x2.fill").tag(ViewStyle.smallCard)
                }
                .pickerStyle(.segmented)
                .controlSize(.large)
            }
        }
        .formStyle(.grouped)
        .navigationTitle("SETTINGS_APPEARANCE")
    }
}

#Preview {
    SettingsAppearanceView()
}
