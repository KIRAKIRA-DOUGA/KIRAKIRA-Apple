import Combine
import Foundation

@Observable
class VideoViewModel {
    var video: GetVideoByKvidResponseDTO?
    var isLoading = false
    var errorMessage: String?

    private let apiService = APIService.shared

    func fetchVideo(of id: Int?) async {
        isLoading = true
        errorMessage = nil

        guard let id else {
            isLoading = false
            errorMessage = "No Video"
            return
        }

        do {
            let response: GetVideoByKvidResponseDTO = try await apiService.request(.getVideo(id: id))
            self.video = response
        } catch {
            self.errorMessage = error.localizedDescription
        }

        isLoading = false
    }
}
