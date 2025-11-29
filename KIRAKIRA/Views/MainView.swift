//
//  MainView.swift
//  KIRAKIRA
//
//  Created by Aira Sakuranomiya on 2025/11/8.
//

import SwiftUI

struct MainView: View {
    @State var searchText: String = ""
    @State var tabSelection: MainTab = .home
    @State private var isPlayerExpend: Bool = false
    @State private var isPlayerPlaying: Bool = false
    @Namespace private var animation

    var body: some View {
        TabView(selection: $tabSelection) {
            Tab("主页", systemImage: "house", value: MainTab.home) {
                HomeView(tabSelection: $tabSelection)
            }
            Tab("关注", systemImage: "mail.stack", value: MainTab.feed) {
                FeedView(tabSelection: $tabSelection)
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
            MiniPlayer(isPlayerPlaying: isPlayerPlaying)
                .matchedTransitionSource(id: "player", in: animation)
                .onTapGesture {
                    isPlayerExpend = true
                }
        }
        .tabBarMinimizeBehavior(.onScrollDown)
        .fullScreenCover(isPresented: $isPlayerExpend) {
            VideoPlayerView()
                .navigationTransition(.zoom(sourceID: "player", in: animation))
        }
    }
}

private struct MiniPlayer: View {
    @Environment(\.tabViewBottomAccessoryPlacement)
    var tabViewBottomAccessoryPlacement
    @State var isPlayerPlaying: Bool

    var body: some View {
        HStack {
            RoundedRectangle(cornerRadius: 4)
                .frame(width: 53, height: 30)
                .foregroundStyle(.accent)

            VStack(alignment: .leading) {
                Text("Apple Event - September 9")
                    .font(.footnote)
                    .bold()
                Text("6月10日")
                    .font(.caption)
            }.lineLimit(1)

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
        }.padding(.horizontal)
    }
}

enum MainTab: Hashable {
    case home
    case feed
    case messages
    case me
    case search
}

#Preview {
    MainView()
}
