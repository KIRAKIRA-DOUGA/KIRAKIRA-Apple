//
//  MainView.swift
//  KIRAKIRA
//
//  Created by Aira Sakuranomiya on 2025/11/8.
//

import SwiftUI

struct MainView: View {
    @Environment(GlobalStateManager.self) private var globalStateManager
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
            Tab(.maintabMy, systemImage: "person", value: MainTab.me) {
                MyView()
            }
            Tab(value: MainTab.search, role: .search) {
                SearchView()
                    .searchable(text: $searchText)
            }
        }
        .tabViewBottomAccessory {
            MiniPlayer()
                .matchedTransitionSource(id: AnimationTransitionSource.miniPlayer, in: animationNamespace)
                .onTapGesture {
                    globalStateManager.activeTransitionSource = .miniPlayer
                    isPlayerExpanded = true
                }
        }

        .tabBarMinimizeBehavior(.onScrollDown)
        .fullScreenCover(isPresented: $isPlayerExpanded) {
            VideoPlayerView()
                .navigationTransition(
                    .zoom(sourceID: globalStateManager.activeTransitionSource, in: animationNamespace)
                )
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
                    Button(.miniplayerClose, systemImage: "forward.fill", action: {})
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
