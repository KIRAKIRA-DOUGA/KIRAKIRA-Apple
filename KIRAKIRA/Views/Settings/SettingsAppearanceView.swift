import SwiftUI

struct SettingsAppearanceView: View {
    @AppSetting(\.videoDisplayStyle) private var videoDisplayStyle
    @State private var colorMode: ColorMode = .auto

    var body: some View {
        Form {
            Section(header: Text("主题模式")) {
                Picker("Color Scheme", selection: $colorMode) {
                    Text("AUTO").tag(ColorMode.auto)
                    Image(systemName: "sun.max.fill").tag(ColorMode.light)
                    Image(systemName: "moon.fill").tag(ColorMode.dark)
                }
                .pickerStyle(.segmented)
                .controlSize(.large)
            }
            
            Section(header: Text("视频列表视图")) {
                Picker("Video Display Style", selection: $videoDisplayStyle) {
//                    ForEach(ViewStyle.allCases) { style in
//                        Text(style.displayName)
//                            .tag(style)
//                    }
                    Image(systemName: "rectangle.fill").tag(ViewStyle.card)
                    Image(systemName: "rectangle.grid.1x3.fill").tag(ViewStyle.row)
                    Image(systemName: "square.grid.2x2.fill").tag(ViewStyle.smallCard)
                }
                .pickerStyle(.segmented)
                .controlSize(.large)
            }
        }
        .formStyle(.grouped)
        .navigationTitle("Appearance")
    }
}

#Preview {
    SettingsAppearanceView()
}

enum ColorMode: Hashable {
    case auto
    case light
    case dark
}
