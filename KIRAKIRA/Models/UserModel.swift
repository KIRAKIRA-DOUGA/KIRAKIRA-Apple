import Foundation

struct UserInfoDTO: Codable {
    let username: String
    let userNickname: String
    let avatar: String?  // path of the avatar image
}

struct AccountProfileDTO: Codable {
    let username: String?
    let userNickname: String?
    let avatar: String?
    let userBannerImage: String?
    let signature: String?
    let userBirthday: String?
}

struct SelfUserInfoRequestDTO: Codable {
    let uuid: String
    let token: String
}

struct SelfUserInfoResponseDTO: Codable {
    let success: Bool
    let message: String?
    let result: AccountProfileDTO?
}

struct FollowStatsResponseDTO: Codable {
    let success: Bool
    let message: String?
    let followingCount: Int?
    let followerCount: Int?
}
