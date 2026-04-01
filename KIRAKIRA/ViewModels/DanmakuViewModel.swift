import Combine
import Foundation

@Observable
class DanmakuViewModel {
    var danmaku: [DanmakuDTO] = []
    var isLoading = false
    var errorMessage: String?
    private var loadedVideoId: Int?

    private let apiService = APIService.shared

    func fetchVideoDanmaku(of id: Int?, isRefresh: Bool = false) async {
        if !isRefresh {
            isLoading = true
        }
        errorMessage = nil

        guard let id else {
            isLoading = false
            errorMessage = "No danmaku"
            return
        }

        do {
            let response: DanmakuResponseDTO = try await apiService.request(.getVideoDanmaku(id: id))
            self.danmaku = response.danmaku
            loadedVideoId = id
        } catch {
            self.errorMessage = error.localizedDescription
        }

        if !isRefresh {
            isLoading = false
        }
    }

    func fetchVideoDanmakuIfNeeded(of id: Int?) async {
        guard loadedVideoId != id else { return }
        await fetchVideoDanmaku(of: id)
    }
}
