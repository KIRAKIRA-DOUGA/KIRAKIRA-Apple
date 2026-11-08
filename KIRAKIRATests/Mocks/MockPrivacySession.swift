import Foundation
@testable import KIRAKIRA

@MainActor
final class MockPrivacySession: PrivacySessionProviding {
    var sessionRevision = 0
    var credentials: Credentials? = PrivacyTestSupport.credentials()

    func transition(to credentials: Credentials?) {
        self.credentials = credentials
        sessionRevision += 1
    }
}
