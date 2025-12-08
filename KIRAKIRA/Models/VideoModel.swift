import Foundation
import os

struct GetVideoByKvidResponseDTO: Codable {
    let video: VideoItem
    let isBlocked: Bool
    let isBlockedByOther: Bool
    let isHidden: Bool
}

struct VideoItem: Codable, Identifiable {
    let videoId: Int
    let videoPart: [VideoPartDTO]
    let title: String
    let image: String?  // path of the thumbnail image
    let uploadDate: Date?
    let watchedCount: Int?
    let uploader: String?
    let uploaderInfo: UploaderInfoDTO?
    let duration: Int?
    let `description`: String
    let videoCategory: String
    let copyright: String

    var id: Int { videoId }

    struct UploaderInfoDTO: Codable {
        let uid: Int
        let username: String
        let userNickname: String?
        let avatar: String?
        let userBannerImage: String?
        let signature: String?
        let isFollowing: Bool
        let isSelf: Bool
    }

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

struct ThumbVideoResponseDTO: Codable {
    let videosCount: Int
    let videos: [ThumbVideoItem]
}

struct ThumbVideoItem: Codable, Identifiable {
    let videoId: Int
    let title: String
    let image: String?  // path of the thumbnail image
    let uploadDate: Date?
    let watchedCount: Int?
    let uploaderNickname: String?
    let duration: Int?
    let `description`: String?

    var id: Int { videoId }
}
