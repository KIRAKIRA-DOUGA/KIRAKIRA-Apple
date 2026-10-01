import Foundation

struct PublicUserProfile: Codable, Equatable {
    let username: String?
    let userNickname: String?
    let avatar: String?
    let userBannerImage: String?
    let signature: String?
    let gender: String?
    let userCreateDateTime: Date?
    let roles: [String]?
    let isFollowing: Bool
    let isSelf: Bool

    var displayName: String {
        if let userNickname, !userNickname.isEmpty { return userNickname }
        if let username, !username.isEmpty { return username }
        return "—"
    }
}

struct GetPublicUserResponseDTO: Codable {
    let success: Bool
    let message: String?
    let result: PublicUserProfile?
    let isBlockedByOther: Bool
    let isBlocked: Bool
    let isHidden: Bool
}

struct GetUserVideosResponseDTO: Codable {
    let success: Bool
    let message: String?
    let videosCount: Int
    let videos: [ThumbVideoItem]
    let isBlockedByOther: Bool
    let isBlocked: Bool
    let isHidden: Bool
}

struct FollowUserRequestDTO: Codable {
    let followingUid: Int
}

struct UnfollowUserRequestDTO: Codable {
    let unfollowingUid: Int
}

struct BlockUserRequestDTO: Codable {
    let blockUid: Int
}

struct HideUserRequestDTO: Codable {
    let hideUid: Int
}

struct UserActionResponseDTO: Codable {
    let success: Bool
    let message: String?
}

struct FollowListUser: Codable, Identifiable, Equatable {
    let uid: Int
    let username: String?
    let userNickname: String?
    let avatar: String?
    let followingCreateTime: Date?
    let isFollowing: Bool?

    var id: Int { uid }

    var displayName: String {
        if let userNickname, !userNickname.isEmpty { return userNickname }
        if let username, !username.isEmpty { return username }
        return "UID \(uid)"
    }
}

struct GetFollowListResponseDTO: Codable {
    let success: Bool
    let message: String?
    let totalCount: Int?
    let result: [FollowListUser]?
}
