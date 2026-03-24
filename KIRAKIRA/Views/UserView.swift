import SwiftUI
import RichText

struct UserView: View {
    @Namespace private var namespace

    @State private var isSelf = false
    @State private var isFollowing = false

    @State private var showingView: ViewTab = .videos
    @State private var isShowingFollowDialog = false
    @State private var isShowingFollowingDialog = false
    @State private var isShowingEditProfileSheet = false

    @State private var isBannerVisible = true  // for hide scroll edge effect
    @State private var isUsernameVisble = true  // for toolbar content control

    @State private var userName: String = "艾了个拉"
    @State private var userUsername = "Aira"

    var body: some View {
        ScrollView {
            // Banner
            BannerView()
                .padding(.bottom, -74)
                .onScrollVisibilityChange { visible in
                    if visible {
                        isBannerVisible = true
                    } else {
                        isBannerVisible = false
                    }
                }

            VStack(spacing: 16) {
                VStack {
                    // Avatar
                    Button(action: {}) {
                        Image("SamplePortrait")
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 100, height: 100)
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                    .sheet(isPresented: $isShowingEditProfileSheet) {
                        NavigationStack {
                            SettingsProfileView()
                                #if !os(macOS)
                                    .navigationBarTitleDisplayMode(.inline)
                                #endif
                                .toolbar {
                                    ToolbarItem(placement: .cancellationAction) {
                                        Button(action: {
                                            isShowingEditProfileSheet = false
                                        }) {
                                            Image(systemName: "xmark")
                                        }
                                    }
                                }
                        }
                    }

                    // Name
                    Text(verbatim: "\(userName)")
                        .font(.title)
                        .bold()

                    // Username
                    Text(verbatim: "@\(userUsername)")
                        .foregroundStyle(.secondary)
                        .fontDesign(.monospaced)
                }
                .onScrollVisibilityChange { visible in
                    if visible {
                        withAnimation {
                            isUsernameVisble = true
                        }
                    } else {
                        withAnimation {
                            isUsernameVisble = false
                        }
                    }
                }

                // Bio
                TextView("Kawaii Forever!~")
                    .fontWeight(.medium)

                // Follower Info
                HStack(spacing: 16) {
                    Button(.userFollowingCount(count: 233), action: {})
                    Button(.userFollowersCount(count: 233), action: {})
                }

                // Main Actions
                HStack {
                    Button(.message, systemImage: "message", action: {})
                        .labelStyle(.iconOnly)
                        .buttonBorderShape(.circle)
                        .padding(.horizontal, -6.5)  // 我实在是不理解SwiftUI为啥设置了圆形按钮后还保留原本药丸形状的大小？何意味？

                    if isSelf {
                        Button(.userEditProfile, action: { isShowingEditProfileSheet = true })
                    } else {
                        Button(
                            role: isFollowing ? .cancel : .confirm,
                            action: { withAnimation { isFollowing.toggle() } }
                        ) {
                            Label(
                                isFollowing ? .userFollowing : .userFollow,
                                systemImage: isFollowing ? "checkmark" : "plus"
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
                    switch showingView {
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
                    Picker(.userTabPicker, selection: $showingView) {
                        Text(.videos).tag(ViewTab.videos)
                        Text(.userCollections).tag(ViewTab.collections)
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal)
                }
            }
        }
        .toolbar {
            if !isUsernameVisble {
                ToolbarItem(placement: .principal) {
                    VStack {
                        Text(verbatim: userName)
                        Text(verbatim: "@\(userUsername)")
                            .foregroundStyle(.secondary)
                            .font(.caption)
                            .fontDesign(.monospaced)
                    }
                }
            }
            if !isSelf {
                ToolbarItemGroup {
                    Menu {
                        ControlGroup {
                            Button(
                                isFollowing ? .userFollowing : .userFollow,
                                systemImage: isFollowing ? "checkmark.circle" : "plus.circle",
                                action: { withAnimation { isFollowing.toggle() } }
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
        .scrollEdgeEffectHidden(isBannerVisible, for: .top)
    }
}

private enum ViewTab: Hashable {
    case videos
    case collections
}

#Preview {
    NavigationStack {
        UserView()
    }
    .environment(\.locale, .init(identifier: "en"))
}
