import Foundation
@testable import KIRAKIRA

@MainActor
final class MockBlockingSession: BlockingSessionProviding {
    var sessionRevision = 0
    var credentials: Credentials? = BlockingTestSupport.credentials

    func transition(to credentials: Credentials?) {
        self.credentials = credentials
        sessionRevision += 1
    }
}
