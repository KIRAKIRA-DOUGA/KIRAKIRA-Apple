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
                        Label(.settingsProfile, systemImage: "person.crop.circle")
                    }

                    NavigationLink {

                    } label: {
                        Label(.settingsPrivacy, systemImage: "hand.raised")
                    }

                    NavigationLink {

                    } label: {
                        Label(.settingsSafety, systemImage: "lock")
                    }

                    NavigationLink {

                    } label: {
                        Label(.settingsBlockAndHide, systemImage: "nosign")
                    }

                    NavigationLink {

                    } label: {
                        Label(.settingsInvitationCode, systemImage: "app.gift")
                    }
                } header: {
                    Text(.settingsMe)
                }

                Section {
                    NavigationLink {
                        SettingsAppearanceView()
                    } label: {
                        Label(.settingsAppearance, systemImage: "paintbrush")
                    }

                    NavigationLink {
                        SettingsPlayerView()
                    } label: {
                        Label(.settingsPlaying, systemImage: "play")
                    }

                    NavigationLink {
                        SettingsDanmakuView()
                    } label: {
                        Label(.settingsDanmaku, systemImage: "list.bullet.indent")
                    }

                    NavigationLink {
                        SettingsAboutView()
                    } label: {
                        Label(.settingsAbout, systemImage: "info.circle")
                    }
                } header: {
                    Text(.settingsGeneral)
                }

                Section {
                    Button(action: {}) {
                        Label(.switchAccount, systemImage: "person.2")
                    }

                    Button(role: .destructive, action: {}) {
                        Label(.logOut, systemImage: "door.right.hand.open")
                    }.foregroundStyle(.red)
                }
            }
            .navigationTitle(.settings)
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
