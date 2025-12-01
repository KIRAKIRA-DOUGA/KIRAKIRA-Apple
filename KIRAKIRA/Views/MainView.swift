//
//  MainView.swift
//  KIRAKIRA
//
//  Created by Aira Sakuranomiya on 2025/11/8.
//

import SwiftUI

struct MainView: View {
    @EnvironmentObject private var globalStateManager: GlobalStateManager
    @State var searchText: String = ""
    @State private var isPlayerExpend: Bool = false
    @State private var isPlayerPlaying: Bool = false
    @Namespace private var animationNamespace

    var body: some View {
        TabView(selection: $globalStateManager.mainTabSelection) {
            Tab("主页", systemImage: "house", value: MainTab.home) {
                HomeView()
            }
            Tab("关注", systemImage: "mail.stack", value: MainTab.feed) {
                FeedView()
            }
            Tab("我", systemImage: "person", value: MainTab.me) {
                MeView()
            }
            Tab(value: MainTab.search, role: .search) {
                SearchView()
                    .searchable(text: $searchText)
            }
        }
        .tabViewBottomAccessory {
            MiniPlayer(isPlayerPlaying: isPlayerPlaying)
                .matchedTransitionSource(id: "player", in: animationNamespace)
                .onTapGesture {
                    isPlayerExpend = true
                }
        }
        .tabBarMinimizeBehavior(.onScrollDown)
        .fullScreenCover(isPresented: $isPlayerExpend) {
            VideoPlayerView()
                .navigationTransition(.zoom(sourceID: "player", in: animationNamespace))
        }
    }
}

private struct MiniPlayer: View {
    @Environment(\.tabViewBottomAccessoryPlacement) var tabViewBottomAccessoryPlacement
    @State var isPlayerPlaying: Bool

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
                Button(
                    "播放 / 暂停", systemImage: isPlayerPlaying ? "pause.fill" : "play.fill",
                    action: { isPlayerPlaying = !isPlayerPlaying })
                if tabViewBottomAccessoryPlacement == .expanded {
                    Button("关闭", systemImage: "xmark", action: {})
                }
            }
            .buttonStyle(.plain)
            .buttonBorderShape(.circle)
            .contentTransition(.symbolEffect)
            .labelStyle(.iconOnly)
        }
        .padding(.horizontal)
    }
}

#Preview {
    MainView()
}
