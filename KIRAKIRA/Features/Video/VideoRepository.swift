import Foundation

protocol VideoRepository {
    func videoDetail(for videoID: Int) async throws -> GetVideoByKvidResponseDTO
    func comments(for videoID: Int) async throws -> [VideoCommentDTO]
    func danmaku(for videoID: Int) async throws -> [DanmakuDTO]
}

struct LiveVideoRepository: VideoRepository {
    private let apiService: APIServiceProtocol

    init(apiService: APIServiceProtocol) {
        self.apiService = apiService
    }

    func videoDetail(for videoID: Int) async throws -> GetVideoByKvidResponseDTO {
        try await apiService.request(.getVideo(id: videoID))
    }

    func comments(for videoID: Int) async throws -> [VideoCommentDTO] {
        let response: VideoRequestCommentDTO = try await apiService.request(.getVideoComments(id: videoID))
        return response.videoCommentList
    }

    func danmaku(for videoID: Int) async throws -> [DanmakuDTO] {
        let response: DanmakuResponseDTO = try await apiService.request(.getVideoDanmaku(id: videoID))
        return response.danmaku
    }
}
