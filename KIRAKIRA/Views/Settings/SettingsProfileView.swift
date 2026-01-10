//
//  SettingsProfileView.swift
//  KIRAKIRA
//
//  Created by Aira Sakuranomiya on 2025/11/12.
//

import SwiftUI

struct SettingsProfileView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var isEdited = false
    @State private var isShowingConfirmationDialog = false

    @State private var username: String = "Aira"
    @State private var name: String = "艾了个拉"
    @State private var bio: String = "Kawaii Forever!~\nwow"
    @State private var birthday: Date = Date()
    @State private var avatarURL = URL(
        string:
            "https://kirafile.com/cdn-cgi/imagedelivery/Gyz90amG54C4b_dtJiRpYg/avatar-1-xiQgrY2SDDx68HbIH8LSSBZqDpbSOFBf-1722666535442/f=avif"
    )
    
    private let bioMaxLength = 200

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
                LabeledContent {
                    TextField(
                        .settingsProfileUsername,
                        text: $username
                    )
                } label: {
                    Text(verbatim: "@")
                }
                .fontDesign(.monospaced)

                TextField(
                    .settingsProfileNickname,
                    text: $name
                )
            }

            Section {
                TextField(
                    .settingsProfileBio,
                    text: $bio,
                    axis: .vertical
                )
            } footer: {
                HStack {
                    Spacer()
                    Text(verbatim: "\(bio.count) / \(bioMaxLength)")
                        .foregroundStyle(bio.count > bioMaxLength ? .red : .secondary)
                        .monospacedDigit()
                }
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
        .navigationBarBackButtonHidden(isEdited)
        .interactiveDismissDisabled(isEdited)
        .toolbar {
            if isEdited {
                ToolbarItem(placement: .cancellationAction) {
                    Button(
                        role: .cancel,
                        action: { isShowingConfirmationDialog = true }
                    ) {
                        Image(systemName: "chevron.backward")
                            .fontWeight(.semibold)
                    }
                    .confirmationDialog(
                        .discardChangesDescription, isPresented: $isShowingConfirmationDialog, titleVisibility: .visible
                    ) {
                        Button(.discardChanges, role: .destructive, action: { dismiss() })
                    }
                }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button(.actionOk, systemImage: "checkmark", role: .confirm, action: {})
                    .disabled(!isEdited)
            }
        }
        .scrollDismissesKeyboard(.interactively)
        .onChange(of: [username, name, bio]) {
            isEdited = true
        }
        .onChange(of: birthday) {
            isEdited = true
        }
        .onChange(of: avatarURL) {
            isEdited = true
        }
    }
}

#Preview {
    SettingsProfileView()
}
