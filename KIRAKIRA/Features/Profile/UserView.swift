import RichText
import SwiftUI

struct UserView: View {
    @State private var screenModel: UserScreenModel

    init(userID: Int? = nil, profileRepository: ProfileRepository) {
        _screenModel = State(initialValue: UserScreenModel(userID: userID, repository: profileRepository))
    }

    var body: some View {
        ScrollView {
            BannerView()
                .padding(.bottom, -74)
                .onScrollVisibilityChange { visible in
                    screenModel.isBannerVisible = visible
                }

            if screenModel.isLoading {
                ProgressView()
                    .padding()
            } else if let errorMessage = screenModel.errorMessage {
                ErrorView(errorMessage: errorMessage) {
                    Task {
                        await screenModel.load()
                    }
                }
                .padding()
            } else if let profile = screenModel.profile {
                profileContent(profile)
            }
        }
        .toolbar {
            if let profile = screenModel.profile, !screenModel.isUsernameVisible {
                ToolbarItem(placement: .principal) {
                    VStack {
                        Text(verbatim: profile.displayName)
                        Text(verbatim: "@\(profile.username)")
                            .foregroundStyle(.secondary)
                            .font(.caption)
                            .fontDesign(.monospaced)
                    }
                }
            }
            if let profile = screenModel.profile, !profile.isSelf {
                ToolbarItemGroup {
                    Menu {
                        ControlGroup {
                            Button(
                                profile.isFollowing ? .userFollowing : .userFollow,
                                systemImage: profile.isFollowing ? "checkmark.circle" : "plus.circle",
                                action: { withAnimation { screenModel.toggleFollowing() } }
                            )
                            Button(.message, systemImage: "message", action: {})
                            Button(.share, systemImage: "square.and.arrow.up", action: {})
                        }
                        Button(.report, systemImage: "exclamationmark.bubble", action: {})
                        Button(.userBlock, systemImage: "nosign", action: {})
                        Button(.userHide, systemImage: "eye.slash", action: {})
                    } label: {
                        Image(systemName: "ellipsis")
                    }
                }
            }
        }
        #if !os(macOS)
            .navigationBarTitleDisplayMode(.inline)
        #endif
        .ignoresSafeArea(edges: .top)
        .scrollEdgeEffectHidden(screenModel.isBannerVisible, for: .top)
        .task {
            await screenModel.load()
        }
    }

    @ViewBuilder
    private func profileContent(_ profile: UserProfile) -> some View {
        VStack(spacing: 16) {
            VStack {
                Button(action: {}) {
                    avatarView(imageID: profile.avatarImageID)
                }
                .buttonStyle(.plain)
                .sheet(isPresented: $screenModel.isShowingEditProfileSheet) {
                    NavigationStack {
                        SettingsProfileView()
                            #if !os(macOS)
                                .navigationBarTitleDisplayMode(.inline)
                            #endif
                            .toolbar {
                                ToolbarItem(placement: .cancellationAction) {
                                    Button(action: {
                                        screenModel.isShowingEditProfileSheet = false
                                    }) {
                                        Image(systemName: "xmark")
                                    }
                                }
                            }
                    }
                }

                Text(verbatim: profile.displayName)
                    .font(.title)
                    .bold()

                Text(verbatim: "@\(profile.username)")
                    .foregroundStyle(.secondary)
                    .fontDesign(.monospaced)
            }
            .onScrollVisibilityChange { visible in
                withAnimation {
                    screenModel.isUsernameVisible = visible
                }
            }

            TextView(verbatim: profile.bio)
                .fontWeight(.medium)

            HStack(spacing: 16) {
                Button(.userFollowingCount(count: profile.followingCount), action: {})
                Button(.userFollowersCount(count: profile.followerCount), action: {})
            }

            HStack {
                Button(.message, systemImage: "message", action: {})
                    .labelStyle(.iconOnly)
                    .buttonBorderShape(.circle)
                    .padding(.horizontal, -6.5)

                if profile.isSelf {
                    Button(.userEditProfile, action: { screenModel.isShowingEditProfileSheet = true })
                } else {
                    Button(
                        role: profile.isFollowing ? .cancel : .confirm,
                        action: { withAnimation { screenModel.toggleFollowing() } }
                    ) {
                        Label(
                            profile.isFollowing ? .userFollowing : .userFollow,
                            systemImage: profile.isFollowing ? "checkmark" : "plus"
                        )
                    }
                }
            }
            .buttonStyle(.bordered)
            .tint(.accent)
            .fontWeight(.medium)
            .controlSize(.large)
        }
        .padding()
        .textSelection(.enabled)
        .multilineTextAlignment(.center)

        LazyVStack {
            Section {
                switch screenModel.selectedTab {
                case .videos:
                    LazyVStack {
                        ForEach(1...100, id: \.self) { _ in
                            Text(verbatim: "VIDEOS PAGE")
                        }
                    }
                case .collections:
                    LazyVStack {
                        ForEach(1...100, id: \.self) { _ in
                            Text(verbatim: "COLLECTIONS PAGE")
                        }
                    }
                }
            } header: {
                Picker(.userTabPicker, selection: $screenModel.selectedTab) {
                    Text(.videos).tag(UserScreenModel.Tab.videos)
                    Text(.userCollections).tag(UserScreenModel.Tab.collections)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
            }
        }
    }

    @ViewBuilder
    private func avatarView(imageID: String?) -> some View {
        if let imageID {
            Image(imageID)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 100, height: 100)
                .clipShape(Circle())
        } else {
            Image(systemName: "person.crop.circle")
                .resizable()
                .frame(width: 100, height: 100)
        }
    }
}

#Preview {
    NavigationStack {
        UserView(profileRepository: AppDependencies(sessionStore: .shared).profileRepository)
    }
    .environment(\.locale, .init(identifier: "en"))
}
