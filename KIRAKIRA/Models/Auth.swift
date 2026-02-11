import Foundation

struct UserLoginRequestDTO: Codable {
    let email: String
    let passwordHash: String  // SHA256
    let verificationCode: Int?
}

struct UserVerificationResponseDTO: Codable {
    let success: Bool
    let have2FA: Bool
    let type: String?
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
