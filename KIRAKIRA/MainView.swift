import SwiftUI

struct MainView: View {
    @Environment(GlobalStateManager.self) private var globalStateManager
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @State private var authManager = AuthManager.shared
    @State var searchText: String = ""
    @Namespace private var animationNamespace

    var body: some View {
        @Bindable var globalStateManager = globalStateManager

        TabView(selection: $globalStateManager.mainTabSelection) {
            Tab(.maintabHome, systemImage: "house", value: MainTab.home) {
                HomeView(animationNamespace: animationNamespace)
            }

            Tab(.maintabFollowing, systemImage: "rectangle.stack", value: MainTab.feed) {
                FollowingFeedView()
            }

            TabSection(.maintabMy) {
                Tab(.userPage, systemImage: "person", value: MainTab.myUserPage) {
                    NavigationStack {
                        UserView(animationNamespace: animationNamespace)
                    }
                }

                Tab(.notifications, systemImage: "bell", value: MainTab.myNotifications) {
                    NavigationStack {
                        MyNotificationsView(animationNamespace: animationNamespace)
                    }
                }

                Tab(.messages, systemImage: "message", value: MainTab.myMessages) {
                    NavigationStack {
                        MyMessagesView()
                    }
                }

                Tab(.userCollections, systemImage: "star", value: MainTab.myCollections) {
                    NavigationStack {
                        MyCollectionsView()
                    }
                }

                Tab(
                    .userHistory,
                    systemImage: "clock.arrow.trianglehead.counterclockwise.rotate.90",
                    value: MainTab.myHistory
                ) {
                    NavigationStack {
                        MyHistoryView()
                    }
                }
            }
            .hidden(horizontalSizeClass == .compact)

            Tab(.maintabMy, systemImage: "person.crop.circle", value: MainTab.me) {
                MyView(animationNamespace: animationNamespace)
            }
            .hidden(horizontalSizeClass != .compact)

            Tab(value: MainTab.search, role: .search) {
                SearchView()
                    .searchable(text: $searchText)
            }
        }
        .tabViewSidebarBottomBar {
            Button {
                if authManager.isAuthenticated {
                    globalStateManager.showSettings()
                } else {
                    globalStateManager.isShowingLogin = true
                }
            } label: {
                Label {
                    if let account = authManager.credentials {
                        Text(verbatim: account.displayName).fontWeight(.medium)
                    } else {
                        Text(.logIn).fontWeight(.medium)
                    }
                    Spacer()
                } icon: {
                    UserAvatarView(imageId: authManager.credentials?.avatar)
                        .frame(width: 30, height: 30)
                }
            }
            .padding(.horizontal)
            .padding()
            .buttonStyle(.plain)
            .buttonSizing(.flexible)
        }
        .scrollEdgeEffectStyle(.soft, for: .top)
        .tabViewStyle(.sidebarAdaptable)
        .fullScreenCover(isPresented: $globalStateManager.isPlayerExpanded, content: {
            if globalStateManager.selectedVideo != nil {
                VideoPlayerView(
                    videoId: globalStateManager.selectedVideo!,
                    animationNamespace: animationNamespace
                )
                    .navigationTransition(
                        .zoom(sourceID: globalStateManager.activeTransitionSource, in: animationNamespace)
                    )
                    .interactiveDismissDisabled()
            } else {
                Image(systemName: "play.slash.fill")
                    .foregroundStyle(.tertiary)
                    .font(.largeTitle)
            }
        })
        .sheet(
            isPresented: $globalStateManager.isShowingSettings,
            onDismiss: { globalStateManager.resetSettingsNavigation() }
        ) {
            SettingsView()
        }
        .sheet(isPresented: $globalStateManager.isShowingLogin) {
            AuthView()
        }
        .task {
            await authManager.refreshAccountProfiles()
        }
    }
}

#Preview(traits: .commonPreviewTrait) {
    MainView()
}
