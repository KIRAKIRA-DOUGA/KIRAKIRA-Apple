import Foundation

@MainActor
@Observable
final class UserProfileViewModel {
    private(set) var profileState: LoadingState<PublicUserProfile> = .idle
    private(set) var videosState: LoadingState<[ThumbVideoItem]> = .idle
    private(set) var followingCount: Int?
    private(set) var followerCount: Int?
    private(set) var isBlocked = false
    private(set) var isBlockedByOther = false
    private(set) var isHidden = false
    private(set) var isFollowing = false
    private(set) var isSelf = false
    private(set) var isRelationshipLoading = false
    var errorMessage: String?

    private let apiService = APIService.shared
    private(set) var uid: Int?

    var profile: PublicUserProfile? { profileState.value }
    var videos: [ThumbVideoItem] { videosState.value ?? [] }

    func load(uid: Int) async {
        self.uid = uid
        profileState.beginLoading()
        videosState.beginLoading()
        errorMessage = nil

        do {
            async let profileRequest: GetPublicUserResponseDTO = apiService.request(.getUserInfo(uid: uid))
            async let videosRequest: GetUserVideosResponseDTO = apiService.request(.getUserVideos(uid: uid))
            async let statsRequest: FollowStatsResponseDTO = apiService.request(.getFollowStats(uid: uid))
            let (profileResponse, videosResponse, statsResponse) = try await (
                profileRequest,
                videosRequest,
                statsRequest
            )

            isBlocked = profileResponse.isBlocked
            isBlockedByOther = profileResponse.isBlockedByOther
            isHidden = profileResponse.isHidden

            guard profileResponse.success else {
                throw UserFeatureError.server(profileResponse.message)
            }

            if let profile = profileResponse.result {
                self.isFollowing = profile.isFollowing
                self.isSelf = profile.isSelf
                profileState = .success(profile)
            } else if profileResponse.isBlocked {
                profileState = .empty
            } else {
                throw UserFeatureError.server(profileResponse.message)
            }

            if videosResponse.success {
                videosState = videosResponse.videos.isEmpty ? .empty : .success(videosResponse.videos)
            } else {
                videosState = .error(videosResponse.message ?? String(localized: .userVideosLoadFailed))
            }

            if statsResponse.success {
                followingCount = statsResponse.followingCount ?? 0
                followerCount = statsResponse.followerCount ?? 0
            }
        } catch is CancellationError {
            profileState.cancelLoading()
            videosState.cancelLoading()
        } catch {
            let message = error.localizedDescription
            profileState = .error(message)
            videosState = .error(message)
        }
    }

    func toggleFollow() async {
        guard let uid, !isSelf, !isBlocked, !isBlockedByOther else { return }
        isRelationshipLoading = true
        errorMessage = nil
        defer { isRelationshipLoading = false }

        do {
            let response: UserActionResponseDTO
            if isFollowing {
                response = try await apiService.request(
                    .unfollowUser,
                    body: UnfollowUserRequestDTO(unfollowingUid: uid)
                )
            } else {
                response = try await apiService.request(
                    .followUser,
                    body: FollowUserRequestDTO(followingUid: uid)
                )
            }
            guard response.success else { throw UserFeatureError.server(response.message) }

            isFollowing.toggle()
            if let followerCount {
                self.followerCount = max(0, followerCount + (isFollowing ? 1 : -1))
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func toggleBlock() async {
        guard let uid, !isSelf else { return }
        isRelationshipLoading = true
        errorMessage = nil
        defer { isRelationshipLoading = false }

        do {
            let response: UserActionResponseDTO = try await apiService.request(
                isBlocked ? .unblockUser : .blockUser,
                body: BlockUserRequestDTO(blockUid: uid)
            )
            guard response.success else { throw UserFeatureError.server(response.message) }
            isBlocked.toggle()

            if isBlocked {
                if isFollowing, let followerCount {
                    self.followerCount = max(0, followerCount - 1)
                }
                profileState = .empty
                videosState = .empty
                isFollowing = false
            } else {
                await load(uid: uid)
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func toggleHidden() async {
        guard let uid, !isSelf else { return }
        isRelationshipLoading = true
        errorMessage = nil
        defer { isRelationshipLoading = false }

        do {
            let response: UserActionResponseDTO = try await apiService.request(
                isHidden ? .showUser : .hideUser,
                body: HideUserRequestDTO(hideUid: uid)
            )
            guard response.success else { throw UserFeatureError.server(response.message) }
            isHidden.toggle()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func clearError() {
        errorMessage = nil
    }
}

enum FollowListKind: Hashable {
    case following
    case followers
}

@MainActor
@Observable
final class FollowListViewModel {
    private(set) var state: LoadingState<[FollowListUser]> = .idle
    private(set) var totalCount = 0
    private(set) var isLoadingMore = false

    private let apiService = APIService.shared
    private let pageSize = 50
    private var page = 0
    private var uid: Int?
    private var kind: FollowListKind?

    var items: [FollowListUser] { state.value ?? [] }
    var canLoadMore: Bool { items.count < totalCount }

    func load(uid: Int, kind: FollowListKind) async {
        self.uid = uid
        self.kind = kind
        page = 0
        totalCount = 0
        state.beginLoading()
        await requestPage(1, replacing: true)
    }

    func loadMoreIfNeeded(currentItem: FollowListUser) async {
        guard currentItem.id == items.last?.id, canLoadMore, !isLoadingMore else { return }
        await requestPage(page + 1, replacing: false)
    }

    private func requestPage(_ requestedPage: Int, replacing: Bool) async {
        guard let uid, let kind else { return }
        if !replacing { isLoadingMore = true }
        defer { isLoadingMore = false }

        do {
            let endpoint: Endpoint = switch kind {
            case .following:
                .getFollowingList(uid: uid, page: requestedPage, pageSize: pageSize)
            case .followers:
                .getFollowerList(uid: uid, page: requestedPage, pageSize: pageSize)
            }
            let response: GetFollowListResponseDTO = try await apiService.request(endpoint)
            guard response.success else { throw UserFeatureError.server(response.message) }

            totalCount = response.totalCount ?? 0
            page = requestedPage
            let newItems = response.result ?? []
            let allItems = replacing ? newItems : items + newItems
            state = allItems.isEmpty ? .empty : .success(allItems)
        } catch is CancellationError {
            state.cancelLoading()
        } catch {
            if replacing {
                state = .error(error.localizedDescription)
            }
        }
    }
}

private enum UserFeatureError: LocalizedError {
    case server(String?)

    var errorDescription: String? {
        switch self {
        case .server(let message): message ?? String(localized: .errorRequestFailed)
        }
    }
}
