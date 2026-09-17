import AVKit
import RichText
import SwiftUI

struct VideoPlayerView: View {
    let videoId: Int
    let animationNamespace: Namespace.ID
    @Environment(\.dismiss) private var dismiss
    @Environment(\.scenePhase) private var scenePhase
    @State private var authManager = AuthManager.shared
    @State private var isShowingLogin = false
    @State private var isShowingEditTag = false
    @State private var viewModel = VideoViewModel()
    @State private var commentViewModel = CommentViewModel()
    @State private var danmakuViewModel = DanmakuViewModel()
    @State private var historyManager = BrowsingHistoryManager.shared
    @State private var playbackHistoryController = VideoPlaybackHistoryController()
    @State private var showingView: VideoPlayerTab = .info
    @Namespace private var namespace
    @State private var countLike = 0
    @State private var countDislike = 0
    @State private var countCollected = 0
    @State private var liked = false
    @State private var disliked = false
    @State private var collected = false
    @State private var player: AVPlayer?
    @State private var uploaderIsFollowing = false
    @State private var isUploaderFollowLoading = false
    @State private var uploaderFollowError: String?

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
            ZStack {
                switch viewModel.state {
                case .idle, .loading(previous: nil):
                    LoadingView()
                case .success(let videoDto), .loading(previous: .some(let videoDto)):
                    content(video: videoDto.video)
                        .transition(.opacity)
                case .error(let msg):
                    ErrorView(errorMessage: msg)
                default:
                    Color.clear
                }
            }
            .animation(.easeInOut(duration: 0.25), value: viewModel.state)
            .task(id: videoId) {
                await historyManager.loadIfNeeded()
                await viewModel.fetchVideo(of: videoId)
            }
            .onDisappear {
                playbackHistoryController.stop()
            }
            .onChange(of: scenePhase) {
                if scenePhase != .active {
                    playbackHistoryController.flush()
                }
            }
//            .toolbar {
//                ToolbarItem(placement: .cancellationAction) {
//                    Button(role: .close, action: { dismiss() })
//                }
//            }
            .sheet(isPresented: $isShowingLogin) {
                AuthView()
            }
            .sheet(isPresented: $isShowingEditTag) {
                EditTagView()
            }
            .alert(
                String(localized: .errorOperationFailed),
                isPresented: Binding(
                    get: { uploaderFollowError != nil },
                    set: { if !$0 { uploaderFollowError = nil } }
                )
            ) {
                Button(.actionOk) { uploaderFollowError = nil }
            } message: {
                Text(uploaderFollowError ?? String(localized: .errorRequestFailed))
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
                            let newPlayer = AVPlayer(url: url)
                            playbackHistoryController.attach(
                                to: newPlayer,
                                videoID: videoId,
                                resumeAt: historyManager.resumePosition(for: videoId)
                            )
                            player = newPlayer
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
                    
                    if showingView == .comments {
                        HStack {
                            Spacer()
                            
                            Button {
                                
                            } label: {
                                Text(verbatim: "1 / 6")
                            }
                            
                            Button {
                                
                            } label: {
                                Label {
                                    Text(.videoSortByTime)
                                } icon: {
                                    Image(systemName: "arrow.down")
                                }
                                
                            }
                        }
                        .font(.caption)
                        .padding(.horizontal)
                        .buttonStyle(.glass)
                    }
                }
            }
        }
    }

    @ViewBuilder
    func info(video: VideoItem) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    if let uploader = video.uploaderInfo {
                        NavigationLink {
                            UserView(uid: uploader.uid, animationNamespace: animationNamespace)
                        } label: {
                            HStack(spacing: 12) {
                                UserAvatarView(imageId: uploader.avatar)
                                    .frame(width: 48, height: 48)
                                    .glassEffect(.regular.interactive())

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(verbatim: uploader.userNickname ?? uploader.username)
                                        .bold()
                                    Text(verbatim: "@\(uploader.username)")
                                        .foregroundStyle(.secondary)
                                        .font(.caption)
                                        .fontDesign(.monospaced)
                                }
                            }
                        }
                        .buttonStyle(.plain)
                    }

                    Spacer()

                    if let uploader = video.uploaderInfo, !uploader.isSelf {
                        Button {
                            if authManager.isAuthenticated {
                                Task { await toggleUploaderFollow(uid: uploader.uid) }
                            } else {
                                isShowingLogin = true
                            }
                        } label: {
                            if isUploaderFollowLoading {
                                ProgressView()
                                    .controlSize(.regular)
                            } else {
                                Label(
                                    uploaderIsFollowing ? .userFollowing : .userFollow,
                                    systemImage: uploaderIsFollowing ? "checkmark" : "plus"
                                )
                            }
                        }
                        .buttonStyle(.bordered)
                        .disabled(isUploaderFollowLoading)
                    }
                }
                .task(id: video.uploaderInfo?.uid) {
                    uploaderIsFollowing = video.uploaderInfo?.isFollowing ?? false
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
                                Button(action: { like() }) {
                                    Image(systemName: "hand.thumbsup")
                                        .symbolVariant(liked ? .fill : .none)
                                        .frame(width: 20, height: 20)

                                    Text(countLike, format: .number)
                                        .contentTransition(.numericText(value: Double(countLike)))
                                }
                                .foregroundStyle(liked ? .accent : .primary)
                                .sensoryFeedback(.success, trigger: liked) { oldValue, newValue in
                                    return newValue
                                }

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
                        .sensoryFeedback(.success, trigger: collected) { oldValue, newValue in
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
                    }
                    .monospacedDigit()
                    .contentTransition(.symbolEffect(.replace.offUp.byLayer))
                    .buttonStyle(.bordered)
                    .foregroundStyle(.primary)
                }
                .scrollClipDisabled()

                
                ScrollView(.horizontal, showsIndicators: false) {
                    Button {
                        isShowingEditTag = true
                    } label: {
                        Text(.videoOpenTagEditor)
                    }
                }
                .scrollClipDisabled()
            }
            .padding()
        }
    }

    @MainActor
    private func toggleUploaderFollow(uid: Int) async {
        guard !isUploaderFollowLoading else { return }
        isUploaderFollowLoading = true
        uploaderFollowError = nil
        defer { isUploaderFollowLoading = false }

        do {
            let response: UserActionResponseDTO
            if uploaderIsFollowing {
                response = try await APIService.shared.request(
                    .unfollowUser,
                    body: UnfollowUserRequestDTO(unfollowingUid: uid)
                )
            } else {
                response = try await APIService.shared.request(
                    .followUser,
                    body: FollowUserRequestDTO(followingUid: uid)
                )
            }

            guard response.success else {
                throw VideoUploaderFollowError.server(response.message)
            }
            uploaderIsFollowing.toggle()
        } catch {
            uploaderFollowError = error.localizedDescription
        }
    }

    var comments: some View {
        CommentsView(videoId: videoId, commentViewModel: commentViewModel)
    }

    var danmaku: some View {
        DanmakuView(videoId: videoId, danmakuViewModel: danmakuViewModel)
    }
}

private enum VideoUploaderFollowError: LocalizedError {
    case server(String?)

    var errorDescription: String? {
        switch self {
        case .server(let message): message ?? String(localized: .errorRequestFailed)
        }
    }
}

private enum VideoPlayerTab: Hashable, CaseIterable {
    case info
    case comments
    case danmakus
}

#Preview(traits: .commonPreviewTrait) {
    @Previewable @Namespace var animationNamespace
    VideoPlayerView(videoId: 1, animationNamespace: animationNamespace)
}
