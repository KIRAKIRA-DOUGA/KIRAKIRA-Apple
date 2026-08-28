import Combine
import Foundation

@MainActor
@Observable
class HomeVideoViewModel {
    var state: LoadingState<[ThumbVideoItem]> = .idle
    private let apiService = APIService.shared

    func fetch() async {
        state.beginLoading()

        do {
            let response: ThumbVideoResponseDTO = try await apiService.request(.getHomeVideos)
            state = response.videos.isEmpty ? .empty : .success(response.videos)
        } catch is CancellationError {
            state.cancelLoading()
        } catch {
            state = .error(error.localizedDescription)
        }
    }
}
