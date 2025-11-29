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
                Label("自动播放", systemImage: "play")
            }
            Toggle(isOn: $isPipOnExit) {
                Label("退出时自动小窗播放", systemImage: "pip")
            }
        }
        .navigationTitle("播放")
    }
}

#Preview {
    SettingsPlayerView()
}
