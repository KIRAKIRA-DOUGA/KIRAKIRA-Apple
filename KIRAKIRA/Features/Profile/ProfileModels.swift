import Foundation

struct UserProfile: Identifiable, Equatable {
    let id: Int
    let username: String
    let displayName: String
    let bio: String
    let avatarImageID: String?
    let followerCount: Int
    let followingCount: Int
    let isSelf: Bool
    let isFollowing: Bool
}

struct CurrentUserDashboard: Equatable {
    let profile: UserProfile
    let notificationCount: Int
    let messageCount: Int
}
