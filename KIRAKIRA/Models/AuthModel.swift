import Foundation

nonisolated struct Credentials: Codable {
    let email: String
    let token: String
    let uid: Int
    let uuid: String

    nonisolated var cookieString: String {
        "email=\(email); token=\(token); uid=\(uid); uuid=\(uuid)"
    }
}

struct UserLoginRequestDTO: Codable {
    let email: String
    let passwordHash: String  // SHA256
}

struct UserLoginResponseDTO: Codable {
    let success: Bool
    let token: String
    let uid: Int
    let uuid: String

    private enum CodingKeys: String, CodingKey {
        case success
        case token
        case uid
        case uuid = "UUID"
    }
}

struct UserLogoutResponseDTO: Codable {}
