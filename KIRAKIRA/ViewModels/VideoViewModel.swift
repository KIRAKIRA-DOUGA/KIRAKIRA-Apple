import Combine
import Foundation

@Observable
class VideoViewModel {
    var videos: [VideoListItemDTO] = []
    var isLoading = false
    var errorMessage: String?

    private let apiService = APIService.shared

    func fetchHomeVideos() async {
        isLoading = true
        errorMessage = nil

        do {
            let response: VideoListDTO = try await apiService.request(.getHomeVideos)
            self.videos = response.videos
        } catch {
            self.errorMessage = error.localizedDescription
        }

        isLoading = false
    }
}
