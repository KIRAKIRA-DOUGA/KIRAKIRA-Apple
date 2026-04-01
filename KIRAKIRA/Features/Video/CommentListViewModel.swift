import Foundation

@Observable
class CommentListViewModel {
    var comments: [VideoCommentDTO] = []
    var isLoading = false
    var errorMessage: String?
    private var loadedVideoId: Int?

    private let repository: VideoRepository

    init(repository: VideoRepository) {
        self.repository = repository
    }

    func load(videoID: Int?, isRefresh: Bool = false) async {
        if !isRefresh {
            isLoading = true
        }
        errorMessage = nil

        guard let videoID else {
            isLoading = false
            errorMessage = "No comments"
            return
        }

        do {
            comments = try await repository.comments(for: videoID)
            loadedVideoId = videoID
        } catch {
            errorMessage = error.localizedDescription
        }

        if !isRefresh {
            isLoading = false
        }
    }

    func loadIfNeeded(videoID: Int?) async {
        guard loadedVideoId != videoID else { return }
        await load(videoID: videoID)
    }
}
