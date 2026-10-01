import Foundation
import OSLog

@MainActor
@Observable
final class BrowsingHistoryManager {
    static let shared = BrowsingHistoryManager()

    private(set) var state: LoadingState<[BrowsingHistoryItem]> = .idle

    private let apiService = APIService.shared
    private let logger = Logger(subsystem: "moe.kirakira", category: "BrowsingHistory")
    private var loadedAccountID: String?

    private init() {}

    var items: [BrowsingHistoryItem] {
        state.value ?? []
    }

    func loadIfNeeded() async {
        guard let accountID = AuthManager.shared.credentials?.id else {
            loadedAccountID = nil
            state = .empty
            return
        }
        guard loadedAccountID != accountID else { return }
        await fetch()
    }

    func fetch(videoTitle: String? = nil) async {
        guard let account = AuthManager.shared.credentials else {
            loadedAccountID = nil
            state = .empty
            return
        }

        state.beginLoading()
        do {
            let response: GetBrowsingHistoryResponseDTO = try await apiService.request(
                .getBrowsingHistory(videoTitle: videoTitle),
                body: nil as String?,
                authenticatedWith: account
            )
            guard response.success else { throw BrowsingHistoryError.server(response.message) }
            let history = response.result ?? []
            loadedAccountID = account.id
            state = history.isEmpty ? .empty : .success(history)
        } catch is CancellationError {
            state.cancelLoading()
        } catch {
            logger.error("Failed to load browsing history: \(error.localizedDescription)")
            state = .error(error.localizedDescription)
        }
    }

    func resumePosition(for videoID: Int) -> TimeInterval? {
        guard let item = items.first(where: { $0.videoId == videoID }),
            let position = item.playbackPosition,
            position >= 3
        else { return nil }

        if let duration = item.duration, position >= duration - 10 { return nil }
        return position
    }

    func record(videoID: Int, position: TimeInterval) async {
        guard let account = AuthManager.shared.credentials,
            position.isFinite,
            position >= 0
        else { return }

        let wholeSeconds = Int(position.rounded(.down))
        let request = UpdateBrowsingHistoryRequestDTO(
            uuid: account.uuid,
            category: .video,
            id: String(videoID),
            anchor: String(wholeSeconds)
        )

        do {
            let response: UpdateBrowsingHistoryResponseDTO = try await apiService.request(
                .updateBrowsingHistory,
                body: request,
                authenticatedWith: account
            )
            guard response.success else {
                throw BrowsingHistoryError.server(response.message)
            }
            updateCachedPosition(videoID: videoID, seconds: wholeSeconds)
        } catch is CancellationError {
            return
        } catch {
            logger.warning("Failed to record playback position: \(error.localizedDescription)")
        }
    }

    private func updateCachedPosition(videoID: Int, seconds: Int) {
        guard var history = state.value,
            let index = history.firstIndex(where: { $0.videoId == videoID })
        else { return }

        history[index].anchor = String(seconds)
        history[index].lastUpdateDateTime = .now
        history.sort { $0.lastUpdateDateTime > $1.lastUpdateDateTime }
        state = .success(history)
    }
}

private enum BrowsingHistoryError: LocalizedError {
    case server(String?)

    var errorDescription: String? {
        switch self {
        case .server(let message): message ?? String(localized: .historyRequestFailed)
        }
    }
}
