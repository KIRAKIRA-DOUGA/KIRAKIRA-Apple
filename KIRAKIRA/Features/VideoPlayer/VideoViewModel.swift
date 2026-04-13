import Combine
import Foundation

@MainActor
@Observable
class VideoViewModel {
    var state: LoadingState<GetVideoByKvidResponseDTO> = .idle
    private let apiService = APIService.shared

    func fetchVideo(of id: Int) async {
        state.beginLoading()

        do {
            let response: GetVideoByKvidResponseDTO = try await apiService.request(.getVideo(id: id))
            state = .success(response)
        } catch is CancellationError {
            state.cancelLoading()
        } catch {
            state = .error(error.localizedDescription)
        }
    }
}
