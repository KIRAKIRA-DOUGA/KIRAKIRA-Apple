import Foundation

nonisolated struct Credentials: Codable, Sendable, Equatable {
    let email: String
    let token: String
    let uid: Int
    let uuid: String

    nonisolated var cookieString: String {
        "email=\(email); token=\(token); uid=\(uid); uuid=\(uuid)"
    }
}
