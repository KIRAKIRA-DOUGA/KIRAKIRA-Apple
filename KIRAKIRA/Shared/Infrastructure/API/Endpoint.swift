import Foundation

enum Endpoint {
    case getVideo(id: Int)
    case getHomeVideos
    case getVideoComments(id: Int)
    case getVideoDanmaku(id: Int)
    case login
    case logout
    case getSelfInfo

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
        case .logout:
            return "/user/logout"
        case .getSelfInfo:
            return "/user/self"
        }
    }

    var method: HTTPMethod {
        switch self {
        case .getVideo, .getHomeVideos, .getVideoComments, .getVideoDanmaku, .logout:
            return .get
        case .login, .getSelfInfo:
            return .post
        }
    }

    enum HTTPMethod: String {
        case get
        case post
    }

    var url: URL? {
        URL(string: baseURL + path)
    }
}
