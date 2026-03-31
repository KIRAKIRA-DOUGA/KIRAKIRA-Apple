import Combine
import Foundation

@Observable
class ThumbVideoViewModel {
    var videos: [ThumbVideoItem] = []
    var isLoading = false
    var errorMessage: String?

    private let apiService = APIService.shared

    func fetchHomeVideos(isRefresh: Bool = false) async {
        if !isRefresh {
            isLoading = true
        }
        errorMessage = nil

        do {
            let response: ThumbVideoResponseDTO = try await apiService.request(.getHomeVideos)
            self.videos = response.videos
        } catch {
            self.errorMessage = error.localizedDescription
        }

        if !isRefresh {
            isLoading = false
        }
    }
}
