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
            Tab("主页", systemImage: "house", value: MainTab.home) {
                HomeView(isPlayerExpanded: $isPlayerExpanded, animationNamespace: animationNamespace)
            }
            Tab("关注", systemImage: "mail.stack", value: MainTab.feed) {
                FeedView()
            }
            Tab("个人", systemImage: "person", value: MainTab.me) {
                MeView()
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
                Text("Apple Event - September 9")
                    .font(.footnote)
                    .bold()
                Text("6月10日")
                    .font(.caption)
            }
            .lineLimit(1)

            Spacer()

            HStack {
                Button {
                    globalStateManger.isPlayerPlaying.toggle()
                } label: {
                    Label(
                        "Toggle Play / Pause",
                        systemImage: globalStateManger.isPlayerPlaying ? "play.fill" : "pause.fill"
                    )
                    .contentTransition(.symbolEffect(.replace))
                }

                if tabViewBottomAccessoryPlacement == .expanded {
                    Button("关闭", systemImage: "xmark", action: {})
                }
            }
            .buttonStyle(.plain)
            .labelStyle(.iconOnly)
            .controlSize(.large)
        }
        .padding(.horizontal)
    }
}

#Preview(traits: .commonPreviewTrait) {
    MainView()
}
