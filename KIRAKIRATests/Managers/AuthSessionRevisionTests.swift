import XCTest
@testable import KIRAKIRA

@MainActor
final class AuthSessionRevisionTests: XCTestCase {
    func testExplicitTransitionsAdvanceRevisionWithoutRealKeychain() async throws {
        let suite = "KIRAKIRATests.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let a = PrivacyTestSupport.credentials()
        let b = PrivacyTestSupport.credentials(uid: 2, uuid: "test-session-b")
        let manager = AuthManager(accounts: [a, b], defaults: defaults, accountStore: { _ in })
        XCTAssertEqual(manager.sessionRevision, 0)
        manager.switchAccount(to: b.id)
        XCTAssertEqual(manager.sessionRevision, 1)
        manager.switchAccount(to: a.id)
        XCTAssertEqual(manager.sessionRevision, 2)
        manager.switchAccount(to: a.id)
        XCTAssertEqual(manager.sessionRevision, 3)
        manager.switchAccount(to: "missing")
        XCTAssertEqual(manager.sessionRevision, 3)
        manager.continueAsGuest()
        XCTAssertEqual(manager.sessionRevision, 4)
        XCTAssertNil(manager.credentials)
    }

    func testCachedProfileUpdateDoesNotAdvanceSessionRevision() async throws {
        let suite = "KIRAKIRATests.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let original = PrivacyTestSupport.credentials()
        var storedAccounts: [Credentials] = []
        let manager = AuthManager(accounts: [original], defaults: defaults, accountStore: { storedAccounts = $0 })
        let refreshed = Credentials(email: original.email, token: original.token, uid: original.uid, uuid: original.uuid, userNickname: "Updated fixture")
        manager.storeUpdatedAccount(refreshed)
        XCTAssertEqual(manager.credentials?.userNickname, "Updated fixture")
        XCTAssertEqual(manager.sessionRevision, 0)
        XCTAssertEqual(storedAccounts, [refreshed])
    }
}
