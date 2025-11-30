import Foundation

struct UserLoginRequestDTO: Codable {
    let email: String
    let passwordHash: String  // SHA256
}

struct UserLoginResponseDTO: Codable {
    let success: Bool
    let token: String
    let uid: Int
    let UUID: String
}

struct UserLogoutResponseDTO: Codable {}
