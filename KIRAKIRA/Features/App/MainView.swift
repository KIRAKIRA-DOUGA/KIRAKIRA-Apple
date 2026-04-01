import SwiftUI

struct MainView: View {
    let dependencies: AppDependencies
    @Environment(AppRouter.self) private var appRouter
    @Environment(AppUIState.self) private var appUIState
    @Environment(PlaybackState.self) private var playbackState
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @State private var isPlayerExpanded = false
    @State var searchText: String = ""
    @Namespace private var animationNamespace

    var body: some View {
        @Bindable var appRouter = appRouter

        TabView(selection: $appRouter.mainTabSelection) {
            Tab(.maintabHome, systemImage: "house", value: MainTab.home) {
                NavigationStack {
                    HomeView(
                        isPlayerExpanded: $isPlayerExpanded,
                        animationNamespace: animationNamespace,
                        repository: dependencies.homeRepository
                    )
                }
            }

            Tab(.maintabFollowing, systemImage: "rectangle.stack", value: MainTab.feed) {
                NavigationStack {
                    FollowingFeedView()
                }
            }

            TabSection(.maintabMy) {
                Tab(.userPage, systemImage: "person", value: MainTab.myUserPage) {
                    NavigationStack {
                        UserView(profileRepository: dependencies.profileRepository)
                    }
                }

                Tab(.notifications, systemImage: "bell", value: MainTab.myNotifications) {
                    NavigationStack {
                        MyNotificationsView(profileRepository: dependencies.profileRepository)
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

            Tab(.maintabMy, systemImage: "person", value: MainTab.me) {
                NavigationStack {
                    MyView(profileRepository: dependencies.profileRepository)
                }
            }
            .hidden(horizontalSizeClass != .compact)

            Tab(value: MainTab.search, role: .search) {
                NavigationStack {
                    SearchView()
                        .searchable(text: $searchText)
                }
            }
        }
        .tabViewSidebarBottomBar {
            Button {
                appRouter.isShowingSettings = true
            } label: {
                Label {
                    Text(verbatim: "艾了个拉").fontWeight(.medium)
                    Spacer()
                } icon: {
                    Image("SamplePortrait")
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 30, height: 30)
                        .clipShape(Circle())
                }
            }
            .padding(.horizontal)
            .padding()
            .buttonStyle(.plain)
            .buttonSizing(.flexible)
        }
        .tabViewStyle(.sidebarAdaptable)
        .fullScreenCover(
            isPresented: $isPlayerExpanded,
            content: {
                if playbackState.selectedVideo != nil {
                    VideoPlayerView(
                        videoId: playbackState.selectedVideo!, repository: dependencies.videoRepository
                    )
                    .navigationTransition(
                        .zoom(sourceID: playbackState.activeTransitionSource, in: animationNamespace)
                    )
                } else {
                    Image(systemName: "play.slash.fill")
                        .foregroundStyle(.tertiary)
                        .font(.largeTitle)
                }
            }
        )
        .sheet(isPresented: $appRouter.isShowingSettings) {
            SettingsView()
        }
        .sheet(isPresented: $appRouter.isShowingLogin) {
            LoginView()
        }
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)) { _ in
            appUIState.isShowingKeyboard = true
        }
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)) { _ in
            appUIState.isShowingKeyboard = false
        }
    }
}

#Preview(traits: .commonPreviewTrait) {
    MainView(dependencies: AppDependencies(sessionStore: .shared))
}
