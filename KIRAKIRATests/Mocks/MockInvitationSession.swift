import Foundation
@testable import KIRAKIRA

@MainActor
final class MockInvitationSession: InvitationSessionProviding {
    var sessionRevision = 0
    var credentials: Credentials? = Credentials(
        email: "invitation-tests@example.invalid",
        token: "not-a-real-credential",
        uid: 1,
        uuid: "invitation-test-account-a"
    )

    func transition(to credentials: Credentials?) {
        self.credentials = credentials
        sessionRevision += 1
    }
}
