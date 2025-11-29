//
//  VideoPlayerView.swift
//  KIRAKIRA
//
//  Created by Aira Sakuranomiya on 2025/11/20.
//

import SwiftUI

struct VideoPlayerView: View {
    @State private var showingView: VideoPlayerTab = .info
    @Namespace private var namespace
    @State private var countLike = 0
    @State private var countDislike = 0
    @State private var countCollected = 0
    @State private var liked = false
    @State private var disliked = false
    @State private var collected = false

    func like() {
        liked = !liked
        if liked {
            countLike += 1
        } else {
            countLike -= 1
        }
    }

    func dislike() {
        disliked = !disliked
        if disliked {
            countDislike += 1
        } else {
            countDislike -= 1
        }
    }

    func collect() {
        collected = !collected
        if collected {
            countCollected += 1
        } else {
            countCollected -= 1
        }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                VStack(spacing: 0) {
                    Rectangle()
                        .foregroundStyle(.green)
                        .aspectRatio(16 / 9, contentMode: .fit)
                }

                TabView(selection: $showingView) {
                    Tab(
                        "详情",
                        systemImage: "info.circle",
                        value: VideoPlayerTab.info
                    ) {
                        ScrollView {
                            VStack(alignment: .leading, spacing: 16) {
                                HStack {
                                    Image("SamplePortrait")
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                        .frame(width: 48, height: 48)
                                        .clipShape(Circle())
                                        .glassEffect(.regular.interactive())

                                    VStack(alignment: .leading) {
                                        Text("残月的余响")
                                            .bold()
                                        Text("1024粉丝")
                                            .foregroundStyle(.secondary)
                                            .font(.caption)
                                    }

                                    Spacer()

                                    Button(action: {}) {
                                        Label("关注", systemImage: "plus")
                                    }.buttonStyle(.glassProminent)
                                }

                                VStack(alignment: .leading, spacing: 16) {
                                    Text("我的天呐丰川祥子大人")
                                        .font(.title2)
                                        .bold()

                                    HStack(spacing: 20) {
                                        InfoItemView(
                                            systemImage: "play",
                                            text: "0"
                                        )
                                        InfoItemView(
                                            systemImage: "calendar",
                                            text: "7天前"
                                        )
                                        InfoItemView(
                                            systemImage: "square.grid.2x2",
                                            text: "游戏"
                                        )
                                    }
                                    .font(.callout)
                                    .foregroundStyle(.secondary)
                                    .monospacedDigit()
                                    .contentTransition(.numericText())

                                    Text("我的天呐这简介太厉害了")
                                }

                                // 操作
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 16) {
                                        GlassEffectContainer {
                                            HStack {
                                                Button(action: { like() }) {
                                                    Image(
                                                        systemName:
                                                            "hand.thumbsup"
                                                    )
                                                    .symbolVariant(
                                                        liked ? .fill : .none
                                                    )
                                                    Text("\(countLike)")
                                                        .contentTransition(
                                                            .numericText(
                                                                value: Double(
                                                                    countLike
                                                                )
                                                            )
                                                        )
                                                }

                                                Button(action: { dislike() }) {
                                                    Image(
                                                        systemName:
                                                            "hand.thumbsdown"
                                                    )
                                                    .symbolVariant(
                                                        disliked ? .fill : .none
                                                    )
                                                    Text("\(countDislike)")
                                                        .contentTransition(
                                                            .numericText(
                                                                value: Double(
                                                                    -countDislike
                                                                )
                                                            )
                                                        )
                                                }
                                            }.glassEffectUnion(
                                                id: "like",
                                                namespace: namespace
                                            )
                                        }

                                        Button(action: { collect() }) {
                                            Image(systemName: "star")
                                                .symbolVariant(
                                                    collected ? .fill : .none
                                                )
                                            Text("\(countCollected)")
                                                .contentTransition(
                                                    .numericText(
                                                        value: Double(
                                                            countCollected
                                                        )
                                                    )
                                                )
                                        }

                                        Button(action: {}) {
                                            Label(
                                                "分享",
                                                systemImage:
                                                    "square.and.arrow.up"
                                            )
                                        }.labelStyle(.iconOnly)

                                        Button(action: {}) {
                                            Label("更多", systemImage: "ellipsis")
                                                .frame(height: 20)
                                        }.labelStyle(.iconOnly)
                                    }
                                    .monospacedDigit()
                                    .contentTransition(.symbolEffect(.replace))
                                    .buttonStyle(.glass)
                                }.scrollClipDisabled()

                            }
                            .padding()

                            // 推荐视频
                            VStack(spacing: 0) {
                                ForEach(1...10, id: \.self) { _ in
                                    VideoListItemView()
                                }
                            }
                        }
                    }
                    Tab(
                        "评论",
                        systemImage: "bubble",
                        value: VideoPlayerTab.comments
                    ) {
                        List {
                            Text("你好")
                            Text("你好")
                            Text("你好")
                            Text("你好")
                            Text("你好")
                            Text("你好")
                            Text("你好")
                            Text("你好")
                            Text("你好")
                            Text("你好")
                        }.listStyle(.plain)
                    }
                    Tab(
                        "弹幕",
                        systemImage: "line.3.horizontal",
                        value: VideoPlayerTab.danmakus
                    ) {
                        List {
                            Text("好！")
                            Text("好！")
                            Text("好！")
                            Text("好！")
                            Text("好！")
                            Text("好！")
                            Text("好！")
                            Text("好！")
                            Text("好！")
                            Text("好！")
                            Text("好！")
                            Text("好！")
                        }.listStyle(.plain)
                    }
                }
            }
            //			.preferredColorScheme(.dark)
        }
    }
}

private enum VideoPlayerTab: Hashable {
    case info
    case comments
    case danmakus
}

#Preview {
    VideoPlayerView()
}
