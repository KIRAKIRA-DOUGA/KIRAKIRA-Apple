import Combine
import Foundation

@Observable
class CommentViewModel {
    var comments: [VideoCommentDTO] = []
    var isLoading = false
    var errorMessage: String?

    private let apiService = APIService.shared

    func fetchVideoComment(of id: Int?) async {
        isLoading = true
        errorMessage = nil

        guard let id else {
            isLoading = false
            errorMessage = "No comments"
            return
        }

        do {
            let response: VideoRequestCommentDTO = try await apiService.request(.getVideoComments(id: id))
            self.comments = response.videoCommentList
        } catch {
            self.errorMessage = error.localizedDescription
        }

        isLoading = false
    }
}
