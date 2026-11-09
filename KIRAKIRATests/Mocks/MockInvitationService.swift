import Foundation
@testable import KIRAKIRA

@MainActor
final class MockInvitationService: InvitationServiceProtocol {
    var loadHandler: (Credentials) async throws -> [Invitation] = { _ in [] }
    var createHandler: (Credentials) async throws -> InvitationCreationResult = { _ in .coolingDown }
    private(set) var reads: [Credentials] = []
    private(set) var creations: [Credentials] = []

    func load(credentials: Credentials) async throws -> [Invitation] {
        reads.append(credentials)
        return try await loadHandler(credentials)
    }

    func create(credentials: Credentials) async throws -> InvitationCreationResult {
        creations.append(credentials)
        return try await createHandler(credentials)
    }
}
