import XCTest
@testable import KIRAKIRA

@MainActor
final class PrivacySettingsServiceTests: XCTestCase {
    func testEndpointsArePostAndReadBodyIsEmptyObject() async throws {
        XCTAssertEqual(Endpoint.getPrivacySettings.path, "/user/settings")
        XCTAssertEqual(Endpoint.updatePrivacySettings.path, "/user/settings/update")
        XCTAssertEqual(Endpoint.getPrivacySettings.method, .post)
        XCTAssertEqual(Endpoint.updatePrivacySettings.method, .post)
        XCTAssertEqual(String(data: try JSONEncoder().encode([String: String]()), encoding: .utf8), "{}")
    }

    func testLoadValidatesAccount() async throws {
        let transport = MockPrivacyTransport()
        transport.readHandler = { _ in try PrivacyTestSupport.response(uid: 2) }
        do {
            _ = try await PrivacySettingsService(transport: transport).load(credentials: PrivacyTestSupport.credentials())
            XCTFail("Mismatched uid must fail")
        } catch { XCTAssertTrue(error is PrivacySettingsError) }
    }

    func testConfirmedWriteWithUIDDoesNotReadAgain() async throws {
        let transport = MockPrivacyTransport()
        transport.updateHandler = { _, _ in try PrivacyTestSupport.response(visibility: .private) }
        let result = try await save(transport)
        XCTAssertEqual(result, .confirmed(PrivacyTestSupport.settings(visibility: .private)))
        XCTAssertEqual(transport.updates.count, 1)
        XCTAssertTrue(transport.reads.isEmpty)
    }

    func testMissingUIDRequiresReadWithSameCredentials() async throws {
        let transport = MockPrivacyTransport()
        transport.updateHandler = { _, _ in try PrivacyTestSupport.response(uid: nil, visibility: .private) }
        transport.readHandler = { _ in try PrivacyTestSupport.response(visibility: .private) }
        let result = try await save(transport)
        XCTAssertEqual(result, .confirmed(PrivacyTestSupport.settings(visibility: .private)))
        XCTAssertEqual(transport.reads, [PrivacyTestSupport.credentials()])
        XCTAssertEqual(transport.updates.first?.1, transport.reads.first)
    }

    func testAcceptedWriteReadFailureIsPendingAndNeverReplayed() async throws {
        let transport = MockPrivacyTransport()
        transport.updateHandler = { _, _ in try PrivacyTestSupport.response(uid: nil) }
        transport.readHandler = { _ in throw URLError(.timedOut) }
        let result = try await save(transport)
        XCTAssertEqual(result, .unconfirmed)
        XCTAssertEqual(transport.updates.count, 1)
        XCTAssertEqual(transport.reads.count, 1)
    }

    func testWrongValuesAndMissingKnownEntriesArePending() async throws {
        let transport = MockPrivacyTransport()
        let result = try await save(transport)
        XCTAssertEqual(result, .unconfirmed)
        transport.updateHandler = { _, _ in
            try PrivacyTestSupport.decode(["success": true, "userSettings": ["uid": 1]])
        }
        let missing = try await PrivacySettingsService(transport: transport).save(
            original: PrivacyTestSupport.settings(), values: PrivacyTestSupport.values(), credentials: PrivacyTestSupport.credentials()
        )
        XCTAssertEqual(missing, .unconfirmed)
    }

    func testTimeoutServerFailureAndDecodingFailureArePending() async throws {
        for error: Error in [URLError(.timedOut), APIError.httpError(statusCode: 500), APIError.decodingError(PrivacySettingsError.invalidResponse)] {
            let transport = MockPrivacyTransport()
            transport.updateHandler = { _, _ in throw error }
            let result = try await save(transport)
            XCTAssertEqual(result, .unconfirmed)
            XCTAssertEqual(transport.updates.count, 1)
            XCTAssertTrue(transport.reads.isEmpty)
        }
    }

    func testDefiniteRejectionAndUnauthorizedThrow() async throws {
        for error: Error in [PrivacySettingsError.rejected, APIError.httpError(statusCode: 401), URLError(.notConnectedToInternet)] {
            let transport = MockPrivacyTransport()
            transport.updateHandler = { _, _ in throw error }
            do {
                _ = try await save(transport)
                XCTFail("Definite rejection must throw")
            } catch {
                if PrivacySettingsError.isUnauthorized(error) {
                    XCTAssertEqual(error.localizedDescription, PrivacySettingsError.unauthorized.localizedDescription)
                }
            }
            XCTAssertEqual(transport.updates.count, 1)
        }
        let transport = MockPrivacyTransport()
        transport.updateHandler = { _, _ in try PrivacyTestSupport.decode(["success": false]) }
        do { _ = try await save(transport); XCTFail("success=false must throw") }
        catch { XCTAssertTrue(error is PrivacySettingsError) }
    }

    // A returned DTO models an HTTP 200 response: non-2xx responses throw at the APIService boundary.
    func testLoadMapsHTTP200AuthenticationFailureToUnauthorized() async throws {
        let transport = MockPrivacyTransport()
        transport.readHandler = { _ in
            try PrivacyTestSupport.decode([
                "success": false,
                "message": "获取用户个性设置失败，用户验证时未通过"
            ])
        }
        do {
            _ = try await PrivacySettingsService(transport: transport).load(credentials: PrivacyTestSupport.credentials())
            XCTFail("Body-level authentication failure must throw")
        } catch {
            guard case PrivacySettingsError.unauthorized = error else {
                return XCTFail("Expected unauthorized, got \(error)")
            }
        }
        XCTAssertEqual(transport.reads.count, 1)
    }

    func testSaveMapsHTTP200AuthenticationFailureToUnauthorizedWithoutConfirmationRead() async throws {
        let transport = MockPrivacyTransport()
        transport.updateHandler = { _, _ in
            try PrivacyTestSupport.decode([
                "success": false,
                "message": "更新或创建用户设置失败，非法用户！"
            ])
        }
        do {
            _ = try await save(transport)
            XCTFail("Body-level authentication failure must throw")
        } catch {
            guard case PrivacySettingsError.unauthorized = error else {
                return XCTFail("Expected unauthorized, got \(error)")
            }
        }
        XCTAssertEqual(transport.updates.count, 1)
        XCTAssertTrue(transport.reads.isEmpty)
    }

    func testConfirmationReadHTTP200AuthenticationFailureThrowsInsteadOfBecomingPending() async throws {
        let transport = MockPrivacyTransport()
        transport.updateHandler = { _, _ in try PrivacyTestSupport.response(uid: nil, visibility: .private) }
        transport.readHandler = { _ in
            try PrivacyTestSupport.decode([
                "success": false,
                "message": "获取用户个性设置失败，用户验证时未通过"
            ])
        }
        do {
            _ = try await save(transport)
            XCTFail("Confirmation authentication failure must throw")
        } catch {
            guard case PrivacySettingsError.unauthorized = error else {
                return XCTFail("Expected unauthorized, got \(error)")
            }
        }
        XCTAssertEqual(transport.updates.count, 1)
        XCTAssertEqual(transport.reads.count, 1)
    }

    func testOtherHTTP200FailuresRemainRejected() async throws {
        for message in [
            "获取用户个性设置失败，查询未成功",
            "更新或创建用户设置失败，必要的数据为空或关联平台信息出错",
            "更新或创建用户设置失败，未知异常"
        ] {
            let transport = MockPrivacyTransport()
            transport.readHandler = { _ in try PrivacyTestSupport.decode(["success": false, "message": message]) }
            transport.updateHandler = { _, _ in try PrivacyTestSupport.decode(["success": false, "message": message]) }
            do {
                _ = try await PrivacySettingsService(transport: transport).load(credentials: PrivacyTestSupport.credentials())
                XCTFail("Failed read must throw")
            } catch {
                guard case PrivacySettingsError.rejected = error else {
                    return XCTFail("Expected rejected, got \(error)")
                }
            }
            do {
                _ = try await save(transport)
                XCTFail("Rejected write must throw")
            } catch {
                guard case PrivacySettingsError.rejected = error else {
                    return XCTFail("Expected rejected, got \(error)")
                }
            }
        }
    }

    func testCancellationPropagatesRatherThanBecomingFailure() async throws {
        let transport = MockPrivacyTransport()
        transport.updateHandler = { _, _ in throw CancellationError() }
        do { _ = try await save(transport); XCTFail("Expected cancellation") }
        catch { XCTAssertTrue(error is CancellationError) }
    }

    private func save(_ transport: MockPrivacyTransport) async throws -> PrivacySaveResult {
        try await PrivacySettingsService(transport: transport).save(
            original: PrivacyTestSupport.settings(),
            values: PrivacyTestSupport.values(.private),
            credentials: PrivacyTestSupport.credentials()
        )
    }
}
