import SwiftUI

struct MyView: View {
    @Environment(GlobalStateManager.self) private var globalStateManager
    @State private var authManager = AuthManager.shared

    let avatarSize: CGFloat = 60
    let userInfoSpacing: CGFloat = 8

    var body: some View {
        NavigationStack {
            List {
                if authManager.isAuthenticated {
                    Section {
                        NavigationLink {
                            UserView()
                        } label: {
                            HStack(spacing: userInfoSpacing) {
                                Image("SamplePortrait")
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: avatarSize, height: avatarSize)
                                    .clipShape(Circle())

                                VStack(alignment: .leading, spacing: 4) {
                                    Text(verbatim: "艾了个拉")
                                        .font(.title3)
                                        .bold()

                                    Text(verbatim: "@Aira")
                                        .font(.footnote)
                                        .fontDesign(.monospaced)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                    }

                    Section {
                        NavigationLink {
                            MyNotificationsView()
                        } label: {
                            Label(.notifications, systemImage: "bell")
                                .badge(3)
                        }

                        NavigationLink {
                            MyMessagesView()
                        } label: {
                            Label(.messages, systemImage: "message")
                                .badge(10)
                        }
                    }

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
                .contentMargins(.top, 20)
            #endif
            .navigationTitle(.maintabMy)
            .toolbarTitleDisplayMode(.inlineLarge)
            .toolbar {
                ToolbarItem {
                    Button(.settings, systemImage: "gear") {
                        globalStateManager.isShowingSettings = true
                    }
                }
            }
        }
    }
}

#Preview(traits: .commonPreviewTrait) {
    MyView()
}
