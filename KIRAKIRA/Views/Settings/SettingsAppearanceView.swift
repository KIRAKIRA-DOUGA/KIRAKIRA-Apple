//
//  SettingsAppearanceView.swift
//  KIRAKIRA
//
//  Created by Aira Sakuranomiya on 2025/11/30.
//

import SwiftUI

struct SettingsAppearanceView: View {
    @State var colorMode: ColorMode = .auto
    @State var homeMode: HomeMode = .dual

    var body: some View {
        List {
            Section(header: Text("主题模式")) {
                Picker("颜色模式", selection: $colorMode) {
                    Text("AUTO").tag(ColorMode.auto)
                    Image(systemName: "sun.max.fill").tag(ColorMode.light)
                    Image(systemName: "moon.fill").tag(ColorMode.dark)
                }
                .pickerStyle(.segmented)
                .controlSize(.large)
            }
            
            Section(header: Text("首页模式")) {
                Picker("首页模式", selection: $homeMode) {
                    Image(systemName: "rectangle.grid.1x2.fill").tag(HomeMode.dual)
                    Image(systemName: "square.grid.2x2.fill").tag(HomeMode.single)
                }
                .pickerStyle(.segmented)
                .controlSize(.large)
            }
        }.navigationTitle("外观")
    }
}

enum ColorMode: Hashable {
    case auto
    case light
    case dark
}

enum HomeMode: Hashable {
    case single
    case dual
}

#Preview {
    SettingsAppearanceView()
}
