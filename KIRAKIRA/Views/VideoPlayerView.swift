//
//  VideoPlayerView.swift
//  KIRAKIRA
//
//  Created by Aira Sakuranomiya on 2025/11/20.
//

import SwiftUI
import AVKit

struct VideoPlayerView: View {
    @Environment(GlobalStateManager.self) private var globalStateManager
    @State private var viewModel = VideoViewModel()
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
        Group {
            if let video = viewModel.video, let videoPart = video.video.videoPart.first {
                let player = AVPlayer(url: videoPart.m3u8URL)

                VStack(spacing: 0) {
                    // Drag Indicator
                    Capsule()
                        .frame(width: 64, height: 5)
                        .padding(.bottom)
                        .foregroundStyle(.tertiary)

                    VideoPlayer(player: player)
                        .aspectRatio(16 / 9, contentMode: .fit)

                    Group {
                        switch showingView {
                        case .info:
                            info(video: video.video)
                        case .comments:
                            comments
                        case .danmakus:
                            danmaku
                        }
                    }
                    .safeAreaBar(edge: .top) {
                        Picker("VIDEO_TAB", selection: $showingView) {
                            Text("VIDEO_INFO").tag(VideoPlayerTab.info)
                            Text("COMMENT").tag(VideoPlayerTab.comments)
                            Text("DANMAKU").tag(VideoPlayerTab.danmakus)
                        }
                        .pickerStyle(.segmented)
                        .padding()
                    }
                }
            }
        }
        .task {
            await viewModel.fetchVideo(of: globalStateManager.selectedVideo)
        }
    }

    @ViewBuilder
    func info(video: VideoItem) -> some View {
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
                        Text(verbatim: "残月的余响")
                            .bold()
                        Text(verbatim: "1024粉丝")
                            .foregroundStyle(.secondary)
                            .font(.caption)
                    }

                    Spacer()

                    Button(action: {}) {
                        Label("SUBSCRIBE", systemImage: "plus")
                    }
                    .buttonStyle(.glassProminent)
                }

                VStack(alignment: .leading, spacing: 16) {
                    Text(video.title)
                        .font(.title2)
                        .bold()

                    HStack(spacing: 20) {
                        Label("0", systemImage: "play")
                        Label("7 days ago", systemImage: "calendar")
                        Label("Game", systemImage: "square.grid.2x2")
                    }
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
                    .contentTransition(.numericText())

                    Text(video.description)
                }

                // 操作
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 16) {
                        GlassEffectContainer {
                            HStack(spacing: 0) {
                                Button(action: { like() }) {
                                    Image(systemName: "hand.thumbsup")
                                        .symbolVariant(liked ? .fill : .none)

                                    Text("\(countLike)")
                                        .contentTransition(.numericText(value: Double(countLike)))
                                }

                                Button(action: { dislike() }) {
                                    Image(systemName: "hand.thumbsdown")
                                        .symbolVariant(disliked ? .fill : .none)

                                    Text("\(countDislike)")
                                        .contentTransition(.numericText(value: Double(-countDislike)))
                                }
                            }
                            .glassEffectUnion(id: "like", namespace: namespace)
                        }

                        Button(action: { collect() }) {
                            Image(systemName: "star")
                                .symbolVariant(collected ? .fill : .none)

                            Text("\(countCollected)")
                                .contentTransition(.numericText(value: Double(countCollected)))
                        }

                        Button(action: {}) {
                            Label("SHARE", systemImage: "square.and.arrow.up")
                        }
                        .labelStyle(.iconOnly)

                        Menu {
                            Button("REPORT", systemImage: "flag", action: {})
                            Button("CHECK_THUMBNAIL", systemImage: "photo", action: {})
                            Button("DOWNLOAD", systemImage: "square.and.arrow.down", action: {})
                        } label: {
                            Image(systemName: "ellipsis")
                                .frame(height: 20)
                        }
                    }
                    .monospacedDigit()
                    .contentTransition(.symbolEffect(.replace))
                    .buttonStyle(.glass)
                }
                .scrollClipDisabled()

            }
            .padding()
        }
    }

    var comments: some View {
        List(0..<10) { _ in
            Text(verbatim: "你好")
        }
        .listStyle(.plain)
    }

    var danmaku: some View {
        List(0..<10) { _ in
            Text(verbatim: "好！")
        }
        .listStyle(.plain)
    }
}

private enum VideoPlayerTab: Hashable, CaseIterable {
    case info
    case comments
    case danmakus
}

#Preview {
    VideoPlayerView()
}
