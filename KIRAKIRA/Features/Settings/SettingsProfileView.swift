import SwiftUI

struct SettingsProfileView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var isEdited = false
    @State private var isShowingConfirmationDialog = false

    @State private var username: String
    @State private var name: String
    @State private var bio: String
    @State private var birthday: Date?
    @State private var avatarId: String?
    @State private var bannerId: String?

    private let bioMaxLength = 200

    init() {
        let account = AuthManager.shared.credentials
        _username = State(initialValue: account?.username ?? "")
        _name = State(initialValue: account?.userNickname ?? "")
        _bio = State(initialValue: account?.signature ?? "")
        _birthday = State(initialValue: Self.parseBirthday(account?.userBirthday))
        _avatarId = State(initialValue: account?.avatar)
        _bannerId = State(initialValue: account?.userBannerImage)
    }

    var body: some View {
        Form {
            Section {
                Button(action: {}) {
                    BannerView(imageId: bannerId)
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
                    UserAvatarView(imageId: avatarId)
                        .frame(width: 128, height: 128)
                        .glassEffect(.regular.interactive())
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
                if birthday != nil {
                    DatePicker(
                        .settingsProfileBirthday,
                        selection: Binding(
                            get: { birthday ?? Date() },
                            set: { birthday = $0 }
                        ),
                        displayedComponents: [.date]
                    )
                } else {
                    LabeledContent(.settingsProfileBirthday) {
                        Text(verbatim: "—")
                            .foregroundStyle(.secondary)
                    }
                }
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
        .scrollDismissesKeyboard(.immediately)
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

    private static func parseBirthday(_ value: String?) -> Date? {
        guard let value else { return nil }
        let components = value.prefix(10).split(separator: "-").compactMap { Int($0) }
        guard components.count == 3 else { return nil }
        return Calendar(identifier: .gregorian).date(
            from: DateComponents(year: components[0], month: components[1], day: components[2])
        )
    }
}

#Preview {
    SettingsProfileView()
}
