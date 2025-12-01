import Foundation
import os

struct VideoResponseDTO: Codable {
    let video: VideoResponseInfoDTO
    let isBlocked: Bool
    let isBlockedByOther: Bool
    let isHidden: Bool
}

struct VideoResponseInfoDTO: Codable, Identifiable {
    let videoId: Int
    let title: String
    let image: String  // path of the thumbnail image
    let uploadDate: Date
    let videoPart: [VideoPartDTO]
    let `description`: String

    var id: Int { videoId }
}

struct VideoPartDTO: Codable, Identifiable {
    let id: Int
    let videoPartTitle: String
    let link: String

    var mpdURL: URL {
        return URL(string: link)!
    }

    var m3u8URL: URL {
        return URL(string: link.replacingOccurrences(of: ".mpd", with: ".m3u8"))!
    }
}

struct VideoListDTO: Codable {
    let videosCount: Int
    let videos: [VideoListItemDTO]
}

struct VideoListItemDTO: Codable, Identifiable {
    let videoId: Int
    let title: String
    let image: String  // path of the thumbnail image
    let uploadDate: Date
    let uploaderNickname: String

    var id: Int { videoId }
}
