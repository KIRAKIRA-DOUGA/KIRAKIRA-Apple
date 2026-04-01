import Foundation

@Observable
final class UserScreenModel {
    enum Tab: Hashable {
        case videos
        case collections
    }

    let userID: Int?

    var profile: UserProfile?
    var isLoading = false
    var errorMessage: String?
    var selectedTab: Tab = .videos
    var isShowingEditProfileSheet = false
    var isBannerVisible = true
    var isUsernameVisible = true

    private let repository: ProfileRepository

    init(userID: Int? = nil, repository: ProfileRepository) {
        self.userID = userID
        self.repository = repository
    }

    func load() async {
        isLoading = true
        errorMessage = nil

        do {
            profile = try await repository.profile(for: userID)
        } catch {
            profile = nil
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    func toggleFollowing() {
        guard let profile else { return }

        self.profile = UserProfile(
            id: profile.id,
            username: profile.username,
            displayName: profile.displayName,
            bio: profile.bio,
            avatarImageID: profile.avatarImageID,
            followerCount: profile.followerCount + (profile.isFollowing ? -1 : 1),
            followingCount: profile.followingCount,
            isSelf: profile.isSelf,
            isFollowing: !profile.isFollowing
        )
    }
}
