import Foundation

// MARK: - Service boundary

enum PrivacySaveResult: Equatable {
    case confirmed(PrivacySettings)
    case unconfirmed
}

@MainActor
protocol PrivacySettingsServiceProtocol {
    func load(credentials: Credentials) async throws -> PrivacySettings
    func save(
        original: PrivacySettings,
        values: [PrivacyItem: PrivacyVisibility],
        credentials: Credentials
    ) async throws -> PrivacySaveResult
}

// MARK: - Saving and confirmation

struct PrivacySettingsService: PrivacySettingsServiceProtocol {
    private let transport: any PrivacySettingsTransport

    init(transport: (any PrivacySettingsTransport)? = nil) {
        self.transport = transport ?? APIPrivacySettingsTransport()
    }

    func load(credentials: Credentials) async throws -> PrivacySettings {
        let response = try await transport.read(credentials: credentials)
        try Task.checkCancellation()
        return try response.validated(expectedUID: credentials.uid)
    }

    func save(
        original: PrivacySettings,
        values: [PrivacyItem: PrivacyVisibility],
        credentials: Credentials
    ) async throws -> PrivacySaveResult {
        guard original.uid == credentials.uid else { throw PrivacySettingsError.invalidResponse }
        let body = try PrivacySettingsUpdateDTO(original: original, values: values)
        try Task.checkCancellation()
        var accepted = false
        do {
            let response = try await transport.update(body, credentials: credentials)
            try Task.checkCancellation()
            try response.validateSuccess()
            accepted = true

            // Rosales can echo a payload without uid. Let the caller own the
            // account-scoped confirmation read separately from the write lifecycle.
            guard response.userSettings?.uid != nil else { return .unconfirmed }
            let saved = try response.validated(expectedUID: credentials.uid)
            try Task.checkCancellation()
            guard saved.values == values,
                PrivacyItem.allCases.allSatisfy({ item in saved.entries.contains { $0.id == item.rawValue } })
            else { return .unconfirmed }
            return .confirmed(saved)
        } catch is CancellationError {
            throw CancellationError()
        } catch {
            try Task.checkCancellation()
            if PrivacySettingsError.isUnauthorized(error) { throw PrivacySettingsError.unauthorized }
            // Never replay an uncertain write. A later explicit read reconciles the actual server state.
            if !accepted, Self.isDefiniteRejection(error) { throw error }
            return .unconfirmed
        }
    }

    private static func isDefiniteRejection(_ error: Error) -> Bool {
        if case PrivacySettingsError.rejected = error { return true }
        if case APIError.invalidURL = error { return true }
        if error is EncodingError { return true }
        if case APIError.httpError(let status) = error {
            return (400...499).contains(status) && status != 408
        }
        if let error = error as? URLError {
            return [.badURL, .unsupportedURL, .notConnectedToInternet, .cannotFindHost, .dnsLookupFailed].contains(error.code)
        }
        return false
    }
}

// MARK: - Injectable network adapter

/// A narrow, injectable boundary; all steps use the operation's credential snapshot.
@MainActor
protocol PrivacySettingsTransport {
    func read(credentials: Credentials) async throws -> PrivacySettingsResponseDTO
    func update(_ body: PrivacySettingsUpdateDTO, credentials: Credentials) async throws -> PrivacySettingsResponseDTO
}

struct APIPrivacySettingsTransport: PrivacySettingsTransport {
    func read(credentials: Credentials) async throws -> PrivacySettingsResponseDTO {
        try Task.checkCancellation()
        return try await APIService.shared.request(
            .getPrivacySettings,
            body: [String: String](),
            authenticatedWith: credentials
        )
    }

    func update(_ body: PrivacySettingsUpdateDTO, credentials: Credentials) async throws -> PrivacySettingsResponseDTO {
        try Task.checkCancellation()
        return try await APIService.shared.request(
            .updatePrivacySettings,
            body: body,
            authenticatedWith: credentials
        )
    }
}
