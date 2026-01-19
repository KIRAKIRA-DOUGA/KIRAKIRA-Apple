import SwiftUI

struct SettingsPlayerView: View {
    @State var isPipOnExit = false
    @State var isAutoPlay = false

    var body: some View {
        List {
            Toggle(isOn: $isAutoPlay) {
                Label(.settingsPlayingAutoPlay, systemImage: "play")
            }
            Toggle(isOn: $isPipOnExit) {
                Label(.settingsPlayingAutoPip, systemImage: "pip")
            }
        }
        .navigationTitle(.settingsPlaying)
    }
}

#Preview {
    SettingsPlayerView()
}
