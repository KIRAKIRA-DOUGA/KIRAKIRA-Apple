import Foundation

enum BrowsingHistoryCategory: String, Codable {
    case video
    case photo
    case comment
}

struct BrowsingHistoryItem: Codable, Identifiable, Equatable {
    let category: BrowsingHistoryCategory
    let videoId: Int
    let title: String
    let image: String?
    let uploadDate: Date?
    let watchedCount: Int?
    let uploader: String?
    let uploaderId: Int?
    let duration: TimeInterval?
    let description: String?
    var anchor: String?
    var lastUpdateDateTime: Date

    var id: Int { videoId }

    var playbackPosition: TimeInterval? {
        guard let anchor, let seconds = TimeInterval(anchor), seconds.isFinite, seconds >= 0 else { return nil }
        return seconds
    }

    var playbackProgress: Double? {
        guard let playbackPosition, let duration, duration > 0 else { return nil }
        return min(max(playbackPosition / duration, 0), 1)
    }
}

struct GetBrowsingHistoryResponseDTO: Codable {
    let success: Bool
    let message: String?
    let result: [BrowsingHistoryItem]?
}

struct UpdateBrowsingHistoryRequestDTO: Codable {
    let uuid: String
    let category: BrowsingHistoryCategory
    let id: String
    let anchor: String
}

struct UpdateBrowsingHistoryResponseDTO: Codable {
    let success: Bool
    let message: String?
}
