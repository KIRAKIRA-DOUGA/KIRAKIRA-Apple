import Foundation
@testable import KIRAKIRA

@MainActor
final class MockInvitationTransport: InvitationTransport {
    var readHandler: (Credentials) async throws -> InvitationListResponseDTO = { _ in
        try InvitationTestSupport.list()
    }
    var createHandler: (Credentials) async throws -> InvitationCreationResponseDTO = { _ in
        try InvitationTestSupport.creation()
    }
    private(set) var reads: [Credentials] = []
    private(set) var creations: [Credentials] = []

    func read(credentials: Credentials) async throws -> InvitationListResponseDTO {
        reads.append(credentials)
        return try await readHandler(credentials)
    }

    func create(credentials: Credentials) async throws -> InvitationCreationResponseDTO {
        creations.append(credentials)
        return try await createHandler(credentials)
    }
}
