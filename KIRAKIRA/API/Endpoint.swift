import Foundation

enum Endpoint {
    case getVideo(id: Int)
    case getHomeVideos
    case getVideoComments(id: Int)
    case getVideoDanmaku(id: Int)
    case login
    case register
    case logout
    case getSelfInfo
    case getUserInfo(uid: Int)
    case getUserVideos(uid: Int)
    case getFollowStats(uid: Int)
    case getFollowingList(uid: Int, page: Int, pageSize: Int)
    case getFollowerList(uid: Int, page: Int, pageSize: Int)
    case followUser
    case unfollowUser
    case blockUser
    case unblockUser
    case hideUser
    case showUser
    case getBrowsingHistory(videoTitle: String?)
    case updateBrowsingHistory
    case checkTwoFactor(email: String)
    case checkEmailExists(email: String)
    case checkUsername(username: String)
    case checkInvitationCode
    case sendEmailVerificationCode

    var baseURL: String { "https://rosales.kirakira.moe" }

    var path: String {
        switch self {
        case .getVideo(let id):
            return "/video?videoId=\(id)"
        case .getHomeVideos:
            return "/video/home"
        case .getVideoComments(let id):
            return "/video/comment?videoId=\(id)"
        case .getVideoDanmaku(let id):
            return "/video/danmaku?videoId=\(id)"
        case .login:
            return "/user/login"
        case .register:
            return "/user/registering"
        case .logout:
            return "/user/logout"
        case .getSelfInfo:
            return "/user/self"
        case .getUserInfo(let uid):
            return "/user/info?uid=\(uid)"
        case .getUserVideos(let uid):
            return "/video/user?uid=\(uid)"
        case .getFollowStats(let uid):
            return "/feed/stats?targetUid=\(uid)"
        case .getFollowingList(let uid, let page, let pageSize):
            return "/feed/following/list?targetUid=\(uid)&page=\(page)&pageSize=\(pageSize)"
        case .getFollowerList(let uid, let page, let pageSize):
            return "/feed/follower/list?targetUid=\(uid)&page=\(page)&pageSize=\(pageSize)"
        case .followUser:
            return "/feed/following"
        case .unfollowUser:
            return "/feed/unfollowing"
        case .blockUser:
            return "/block/user"
        case .unblockUser:
            return "/block/delete/user"
        case .hideUser:
            return "/block/hideuser"
        case .showUser:
            return "/block/delete/hideuser"
        case .getBrowsingHistory(let videoTitle):
            guard let videoTitle, !videoTitle.isEmpty else { return "/history/filter" }
            return "/history/filter?videoTitle=\(videoTitle.urlQueryEncoded)"
        case .updateBrowsingHistory:
            return "/history/merge"
        case .checkTwoFactor(let email):
            return "/user/checkUserHave2FAByEmail?email=\(email.urlQueryEncoded)"
        case .checkEmailExists(let email):
            return "/user/existsCheck?email=\(email.urlQueryEncoded)"
        case .checkUsername(let username):
            return "/user/checkUsername?username=\(username.urlQueryEncoded)"
        case .checkInvitationCode:
            return "/user/checkInvitationCode"
        case .sendEmailVerificationCode:
            return "/user/sendGeneralEmailVerificationCode"
        }
    }

    var method: HTTPMethod {
        switch self {
        case .getVideo, .getHomeVideos, .getVideoComments, .getVideoDanmaku, .getUserInfo, .getUserVideos,
            .logout, .getFollowStats, .getFollowingList, .getFollowerList, .getBrowsingHistory,
            .checkTwoFactor, .checkEmailExists, .checkUsername:
            return .get
        case .login, .register, .getSelfInfo, .followUser, .unfollowUser, .blockUser, .hideUser,
            .updateBrowsingHistory, .checkInvitationCode, .sendEmailVerificationCode:
            return .post
        case .unblockUser, .showUser:
            return .delete
        }
    }

    enum HTTPMethod: String {
        case get
        case post
        case delete
    }

    var url: URL? {
        URL(string: baseURL + path)
    }
}

private extension String {
    var urlQueryEncoded: String {
        addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? self
    }
}
