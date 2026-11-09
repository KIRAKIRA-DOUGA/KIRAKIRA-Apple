import Foundation

nonisolated enum InvitationCreationResult: Equatable, Sendable {
    case created(Invitation)
    case coolingDown
    case unconfirmed
}

nonisolated enum InvitationError: Error, LocalizedError {
    case invalidResponse
    case rejected
    case unauthorized

    var errorDescription: String? {
        switch self {
        case .invalidResponse: String(localized: "INVITATION_INVALID_RESPONSE")
        case .rejected: String(localized: "INVITATION_REQUEST_FAILED")
        case .unauthorized: String(localized: "INVITATION_SIGN_IN_REQUIRED")
        }
    }

    static func isUnauthorized(_ error: Error) -> Bool {
        if case InvitationError.unauthorized = error { return true }
        if case APIError.httpError(let status) = error { return status == 401 || status == 403 }
        if case APIError.requestFailed(let underlying) = error { return isUnauthorized(underlying) }
        return false
    }

    static func validateSuccess(_ success: Bool, message: String?) throws {
        guard !success else { return }
        switch message?.trimmingCharacters(in: .whitespacesAndNewlines) {
        case "生成邀请码失败，非法用户！", "获取自己的邀请码失败，非法用户！":
            throw InvitationError.unauthorized
        default:
            throw InvitationError.rejected
        }
    }
}

@MainActor
protocol InvitationServiceProtocol {
    func load(credentials: Credentials) async throws -> [Invitation]
    func create(credentials: Credentials) async throws -> InvitationCreationResult
}

struct InvitationService: InvitationServiceProtocol {
    private let transport: any InvitationTransport

    init(transport: (any InvitationTransport)? = nil) {
        self.transport = transport ?? APIInvitationTransport()
    }

    func load(credentials: Credentials) async throws -> [Invitation] {
        try Task.checkCancellation()
        do {
            let response = try await transport.read(credentials: credentials)
            try Task.checkCancellation()
            return try response.validated(expectedUID: credentials.uid)
        } catch is CancellationError {
            throw CancellationError()
        } catch {
            try Task.checkCancellation()
            if InvitationError.isUnauthorized(error) { throw InvitationError.unauthorized }
            throw error
        }
    }

    func create(credentials: Credentials) async throws -> InvitationCreationResult {
        try Task.checkCancellation()
        do {
            let response = try await transport.create(credentials: credentials)
            try Task.checkCancellation()
            try InvitationError.validateSuccess(response.success, message: response.message)
            if response.isCoolingDown { return .coolingDown }
            guard let payload = response.invitationCodeResult,
                let invitation = try? payload.validated(expectedUID: credentials.uid)
            else { return .unconfirmed }
            return .created(invitation)
        } catch is CancellationError {
            throw CancellationError()
        } catch {
            try Task.checkCancellation()
            if InvitationError.isUnauthorized(error) { throw InvitationError.unauthorized }
            if Self.isDefiniteRejection(error) { throw error }
            // The server may have committed the write. Never replay POST or infer failure from a read.
            return .unconfirmed
        }
    }

    private static func isDefiniteRejection(_ error: Error) -> Bool {
        if case InvitationError.rejected = error { return true }
        if case APIError.invalidURL = error { return true }
        if case APIError.requestFailed(let underlying) = error { return isDefiniteRejection(underlying) }
        if error is EncodingError { return true }
        if case APIError.httpError(let status) = error {
            return (400..<500).contains(status) && status != 408
        }
        if let error = error as? URLError {
            return [.badURL, .unsupportedURL, .notConnectedToInternet, .cannotFindHost, .dnsLookupFailed].contains(error.code)
        }
        return false
    }
}

@MainActor
protocol InvitationTransport {
    func read(credentials: Credentials) async throws -> InvitationListResponseDTO
    func create(credentials: Credentials) async throws -> InvitationCreationResponseDTO
}

struct APIInvitationTransport: InvitationTransport {
    func read(credentials: Credentials) async throws -> InvitationListResponseDTO {
        try Task.checkCancellation()
        return try await APIService.shared.request(
            .getMyInvitationCode,
            body: nil as String?,
            authenticatedWith: credentials
        )
    }

    func create(credentials: Credentials) async throws -> InvitationCreationResponseDTO {
        try Task.checkCancellation()
        return try await APIService.shared.request(
            .createInvitationCode,
            body: [String: String](),
            authenticatedWith: credentials
        )
    }
}
