import Foundation

protocol HomeRepository {
    func homeVideos() async throws -> [ThumbVideoItem]
}

struct LiveHomeRepository: HomeRepository {
    private let apiService: APIServiceProtocol

    init(apiService: APIServiceProtocol) {
        self.apiService = apiService
    }

    func homeVideos() async throws -> [ThumbVideoItem] {
        let response: ThumbVideoResponseDTO = try await apiService.request(.getHomeVideos)
        return response.videos
    }
}
