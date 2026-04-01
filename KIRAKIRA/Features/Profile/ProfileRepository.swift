import Foundation

enum ProfileRepositoryError: LocalizedError {
    case unauthenticated

    var errorDescription: String? {
        switch self {
        case .unauthenticated:
            return "You need to log in first."
        }
    }
}

protocol ProfileRepository {
    func currentUserDashboard() async throws -> CurrentUserDashboard
    func profile(for userID: Int?) async throws -> UserProfile
}

struct LiveProfileRepository: ProfileRepository {
    private let sessionStore: any AuthSessionProviding

    init(sessionStore: any AuthSessionProviding) {
        self.sessionStore = sessionStore
    }

    func currentUserDashboard() async throws -> CurrentUserDashboard {
        guard let credentials = await sessionStore.currentCredentials() else {
            throw ProfileRepositoryError.unauthenticated
        }

        let username =
            credentials.email
            .split(separator: "@")
            .first
            .map(String.init) ?? "user"

        let profile = UserProfile(
            id: credentials.uid,
            username: username,
            displayName: username.capitalized,
            bio: "Kawaii Forever!~",
            avatarImageID: "SamplePortrait",
            followerCount: 233,
            followingCount: 233,
            isSelf: true,
            isFollowing: false
        )

        return CurrentUserDashboard(
            profile: profile,
            notificationCount: 3,
            messageCount: 10
        )
    }

    func profile(for userID: Int?) async throws -> UserProfile {
        if userID == nil, let dashboard = try? await currentUserDashboard() {
            return dashboard.profile
        }

        return UserProfile(
            id: userID ?? 1,
            username: "Aira",
            displayName: "艾了个拉",
            bio: "Kawaii Forever!~",
            avatarImageID: "SamplePortrait",
            followerCount: 233,
            followingCount: 233,
            isSelf: false,
            isFollowing: false
        )
    }
}
