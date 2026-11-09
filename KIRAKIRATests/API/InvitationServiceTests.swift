import XCTest
@testable import KIRAKIRA

@MainActor
final class InvitationServiceTests: XCTestCase {
    func testEndpointPathsMethodsAndEmptyCreationBody() async throws {
        XCTAssertEqual(Endpoint.getMyInvitationCode.path, "/user/myInvitationCode")
        XCTAssertEqual(Endpoint.getMyInvitationCode.method, .get)
        XCTAssertEqual(Endpoint.createInvitationCode.path, "/user/createInvitationCode")
        XCTAssertEqual(Endpoint.createInvitationCode.method, .post)
        XCTAssertEqual(String(data: try JSONEncoder().encode([String: String]()), encoding: .utf8), "{}")
    }

    func testLoadAndCreateUseExplicitCredentialSnapshot() async throws {
        let transport = MockInvitationTransport()
        let credentials = InvitationTestSupport.credentials(uuid: "fixture-explicit-snapshot")
        let service = InvitationService(transport: transport)
        let loaded = try await service.load(credentials: credentials)
        let created = try await service.create(credentials: credentials)
        XCTAssertEqual(loaded, [InvitationTestSupport.invitation()])
        XCTAssertEqual(created, .created(InvitationTestSupport.invitation()))
        XCTAssertEqual(transport.reads, [credentials])
        XCTAssertEqual(transport.creations, [credentials])
    }

    func testLoadThrowsForMissingListWrongAccountAndBlankCode() async throws {
        for object: [String: Any] in [
            ["success": true],
            ["success": true, "invitationCodeResult": [InvitationTestSupport.payload(uid: 2)]],
            ["success": true, "invitationCodeResult": [InvitationTestSupport.payload(code: " \n")]],
        ] {
            let transport = MockInvitationTransport()
            transport.readHandler = { _ in try InvitationTestSupport.decode(object) }
            do {
                _ = try await InvitationService(transport: transport).load(credentials: InvitationTestSupport.credentials())
                XCTFail("Invalid list must throw")
            } catch {
                guard case InvitationError.invalidResponse = error else { return XCTFail("Expected invalid response") }
            }
        }
    }

    func testSuccessfulCoolingDownDoesNotCreateOrReadAgain() async throws {
        let transport = MockInvitationTransport()
        transport.createHandler = { _ in
            try InvitationTestSupport.decode(["success": true, "isCoolingDown": true])
        }
        let result = try await create(transport)
        XCTAssertEqual(result, .coolingDown)
        XCTAssertEqual(transport.creations.count, 1)
        XCTAssertTrue(transport.reads.isEmpty)
    }

    func testFailedSuccessTakesPrecedenceOverCoolingAndMalformedPayload() async throws {
        let transport = MockInvitationTransport()
        transport.createHandler = { _ in
            try InvitationTestSupport.decode([
                "success": false, "isCoolingDown": true,
                "invitationCodeResult": "malformed-unused-payload",
            ])
        }
        do { _ = try await create(transport); XCTFail("success=false is a definite rejection") }
        catch {
            guard case InvitationError.rejected = error else { return XCTFail("Expected rejected") }
        }
        XCTAssertEqual(transport.creations.count, 1)
        XCTAssertTrue(transport.reads.isEmpty)
    }

    func testAcceptedMissingOrInvalidPayloadIsUnconfirmedAndNeverReplayed() async throws {
        for payload: Any in [NSNull(), InvitationTestSupport.payload(uid: 2), InvitationTestSupport.payload(code: " "), InvitationTestSupport.payload(milliseconds: -1), ["invalid": true]] {
            let transport = MockInvitationTransport()
            transport.createHandler = { _ in
                try InvitationTestSupport.decode([
                    "success": true, "isCoolingDown": false, "invitationCodeResult": payload,
                ])
            }
            let result = try await create(transport)
            XCTAssertEqual(result, .unconfirmed)
            XCTAssertEqual(transport.creations.count, 1)
            XCTAssertTrue(transport.reads.isEmpty)
        }
        let transport = MockInvitationTransport()
        transport.createHandler = { _ in try InvitationTestSupport.decode(["success": true, "isCoolingDown": false]) }
        let result = try await create(transport)
        XCTAssertEqual(result, .unconfirmed)
        XCTAssertEqual(transport.creations.count, 1)
    }

    func testTimeoutDisconnectedServerAndDecodingErrorsAreUnconfirmedWithoutReplay() async throws {
        let errors: [Error] = [
            URLError(.timedOut), URLError(.networkConnectionLost), URLError(.cannotConnectToHost),
            APIError.httpError(statusCode: 408), APIError.httpError(statusCode: 500),
            APIError.httpError(statusCode: 503), APIError.decodingError(InvitationError.invalidResponse),
            DecodingError.dataCorrupted(.init(codingPath: [], debugDescription: "fixture-invalid-response")),
            APIError.requestFailed(URLError(.timedOut)),
        ]
        for error in errors {
            let transport = MockInvitationTransport()
            transport.createHandler = { _ in throw error }
            let result = try await create(transport)
            XCTAssertEqual(result, .unconfirmed)
            XCTAssertEqual(transport.creations.count, 1)
            XCTAssertTrue(transport.reads.isEmpty)
        }
    }

    func testDefiniteTransportFailuresThrowWithoutReplay() async throws {
        let errors: [Error] = [
            APIError.invalidURL, InvitationError.rejected,
            APIError.httpError(statusCode: 400), APIError.httpError(statusCode: 404), APIError.httpError(statusCode: 429),
            URLError(.badURL), URLError(.unsupportedURL), URLError(.notConnectedToInternet),
            URLError(.cannotFindHost), URLError(.dnsLookupFailed),
            EncodingError.invalidValue("fixture", .init(codingPath: [], debugDescription: "fixture-encoding-failure")),
            APIError.requestFailed(URLError(.notConnectedToInternet)),
        ]
        for expected in errors {
            let transport = MockInvitationTransport()
            transport.createHandler = { _ in throw expected }
            do { _ = try await create(transport); XCTFail("Definite failure must throw") }
            catch { XCTAssertFalse(InvitationError.isUnauthorized(error)) }
            XCTAssertEqual(transport.creations.count, 1)
            XCTAssertTrue(transport.reads.isEmpty)
        }
    }

    func testOnlyExactTrimmedMessagesMapToUnauthorizedForReadAndCreate() async throws {
        for message in ["生成邀请码失败，非法用户！", " \n获取自己的邀请码失败，非法用户！\t"] {
            let transport = MockInvitationTransport()
            transport.readHandler = { _ in try InvitationTestSupport.decode(["success": false, "message": message]) }
            transport.createHandler = { _ in try InvitationTestSupport.decode(["success": false, "isCoolingDown": true, "message": message]) }
            do {
                _ = try await InvitationService(transport: transport).load(credentials: InvitationTestSupport.credentials())
                XCTFail("Authentication rejection must throw")
            } catch {
                guard case InvitationError.unauthorized = error else { return XCTFail("Expected unauthorized") }
            }
            do { _ = try await create(transport); XCTFail("Authentication rejection must throw") }
            catch {
                guard case InvitationError.unauthorized = error else { return XCTFail("Expected unauthorized") }
            }
        }
        for message in ["未知错误", "生成邀请码失败，非法用户！额外文字", "非法用户", ""] {
            let transport = MockInvitationTransport()
            transport.readHandler = { _ in try InvitationTestSupport.decode(["success": false, "message": message]) }
            transport.createHandler = { _ in try InvitationTestSupport.decode(["success": false, "isCoolingDown": false, "message": message]) }
            do {
                _ = try await InvitationService(transport: transport).load(credentials: InvitationTestSupport.credentials())
                XCTFail("Rejected read must throw")
            } catch {
                guard case InvitationError.rejected = error else { return XCTFail("Expected rejected") }
            }
            do { _ = try await create(transport); XCTFail("Rejected create must throw") }
            catch {
                guard case InvitationError.rejected = error else { return XCTFail("Expected rejected") }
            }
        }
    }

    func testHTTP401And403AreUnauthorizedForBothOperations() async throws {
        for status in [401, 403] {
            let transport = MockInvitationTransport()
            transport.readHandler = { _ in throw APIError.httpError(statusCode: status) }
            transport.createHandler = { _ in throw APIError.httpError(statusCode: status) }
            do {
                _ = try await InvitationService(transport: transport).load(credentials: InvitationTestSupport.credentials())
                XCTFail("Expected authentication failure")
            } catch {
                guard case InvitationError.unauthorized = error else { return XCTFail("Expected unauthorized") }
            }
            do { _ = try await create(transport); XCTFail("Expected authentication failure") }
            catch {
                guard case InvitationError.unauthorized = error else { return XCTFail("Expected unauthorized") }
            }
        }
        XCTAssertFalse(InvitationError.isUnauthorized(APIError.httpError(statusCode: 500)))
        XCTAssertFalse(InvitationError.isUnauthorized(InvitationError.rejected))
        XCTAssertTrue(InvitationError.isUnauthorized(APIError.requestFailed(APIError.httpError(statusCode: 401))))
    }

    func testReadTransportFailuresRemainErrorsRatherThanEmptyResults() async throws {
        let transport = MockInvitationTransport()
        transport.readHandler = { _ in throw URLError(.timedOut) }
        do {
            _ = try await InvitationService(transport: transport).load(credentials: InvitationTestSupport.credentials())
            XCTFail("Read errors must propagate")
        } catch { XCTAssertEqual((error as? URLError)?.code, .timedOut) }
        XCTAssertEqual(transport.reads.count, 1)
        XCTAssertTrue(transport.creations.isEmpty)
    }

    func testCancellationPropagatesFromBothOperations() async throws {
        let transport = MockInvitationTransport()
        transport.readHandler = { _ in throw CancellationError() }
        transport.createHandler = { _ in throw CancellationError() }
        do {
            _ = try await InvitationService(transport: transport).load(credentials: InvitationTestSupport.credentials())
            XCTFail("Expected cancellation")
        } catch { XCTAssertTrue(error is CancellationError) }
        do { _ = try await create(transport); XCTFail("Expected cancellation") }
        catch { XCTAssertTrue(error is CancellationError) }
    }

    func testAlreadyCancelledTasksDoNotStartRequests() async {
        let transport = MockInvitationTransport()
        let service = InvitationService(transport: transport)
        let credentials = InvitationTestSupport.credentials()
        let read = Task { try await service.load(credentials: credentials) }
        read.cancel()
        do { _ = try await read.value; XCTFail("Expected cancellation") }
        catch { XCTAssertTrue(error is CancellationError) }
        let write = Task { try await service.create(credentials: credentials) }
        write.cancel()
        do { _ = try await write.value; XCTFail("Expected cancellation") }
        catch { XCTAssertTrue(error is CancellationError) }
        XCTAssertTrue(transport.reads.isEmpty)
        XCTAssertTrue(transport.creations.isEmpty)
    }

    func testLateCancelledCreateDoesNotPublishSuccessfulResponse() async {
        let transport = MockInvitationTransport()
        transport.createHandler = { _ in
            withUnsafeCurrentTask { $0?.cancel() }
            return try InvitationTestSupport.creation()
        }
        let service = InvitationService(transport: transport)
        let credentials = InvitationTestSupport.credentials()
        let task = Task { try await service.create(credentials: credentials) }
        do { _ = try await task.value; XCTFail("Expected cancellation") }
        catch { XCTAssertTrue(error is CancellationError) }
        XCTAssertEqual(transport.creations.count, 1)
        XCTAssertTrue(transport.reads.isEmpty)
    }

    private func create(_ transport: MockInvitationTransport) async throws -> InvitationCreationResult {
        try await InvitationService(transport: transport).create(credentials: InvitationTestSupport.credentials())
    }
}
