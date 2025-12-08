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
                Section {
                    NavigationLink {
                        SettingsProfileView()
                    } label: {
                        Label("SETTINGS_PROFILE", systemImage: "person.crop.circle")
                    }

                    NavigationLink {

                    } label: {
                        Label("SETTINGS_PRIVACY", systemImage: "hand.raised")
                    }

                    NavigationLink {

                    } label: {
                        Label("SETTINGS_SAFETY", systemImage: "lock")
                    }

                    NavigationLink {

                    } label: {
                        Label("SETTINGS_BLOCK_AND_HIDE", systemImage: "nosign")
                    }

                    NavigationLink {

                    } label: {
                        Label("SETTINGS_INVITATION_CODE", systemImage: "app.gift")
                    }
                } header: {
                    Text("SETTINGS_ME")
                }

                Section {
                    NavigationLink {
                        SettingsAppearanceView()
                    } label: {
                        Label("SETTINGS_APPEARENCE", systemImage: "paintbrush")
                    }

                    NavigationLink {
                        SettingsPlayerView()
                    } label: {
                        Label("SETTINGS_PLAYING", systemImage: "play")
                    }

                    NavigationLink {
                        SettingsDanmakuView()
                    } label: {
                        Label("SETTINGS_DANMAKU", systemImage: "list.bullet.indent")
                    }

                    NavigationLink {
                        SettingsAboutView()
                    } label: {
                        Label("SETTINGS_ABOUT", systemImage: "info.circle")
                    }
                } header: {
                    Text("SETTINGS_GENERAL")
                }

                Section {
                    Button(action: {}) {
                        Label("SWITCH_ACCOUNT", systemImage: "person.2")
                    }

                    Button(role: .destructive, action: {}) {
                        Label("LOG_OUT", systemImage: "door.right.hand.open")
                    }.foregroundStyle(.red)
                }
            }
            .navigationTitle("SETTINGS")
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
