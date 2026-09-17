import SwiftUI

struct SettingsSwitchAccountView: View {
    @State private var isShowingLogin = false
    @State private var authManager = AuthManager.shared
    private let hStackSpacing: CGFloat = 12

    func delete(at offsets: IndexSet) {
        authManager.removeAccounts(at: offsets)
    }

    var body: some View {
        List {
            Group {
                Button(action: { authManager.continueAsGuest() }) {
                    HStack(spacing: hStackSpacing) {
                        Image(systemName: "person.crop.circle")
                            .resizable()
                            .frame(width: 50, height: 50)
                            .foregroundStyle(.secondary)
                        Text(.guest)

                        Spacer()

                        if !authManager.isAuthenticated { checkmark }
                    }
                }

                ForEach(authManager.accounts) { account in
                    Button(action: { authManager.switchAccount(to: account.id) }) {
                        HStack(spacing: hStackSpacing) {
                            accountAvatar(account)

                            VStack(alignment: .leading, spacing: 3) {
                                Text(verbatim: account.displayName)
                                if let username = account.username, !username.isEmpty {
                                    Text(verbatim: "@\(username)")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }

                            Spacer()

                            if authManager.credentials?.id == account.id { checkmark }
                        }
                    }
                }
                .onDelete(perform: delete)
            }
            .foregroundStyle(.opacity(1))  // HACK: 让按钮不使用强调色，不用.primary是因为它其实会让不透明度降低。

            Button(.addAccount, systemImage: "plus") {
                isShowingLogin = true
            }
            .sheet(isPresented: $isShowingLogin) {
                AuthView()
            }
        }
        .navigationTitle(.switchAccount)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                if !authManager.accounts.isEmpty { EditButton() }
            }
        }
        .task {
            await authManager.refreshAccountProfiles()
        }
    }

    var checkmark: some View {
        Image(systemName: "checkmark")
            .foregroundStyle(.accent)
            .fontWeight(.semibold)
    }

    @ViewBuilder
    private func accountAvatar(_ account: Credentials) -> some View {
        UserAvatarView(imageId: account.avatar)
            .frame(width: 50, height: 50)
    }
}

#Preview(traits: .commonPreviewTrait) {
    SettingsSwitchAccountView()
}
