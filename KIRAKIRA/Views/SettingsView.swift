//
//  SettingsView.swift
//  KIRAKIRA
//
//  Created by Aira Sakuranomiya on 2025/11/8.
//

import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                Section(header: Text("个人")) {
                    NavigationLink {
                        SettingsProfileView()
                    } label: {
                        Label("资料", systemImage: "person.crop.circle")
                    }

                    NavigationLink {

                    } label: {
                        Label("隐私", systemImage: "hand.raised")
                    }

                    NavigationLink {

                    } label: {
                        Label("安全", systemImage: "lock")
                    }

                    NavigationLink {

                    } label: {
                        Label("屏蔽和隐藏", systemImage: "nosign")
                    }

                    NavigationLink {

                    } label: {
                        Label("邀请码", systemImage: "app.gift")
                    }
                }

                Section(header: Text("通用")) {
                    NavigationLink {

                    } label: {
                        Label("外观", systemImage: "paintbrush")
                    }

                    NavigationLink {

                    } label: {
                        Label("播放", systemImage: "play")
                    }

                    NavigationLink {

                    } label: {
                        Label("弹幕", systemImage: "list.bullet.indent")
                    }

                    NavigationLink {
                        SettingsAboutView()
                    } label: {
                        Label("关于", systemImage: "info.circle")
                    }
                }

                Section {
                    Button(action: {}) {
                        Label("切换账号", systemImage: "person.2")
                    }

                    Button(role: .destructive, action: {}) {
                        Label("退出登入", systemImage: "door.right.hand.open")
                    }.foregroundStyle(.red)
                }
            }
            .navigationTitle("设置")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                    }
                }
            }
            #if !os(macOS)
                .navigationBarTitleDisplayMode(.inline)
            #endif
        }
    }
}

#Preview {
    SettingsView()
}
