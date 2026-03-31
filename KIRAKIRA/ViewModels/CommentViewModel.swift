import Combine
import Foundation

@Observable
class CommentViewModel {
    var comments: [VideoCommentDTO] = []
    var isLoading = false
    var errorMessage: String?
    private var loadedVideoId: Int?

    private let apiService = APIService.shared

    func fetchVideoComment(of id: Int?, isRefresh: Bool = false) async {
        if !isRefresh {
            isLoading = true
        }
        errorMessage = nil

        guard let id else {
            isLoading = false
            errorMessage = "No comments"
            return
        }

        do {
            let response: VideoRequestCommentDTO = try await apiService.request(.getVideoComments(id: id))
            self.comments = response.videoCommentList
            loadedVideoId = id
        } catch {
            self.errorMessage = error.localizedDescription
        }

        if !isRefresh {
            isLoading = false
        }
    }

    func fetchVideoCommentIfNeeded(of id: Int?) async {
        guard loadedVideoId != id else { return }
        await fetchVideoComment(of: id)
    }
}
