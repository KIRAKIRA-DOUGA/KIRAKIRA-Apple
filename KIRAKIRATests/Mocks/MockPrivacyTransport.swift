import Foundation
@testable import KIRAKIRA

@MainActor
final class MockPrivacyTransport: PrivacySettingsTransport {
    var readHandler: (Credentials) async throws -> PrivacySettingsResponseDTO = { _ in
        try PrivacyTestSupport.response()
    }
    var updateHandler: (PrivacySettingsUpdateDTO, Credentials) async throws -> PrivacySettingsResponseDTO = { _, _ in
        try PrivacyTestSupport.response()
    }
    private(set) var reads: [Credentials] = []
    private(set) var updates: [(PrivacySettingsUpdateDTO, Credentials)] = []

    func read(credentials: Credentials) async throws -> PrivacySettingsResponseDTO {
        reads.append(credentials)
        return try await readHandler(credentials)
    }

    func update(_ body: PrivacySettingsUpdateDTO, credentials: Credentials) async throws -> PrivacySettingsResponseDTO {
        updates.append((body, credentials))
        return try await updateHandler(body, credentials)
    }
}
