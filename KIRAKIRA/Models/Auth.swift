import Foundation

struct UserLoginRequestDTO: Codable {
    let email: String
    let passwordHash: String  // SHA256
    let clientOtp: String?
    let verificationCode: String?
}

struct UserLoginResponseDTO: Codable {
    let success: Bool
    let email: String?
    let token: String?
    let uid: Int?
    let uuid: String?
    let userDataBootstrapHint: String?
    let passwordHint: String?
    let message: String?
    let authenticatorType: AuthenticatorType?

    private enum CodingKeys: String, CodingKey {
        case success, email, token, uid, userDataBootstrapHint, passwordHint, message, authenticatorType
        case uuid = "UUID"
    }
}

enum AuthenticatorType: String, Codable {
    case email, totp, none
}

struct CheckTwoFactorResponseDTO: Codable {
    let success: Bool
    let have2FA: Bool
    let type: AuthenticatorType?
    let message: String?
}

struct UserRegistrationRequestDTO: Codable {
    let email: String
    let verificationCode: String
    let passwordHash: String
    let invitationCode: String
    let username: String
    let userNickname: String?
}

struct UserRegistrationResponseDTO: Codable {
    let success: Bool
    let token: String?
    let uid: Int?
    let uuid: String?
    let userDataBootstrapHint: String?
    let message: String?

    private enum CodingKeys: String, CodingKey {
        case success, token, uid, userDataBootstrapHint, message
        case uuid = "UUID"
    }
}

struct SendEmailVerificationCodeRequestDTO: Codable {
    let email: String
    let clientLanguage: String
    let mailTemplate: String
    let exclusiveBusinessName: String
}

struct SendEmailVerificationCodeResponseDTO: Codable {
    let success: Bool
    let isCoolingDown: Bool
    let isMaxDailyCreateAttempts: Bool
    let isMaxDailyVerifierAttempts: Bool
    let message: String?
}

struct EmailExistsResponseDTO: Codable {
    let success: Bool
    let exists: Bool
    let message: String?
}

struct InvitationCodeRequestDTO: Codable {
    let invitationCode: String
}

struct InvitationCodeResponseDTO: Codable {
    let success: Bool
    let isAvailableInvitationCode: Bool
    let message: String?
}

struct UsernameResponseDTO: Codable {
    let success: Bool
    let isAvailableUsername: Bool
    let message: String?
}

struct UserLogoutResponseDTO: Codable {}
