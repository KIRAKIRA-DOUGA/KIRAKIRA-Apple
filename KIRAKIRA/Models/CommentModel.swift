import Foundation

nonisolated struct VideoRequestCommentDTO: Decodable {
    let videoCommentCount: Int
    let videoCommentList: [VideoCommentDTO]

    private enum CodingKeys: String, CodingKey {
        case success, videoCommentCount, videoCommentList
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        guard try container.decode(Bool.self, forKey: .success) else {
            throw DecodingError.dataCorruptedError(
                forKey: .success, in: container, debugDescription: "Comment request was rejected."
            )
        }
        videoCommentList = try container.decodeIfPresent([VideoCommentDTO].self, forKey: .videoCommentList) ?? []
        // The backend omits the aggregate count when there are no comments.
        videoCommentCount = try container.decodeIfPresent(Int.self, forKey: .videoCommentCount) ?? videoCommentList.count
    }
}

struct VideoCommentDTO: Codable, Identifiable, Equatable {
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

    static func == (lhs: Self, rhs: Self) -> Bool {
        return lhs._id == rhs._id
    }

    var score: Int {
        upvoteCount - downvoteCount
    }
}
