import AVKit
import Foundation

@Observable
final class VideoPlayerScreenModel {
    let videoId: Int
    let detailModel: VideoDetailViewModel
    let commentModel: CommentListViewModel
    let danmakuModel: DanmakuListViewModel

    var selectedTab: VideoPlayerTab = .info
    var isShowingLogin = false
    var countLike = 0
    var countDislike = 0
    var countCollected = 0
    var liked = false
    var disliked = false
    var collected = false
    var player: AVPlayer?

    init(videoId: Int, repository: VideoRepository) {
        self.videoId = videoId
        self.detailModel = VideoDetailViewModel(repository: repository)
        self.commentModel = CommentListViewModel(repository: repository)
        self.danmakuModel = DanmakuListViewModel(repository: repository)
    }

    func load() async {
        await detailModel.load(videoID: videoId)

        guard player == nil, let url = detailModel.video?.video.videoPart.first?.m3u8URL else {
            return
        }

        player = AVPlayer(url: url)
    }

    func followTapped(isAuthenticated: Bool) {
        if !isAuthenticated {
            isShowingLogin = true
        }
    }

    func toggleLike() {
        liked.toggle()
        countLike += liked ? 1 : -1
    }

    func toggleDislike() {
        disliked.toggle()
        countDislike += disliked ? 1 : -1
    }

    func toggleCollection() {
        collected.toggle()
        countCollected += collected ? 1 : -1
    }
}
