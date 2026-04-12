import SwiftUI

struct SettingsAppearanceView: View {
    @AppSetting(\.videoDisplayStyle) private var videoDisplayStyle
    @AppSetting(\.globalColorScheme) private var globalColorScheme

    var body: some View {
        Form {
            Section(header: Text(.settingsAppearanceColorScheme)) {
                Picker(.settingsAppearanceColorScheme, selection: $globalColorScheme) {
                    Text(verbatim: "AUTO").tag(GlobalColorScheme.auto)
                    Image(systemName: "sun.max.fill").tag(GlobalColorScheme.light)
                    Image(systemName: "moon.fill").tag(GlobalColorScheme.dark)
                }
                .modifier(RawListPickerViewModifier())
            }.listRowBackground(Color.clear)

            Section(header: Text(.settingsAppearanceVideoDisplayStyle)) {
                Picker(.settingsAppearanceVideoDisplayStyle, selection: $videoDisplayStyle) {
                    Image(systemName: "rectangle.fill").tag(ViewStyle.card)
                    Image(systemName: "rectangle.grid.1x3.fill").tag(ViewStyle.row)
                    Image(systemName: "square.grid.2x2.fill").tag(ViewStyle.smallCard)
                }
                .modifier(RawListPickerViewModifier())
            }.listRowBackground(Color.clear)
        }
        .formStyle(.grouped)
        .navigationTitle(.settingsAppearance)
    }
}

private struct RawListPickerViewModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .pickerStyle(.segmented)
            .controlSize(.large)
            .listRowInsets(.all, 0)
    }
}

#Preview {
    SettingsAppearanceView()
}
