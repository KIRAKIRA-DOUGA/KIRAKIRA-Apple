import SwiftUI

struct SettingsAppearanceView: View {
    @AppSetting(\.videoDisplayStyle) private var videoDisplayStyle
    @AppSetting(\.globalColorScheme) private var globalColorScheme

    var body: some View {
        Form {
            Section(header: Text("主题模式")) {
                Picker("Color Scheme", selection: $globalColorScheme) {
                    Text("AUTO").tag(GlobalColorScheme.auto)
                    Image(systemName: "sun.max.fill").tag(GlobalColorScheme.light)
                    Image(systemName: "moon.fill").tag(GlobalColorScheme.dark)
                }
                .pickerStyle(.segmented)
                .controlSize(.large)
            }
            
            Section(header: Text("视频列表视图")) {
                Picker("Video Display Style", selection: $videoDisplayStyle) {
                    Image(systemName: "rectangle.fill").tag(ViewStyle.card)
                    Image(systemName: "rectangle.grid.1x3.fill").tag(ViewStyle.row)
                    Image(systemName: "square.grid.2x2.fill").tag(ViewStyle.smallCard)
                }
                .pickerStyle(.segmented)
                .controlSize(.large)
            }
        }
        .formStyle(.grouped)
        .navigationTitle("外观")
    }
}

#Preview {
    SettingsAppearanceView()
}
