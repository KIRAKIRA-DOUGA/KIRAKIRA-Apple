//
//  MainView.swift
//  KIRAKIRA
//
//  Created by Aira Sakuranomiya on 2025/11/8.
//

import SwiftUI

struct MainView: View {
    @Environment(GlobalStateManager.self) private var globalStateManager
    @Environment(\.horizontalSizeClass) private var horizontalSize
    @State private var isPlayerExpanded = false
    @State var searchText: String = ""
    @Namespace private var animationNamespace

    var body: some View {
        @Bindable var globalStateManager = globalStateManager

        TabView(selection: $globalStateManager.mainTabSelection) {
            Tab(.maintabHome, systemImage: "house", value: MainTab.home) {
                HomeView(isPlayerExpanded: $isPlayerExpanded, animationNamespace: animationNamespace)
            }

            Tab(.maintabFollowing, systemImage: "mail.stack", value: MainTab.feed) {
                FollowingFeedView()
            }

            if horizontalSize == .regular {
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
            } else {
                Tab(.maintabMy, systemImage: "person", value: MainTab.me) {
                    MyView()
                }
            }

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
        .tabBarMinimizeBehavior(.onScrollDown)
        .tabViewStyle(.sidebarAdaptable)
        .tabViewBottomAccessory {
            MiniPlayer()
                .matchedTransitionSource(id: AnimationTransitionSource.miniPlayer, in: animationNamespace)
                .onTapGesture {
                    globalStateManager.activeTransitionSource = .miniPlayer
                    isPlayerExpanded = true
                }
        }
        .fullScreenCover(isPresented: $isPlayerExpanded) {
            VideoPlayerView()
                .navigationTransition(
                    .zoom(sourceID: globalStateManager.activeTransitionSource, in: animationNamespace)
                )
        }
        .sheet(isPresented: $globalStateManager.isShowingSettings) {
            SettingsView()
        }
    }
}

private struct MiniPlayer: View {
    @Environment(\.tabViewBottomAccessoryPlacement) var tabViewBottomAccessoryPlacement
    @Environment(GlobalStateManager.self) private var globalStateManger

    var body: some View {
        HStack {
            RoundedRectangle(cornerRadius: 4)
                .frame(width: 53, height: 30)
                .foregroundStyle(.green)

            VStack(alignment: .leading) {
                Text(verbatim: "Apple Event - September 9")
                    .font(.footnote)
                    .bold()
                Text(verbatim: "6月10日")
                    .font(.caption)
            }
            .lineLimit(1)

            Spacer()

            HStack {
                Button {
                    globalStateManger.isPlayerPlaying.toggle()
                } label: {
                    Label(
                        .miniplayerTogglePlayPause,
                        systemImage: globalStateManger.isPlayerPlaying ? "play.fill" : "pause.fill"
                    )
                    .contentTransition(.symbolEffect(.replace))
                }
                .frame(width: 36, height: 36)

                if tabViewBottomAccessoryPlacement == .expanded {
                    Button(.close, systemImage: "xmark", action: {})
                        .frame(width: 36, height: 36)
                }
            }
            .buttonStyle(.plain)
            .labelStyle(.iconOnly)
            .font(.system(size: 20))
        }
        .padding(.horizontal)
    }
}

#Preview(traits: .commonPreviewTrait) {
    MainView()
}
