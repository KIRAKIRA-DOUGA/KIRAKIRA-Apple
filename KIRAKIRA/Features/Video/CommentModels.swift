import Foundation

struct VideoRequestCommentDTO: Codable {
    let videoCommentCount: Int
    let videoCommentList: [VideoCommentDTO]
}

struct VideoCommentDTO: Codable, Identifiable {
    let _id: String
    let text: String  // the comment text
    let commentIndex: Int
    let emitTime: Date
    let userInfo: UserInfoDTO
    let upvoteCount: Int
    let isUpvote: Bool
    let downvoteCount: Int
    let isDownvote: Bool

    var id: String { _id }

    var score: Int {
        upvoteCount - downvoteCount
    }
}
