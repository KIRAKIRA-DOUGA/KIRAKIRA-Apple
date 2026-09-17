import Foundation

enum APIError: Error, LocalizedError {
    case invalidURL
    case requestFailed(Error)
    case decodingError(Error)
    case httpError(statusCode: Int)
    case unknown

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return String(localized: "ERROR_INVALID_URL")
        case .requestFailed:
            return String(localized: "ERROR_NETWORK_REQUEST_FAILED")
        case .decodingError:
            return String(localized: "ERROR_RESPONSE_DECODING_FAILED")
        case .httpError(let code):
            return String.localizedStringWithFormat(
                String(localized: "ERROR_HTTP_STATUS"),
                code
            )
        case .unknown:
            return String(localized: "ERROR_UNKNOWN")
        }
    }
}
