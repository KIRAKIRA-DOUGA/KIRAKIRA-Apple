import AVKit
import RichText
import SwiftUI

struct VideoPlayerView: View {
    let videoId: Int
    @Environment(\.dismiss) private var dismiss
    @Environment(AuthManager.self) private var authManager
    @State private var screenModel: VideoPlayerScreenModel

    init(videoId: Int, repository: VideoRepository) {
        self.videoId = videoId
        _screenModel = State(initialValue: VideoPlayerScreenModel(videoId: videoId, repository: repository))
    }

    var body: some View {
        NavigationStack {
            Group {
                if let video = screenModel.detailModel.video {
                    content(video: video.video)
                } else if let errorMessage = screenModel.detailModel.errorMessage {
                    ErrorView(errorMessage: errorMessage) {
                        Task {
                            await screenModel.load()
                        }
                    }
                } else {
                    ProgressView()
                }
            }
            .task {
                await screenModel.load()
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(role: .close, action: { dismiss() })
                }
            }
            .sheet(isPresented: $screenModel.isShowingLogin) {
                LoginView()
            }
        }
    }

    @ViewBuilder
    func content(video: VideoItem) -> some View {
        VStack(spacing: 0) {
            if screenModel.player != nil {
                VideoPlayer(player: screenModel.player)
                    .aspectRatio(16 / 9, contentMode: .fit)
                    .layoutPriority(1)
            } else {
                Color.black
                    .aspectRatio(16 / 9, contentMode: .fit)
                    .layoutPriority(1)
            }

            VStack {
                switch screenModel.selectedTab {
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
                    Picker(.videoTabPicker, selection: $screenModel.selectedTab) {
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

                    Button {
                        screenModel.followTapped(isAuthenticated: authManager.isAuthenticated)
                    } label: {
                        Label(.userFollow, systemImage: "plus")
                    }
                    .buttonStyle(.bordered)
                }

                VStack(alignment: .leading, spacing: 16) {
                    TextView(video.title)
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
                                Text(uploadDate, format: .smart)
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

                    TextView(video.description)
                }

                // 操作
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack {
                        Button(action: {}) {  // 使用我认为最扯淡但是居然真的可行的方式实现连体按钮
                            HStack(spacing: 24) {
                                Button(action: { screenModel.toggleLike() }) {
                                    Image(systemName: "hand.thumbsup")
                                        .symbolVariant(screenModel.liked ? .fill : .none)
                                        .frame(width: 20, height: 20)

                                    Text(screenModel.countLike, format: .number)
                                        .contentTransition(.numericText(value: Double(screenModel.countLike)))
                                }
                                .foregroundStyle(screenModel.liked ? .accent : .primary)
                                .sensoryFeedback(.success, trigger: screenModel.liked) { oldValue, newValue in
                                    return newValue
                                }

                                Button(action: { screenModel.toggleDislike() }) {
                                    Image(systemName: "hand.thumbsdown")
                                        .symbolVariant(screenModel.disliked ? .fill : .none)
                                        .frame(width: 20, height: 20)

                                    Text(screenModel.countDislike, format: .number)
                                        .contentTransition(.numericText(value: Double(-screenModel.countDislike)))
                                }
                                .foregroundStyle(screenModel.disliked ? .accent : .primary)
                            }.buttonStyle(.plain)
                        }

                        Button(action: { screenModel.toggleCollection() }) {
                            Image(systemName: "star")
                                .symbolVariant(screenModel.collected ? .fill : .none)
                                .frame(width: 20, height: 20)

                            Text(screenModel.countCollected, format: .number)
                                .contentTransition(.numericText(value: Double(screenModel.countCollected)))
                        }
                        .foregroundStyle(screenModel.collected ? .accent : .primary)
                        .sensoryFeedback(.success, trigger: screenModel.collected) { oldValue, newValue in
                            return newValue
                        }

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
        CommentsView(videoId: videoId, commentViewModel: screenModel.commentModel)
    }

    var danmaku: some View {
        DanmakuView(videoId: videoId, danmakuViewModel: screenModel.danmakuModel)
    }
}

enum VideoPlayerTab: Hashable, CaseIterable {
    case info
    case comments
    case danmakus
}

#Preview(traits: .commonPreviewTrait) {
    VideoPlayerView(videoId: 1, repository: AppDependencies(sessionStore: .shared).videoRepository)
}
