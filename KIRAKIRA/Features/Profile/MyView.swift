import SwiftUI

struct MyView: View {
    @Environment(AppRouter.self) private var appRouter
    @Environment(AuthManager.self) private var authManager
    @State private var screenModel: MyScreenModel
    private let profileRepository: ProfileRepository

    let avatarSize: CGFloat = 60
    let userInfoSpacing: CGFloat = 8

    init(profileRepository: ProfileRepository) {
        self.profileRepository = profileRepository
        _screenModel = State(initialValue: MyScreenModel(repository: profileRepository))
    }

    var body: some View {
        List {
            if authManager.isAuthenticated, let dashboard = screenModel.dashboard {
                Section {
                    NavigationLink {
                        UserView(profileRepository: profileRepository)
                    } label: {
                        HStack(spacing: userInfoSpacing) {
                            profileAvatar(dashboard.profile.avatarImageID)

                            VStack(alignment: .leading, spacing: 4) {
                                Text(verbatim: dashboard.profile.displayName)
                                    .font(.title3)
                                    .bold()

                                Text(verbatim: "@\(dashboard.profile.username)")
                                    .font(.footnote)
                                    .fontDesign(.monospaced)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }

                Section {
                    NavigationLink {
                        MyNotificationsView(profileRepository: profileRepository)
                    } label: {
                        Label(.notifications, systemImage: "bell")
                            .badge(dashboard.notificationCount)
                    }

                    NavigationLink {
                        MyMessagesView()
                    } label: {
                        Label(.messages, systemImage: "message")
                            .badge(dashboard.messageCount)
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
            } else if authManager.isAuthenticated, screenModel.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, alignment: .center)
            } else if authManager.isAuthenticated, let errorMessage = screenModel.errorMessage {
                ErrorView(errorMessage: errorMessage) {
                    Task {
                        await screenModel.load()
                    }
                }
            } else {
                Button(action: { appRouter.isShowingLogin = true }) {
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
                    appRouter.isShowingSettings = true
                }
            }
        }
        .task(id: authManager.isAuthenticated) {
            await screenModel.loadIfAuthenticated(authManager.isAuthenticated)
        }
    }

    @ViewBuilder
    private func profileAvatar(_ imageID: String?) -> some View {
        if let imageID {
            Image(imageID)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: avatarSize, height: avatarSize)
                .clipShape(Circle())
        } else {
            Image(systemName: "person.crop.circle")
                .resizable()
                .frame(width: avatarSize, height: avatarSize)
        }
    }
}

#Preview(traits: .commonPreviewTrait) {
    MyView(profileRepository: AppDependencies(sessionStore: .shared).profileRepository)
}
