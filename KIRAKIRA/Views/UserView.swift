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
    @State private var isSelf = false
    @State private var isBannerVisible = true
    @State private var isSegmentedVisible = true
    @State private var showingView: ViewTab = .videos
    @State private var userName: String = "艾了个拉"
    @State private var userUsername = "Aira"

    var body: some View {
        ScrollView {
            // Banner
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
            }
            .padding(.bottom, -74)
            .onScrollVisibilityChange { visible in
                if visible {
                    isBannerVisible = true
                } else {
                    isBannerVisible = false
                }
            }

            VStack(alignment: .leading, spacing: 8) {
                HStack(alignment: .bottom) {
                    // Avatar
                    Button(action: {}) {
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

                    // Actions
                    if isSelf {
                        Button(action: { isShowingEditProfile = true }) {
                            Text("编辑资料")
                        }.buttonStyle(.glass)
                    } else {
                        HStack {
                            Button(action: {}) {
                                Label("USER_FOLLOW", systemImage: "plus")
                                    .frame(height: 20)
                            }.buttonStyle(.glassProminent)

                            Button(action: {}) {
                                Image(systemName: "message")
                                    .frame(height: 20)
                            }.buttonStyle(.glass)

                            Menu {
                                Button("USER_REPORT", systemImage: "flag", action: {})
                                Button("USER_BLOCK", systemImage: "nosign", action: {})
                                Button("USER_HIDE", systemImage: "eye.slash", action: {})
                            } label: {
                                Image(systemName: "ellipsis")
                                    .frame(height: 20)
                            }.buttonStyle(.glass)
                        }
                    }
                }

                // Name
                Text(verbatim: "\(userName)")
                    .font(.title)
                    .bold()

                // Username
                Text(verbatim: "@\(userUsername)")
                    .foregroundStyle(.secondary)

                // Follower Info
                HStack(spacing: 16) {
                    HStack {
                        Text(verbatim: "233")
                        Text("USER_FOLLOWERS", comment: "The number of people following this user.")
                            .foregroundStyle(.secondary)
                    }
                    HStack {
                        Text(verbatim: "233")
                        Text("USER_FOLLOWING", comment: "The number of accounts this user is following.")
                            .foregroundStyle(.secondary)
                    }
                }

                // Bio
                Text(verbatim: "Kawaii Forever!~")
                    .padding(.top, 16)
            }
            .padding()
            .textSelection(.enabled)

            segmented
                .pickerStyle(.segmented)
                .padding(.horizontal)
                .onScrollVisibilityChange { visible in
                    if visible {
                        isSegmentedVisible = true
                    } else {
                        isSegmentedVisible = false
                    }
                }

            LazyVStack {
                ForEach(1...100, id: \.self) { _ in
                    Text("placeholder for scroll testing")
                }
            }
        }
        .toolbar {
            if !isSegmentedVisible {
                ToolbarItem(placement: .principal) {
                    segmented
                }
            }
        }
        .animation(.smooth, value: isSegmentedVisible)
        #if !os(macOS)
            .navigationBarTitleDisplayMode(.inline)
        #endif
        .ignoresSafeArea(edges: .top)
        .scrollEdgeEffectHidden(isBannerVisible, for: .top)
    }

    var segmented: some View {
        Picker("USER_PAGE", selection: $showingView) {
            Text("USER_VIDEO").tag(ViewTab.videos)
            Text("USER_FAVORITE").tag(ViewTab.collections)
        }
        .pickerStyle(.segmented)
    }
}

private enum ViewTab: Hashable {
    case videos
    case collections
}

#Preview {
    UserView()
}
