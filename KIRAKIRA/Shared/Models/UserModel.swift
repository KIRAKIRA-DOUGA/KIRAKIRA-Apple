import Foundation

struct UserInfoDTO: Codable {
    let username: String
    let userNickname: String
    let avatar: String?  // path of the avatar image
}
