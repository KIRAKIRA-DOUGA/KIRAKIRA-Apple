//
//  UserView.swift
//  KIRAKIRA
//
//  Created by Aira Sakuranomiya on 2025/11/11.
//

import SwiftUI
import VariableBlur

struct UserView: View {
    @State private var isShowingEditProfile = false
    @State private var showingView: ViewTab = .videos
    @State private var userName = "艾了个拉"
    @State private var isSelf = false

    var body: some View {
        ScrollView {
            // Personal Banner
            VStack {
                Image("DefaultBanner")
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(
                        minWidth: 0,
                        minHeight: 200,
                        maxHeight: 200
                    )
                    .aspectRatio(contentMode: .fit)
                    .clipped()
                    .overlay(alignment: .bottom) {
                        VariableBlurView(
                            maxBlurRadius: 10,
                            direction: .blurredBottomClearTop
                        ).frame(height: 50)
                    }
                    .mask(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color.black,
                                Color.black.opacity(0),
                            ]),
                            startPoint: .center,
                            endPoint: .bottom
                        )
                    )
            }.padding(.bottom, -74)

            VStack(alignment: .leading, spacing: 8) {
                HStack(alignment: .bottom) {
                    // Avatar
                    Button(action: { isShowingEditProfile = true }) {
                        Image("SamplePortrait")
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 100, height: 100)
                            .clipShape(Circle())
                            .glassEffect(.regular.interactive())
                    }
                    .buttonStyle(.plain)
                    .sheet(isPresented: $isShowingEditProfile) {
                        NavigationStack {
                            SettingsProfileView()
                                #if !os(macOS)
                                    .navigationBarTitleDisplayMode(.inline)
                                #endif
                                .toolbar {
                                    ToolbarItem(placement: .cancellationAction) {
                                        Button(action: {
                                            isShowingEditProfile = false
                                        }) {
                                            Image(systemName: "xmark")
                                        }
                                    }
                                }
                        }
                    }

                    Spacer()

                    HStack {
                        Button(action: {}) {
                            Label("关注", systemImage: "plus")
                                .frame(height: 20)
                        }.buttonStyle(.glassProminent)

                        Button(action: {}) {
                            Image(systemName: "message.fill")
                                .frame(height: 20)
                        }.buttonStyle(.glass)

                        Menu {
                            Button("投诉", systemImage: "flag", action: {})
                            Button("屏蔽", systemImage: "nosign", action: {})
                            Button("隐藏", systemImage: "eye.slash", action: {})
                        } label: {
                            Image(systemName: "ellipsis")
                                .frame(height: 20)
                        }.buttonStyle(.glass)
                    }
                }

                // Name
                Text("艾了个拉")
                    .font(.title)
                    .bold()

                // Username
                Text("@Aira")
                    .foregroundStyle(.secondary)

                // Follower Info
                HStack(spacing: 16) {
                    HStack {
                        Text("233")
                        Text("粉丝")
                            .foregroundStyle(.secondary)
                    }
                    HStack {
                        Text("233")
                        Text("关注")
                            .foregroundStyle(.secondary)
                    }
                }

                // Bio
                Text("Kawaii Forever!~")
                    .padding(.top, 16)
            }.padding()

                .textSelection(.enabled)

            Picker("页面", selection: $showingView) {
                Text("视频").tag(ViewTab.videos)
                Text("收藏").tag(ViewTab.collections)
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)

            LazyVStack(spacing: 0) {
                VideoListItemView()
                VideoListItemView()
                VideoListItemView()
                VideoListItemView()
            }

        }
        //		.navigationTitle(userName)
        #if !os(macOS)
            .navigationBarTitleDisplayMode(.inline)
        #endif
        .ignoresSafeArea(edges: .top)
        .scrollEdgeEffectHidden(true, for: .top)
    }
}

private enum ViewTab: Hashable {
    case videos
    case collections
}

#Preview {
    UserView()
}
