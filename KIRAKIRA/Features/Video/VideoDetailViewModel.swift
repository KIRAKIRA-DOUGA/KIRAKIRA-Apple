import Foundation

@Observable
class VideoDetailViewModel {
    var video: GetVideoByKvidResponseDTO?
    var isLoading = false
    var errorMessage: String?

    private let repository: VideoRepository

    init(repository: VideoRepository) {
        self.repository = repository
    }

    func load(videoID: Int?) async {
        isLoading = true
        errorMessage = nil

        guard let videoID else {
            isLoading = false
            errorMessage = "No Video"
            return
        }

        do {
            video = try await repository.videoDetail(for: videoID)
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }
}
