import XCTest
@testable import KIRAKIRA

@MainActor
final class BlockingSettingsServiceTests: XCTestCase {
    func testEndpointsKeepFivePathsAndMethodsAndEncodeQuery() throws {
        let components = ["user", "hideuser", "tag", "keyword", "regex"]
        for (category, component) in zip(BlockingRuleCategory.allCases, components) {
            XCTAssertEqual(Endpoint.addBlockingRule(category: category).path, "/block/\(component)")
            XCTAssertEqual(Endpoint.addBlockingRule(category: category).method, .post)
            XCTAssertEqual(Endpoint.removeBlockingRule(category: category).path, "/block/delete/\(component)")
            XCTAssertEqual(Endpoint.removeBlockingRule(category: category).method, .delete)
            let list = Endpoint.getBlockingRules(category: category, page: 0, pageSize: 20)
            XCTAssertEqual(list.path, "/block/list?type=\(category.rawValue)&page=0&pageSize=20")
            XCTAssertEqual(list.method, .get)
        }
        let query = "a&b=#?+ 中文/%"
        let endpoint = Endpoint.searchBlockingTags(query: query)
        let url = try XCTUnwrap(endpoint.url)
        let parsed = try XCTUnwrap(URLComponents(url: url, resolvingAgainstBaseURL: false))
        XCTAssertEqual(parsed.queryItems, [URLQueryItem(name: "tagName", value: query)])
        XCTAssertNil(parsed.fragment)
        XCTAssertEqual(endpoint.method, .get)
        XCTAssertEqual(Endpoint.blockUser.path, "/block/user")
        XCTAssertEqual(Endpoint.showUser.path, "/block/delete/hideuser")
    }

    func testConfirmedChangesNeverReadAndPreserveExactRemovalTarget() async throws {
        let transport = MockBlockingTransport()
        transport.mutationResponse = try BlockingTestSupport.decode(["success": true])
        let service = BlockingSettingsService(transport: transport)
        for category in BlockingRuleCategory.allCases {
            for removing in [false, true] {
                let target = category.isUser || category == .tag ? "42" : " rule "
                let result = try await service.change(category: category, target: target, removing: removing, credentials: BlockingTestSupport.credentials)
                XCTAssertEqual(result, .confirmed)
                XCTAssertEqual(transport.writes.last, .init(category: category, target: target, removing: removing))
            }
        }
        XCTAssertEqual(transport.writes.count, 10)
        XCTAssertEqual(transport.loads, 0)
        XCTAssertEqual(transport.lookups, 0)
        XCTAssertEqual(transport.searches, 0)
    }

    func testTimeoutMalformedResponseAndServerErrorAreUnconfirmedWithoutRead() async throws {
        for error in [URLError(.timedOut), BlockingSettingsError.invalidResponse, APIError.httpError(statusCode: 500)] as [Error] {
            let transport = MockBlockingTransport()
            transport.error = error
            let result = try await BlockingSettingsService(transport: transport).change(category: .keyword, target: "word", removing: false, credentials: BlockingTestSupport.credentials)
            XCTAssertEqual(result, .unconfirmed)
            XCTAssertEqual(transport.writes.count, 1)
            XCTAssertEqual(transport.loads, 0)
        }
        let transport = MockBlockingTransport()
        transport.error = APIError.decodingError(NSError(domain: "fixture", code: 1))
        let result = try await BlockingSettingsService(transport: transport).change(category: .regex, target: ".*", removing: false, credentials: BlockingTestSupport.credentials)
        XCTAssertEqual(result, .unconfirmed)
    }

    func testRejectedUnsafeRegexAndHTTP200AuthenticationAreDistinct() async throws {
        let cases: [([String: Any], BlockingSettingsError)] = [
            (["success": false, "message": "添加正则表达式失败，正则表达式已存在"], .rejected),
            (["success": false, "unsafeRegex": true], .unsafeRegex),
            (["success": false, "message": "添加正则表达式失败，用户 Token 不合法"], .unauthorized),
            (["success": false, "message": "获取黑名单失败，用户未登录"], .unauthorized)
        ]
        for (object, expected) in cases {
            let transport = MockBlockingTransport()
            transport.mutationResponse = try BlockingTestSupport.decode(object)
            do {
                _ = try await BlockingSettingsService(transport: transport).change(category: .regex, target: ".*", removing: false, credentials: BlockingTestSupport.credentials)
                XCTFail("Expected \(expected)")
            } catch { XCTAssertEqual(error as? BlockingSettingsError, expected) }
            XCTAssertEqual(transport.writes.count, 1)
            XCTAssertEqual(transport.loads, 0)
        }
    }

    func testDefiniteRejectionAndCancellationPropagate() async {
        for error in [APIError.httpError(statusCode: 400), URLError(.notConnectedToInternet), CancellationError(), URLError(.cancelled)] as [Error] {
            let transport = MockBlockingTransport()
            transport.error = error
            do {
                _ = try await BlockingSettingsService(transport: transport).change(category: .tag, target: "42", removing: false, credentials: BlockingTestSupport.credentials)
                XCTFail("Expected error")
            } catch is CancellationError {
                XCTAssertTrue(error is CancellationError || (error as? URLError)?.code == .cancelled)
            } catch {
                XCTAssertFalse(error is CancellationError)
            }
            XCTAssertEqual(transport.writes.count, 1)
            XCTAssertEqual(transport.loads, 0)
        }
    }

    func testAlreadyCancelledTaskNeverSendsQueuedWrite() async {
        let transport = MockBlockingTransport()
        let service = BlockingSettingsService(transport: transport)
        let task = Task { @MainActor in
            withUnsafeCurrentTask { $0?.cancel() }
            do {
                _ = try await service.change(category: .keyword, target: "word", removing: false, credentials: BlockingTestSupport.credentials)
                return false
            } catch is CancellationError {
                return true
            } catch {
                return false
            }
        }
        let cancelled = await task.value
        XCTAssertTrue(cancelled)
        XCTAssertTrue(transport.writes.isEmpty)
        XCTAssertEqual(transport.loads, 0)
    }

    func testInvalidTargetsNeverReachTransport() async {
        let transport = MockBlockingTransport()
        let service = BlockingSettingsService(transport: transport)
        let inputs: [(BlockingRuleCategory, String)] = [(.block, "1"), (.block, "uuid"), (.hide, "0"), (.tag, "-1"),
            (.tag, "9007199254740992"), (.keyword, ""), (.regex, String(repeating: "😀", count: 16))]
        for (category, target) in inputs {
            do {
                _ = try await service.change(category: category, target: target, removing: false, credentials: BlockingTestSupport.credentials)
                XCTFail("Expected invalid input")
            } catch { XCTAssertEqual(error as? BlockingSettingsError, .invalidInput) }
        }
        for uid in [0, -1, 9_007_199_254_740_992] {
            do {
                _ = try await service.lookupUser(uid: uid, credentials: BlockingTestSupport.credentials)
                XCTFail("Expected invalid UID")
            } catch { XCTAssertEqual(error as? BlockingSettingsError, .invalidInput) }
        }
        XCTAssertTrue(transport.writes.isEmpty)
        XCTAssertEqual(transport.lookups, 0)
    }

    func testLookupRequiresActualProfileOrExplicitBlockedFlag() async throws {
        let transport = MockBlockingTransport()
        let service = BlockingSettingsService(transport: transport)
        for object in [["success": false], ["success": true], ["success": true, "isBlocked": false],
                       ["success": true, "result": [String: Any]()]] as [[String: Any]] {
            transport.userResponse = try BlockingTestSupport.decode(object)
            do {
                _ = try await service.lookupUser(uid: 42, credentials: BlockingTestSupport.credentials)
                XCTFail("Must not fabricate a missing user")
            } catch { XCTAssertTrue(error is BlockingSettingsError) }
        }
        transport.userResponse = try BlockingTestSupport.decode(["success": true, "result": ["userNickname": "Fixture"]])
        let user = try await service.lookupUser(uid: 42, credentials: BlockingTestSupport.credentials)
        XCTAssertEqual(user.uid, 42)
        XCTAssertEqual(user.displayName, "Fixture")
        transport.userResponse = try BlockingTestSupport.decode(["success": true, "isBlocked": true])
        let blockedUser = try await service.lookupUser(uid: 42, credentials: BlockingTestSupport.credentials)
        XCTAssertEqual(blockedUser.displayName, "UID 42")
        transport.userResponse = try BlockingTestSupport.decode(["success": true, "result": ["uid": 43]])
        do {
            _ = try await service.lookupUser(uid: 42, credentials: BlockingTestSupport.credentials)
            XCTFail("Mismatched UID")
        } catch { XCTAssertEqual(error as? BlockingSettingsError, .invalidResponse) }
    }

    func testListAndSearchUseOneReadAndDeduplicate() async throws {
        let transport = MockBlockingTransport()
        transport.listResponse = try BlockingTestSupport.list(count: nil)
        let service = BlockingSettingsService(transport: transport)
        let page = try await service.load(category: .block, page: 0, pageSize: 20, credentials: BlockingTestSupport.credentials)
        XCTAssertEqual(page.total, 0)
        XCTAssertEqual(transport.loads, 1)
        XCTAssertEqual(transport.lastPage, 0)
        XCTAssertEqual(transport.lastPageSize, 20)
        let tag: [String: Any] = ["tagId": 42, "tagNameList": []]
        transport.tagResponse = try BlockingTestSupport.decode(["success": true, "result": [tag, tag]])
        let tags = try await service.searchTags(query: "a&b+中文", credentials: BlockingTestSupport.credentials)
        XCTAssertEqual(tags.map(\.tagId), [42])
        XCTAssertEqual(transport.searches, 1)
        XCTAssertTrue(transport.writes.isEmpty)
    }

    func testReadAuthenticationFailureIsNotPendingWrite() async throws {
        let transport = MockBlockingTransport()
        transport.listResponse = try BlockingTestSupport.decode(["success": false, "message": "获取黑名单失败，用户 Token 不合法"])
        do {
            _ = try await BlockingSettingsService(transport: transport).load(category: .block, page: 1, pageSize: 20, credentials: BlockingTestSupport.credentials)
            XCTFail("Expected authentication error")
        } catch { XCTAssertTrue(BlockingSettingsError.isUnauthorized(error)) }
        XCTAssertEqual(transport.loads, 1)
        XCTAssertTrue(transport.writes.isEmpty)
    }
}
