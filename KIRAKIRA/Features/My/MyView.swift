import SwiftUI

struct MyView: View {
    @Environment(GlobalStateManager.self) private var globalStateManager
    @State private var authManager = AuthManager.shared
    let animationNamespace: Namespace.ID

    let avatarSize: CGFloat = 60
    let userInfoSpacing: CGFloat = 8

    var body: some View {
        NavigationStack {
            List {
                if authManager.isAuthenticated {
                    Section {
                        NavigationLink {
                            UserView(animationNamespace: animationNamespace)
                        } label: {
                            HStack(spacing: userInfoSpacing) {
                                UserAvatarView(imageId: authManager.credentials?.avatar)
                                    .frame(width: avatarSize, height: avatarSize)

                                VStack(alignment: .leading, spacing: 4) {
                                    Text(verbatim: authManager.credentials?.displayName ?? authManager.credentials?.email ?? "")
                                        .font(.title3)
                                        .bold()

                                    if let username = authManager.credentials?.username, !username.isEmpty {
                                        Text(verbatim: "@\(username)")
                                            .font(.footnote)
                                            .fontDesign(.monospaced)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                            }
                        }
                    }

//                    Section {
//                        NavigationLink {
//                            MyNotificationsView()
//                        } label: {
//                            Label(.notifications, systemImage: "bell")
//                                .badge(3)
//                        }
//
//                        NavigationLink {
//                            MyMessagesView()
//                        } label: {
//                            Label(.messages, systemImage: "message")
//                                .badge(10)
//                        }
//                    }

                    Section {
                        NavigationLink {
                            MyCollectionsView()
                        } label: {
                            Label(.userCollections, systemImage: "star")
                        }

                        NavigationLink {
                            MyHistoryView()
                        } label: {
                            Label(.userHistory, systemImage: "clock.arrow.trianglehead.counterclockwise.rotate.90")
                        }
                    }
                } else {
                    Button(action: { globalStateManager.isShowingLogin = true }) {  // TODO: 打开登录fullscreenCover
                        HStack(spacing: userInfoSpacing) {
                            Image(systemName: "person.crop.circle")
                                .resizable()
                                .frame(width: avatarSize, height: avatarSize)
                            Text(.logIn)
                                .font(.title3)
                                .bold()
                        }
                    }
                }

            }
            #if os(iOS)
                .contentMargins(.top, 16)
            #endif
            .navigationTitle(.maintabMy)
            .toolbarTitleDisplayMode(.inlineLarge)
            .toolbar {
                ToolbarItem {
                    Button(.settings, systemImage: "gear") {
                        globalStateManager.showSettings()
                    }
                }
            }
        }
    }
}

#Preview(traits: .commonPreviewTrait) {
    @Previewable @Namespace var animationNamespace
    MyView(animationNamespace: animationNamespace)
}
