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
	@Namespace private var animation

	var body: some View {
		TabView(selection: $tabSelection) {
			Tab("主页", systemImage: "house", value: MainTab.home) {
				HomeView(tabSelection: $tabSelection)
			}
			Tab("关注", systemImage: "mail.stack", value: MainTab.feed) {
				FeedView(tabSelection: $tabSelection)
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
			MiniPlayer()
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

	var body: some View {
		HStack {
			RoundedRectangle(cornerRadius: 6)
				.frame(width: 30, height: 30)
				.foregroundStyle(.accent)

			VStack(alignment: .leading, spacing: 0) {
				Text("我的天呐丰川祥子大人")
					.font(.callout)
				Text("残月的余响")
					.font(.caption)
					.opacity(0.5)
			}.lineLimit(1)

			Spacer()

			HStack {
				Button("播放 / 暂停", systemImage: "pause.fill", action: {})
				if tabViewBottomAccessoryPlacement == .expanded {
					Button("关闭", systemImage: "xmark", action: {})
				}
			}
			.buttonStyle(.plain)
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
