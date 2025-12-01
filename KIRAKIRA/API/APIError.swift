import Foundation

enum APIError: Error, LocalizedError {
    case invalidURL
    case requestFailed(Error)
    case decodingError(Error)
    case httpError(statusCode: Int)
    case unknown

    var errorDescription: String? {
        switch self {
        case .invalidURL: return "The URL was invalid."
        case .requestFailed: return "The network request failed."
        case .decodingError: return "Failed to decode the response."
        case .httpError(let code): return "Server returned status code \(code)."
        case .unknown: return "An unknown error occurred."
        }
    }
}
