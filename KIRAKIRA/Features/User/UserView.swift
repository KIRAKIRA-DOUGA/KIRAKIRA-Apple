import RichText
import SwiftUI

struct UserView: View {
    let uid: Int?
    let animationNamespace: Namespace.ID

    @Environment(GlobalStateManager.self) private var globalStateManager
    @State private var authManager = AuthManager.shared
    @State private var viewModel = UserProfileViewModel()
    @State private var avatarTransitionSource = ZoomTransitionSource()

    @State private var showingView: UserViewTab = .videos
    @State private var isShowingBlockConfirmation = false
    @State private var isShowingHideConfirmation = false
    @State private var isBannerVisible = true
    @State private var isUsernameVisible = true

    init(uid: Int? = nil, animationNamespace: Namespace.ID) {
        self.uid = uid
        self.animationNamespace = animationNamespace
    }

    private var resolvedUID: Int? { uid ?? authManager.credentials?.uid }

    var body: some View {
        Group {
            if let resolvedUID {
                userContent(uid: resolvedUID)
            } else {
                ContentUnavailableView {
                    Label(.userLoginRequiredTitle, systemImage: "person.crop.circle.badge.questionmark")
                } description: {
                    Button(.logIn) {
                        globalStateManager.isShowingLogin = true
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
        }
        .task(id: resolvedUID) {
            guard let resolvedUID else { return }
            await viewModel.load(uid: resolvedUID)
        }
        .onChange(of: globalStateManager.isShowingSettings) { wasPresented, isPresented in
            guard wasPresented, !isPresented, let resolvedUID else { return }
            Task { await viewModel.load(uid: resolvedUID) }
        }
        .confirmationDialog(
            String(localized: .userBlockConfirmTitle),
            isPresented: $isShowingBlockConfirmation,
            titleVisibility: .visible
        ) {
            Button(.userBlock, role: .destructive) {
                Task { await viewModel.toggleBlock() }
            }
            Button(.actionCancel, role: .cancel) {}
        } message: {
            Text(.userBlockConfirmMessage)
        }
        .confirmationDialog(
            String(localized: .userHideConfirmTitle),
            isPresented: $isShowingHideConfirmation,
            titleVisibility: .visible
        ) {
            Button(.userHide, role: .destructive) {
                Task { await viewModel.toggleHidden() }
            }
            Button(.actionCancel, role: .cancel) {}
        } message: {
            Text(.userHideConfirmMessage)
        }
        .alert(
            String(localized: .errorOperationFailed),
            isPresented: Binding(
                get: { viewModel.errorMessage != nil },
                set: { if !$0 { viewModel.clearError() } }
            )
        ) {
            Button(.actionOk) { viewModel.clearError() }
        } message: {
            Text(viewModel.errorMessage ?? String(localized: .errorRequestFailed))
        }
        #if !os(macOS)
            .navigationBarTitleDisplayMode(.inline)
        #endif
    }

    @ViewBuilder
    private func userContent(uid: Int) -> some View {
        switch viewModel.profileState {
        case .idle, .loading(previous: nil):
            LoadingView()
                .refreshable { await viewModel.load(uid: uid) }
        case .success(let profile), .loading(previous: .some(let profile)):
            profileContent(profile: profile, uid: uid)
                .refreshable {
                    await viewModel.load(uid: uid)
                }
                .toolbar { toolbarContent(profile: profile) }
                .ignoresSafeArea(edges: .top)
                .scrollEdgeEffectHidden(isBannerVisible, for: .top)
        case .empty:
            blockedContent(uid: uid)
        case .error(let message):
            ErrorView(errorMessage: message)
                .refreshable { await viewModel.load(uid: uid) }
        }
    }

    @ViewBuilder
    private func profileContent(profile: PublicUserProfile, uid: Int) -> some View {
        profileScrollView(profile: profile, uid: uid) {
            switch showingView {
            case .videos:
                videosContent(profile: profile, uid: uid)
                    .transition(.opacity)
            case .collections:
                ContentUnavailableView(
                    String(localized: .userCollections),
                    systemImage: "star"
                )
                .frame(minHeight: 240)
                .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.2), value: showingView)
    }

    private func profileScrollView<Content: View>(
        profile: PublicUserProfile,
        uid: Int,
        @ViewBuilder content: () -> Content
    ) -> some View {
        ScrollView {
            profileHeader(profile: profile, uid: uid)
            content()
        }
    }

    private func profileHeader(profile: PublicUserProfile, uid: Int) -> some View {
        VStack(spacing: 0) {
            BannerView(imageId: profile.userBannerImage)
                .padding(.bottom, -74)
                .onScrollVisibilityChange { isBannerVisible = $0 }

            VStack(spacing: 16) {
                VStack(spacing: 6) {
                    ZoomTransitionSourceImageView(
                        imageURL: CFImageURLBuilder.url(for: profile.avatar, pixelWidth: 240),
                        source: avatarTransitionSource
                    ) {
                        guard let imageURL = CFImageURLBuilder.url(for: profile.avatar) else { return }
                        LargeImageViewerPresenter.present(
                            imageURL: imageURL,
                            title: profile.displayName,
                            source: avatarTransitionSource
                        )
                    }
                    .frame(width: 100, height: 100)
                    .allowsHitTesting(profile.avatar?.isEmpty == false)
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel(Text(.userAvatarPreviewAccessibility))
                    .accessibilityAddTraits(.isButton)

                    Text(verbatim: profile.displayName)
                        .font(.title)
                        .bold()

                    if let username = profile.username, !username.isEmpty {
                        Text(verbatim: "@\(username)")
                            .foregroundStyle(.secondary)
                            .fontDesign(.monospaced)
                    }
                }
                .onScrollVisibilityChange { visible in
                    withAnimation { isUsernameVisible = visible }
                }

                if let signature = profile.signature, !signature.isEmpty {
                    TextView(verbatim: signature)
                        .fontWeight(.medium)
                }

                if viewModel.isBlockedByOther {
                    Label(.userBlockedByTarget, systemImage: "nosign")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                } else if viewModel.isHidden {
                    Label(.userHiddenStatus, systemImage: "eye.slash")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                }

                HStack(spacing: 16) {
                    NavigationLink {
                        UserFollowListView(
                            uid: uid,
                            kind: .following,
                            animationNamespace: animationNamespace
                        )
                    } label: {
                        Text(.userFollowingCount(count: viewModel.followingCount ?? 0))
                    }

                    NavigationLink {
                        UserFollowListView(
                            uid: uid,
                            kind: .followers,
                            animationNamespace: animationNamespace
                        )
                    } label: {
                        Text(.userFollowersCount(count: viewModel.followerCount ?? 0))
                    }
                }

                mainActions(profile: profile)
            }
            .padding()
            .textSelection(.enabled)
            .multilineTextAlignment(.center)

            Picker(
                .userTabPicker,
                selection: Binding(
                    get: { showingView },
                    set: { newValue in
                        withAnimation(.easeInOut(duration: 0.2)) {
                            showingView = newValue
                        }
                    }
                )
            ) {
                Text(.videos).tag(UserViewTab.videos)
                Text(.userCollections).tag(UserViewTab.collections)
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)
            .padding(.bottom, 16)
        }
    }

    @ViewBuilder
    private func mainActions(profile: PublicUserProfile) -> some View {
        HStack {
            if viewModel.isSelf {
                Button(.userEditProfile) {
                    globalStateManager.showSettings(destination: .profile)
                }
            } else {
//                Button(.message, systemImage: "message") {}
//                    .labelStyle(.iconOnly)
//                    .buttonBorderShape(.circle)

                Button {
                    requireAuthentication {
                        Task { await viewModel.toggleFollow() }
                    }
                } label: {
                    if viewModel.isRelationshipLoading {
                        ProgressView()
                            .controlSize(.regular)
                    } else {
                        Label(
                            viewModel.isFollowing ? .userFollowing : .userFollow,
                            systemImage: viewModel.isFollowing ? "checkmark" : "plus"
                        )
                    }
                }
                .disabled(viewModel.isBlocked || viewModel.isBlockedByOther)
            }
        }
        .buttonStyle(.bordered)
        .tint(.accent)
        .fontWeight(.medium)
        .controlSize(.large)
    }

    @ViewBuilder
    private func videosContent(profile: PublicUserProfile, uid: Int) -> some View {
        switch viewModel.videosState {
        case .idle, .loading(previous: nil):
            ProgressView()
                .controlSize(.regular)
                .frame(maxWidth: .infinity, minHeight: 160)
        case .success(let videos), .loading(previous: .some(let videos)):
            VideoListView(
                videos: videos,
                animationNamespace: animationNamespace,
                uploaderNameOverride: profile.displayName,
                isEmbedded: true
            ) {
                EmptyView()
            }
        case .empty:
            ContentUnavailableView(
                String(localized: .userNoVideos),
                systemImage: "play.rectangle.on.rectangle"
            )
            .frame(minHeight: 240)
        case .error(let message):
            ContentUnavailableView {
                Label(message, systemImage: "exclamationmark.triangle")
            } description: {
                Button(.errorTryAgain) {
                    Task { await viewModel.load(uid: uid) }
                }
            }
            .frame(minHeight: 240)
        }
    }

    @ToolbarContentBuilder
    private func toolbarContent(profile: PublicUserProfile) -> some ToolbarContent {
        if !isUsernameVisible {
            ToolbarItem(placement: .principal) {
                VStack(spacing: 0) {
                    Text(verbatim: profile.displayName)
                    if let username = profile.username, !username.isEmpty {
                        Text(verbatim: "@\(username)")
                            .foregroundStyle(.secondary)
                            .font(.caption)
                            .fontDesign(.monospaced)
                    }
                }
            }
        }

        if !viewModel.isSelf {
            ToolbarItem {
                Menu {
                    Button {
                        requireAuthentication {
                            if viewModel.isHidden {
                                Task { await viewModel.toggleHidden() }
                            } else {
                                isShowingHideConfirmation = true
                            }
                        }
                    } label: {
                        Label(
                            viewModel.isHidden
                                ? String(localized: .userUnhide)
                                : String(localized: .userHide),
                            systemImage: viewModel.isHidden ? "eye" : "eye.slash"
                        )
                    }

                    Button(role: viewModel.isBlocked ? nil : .destructive) {
                        requireAuthentication {
                            if viewModel.isBlocked {
                                Task { await viewModel.toggleBlock() }
                            } else {
                                isShowingBlockConfirmation = true
                            }
                        }
                    } label: {
                        Label(
                            viewModel.isBlocked
                                ? String(localized: .userUnblock)
                                : String(localized: .userBlock),
                            systemImage: viewModel.isBlocked ? "person.crop.circle.badge.checkmark" : "nosign"
                        )
                    }
                } label: {
                    Image(systemName: "ellipsis")
                }
                .disabled(viewModel.isRelationshipLoading)
            }
        }
    }

    private func blockedContent(uid: Int) -> some View {
        ContentUnavailableView {
            Label(
                viewModel.isBlocked
                    ? String(localized: .userBlockedStatus)
                    : String(localized: .userUnavailable),
                systemImage: "nosign"
            )
        } description: {
            if viewModel.isBlocked {
                Button {
                    Task { await viewModel.toggleBlock() }
                } label: {
                    if viewModel.isRelationshipLoading {
                        ProgressView()
                            .controlSize(.regular)
                    } else {
                        Text(.userUnblock)
                    }
                }
                .buttonStyle(.bordered)
            } else {
                Button(.errorTryAgain) {
                    Task { await viewModel.load(uid: uid) }
                }
            }
        }
    }

    private func requireAuthentication(_ action: () -> Void) {
        if authManager.isAuthenticated {
            action()
        } else {
            globalStateManager.isShowingLogin = true
        }
    }
}

private enum UserViewTab: Hashable {
    case videos
    case collections
}

#Preview {
    @Previewable @Namespace var animationNamespace
    NavigationStack {
        UserView(uid: 1, animationNamespace: animationNamespace)
    }
    .environment(GlobalStateManager())
    .environment(\.locale, .init(identifier: "zh-Hans"))
}
