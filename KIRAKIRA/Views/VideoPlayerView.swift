import AVKit
import SwiftUI

struct VideoPlayerView: View {
    let videoId: Int
    @Environment(\.dismiss) private var dismiss
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

    private func like() {
        liked = !liked
        if liked {
            countLike += 1
        } else {
            countLike -= 1
        }
    }

    private func dislike() {
        disliked = !disliked
        if disliked {
            countDislike += 1
        } else {
            countDislike -= 1
        }
    }

    private func collect() {
        collected = !collected
        if collected {
            countCollected += 1
        } else {
            countCollected -= 1
        }
    }

    var body: some View {
        NavigationStack {
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
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(role: .close, action: { dismiss() })
                }
            }
        }
    }

    @ViewBuilder
    func content(video: VideoItem) -> some View {
        VStack(spacing: 0) {
            if player != nil {
                VideoPlayer(player: player)
                    .aspectRatio(16 / 9, contentMode: .fit)
                    .layoutPriority(1)
            } else {
                Color.black
                    .aspectRatio(16 / 9, contentMode: .fit)
                    .layoutPriority(1)
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
                    .buttonStyle(.bordered)
                }

                VStack(alignment: .leading, spacing: 16) {
                    TextSelectable(video.title)
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

                    TextSelectable(video.description)
                }

                // 操作
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack {
                        Button(action: {}) {  // 使用我认为最扯淡但是居然真的可行的方式实现连体按钮
                            HStack(spacing: 24) {
                                Button(action: { like() }) {
                                    Image(systemName: "hand.thumbsup")
                                        .symbolVariant(liked ? .fill : .none)
                                        .frame(width: 20, height: 20)

                                    Text(countLike, format: .number)
                                        .contentTransition(.numericText(value: Double(countLike)))
                                }
                                .foregroundStyle(liked ? .accent : .primary)

                                Button(action: { dislike() }) {
                                    Image(systemName: "hand.thumbsdown")
                                        .symbolVariant(disliked ? .fill : .none)
                                        .frame(width: 20, height: 20)

                                    Text(countDislike, format: .number)
                                        .contentTransition(.numericText(value: Double(-countDislike)))
                                }
                                .foregroundStyle(disliked ? .accent : .primary)
                            }.buttonStyle(.plain)
                        }

                        Button(action: { collect() }) {
                            Image(systemName: "star")
                                .symbolVariant(collected ? .fill : .none)
                                .frame(width: 20, height: 20)

                            Text(countCollected, format: .number)
                                .contentTransition(.numericText(value: Double(countCollected)))
                        }
                        .foregroundStyle(collected ? .accent : .primary)

                        Group {
                            Button(action: {}) {
                                Label(.download, systemImage: "arrow.down")
                                    .frame(width: 20, height: 20)
                            }

                            Button(action: {}) {
                                Label(.share, systemImage: "square.and.arrow.up")
                                    .frame(width: 20, height: 20)
                            }

                            
                            Menu {
                                Button(.report, systemImage: "exclamationmark.bubble", action: {})
                                Button(.checkThumbnail, systemImage: "photo", action: {})
                            } label: {
                                Label(.menuMore, systemImage: "ellipsis")
                                    .frame(width: 20, height: 20)
                            }
                        }
                        .labelStyle(.iconOnly)
                        .buttonBorderShape(.circle)
                        .padding(.horizontal, -5)
                    }
                    .monospacedDigit()
                    .contentTransition(.symbolEffect(.replace.offUp.byLayer))
                    .buttonStyle(.bordered)
                    .foregroundStyle(.primary)
                }
                .scrollClipDisabled()

            }
            .padding()
        }
    }

    var comments: some View {
        CommentsView()
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
