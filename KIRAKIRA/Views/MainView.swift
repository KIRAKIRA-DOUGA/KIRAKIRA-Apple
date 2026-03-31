import SwiftUI

struct MainView: View {
    @Environment(GlobalStateManager.self) private var globalStateManager
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @State private var isPlayerExpanded = false
    @State var searchText: String = ""
    @Namespace private var animationNamespace

    var body: some View {
        @Bindable var globalStateManager = globalStateManager

        TabView(selection: $globalStateManager.mainTabSelection) {
            Tab(.maintabHome, systemImage: "house", value: MainTab.home) {
                HomeView(isPlayerExpanded: $isPlayerExpanded, animationNamespace: animationNamespace)
            }

            Tab(.maintabFollowing, systemImage: "rectangle.stack", value: MainTab.feed) {
                FollowingFeedView()
            }

            TabSection(.maintabMy) {
                Tab(.userPage, systemImage: "person", value: MainTab.myUserPage) {
                    NavigationStack {
                        UserView()
                    }
                }

                Tab(.notifications, systemImage: "bell", value: MainTab.myNotifications) {
                    NavigationStack {
                        MyNotificationsView()
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
                MyView()
            }
            .hidden(horizontalSizeClass != .compact)

            Tab(value: MainTab.search, role: .search) {
                SearchView()
                    .searchable(text: $searchText)
            }
        }
        .tabViewSidebarBottomBar {
            Button {
                globalStateManager.isShowingSettings = true
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
        .fullScreenCover(isPresented: $isPlayerExpanded, content: {
            if globalStateManager.selectedVideo != nil {
                VideoPlayerView(videoId: globalStateManager.selectedVideo!)
                    .navigationTransition(
                        .zoom(sourceID: globalStateManager.activeTransitionSource, in: animationNamespace)
                    )
            } else {
                Image(systemName: "play.slash.fill")
                    .foregroundStyle(.tertiary)
                    .font(.largeTitle)
            }
        })
        .sheet(isPresented: $globalStateManager.isShowingSettings) {
            SettingsView()
        }
        .sheet(isPresented: $globalStateManager.isShowingLogin) {
            LoginView()
        }
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)) { _ in
            globalStateManager.isShowingKeyboard = true
        }
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)) { _ in
            globalStateManager.isShowingKeyboard = false
        }
    }
}

#Preview(traits: .commonPreviewTrait) {
    MainView()
}
