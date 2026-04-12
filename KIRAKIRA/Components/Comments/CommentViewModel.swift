import Combine
import Foundation

@MainActor
@Observable
class CommentViewModel {
    var state: LoadingState<[VideoCommentDTO]> = .idle
    private let apiService = APIService.shared

    func fetch(of id: Int) async {
        state.beginLoading()

        do {
            let response: VideoRequestCommentDTO = try await apiService.request(.getVideoComments(id: id))
            state = response.videoCommentList.isEmpty ? .empty : .success(response.videoCommentList)
        } catch is CancellationError {
            state.cancelLoading()
        } catch {
            state = .error(error.localizedDescription)
        }
    }
}
