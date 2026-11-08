import Foundation

nonisolated enum PrivacySettingsError: Error, LocalizedError {
    case invalidResponse
    case rejected
    case unauthorized

    var errorDescription: String? {
        switch self {
        case .invalidResponse: String(localized: .privacyInvalidResponse)
        case .rejected: String(localized: .privacyRequestRejected)
        case .unauthorized: String(localized: .privacySignInRequired)
        }
    }

    static func isUnauthorized(_ error: Error) -> Bool {
        if case PrivacySettingsError.unauthorized = error { return true }
        if case APIError.httpError(let status) = error { return status == 401 || status == 403 }
        return false
    }
}
