import SwiftUI

struct SettingsSwitchAccountView: View {
    @State private var isShowingLogin = false
    @State private var selection: String = "guest"
    @State private var users = ["Endministrator", "Perlica", "Chen Qianyu"]
    private let hStackSpacing: CGFloat = 12

    func delete(at offsets: IndexSet) {
        users.remove(atOffsets: offsets)
    }

    var body: some View {
        List {
            Group {
                Button(action: { selection = "guest" }) {
                    HStack(spacing: hStackSpacing) {
                        Image(systemName: "person.crop.circle")
                            .resizable()
                            .frame(width: 50, height: 50)
                            .foregroundStyle(.secondary)
                        Text(.guest)

                        Spacer()

                        checkmark
                            .symbolEffect(.drawOn, isActive: selection != "guest")
                    }
                }

                ForEach(users, id: \.self) { user in
                    Button(action: { selection = user }) {
                        HStack(spacing: hStackSpacing) {
                            Image(systemName: "person.crop.circle")  // TODO: 显示用户头像
                                .resizable()
                                .frame(width: 50, height: 50)
                                .foregroundStyle(.secondary)
                            Text(verbatim: user)

                            Spacer()

                            checkmark
                                .symbolEffect(.drawOn, isActive: selection != user)
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
                EditButton()
            }
        }
    }

    var checkmark: some View {
        Image(systemName: "checkmark")
            .foregroundStyle(.accent)
            .fontWeight(.semibold)
    }
}

#Preview(traits: .commonPreviewTrait) {
    SettingsSwitchAccountView()
}
