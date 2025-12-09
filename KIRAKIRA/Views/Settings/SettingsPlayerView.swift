//
//  SettingsPlayerView.swift
//  KIRAKIRA
//
//  Created by Aira Sakuranomiya on 2025/11/30.
//

import SwiftUI

struct SettingsPlayerView: View {
    @State var isPipOnExit = false
    @State var isAutoPlay = false

    var body: some View {
        List {
            Toggle(isOn: $isAutoPlay) {
                Label("SETTINGS_PLAYING_AUTO_PLAY", systemImage: "play")
            }
            Toggle(isOn: $isPipOnExit) {
                Label("SETTINGS_PLAYING_AUTO_PIP", systemImage: "pip")
            }
        }
        .navigationTitle("SETTINGS_PLAYING")
    }
}

#Preview {
    SettingsPlayerView()
}
