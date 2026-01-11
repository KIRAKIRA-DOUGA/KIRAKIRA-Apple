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
    @State private var avatarId = "avatar-1-xiQgrY2SDDx68HbIH8LSSBZqDpbSOFBf-1722666535442"

    private let bioMaxLength = 200

    var body: some View {
        Form {
            Section {
                Button(action: {}) {
                    BannerView()
                }
                .buttonStyle(.plain)
            }
            .listRowBackground(Color.clear)
            .listRowInsets(.all, 0)
            .listRowSeparator(.hidden)
            .listSectionMargins(.all, 0)
            .listSectionSpacing(0)

            Section {
                Button(action: {}) {
                    CFImageView(imageId: avatarId)
                        .frame(width: 128, height: 128)
                        .clipShape(.circle)
                }.buttonStyle(.plain)
            }
            .padding(.bottom, 24)
            .frame(maxWidth: .infinity)
            .listRowBackground(Color.clear)
            .listRowInsets(.vertical, 0)
            .listRowSeparator(.hidden)
            .listSectionMargins(.all, 0)

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
        .scrollEdgeEffectHidden(true, for: .top)
        .interactiveDismissDisabled(isEdited)
        .toolbar {
            if isEdited {
                ToolbarItem(placement: .cancellationAction) {
                    Button(
                        role: .cancel,
                        action: { isShowingConfirmationDialog = true }
                    ) {
                        Image(systemName: "xmark")
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
        .contentMargins(.top, 0)
        .ignoresSafeArea(edges: .top)
        .scrollDismissesKeyboard(.interactively)
        .onChange(of: [username, name, bio]) {
            isEdited = true
        }
        .onChange(of: birthday) {
            isEdited = true
        }
        .onChange(of: avatarId) {
            isEdited = true
        }
    }
}

#Preview {
    SettingsProfileView()
}
