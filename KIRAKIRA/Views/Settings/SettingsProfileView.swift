//
//  SettingsProfileView.swift
//  KIRAKIRA
//
//  Created by Aira Sakuranomiya on 2025/11/12.
//

import SwiftUI

struct SettingsProfileView: View {
    @State private var username: String = ""
    @State private var name: String = ""
    @State private var bio: String = ""
    @State private var birthday: Date = Date()
    @State private var avatarURL = URL(
        string:
            "https://kirafile.com/cdn-cgi/imagedelivery/Gyz90amG54C4b_dtJiRpYg/avatar-1-xiQgrY2SDDx68HbIH8LSSBZqDpbSOFBf-1722666535442/f=avif"
    )

    var body: some View {
        List {
            VStack {
                AsyncImage(
                    url: avatarURL,
                    transaction: .init(animation: .default)
                ) { phase in
                    switch phase {
                    case .empty:
                        ZStack {
                            Circle().fill(Color.gray.opacity(0.15))
                            ProgressView()
                        }
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                    case .failure:
                        Image(systemName: "person.crop.circle.fill")
                            .resizable()
                            .scaledToFit()
                            .foregroundStyle(.secondary)
                    @unknown default:
                        Color.clear
                    }
                }
                .frame(width: 128, height: 128)
                .clipShape(Circle())
                //				.overlay(Circle().stroke(.secondary.opacity(0.3), lineWidth: 1))
                //				.padding(.vertical, 8)
                .glassEffect(.regular.interactive())
            }
            .padding(.vertical, 24)
            .frame(maxWidth: .infinity)
            .listRowBackground(Color.clear)

            Section {
                TextField(
                    .settingsProfileUsername,
                    text: $username
                )
                TextField(
                    .settingsProfileNickname,
                    text: $name
                )
                TextField(
                    .settingsProfileBio,
                    text: $bio
                )
            }

            Section {
                DatePicker(
                    .settingsProfileBirthday,
                    selection: $birthday,
                    displayedComponents: [.date]
                )
            }
        }
        .navigationTitle(.settingsProfile)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button(.actionOk, systemImage: "checkmark", role: .confirm, action: {})
            }
        }
    }
}

#Preview {
    SettingsProfileView()
}
