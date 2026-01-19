import AVKit
import SwiftUI

struct VideoPlayerView: View {
    let videoId: Int
    @State private var viewModel = VideoViewModel()
    @State private var showingView: VideoPlayerTab = .info
    @Namespace private var namespace
    @State private var countLike = 0
    @State private var countDislike = 0
    @State private var countCollected = 0
    @State private var liked = false
    @State private var disliked = false
    @State private var collected = false
    @State private var player: AVPlayer?

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
            if let video = viewModel.video {
                content(video: video.video)
            } else {
                ProgressView()
            }
        }
        .task {
            await viewModel.fetchVideo(of: videoId)
        }
    }

    @ViewBuilder
    func content(video: VideoItem) -> some View {
        VStack(spacing: 0) {
            if player != nil {
                VideoPlayer(player: player)
                    .aspectRatio(16 / 9, contentMode: .fit)
            } else {
                Color.black
                    .aspectRatio(16 / 9, contentMode: .fit)
                    .task {
                        if let url = video.videoPart.first?.m3u8URL {
                            player = AVPlayer(url: url)
                        }
                    }
            }

            VStack {
                switch showingView {
                case .info:
                    info(video: video)
                case .comments:
                    comments
                case .danmakus:
                    danmaku
                }
            }
            .safeAreaBar(edge: .top) {
                VStack {
                    Picker(.videoTabPicker, selection: $showingView) {
                        Text(.videoTabInfo).tag(VideoPlayerTab.info)
                        Text(.videoTabComment).tag(VideoPlayerTab.comments)
                        Text(.videoTabDanmaku).tag(VideoPlayerTab.danmakus)
                    }
                    .pickerStyle(.segmented)
                    .padding(.top)
                    .padding(.horizontal)
                }
            }
        }
    }

    @ViewBuilder
    func info(video: VideoItem) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    CFImageView(imageId: video.uploaderInfo?.avatar)
                        .frame(width: 48, height: 48)
                        .clipShape(Circle())
                        .glassEffect(.regular.interactive())

                    VStack(alignment: .leading) {
                        Text(verbatim: video.uploaderInfo?.userNickname ?? "Unknown User")
                            .bold()
                        Text(verbatim: "1024粉丝")
                            .foregroundStyle(.secondary)
                            .font(.caption)
                    }

                    Spacer()

                    Button(action: {}) {
                        Label(.userFollow, systemImage: "plus")
                    }
                    .buttonStyle(.glassProminent)
                }

                VStack(alignment: .leading, spacing: 16) {
                    Text(video.title)
                        .font(.title2)
                        .bold()

                    HStack(spacing: 20) {
                        if let watchedCount = video.watchedCount {
                            Label {
                                Text(watchedCount, format: .number)
                            } icon: {
                                Image(systemName: "play")
                            }
                        }

                        if let uploadDate = video.uploadDate {
                            Label {
                                Text(uploadDate, format: .dateTime)
                            } icon: {
                                Image(systemName: "calendar")
                            }

                        }

                        Label(video.videoCategory, systemImage: "square.grid.2x2")
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

                                    Text(countLike, format: .number)
                                        .contentTransition(.numericText(value: Double(countLike)))
                                }

                                Button(action: { dislike() }) {
                                    Image(systemName: "hand.thumbsdown")
                                        .symbolVariant(disliked ? .fill : .none)

                                    Text(countDislike, format: .number)
                                        .contentTransition(.numericText(value: Double(-countDislike)))
                                }
                            }
                            .glassEffectUnion(id: "like", namespace: namespace)
                        }

                        Button(action: { collect() }) {
                            Image(systemName: "star")
                                .symbolVariant(collected ? .fill : .none)

                            Text(countCollected, format: .number)
                                .contentTransition(.numericText(value: Double(countCollected)))
                        }

                        Button(action: {}) {
                            Label(.share, systemImage: "square.and.arrow.up")
                        }
                        .labelStyle(.iconOnly)

                        Menu {
                            Button(.report, systemImage: "flag", action: {})
                            Button(.checkThumbnail, systemImage: "photo", action: {})
                            Button(.download, systemImage: "square.and.arrow.down", action: {})
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
        List(0..<30) { _ in
            Text(verbatim: "你好")
        }
        .listStyle(.plain)
    }

    var danmaku: some View {
        List(0..<30) { _ in
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
    VideoPlayerView(videoId: 1)
}
