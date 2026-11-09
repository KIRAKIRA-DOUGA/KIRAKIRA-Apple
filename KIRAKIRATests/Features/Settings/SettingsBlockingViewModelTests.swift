import XCTest
@testable import KIRAKIRA

@MainActor
final class SettingsBlockingViewModelTests: XCTestCase {
    func testOverviewReadsAllFiveCountsWithMinimalPages() async {
        let service = MockBlockingService()
        service.loadHandler = { category, page, _, _ in
            BlockingRulePage(entries: [], total: try XCTUnwrap(BlockingRuleCategory.allCases.firstIndex(of: category)) + 1, page: page)
        }
        let model = SettingsBlockingViewModel(service: service, session: MockBlockingSession())
        await model.load()
        XCTAssertEqual(model.state.value?.values, [.block: 1, .hide: 2, .tag: 3, .keyword: 4, .regex: 5])
        XCTAssertEqual(service.reads.map(\.category), BlockingRuleCategory.allCases)
        XCTAssertTrue(service.reads.allSatisfy { $0.page == 1 && $0.pageSize == 1 })
        XCTAssertTrue(service.writes.isEmpty)
    }

    func testInitialFailureCanRetryAndRefreshFailurePreservesCounts() async {
        let service = MockBlockingService()
        service.loadHandler = { _, _, _, _ in throw URLError(.timedOut) }
        let model = SettingsBlockingViewModel(service: service, session: MockBlockingSession())
        await model.load()
        XCTAssertNotNil(model.state.errorMessage)
        service.loadHandler = { _, page, _, _ in BlockingRulePage(entries: [], total: 3, page: page) }
        await model.load()
        let loaded = model.state.value
        service.loadHandler = { _, _, _, _ in throw URLError(.notConnectedToInternet) }
        await model.load()
        XCTAssertEqual(model.state.value, loaded)
        XCTAssertNotNil(model.message)
    }

    func testCancellationRestoresIdleOrPreviouslyLoadedCountsWithoutMessage() async {
        let service = MockBlockingService()
        let model = SettingsBlockingViewModel(service: service, session: MockBlockingSession())
        service.loadHandler = { _, _, _, _ in throw CancellationError() }
        await model.load()
        XCTAssertNil(model.state.value)
        XCTAssertFalse(model.state.isLoading)
        XCTAssertNil(model.state.errorMessage)
        service.loadHandler = { _, page, _, _ in BlockingRulePage(entries: [], total: 2, page: page) }
        await model.load()
        let loaded = model.state.value
        service.loadHandler = { _, _, _, _ in throw CancellationError() }
        await model.load()
        XCTAssertEqual(model.state.value, loaded)
        XCTAssertNil(model.message)
    }

    func testLateReadAfterDisappearanceCannotReplaceNewLoadInSameSession() async {
        let gate = BlockingAsyncGate<BlockingRulePage>()
        let service = MockBlockingService()
        service.loadHandler = { _, _, _, _ in try await gate.value() }
        let model = SettingsBlockingViewModel(service: service, session: MockBlockingSession())
        let old = Task { await model.load() }
        await gate.waitUntilStarted()
        model.disappear()
        service.loadHandler = { _, page, _, _ in BlockingRulePage(entries: [], total: 7, page: page) }
        await model.load()
        gate.resume(.success(BlockingRulePage(entries: [], total: 99, page: 1)))
        await old.value
        XCTAssertEqual(Set(model.state.value?.values.values.map { $0 } ?? []), [7])
        XCTAssertEqual(service.reads.count, 6)
    }

    func testSessionChangeDiscardsOldCountsAndGuestDoesNotRead() async {
        let gate = BlockingAsyncGate<BlockingRulePage>()
        let service = MockBlockingService()
        let session = MockBlockingSession()
        service.loadHandler = { _, _, _, _ in try await gate.value() }
        let model = SettingsBlockingViewModel(service: service, session: session)
        let old = Task { await model.load() }
        await gate.waitUntilStarted()
        session.transition(to: nil)
        model.synchronizeSession()
        gate.resume(.success(BlockingRulePage(entries: [], total: 99, page: 1)))
        await old.value
        await model.load()
        XCTAssertNil(model.state.value)
        XCTAssertFalse(model.isSignedIn)
        XCTAssertEqual(service.reads.count, 1)
    }

    func testUnauthorizedReadRequiresNewSessionBeforeRetrying() async {
        let service = MockBlockingService()
        service.loadHandler = { _, _, _, _ in throw BlockingSettingsError.unauthorized }
        let session = MockBlockingSession()
        let model = SettingsBlockingViewModel(service: service, session: session)
        await model.load()
        await model.load()
        XCTAssertFalse(model.isSignedIn)
        XCTAssertEqual(service.reads.count, 1)
        session.transition(to: BlockingTestSupport.credentials)
        service.loadHandler = { _, page, _, _ in BlockingRulePage(entries: [], total: 0, page: page) }
        await model.load()
        XCTAssertTrue(model.isSignedIn)
        XCTAssertEqual(service.reads.count, 6)
    }
}
