import Foundation

@Observable
final class HomeFeedViewModel {
    var videos: [ThumbVideoItem] = []
    var isLoading = false
    var errorMessage: String?

    private let repository: HomeRepository

    init(repository: HomeRepository) {
        self.repository = repository
    }

    func fetchHomeVideos(isRefresh: Bool = false) async {
        if !isRefresh {
            isLoading = true
        }
        errorMessage = nil

        do {
            videos = try await repository.homeVideos()
        } catch {
            errorMessage = error.localizedDescription
        }

        if !isRefresh {
            isLoading = false
        }
    }
}
