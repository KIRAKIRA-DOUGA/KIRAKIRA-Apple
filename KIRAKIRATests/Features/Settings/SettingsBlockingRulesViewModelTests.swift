import XCTest
@testable import KIRAKIRA

@MainActor
final class SettingsBlockingRulesViewModelTests: XCTestCase {
    private func rule(_ value: String, category: BlockingRuleCategory = .keyword, uid: Int? = nil) -> BlockingRule {
        BlockingRule(category: category, value: value, createdAt: Date(timeIntervalSince1970: 1_700_000_000), uid: uid)
    }

    private func page(_ entries: [BlockingRule] = [], total: Int? = nil, number: Int = 1) -> BlockingRulePage {
        BlockingRulePage(entries: entries, total: total ?? entries.count, page: number)
    }

    private func makeModel(_ service: MockBlockingService, category: BlockingRuleCategory = .keyword,
                           session: MockBlockingSession? = nil) -> SettingsBlockingRulesViewModel {
        SettingsBlockingRulesViewModel(category: category, service: service, session: session ?? MockBlockingSession())
    }

    private func add(_ input: String, to model: SettingsBlockingRulesViewModel) {
        model.openEditor()
        model.inputChanged(input)
        model.submitEditor()
    }

    func testLoadedEmptyCollectionEnablesAddButNotPagination() async {
        let service = MockBlockingService()
        let model = makeModel(service)
        XCTAssertFalse(model.canAdd)
        await model.load()
        XCTAssertTrue(model.canAdd)
        XCTAssertFalse(model.canLoadMore)
        XCTAssertEqual(service.reads.map(\.page), [1])
        XCTAssertEqual(service.reads.map(\.pageSize), [20])
    }

    func testPaginationDeduplicatesAndFailureRetainsContentAndRetriesSamePage() async {
        let service = MockBlockingService()
        let first = rule("first")
        let second = rule("second")
        service.loadHandler = { _, _, _, _ in self.page([first], total: 4) }
        let model = makeModel(service)
        await model.load()
        service.loadHandler = { _, _, _, _ in throw URLError(.timedOut) }
        model.loadMore()
        await model.waitForOperations()
        XCTAssertEqual(model.state.value?.entries, [first])
        XCTAssertNotNil(model.appendError)
        XCTAssertTrue(model.canLoadMore)
        service.loadHandler = { _, page, _, _ in self.page([first, second], total: 4, number: page) }
        model.loadMore()
        await model.waitForOperations()
        XCTAssertEqual(model.state.value?.entries, [first, second])
        XCTAssertNil(model.appendError)
        XCTAssertEqual(service.reads.map(\.page), [1, 2, 2])
        service.loadHandler = { _, page, _, _ in self.page([], total: 4, number: page) }
        model.loadMore()
        await model.waitForOperations()
        XCTAssertFalse(model.canLoadMore)
        XCTAssertEqual(model.state.value?.entries, [first, second])
        XCTAssertEqual(service.reads.map(\.page), [1, 2, 2, 3])
    }

    func testRefreshSuccessAndSessionTransitionClearPreviousAppendError() async {
        let service = MockBlockingService()
        let session = MockBlockingSession()
        let first = (1...20).map { rule("server-\($0)") }
        service.loadHandler = { _, page, _, _ in self.page(first, total: 40, number: page) }
        let model = makeModel(service, session: session)
        await model.load()
        service.loadHandler = { _, _, _, _ in throw URLError(.timedOut) }
        model.loadMore()
        await model.waitForOperations()
        XCTAssertNotNil(model.appendError)
        XCTAssertEqual(model.state.value?.entries, first)

        let refreshed = Array(first.prefix(10))
        service.loadHandler = { _, page, _, _ in self.page(refreshed, total: 10, number: page) }
        await model.load()
        XCTAssertEqual(model.state.value?.entries, refreshed)
        XCTAssertEqual(model.state.value?.total, 10)
        XCTAssertNil(model.appendError)
        XCTAssertFalse(model.canLoadMore)

        service.loadHandler = { _, page, _, _ in self.page(first, total: 40, number: page) }
        await model.load()
        service.loadHandler = { _, _, _, _ in throw URLError(.timedOut) }
        model.loadMore()
        await model.waitForOperations()
        XCTAssertNotNil(model.appendError)
        session.transition(to: nil)
        model.synchronizeSession()
        XCTAssertNil(model.appendError)
        XCTAssertNil(model.state.value)
        XCTAssertFalse(model.canLoadMore)
        XCTAssertEqual(service.reads.map(\.page), [1, 2, 1, 1, 2])
        XCTAssertTrue(service.writes.isEmpty)
    }

    func testPaginationDoesNotOverlapAnotherAppendOrRefresh() async {
        let gate = BlockingAsyncGate<BlockingRulePage>()
        let service = MockBlockingService()
        service.loadHandler = { _, _, _, _ in self.page([self.rule("first")], total: 3) }
        let model = makeModel(service)
        await model.load()
        service.loadHandler = { _, _, _, _ in try await gate.value() }
        model.loadMore()
        await gate.waitUntilStarted()
        model.loadMore()
        await model.load()
        XCTAssertEqual(service.reads.count, 2)
        XCTAssertTrue(model.isAppending)
        XCTAssertFalse(model.canAdd)
        gate.resume(.success(page([rule("second")], total: 3, number: 2)))
        await model.waitForOperations()
        XCTAssertFalse(model.isAppending)
    }

    func testUserRemovalUsesUIDNeverStoredUUIDAndMissingUIDCannotRemove() async {
        for category in [BlockingRuleCategory.block, .hide] {
            let service = MockBlockingService()
            let valid = rule("stored-user-uuid", category: category, uid: 42)
            let legacy = rule("other-uuid-without-uid", category: category)
            service.loadHandler = { _, _, _, _ in self.page([valid, legacy]) }
            let model = makeModel(service, category: category)
            await model.load()
            XCTAssertFalse(model.canRemove(legacy))
            model.remove(legacy)
            XCTAssertTrue(service.writes.isEmpty)
            service.loadHandler = { _, page, _, _ in self.page([], number: page) }
            model.remove(valid)
            await model.waitForOperations()
            XCTAssertEqual(service.writes, [.init(category: category, target: "42", removing: true, uid: 1)])
            XCTAssertEqual(service.reads.map(\.page), [1, 1])
            XCTAssertEqual(model.state.value?.entries, [])
            XCTAssertNotNil(model.successID)
        }
    }

    func testTextLimitCountsUTF16RatherThanCharactersForKeywordAndRegex() async {
        for category in [BlockingRuleCategory.keyword, .regex] {
            let service = MockBlockingService()
            let model = makeModel(service, category: category)
            await model.load()
            model.openEditor()
            model.inputChanged(String(repeating: "😀", count: 16))
            model.submitEditor()
            await model.waitForOperations()
            XCTAssertNotNil(model.editor?.error)
            XCTAssertTrue(service.writes.isEmpty)
            let limit = String(repeating: "😀", count: 15)
            model.inputChanged(" \n\(limit) \n")
            model.submitEditor()
            await model.waitForOperations()
            XCTAssertEqual(service.writes.map(\.target), [limit])
            XCTAssertNotNil(model.successID)
        }
    }

    func testInvalidAndSelfUIDNeverLookupOrWrite() async {
        let service = MockBlockingService()
        let model = makeModel(service, category: .block)
        await model.load()
        model.openEditor()
        for input in ["", "0", "-1", "+42", "9007199254740992", "not-a-uid", "1"] {
            model.inputChanged(input)
            model.submitEditor()
            await model.waitForOperations()
            XCTAssertNotNil(model.editor?.error)
        }
        XCTAssertTrue(service.lookupUIDs.isEmpty)
        XCTAssertTrue(service.writes.isEmpty)
    }

    func testUserMustPreviewMatchingLookupBeforeWrite() async {
        let service = MockBlockingService()
        let model = makeModel(service, category: .block)
        await model.load()
        add("42", to: model)
        await model.waitForOperations()
        XCTAssertEqual(service.lookupUIDs, [42])
        XCTAssertEqual(model.editor?.profile?.uid, 42)
        XCTAssertTrue(service.writes.isEmpty)
        model.submitEditor()
        await model.waitForOperations()
        XCTAssertEqual(service.writes.map(\.target), ["42"])
    }

    func testTagSearchRequiresSelectionAndOnlyAcceptsReturnedTags() async {
        let service = MockBlockingService()
        let found = BlockingTag(tagId: 42, tagNameList: [])
        service.searchHandler = { _, _ in [found] }
        let model = makeModel(service, category: .tag)
        await model.load()
        add("tag query", to: model)
        await model.waitForOperations()
        XCTAssertEqual(service.searchQueries, ["tag query"])
        XCTAssertTrue(service.writes.isEmpty)
        model.selectTag(BlockingTag(tagId: 99, tagNameList: []))
        XCTAssertTrue(service.writes.isEmpty)
        model.selectTag(found)
        await model.waitForOperations()
        XCTAssertEqual(service.writes.map(\.target), ["42"])
    }

    func testConfirmedWriteReconcilesExactlyOnceAndKeepsSuccessWhenReadFails() async {
        let service = MockBlockingService()
        let model = makeModel(service)
        await model.load()
        service.loadHandler = { _, _, _, _ in throw URLError(.timedOut) }
        add("confirmed", to: model)
        await model.waitForOperations()
        XCTAssertEqual(service.writes.count, 1)
        XCTAssertEqual(service.reads.map(\.page), [1, 1])
        XCTAssertEqual(model.state.value?.entries.map(\.target), ["confirmed"])
        XCTAssertEqual(model.state.value?.total, 1)
        XCTAssertNotNil(model.successID)
        XCTAssertNotNil(model.message)
        XCTAssertFalse(model.showConfirmationError)
        XCTAssertTrue(model.canAdd)
    }

    func testConfirmedRemovalRestartsPaginationAfterSynchronizationFailureOrCancellation() async {
        let failures: [Error] = [URLError(.timedOut), CancellationError()]
        for failure in failures {
            let service = MockBlockingService()
            let original = (1...40).map { rule("server-\($0)") }
            let firstPage = Array(original.prefix(20))
            service.loadHandler = { _, page, _, _ in self.page(firstPage, total: 40, number: page) }
            let model = makeModel(service)
            await model.load()
            let synchronization = BlockingAsyncGate<BlockingRulePage>()
            service.loadHandler = { _, _, _, _ in try await synchronization.value() }
            model.remove(original[0])
            await synchronization.waitUntilStarted()
            let success = model.successID
            XCTAssertNotNil(success)
            XCTAssertFalse(model.isWriting)
            synchronization.resume(.failure(failure))
            await model.waitForOperations()
            XCTAssertEqual(model.state.value?.entries, Array(firstPage.dropFirst()))
            XCTAssertEqual(model.state.value?.total, 39)
            XCTAssertEqual(model.successID, success)
            XCTAssertFalse(model.showConfirmationError)
            XCTAssertTrue(model.canLoadMore)
            XCTAssertEqual(service.reads.map(\.page), [1, 1])

            // Deletion shifts original item 21 onto page one. Skipping directly to page
            // two would permanently lose it from the pre-deletion pagination chain.
            let restartedFirst = Array(original[1...20])
            let restartedSecond = Array(original[21...39])
            service.loadHandler = { _, page, _, _ in
                self.page(page == 1 ? restartedFirst : restartedSecond, total: 39, number: page)
            }
            model.loadMore()
            await model.waitForOperations()
            XCTAssertEqual(service.reads.map(\.page), [1, 1, 1])
            XCTAssertEqual(model.state.value?.entries, restartedFirst)
            XCTAssertTrue(model.state.value?.entries.contains(original[20]) == true)
            XCTAssertEqual(model.successID, success)
            XCTAssertTrue(model.canLoadMore)

            model.loadMore()
            await model.waitForOperations()
            XCTAssertEqual(service.reads.map(\.page), [1, 1, 1, 2])
            XCTAssertEqual(model.state.value?.entries, Array(original.dropFirst()))
            XCTAssertEqual(model.state.value?.entries.filter { $0.id == original[20].id }.count, 1)
            XCTAssertEqual(model.state.value?.total, 39)
            XCTAssertEqual(model.successID, success)
            XCTAssertFalse(model.canLoadMore)
            XCTAssertEqual(service.writes, [.init(category: .keyword, target: original[0].value, removing: true, uid: 1)])
        }
    }

    func testConfirmedWriteOverlaySurvivesStaleCompleteReadAndLaterRefresh() async {
        let service = MockBlockingService()
        let model = makeModel(service)
        await model.load()
        add("confirmed", to: model)
        await model.waitForOperations()
        XCTAssertEqual(model.state.value?.entries.map(\.target), ["confirmed"])
        XCTAssertEqual(model.state.value?.total, 1)
        await model.load()
        XCTAssertEqual(model.state.value?.entries.map(\.target), ["confirmed"])
        XCTAssertEqual(model.state.value?.total, 1)
        XCTAssertEqual(service.writes.count, 1)
        XCTAssertEqual(service.reads.map(\.page), [1, 1, 1])
    }

    func testRefreshUsesServerTotalOnceConfirmedAdditionAppearsInReadModel() async {
        let service = MockBlockingService()
        let model = makeModel(service)
        await model.load()
        // The confirmed write's first synchronization is stale, so its overlay is needed.
        add("confirmed", to: model)
        await model.waitForOperations()
        XCTAssertEqual(model.state.value?.total, 1)
        service.loadHandler = { _, page, _, _ in
            self.page([self.rule("confirmed"), self.rule("another-server-rule")], number: page)
        }
        await model.load()
        XCTAssertEqual(model.state.value?.entries.count, 2)
        // A stale overlay estimate must not override the caught-up server total.
        XCTAssertEqual(model.state.value?.total, 2)
        XCTAssertEqual(service.writes.count, 1)
    }

    func testStaleAdditionCountDoesNotTruncatePaginationWhenServerTotalGrowsToSixty() async {
        let service = MockBlockingService()
        let first = (0..<20).map { rule("server-\($0)") }
        service.loadHandler = { _, page, _, _ in self.page(first, total: 20, number: page) }
        let model = makeModel(service)
        await model.load()
        add("confirmed", to: model)
        await model.waitForOperations()
        XCTAssertEqual(model.state.value?.total, 21)
        XCTAssertEqual(service.reads.map(\.page), [1, 1])
        service.loadHandler = { _, page, _, _ in
            switch page {
            case 1: return self.page(first, total: 60, number: page)
            case 2: return self.page((20..<40).map { self.rule("server-\($0)") }, total: 60, number: page)
            default:
                return self.page((40..<59).map { self.rule("server-\($0)") } + [self.rule("confirmed")], total: 60, number: page)
            }
        }
        await model.load()
        XCTAssertEqual(model.state.value?.total, 60)
        XCTAssertTrue(model.canLoadMore)
        model.loadMore()
        await model.waitForOperations()
        XCTAssertEqual(model.state.value?.entries.count, 41)
        XCTAssertEqual(model.state.value?.total, 60)
        XCTAssertTrue(model.canLoadMore, "Pagination must follow the raw server total, not the old estimate of 21")
        model.loadMore()
        await model.waitForOperations()
        XCTAssertEqual(model.state.value?.entries.count, 60)
        XCTAssertEqual(model.state.value?.entries.filter { $0.target == "confirmed" }.count, 1)
        XCTAssertEqual(model.state.value?.total, 60)
        XCTAssertFalse(model.canLoadMore)
        XCTAssertEqual(service.reads.map(\.page), [1, 1, 1, 2, 3])
        XCTAssertEqual(service.writes.count, 1)
    }

    func testRemovalOverlaySurvivesPartialAbsenceUntilCompleteSnapshotRetiresIt() async {
        let service = MockBlockingService()
        let victim = rule("removed")
        let first = (1..<20).map { rule("server-\($0)") }
        service.loadHandler = { _, page, _, _ in self.page([victim] + first, total: 40, number: page) }
        let model = makeModel(service)
        await model.load()
        let partial = (1...20).map { rule("server-\($0)") }
        service.loadHandler = { _, page, _, _ in self.page(partial, total: 40, number: page) }
        model.remove(victim)
        await model.waitForOperations()
        XCTAssertEqual(model.state.value?.total, 39)
        XCTAssertTrue(model.canLoadMore)
        // A later partial page can still contain the stale removed target.
        service.loadHandler = { _, page, _, _ in
            self.page([victim] + (21..<30).map { self.rule("server-\($0)") }, total: 40, number: page)
        }
        model.loadMore()
        await model.waitForOperations()
        XCTAssertFalse(model.state.value?.entries.contains(victim) == true)
        XCTAssertTrue(model.canLoadMore)
        // Other clients remove enough rules for a complete snapshot to fit on page one.
        let complete = (1..<11).map { rule("server-\($0)") }
        service.loadHandler = { _, page, _, _ in self.page(complete, number: page) }
        await model.load()
        XCTAssertEqual(model.state.value?.total, 10)
        // Once a complete absence retires the overlay, a later external re-add is visible.
        service.loadHandler = { _, page, _, _ in self.page([victim] + complete, number: page) }
        await model.load()
        XCTAssertTrue(model.state.value?.entries.contains(victim) == true)
        XCTAssertEqual(model.state.value?.total, 11)
        XCTAssertEqual(service.reads.map(\.page), [1, 1, 2, 1, 1])
        XCTAssertEqual(service.writes.count, 1)
    }

    func testInvalidTextSnapshotCannotConfirmRemovalEvenWithMatchingCount() async {
        let invalidValues = [String(repeating: "a", count: 31), String(repeating: "😀", count: 15) + "a", " \n\t"]
        for category in [BlockingRuleCategory.keyword, .regex] {
            for invalid in invalidValues {
                let service = MockBlockingService()
                service.changeHandler = { _, _, _, _ in .unconfirmed }
                let original = rule("valid", category: category)
                service.loadHandler = { _, page, _, _ in self.page([original], number: page) }
                let model = makeModel(service, category: category)
                await model.load()
                service.loadHandler = { _, page, _, _ in
                    self.page([self.rule(invalid, category: category)], number: page)
                }
                model.remove(original)
                await model.waitForOperations()
                XCTAssertEqual(model.state.value?.entries, [original])
                XCTAssertTrue(model.showConfirmationError)
                XCTAssertFalse(model.canAdd)
                XCTAssertNil(model.successID)
                XCTAssertEqual(service.reads.map(\.page), [1, 0])
                service.loadHandler = { _, page, _, _ in self.page([], number: page) }
                model.retryConfirmation()
                await model.waitForOperations()
                XCTAssertTrue(model.canAdd)
                XCTAssertNotNil(model.successID)
                XCTAssertEqual(service.reads.map(\.page), [1, 0, 0])
                XCTAssertEqual(service.writes.count, 1)
            }
        }
    }

    func testUnconfirmedMatchingSnapshotSucceedsAfterExactlyOneFullRead() async {
        let service = MockBlockingService()
        service.changeHandler = { _, _, _, _ in .unconfirmed }
        let model = makeModel(service)
        await model.load()
        service.loadHandler = { _, page, _, _ in self.page([self.rule("new")], number: page) }
        add("new", to: model)
        await model.waitForOperations()
        XCTAssertEqual(service.reads.map(\.page), [1, 0])
        XCTAssertEqual(service.writes.count, 1)
        XCTAssertNotNil(model.successID)
        XCTAssertNil(model.editor)
        XCTAssertTrue(model.canAdd)
        XCTAssertFalse(model.showConfirmationError)
    }

    func testUnchangedSnapshotKeepsPendingAndRepeatedRetriesAreReadOnly() async {
        let service = MockBlockingService()
        service.changeHandler = { _, _, _, _ in .unconfirmed }
        let model = makeModel(service)
        await model.load()
        add("new", to: model)
        await model.waitForOperations()
        XCTAssertFalse(model.canAdd)
        XCTAssertNil(model.successID)
        XCTAssertTrue(model.showConfirmationError)
        model.showConfirmationError = false
        model.submitEditor()
        XCTAssertEqual(service.writes.count, 1)
        service.loadHandler = { _, _, _, _ in throw URLError(.timedOut) }
        model.retryConfirmation()
        await model.waitForOperations()
        XCTAssertTrue(model.showConfirmationError)
        model.showConfirmationError = false
        model.retryConfirmation()
        await model.waitForOperations()
        XCTAssertTrue(model.showConfirmationError)
        XCTAssertEqual(service.writes.count, 1)
        XCTAssertEqual(service.reads.map(\.page), [1, 0, 0, 0])
        service.loadHandler = { _, page, _, _ in self.page([self.rule("new")], number: page) }
        model.retryConfirmation()
        await model.waitForOperations()
        XCTAssertTrue(model.canAdd)
        XCTAssertFalse(model.showConfirmationError)
        XCTAssertNotNil(model.successID)
        XCTAssertEqual(service.writes.count, 1)
        XCTAssertEqual(service.reads.map(\.page), [1, 0, 0, 0, 0])
    }

    func testIncompleteCountCannotConfirmAdditionEvenWhenTargetAppears() async {
        let service = MockBlockingService()
        service.changeHandler = { _, _, _, _ in .unconfirmed }
        let original = rule("old")
        service.loadHandler = { _, _, _, _ in self.page([original]) }
        let model = makeModel(service)
        await model.load()
        service.loadHandler = { _, _, _, _ in self.page([self.rule("new")], total: 2, number: 0) }
        add("new", to: model)
        await model.waitForOperations()
        XCTAssertEqual(model.state.value?.entries, [original])
        XCTAssertTrue(model.showConfirmationError)
        XCTAssertFalse(model.canAdd)
        XCTAssertNil(model.successID)
        XCTAssertEqual(service.reads.map(\.page), [1, 0])
        XCTAssertEqual(service.writes.count, 1)
    }

    func testIncompleteCountCannotConfirmRemovalFromMissingTarget() async {
        let service = MockBlockingService()
        service.changeHandler = { _, _, _, _ in .unconfirmed }
        let original = rule("old")
        service.loadHandler = { _, _, _, _ in self.page([original]) }
        let model = makeModel(service)
        await model.load()
        service.loadHandler = { _, _, _, _ in self.page([], total: 1, number: 0) }
        model.remove(original)
        await model.waitForOperations()
        XCTAssertEqual(model.state.value?.entries, [original])
        XCTAssertTrue(model.showConfirmationError)
        XCTAssertFalse(model.canAdd)
        XCTAssertNil(model.successID)
    }

    func testUnconfirmedRemovalResolvesOnlyAfterCompleteAbsence() async {
        let service = MockBlockingService()
        service.changeHandler = { _, _, _, _ in .unconfirmed }
        let original = rule("old")
        service.loadHandler = { _, _, _, _ in self.page([original]) }
        let model = makeModel(service)
        await model.load()
        model.remove(original)
        await model.waitForOperations()
        XCTAssertTrue(model.showConfirmationError)
        XCTAssertNil(model.successID)
        service.loadHandler = { _, page, _, _ in self.page([], number: page) }
        model.retryConfirmation()
        await model.waitForOperations()
        XCTAssertEqual(model.state.value?.entries, [])
        XCTAssertNotNil(model.successID)
        XCTAssertTrue(model.canAdd)
        XCTAssertEqual(service.writes.count, 1)
        XCTAssertEqual(service.reads.map(\.page), [1, 0, 0])
    }

    func testDefiniteRejectionDoesNotReadOrLeavePending() async {
        let service = MockBlockingService()
        service.changeHandler = { _, _, _, _ in throw BlockingSettingsError.rejected }
        let model = makeModel(service)
        await model.load()
        add("rejected", to: model)
        await model.waitForOperations()
        XCTAssertNotNil(model.editor?.error)
        XCTAssertNil(model.successID)
        XCTAssertFalse(model.showConfirmationError)
        XCTAssertTrue(model.canAdd)
        XCTAssertEqual(service.reads.map(\.page), [1])
        XCTAssertEqual(service.writes.count, 1)
    }

    func testWritingProtectionEndsBeforeReadOnlyConfirmationCompletes() async {
        let gate = BlockingAsyncGate<BlockingRulePage>()
        let service = MockBlockingService()
        service.changeHandler = { _, _, _, _ in .unconfirmed }
        let model = makeModel(service)
        await model.load()
        service.loadHandler = { _, _, _, _ in try await gate.value() }
        add("new", to: model)
        await gate.waitUntilStarted()
        XCTAssertFalse(model.isWriting)
        XCTAssertTrue(model.isConfirming)
        XCTAssertFalse(model.canAdd)
        gate.resume(.success(page([rule("new")], number: 0)))
        await model.waitForOperations()
        XCTAssertFalse(model.isConfirming)
        XCTAssertTrue(model.canAdd)
    }

    func testInitialAndRefreshCancellationDoNotShowErrors() async {
        let service = MockBlockingService()
        let model = makeModel(service)
        service.loadHandler = { _, _, _, _ in throw CancellationError() }
        await model.load()
        XCTAssertNil(model.state.value)
        XCTAssertNil(model.state.errorMessage)
        XCTAssertFalse(model.state.isLoading)
        service.loadHandler = { _, _, _, _ in self.page([self.rule("loaded")]) }
        await model.load()
        let previous = model.state.value
        service.loadHandler = { _, _, _, _ in throw CancellationError() }
        await model.load()
        XCTAssertEqual(model.state.value, previous)
        XCTAssertNil(model.message)
        XCTAssertFalse(model.showConfirmationError)
    }

    func testQueuedWriteCancelledOnDisappearanceNeverReachesService() async {
        let service = MockBlockingService()
        let model = makeModel(service)
        await model.load()
        add("never sent", to: model)
        model.disappear()
        await model.waitForOperations()
        // A new structured read also verifies that no pending mutation was created.
        await model.load()
        XCTAssertTrue(service.writes.isEmpty)
        XCTAssertEqual(service.reads.map(\.page), [1, 1])
        XCTAssertTrue(model.canAdd)
        XCTAssertFalse(model.isWriting)
        XCTAssertNil(model.successID)
    }

    func testCancelledSentWriteReconcilesOnReentryWithoutAutomaticReplay() async {
        let gate = BlockingAsyncGate<BlockingMutationResult>()
        let service = MockBlockingService()
        service.changeHandler = { _, _, _, _ in try await gate.value() }
        let model = makeModel(service)
        await model.load()
        add("sent", to: model)
        await gate.waitUntilStarted()
        // The controller runs only after waitForOperations has captured the old task.
        let controller = Task {
            model.disappear()
            gate.resume(.success(.confirmed))
        }
        await model.waitForOperations()
        await controller.value
        XCTAssertNil(model.successID)
        XCTAssertNil(model.message)
        XCTAssertFalse(model.showConfirmationError)
        service.loadHandler = { _, page, _, _ in self.page([self.rule("sent")], number: page) }
        await model.load()
        XCTAssertEqual(service.writes.count, 1)
        XCTAssertEqual(service.reads.map(\.page), [1, 0])
        XCTAssertNotNil(model.successID)
        XCTAssertTrue(model.canAdd)
    }

    func testCancellationFromMutationKeepsPendingWithoutAlertUntilLaterRead() async {
        let service = MockBlockingService()
        service.changeHandler = { _, _, _, _ in throw CancellationError() }
        let model = makeModel(service)
        await model.load()
        add("uncertain", to: model)
        await model.waitForOperations()
        XCTAssertFalse(model.canAdd)
        XCTAssertFalse(model.isWriting)
        XCTAssertFalse(model.showConfirmationError)
        XCTAssertNil(model.message)
        XCTAssertNil(model.editor?.error)
        XCTAssertEqual(service.reads.map(\.page), [1])
        service.loadHandler = { _, page, _, _ in self.page([self.rule("uncertain")], number: page) }
        await model.load()
        XCTAssertTrue(model.canAdd)
        XCTAssertEqual(service.writes.count, 1)
        XCTAssertEqual(service.reads.map(\.page), [1, 0])
    }

    func testCancelledConfirmationKeepsPendingAndHasNoErrorAlert() async {
        let service = MockBlockingService()
        service.changeHandler = { _, _, _, _ in .unconfirmed }
        let model = makeModel(service)
        await model.load()
        service.loadHandler = { _, _, _, _ in throw CancellationError() }
        add("new", to: model)
        await model.waitForOperations()
        XCTAssertFalse(model.canAdd)
        XCTAssertFalse(model.showConfirmationError)
        XCTAssertFalse(model.isConfirming)
        XCTAssertNil(model.message)
        XCTAssertEqual(service.writes.count, 1)
        XCTAssertEqual(service.reads.map(\.page), [1, 0])
    }

    func testLateReadAfterLeavingCannotReplaceNewContentInSameSession() async {
        let gate = BlockingAsyncGate<BlockingRulePage>()
        let service = MockBlockingService()
        service.loadHandler = { _, _, _, _ in try await gate.value() }
        let model = makeModel(service)
        let old = Task { await model.load() }
        await gate.waitUntilStarted()
        model.disappear()
        service.loadHandler = { _, _, _, _ in self.page([self.rule("new")]) }
        await model.load()
        gate.resume(.success(page([rule("old")])))
        await old.value
        XCTAssertEqual(model.state.value?.entries.map(\.target), ["new"])
        XCTAssertTrue(model.canAdd)
    }

    func testOldWriteCannotClearNewWriteProgressAfterSameSessionReentry() async {
        let oldGate = BlockingAsyncGate<BlockingMutationResult>()
        let newGate = BlockingAsyncGate<BlockingMutationResult>()
        let service = MockBlockingService()
        service.changeHandler = { _, _, _, _ in try await oldGate.value() }
        let model = makeModel(service)
        await model.load()
        add("old", to: model)
        await oldGate.waitUntilStarted()
        let controller = Task {
            model.disappear()
            service.loadHandler = { _, page, _, _ in self.page([self.rule("old")], number: page) }
            await model.load()
            service.changeHandler = { _, _, _, _ in try await newGate.value() }
            add("new", to: model)
            await newGate.waitUntilStarted()
            oldGate.resume(.success(.confirmed))
        }
        await model.waitForOperations()
        await controller.value
        XCTAssertTrue(model.isWriting)
        XCTAssertNil(model.successID)
        XCTAssertEqual(service.writes.map(\.target), ["old", "new"])
        newGate.resume(.success(.confirmed))
        await model.waitForOperations()
        XCTAssertFalse(model.isWriting)
        XCTAssertNotNil(model.successID)
        XCTAssertTrue(model.state.value?.entries.contains { $0.target == "new" } == true)
    }

    func testSessionTransitionCancelsQueuedWriteAndClearsContent() async {
        let service = MockBlockingService()
        let session = MockBlockingSession()
        let model = makeModel(service, session: session)
        await model.load()
        add("queued", to: model)
        session.transition(to: nil)
        model.synchronizeSession()
        await model.waitForOperations()
        await model.load()
        XCTAssertTrue(service.writes.isEmpty)
        XCTAssertNil(model.state.value)
        XCTAssertNil(model.editor)
        XCTAssertFalse(model.isSignedIn)
        XCTAssertFalse(model.isWriting)
    }

    func testSessionChangeDiscardsSentWriteAndPendingOperation() async {
        let gate = BlockingAsyncGate<BlockingMutationResult>()
        let service = MockBlockingService()
        let session = MockBlockingSession()
        service.changeHandler = { _, _, _, _ in try await gate.value() }
        let model = makeModel(service, session: session)
        await model.load()
        add("old account", to: model)
        await gate.waitUntilStarted()
        let controller = Task {
            session.transition(to: BlockingTestSupport.credentials)
            model.synchronizeSession()
            gate.resume(.success(.confirmed))
        }
        await model.waitForOperations()
        await controller.value
        await model.load()
        XCTAssertEqual(service.reads.map(\.page), [1, 1])
        XCTAssertEqual(service.writes.count, 1)
        XCTAssertNil(model.successID)
        XCTAssertTrue(model.canAdd)
        XCTAssertEqual(model.state.value?.entries, [])
    }

    func testStaleUserLookupCannotReplaceNewLookupOrClearItsProgress() async {
        let oldGate = BlockingAsyncGate<BlockingUser>()
        let newGate = BlockingAsyncGate<BlockingUser>()
        let service = MockBlockingService()
        service.lookupHandler = { uid, _ in
            if uid == 42 { return try await oldGate.value() }
            return try await newGate.value()
        }
        let model = makeModel(service, category: .block)
        await model.load()
        add("42", to: model)
        await oldGate.waitUntilStarted()
        let controller = Task {
            model.inputChanged("43")
            model.submitEditor()
            await newGate.waitUntilStarted()
            oldGate.resume(.success(BlockingUser(uid: 42)))
        }
        await model.waitForOperations()
        await controller.value
        XCTAssertTrue(model.isLookingUp)
        XCTAssertNil(model.editor?.profile)
        XCTAssertEqual(model.editor?.input, "43")
        newGate.resume(.success(BlockingUser(uid: 43)))
        await model.waitForOperations()
        XCTAssertEqual(model.editor?.profile?.uid, 43)
        XCTAssertFalse(model.isLookingUp)
        XCTAssertEqual(service.lookupUIDs, [42, 43])
        XCTAssertTrue(service.writes.isEmpty)
    }

    func testClosingEditorDiscardsLateTagSearch() async {
        let gate = BlockingAsyncGate<[BlockingTag]>()
        let service = MockBlockingService()
        service.searchHandler = { _, _ in try await gate.value() }
        let model = makeModel(service, category: .tag)
        await model.load()
        add("old query", to: model)
        await gate.waitUntilStarted()
        let controller = Task {
            model.closeEditor()
            model.openEditor()
            model.inputChanged("new query")
            gate.resume(.success([BlockingTag(tagId: 42, tagNameList: [])]))
        }
        await model.waitForOperations()
        await controller.value
        XCTAssertEqual(model.editor?.input, "new query")
        XCTAssertNil(model.editor?.tags)
        XCTAssertFalse(model.isLookingUp)
        XCTAssertTrue(service.writes.isEmpty)
    }

    func testLookupSessionTransitionDiscardsLateProfile() async {
        let gate = BlockingAsyncGate<BlockingUser>()
        let service = MockBlockingService()
        let session = MockBlockingSession()
        service.lookupHandler = { _, _ in try await gate.value() }
        let model = makeModel(service, category: .block, session: session)
        await model.load()
        add("42", to: model)
        await gate.waitUntilStarted()
        let controller = Task {
            session.transition(to: nil)
            model.synchronizeSession()
            gate.resume(.success(BlockingUser(uid: 42)))
        }
        await model.waitForOperations()
        await controller.value
        XCTAssertNil(model.editor)
        XCTAssertFalse(model.isLookingUp)
        XCTAssertFalse(model.isSignedIn)
        XCTAssertTrue(service.writes.isEmpty)
    }

    func testUnauthorizedConfirmationClearsAccountContentAndDoesNotReplay() async {
        let service = MockBlockingService()
        service.changeHandler = { _, _, _, _ in .unconfirmed }
        let model = makeModel(service)
        await model.load()
        service.loadHandler = { _, _, _, _ in throw BlockingSettingsError.unauthorized }
        add("new", to: model)
        await model.waitForOperations()
        XCTAssertFalse(model.isSignedIn)
        XCTAssertNil(model.state.value)
        XCTAssertNil(model.successID)
        XCTAssertFalse(model.showConfirmationError)
        await model.load()
        XCTAssertEqual(service.writes.count, 1)
        XCTAssertEqual(service.reads.map(\.page), [1, 0])
    }

    func testRealServiceMalformedWriteResponseUsesOneMatchingConfirmationRead() async throws {
        let transport = MockBlockingTransport()
        transport.listResponse = try BlockingTestSupport.list()
        let model = SettingsBlockingRulesViewModel(category: .keyword, service: BlockingSettingsService(transport: transport), session: MockBlockingSession())
        await model.load()
        // Missing mutation payload simulates a write whose response cannot be decoded.
        transport.listResponse = try BlockingTestSupport.list([BlockingTestSupport.entry(.keyword, value: "new")], count: 1)
        add("new", to: model)
        await model.waitForOperations()
        XCTAssertEqual(transport.writes.map(\.target), ["new"])
        XCTAssertEqual(transport.loads, 2)
        XCTAssertEqual(transport.lastPage, 0)
        XCTAssertEqual(transport.lastPageSize, 20)
        XCTAssertEqual(model.state.value?.entries.map(\.target), ["new"])
        XCTAssertNotNil(model.successID)
        XCTAssertTrue(model.canAdd)
    }

    func testRealServiceDifferingSnapshotRemainsPendingAndRetryNeverWrites() async throws {
        let transport = MockBlockingTransport()
        transport.listResponse = try BlockingTestSupport.list()
        let model = SettingsBlockingRulesViewModel(category: .keyword, service: BlockingSettingsService(transport: transport), session: MockBlockingSession())
        await model.load()
        transport.listResponse = try BlockingTestSupport.list([BlockingTestSupport.entry(.keyword, value: "actual-server-value")], count: 1)
        add("attempted", to: model)
        await model.waitForOperations()
        XCTAssertEqual(model.state.value?.entries.map(\.target), ["actual-server-value"])
        XCTAssertNil(model.successID)
        XCTAssertFalse(model.canAdd)
        XCTAssertTrue(model.showConfirmationError)
        model.showConfirmationError = false
        transport.error = BlockingSettingsError.unauthorized
        model.retryConfirmation()
        await model.waitForOperations()
        XCTAssertFalse(model.isSignedIn)
        XCTAssertNil(model.state.value)
        XCTAssertEqual(transport.writes.count, 1)
        XCTAssertEqual(transport.loads, 3)
        XCTAssertEqual(transport.lastPage, 0)
    }

    func testRealServiceIncompleteSnapshotAndReadFailurePreservePendingContent() async throws {
        let transport = MockBlockingTransport()
        transport.listResponse = try BlockingTestSupport.list()
        let model = SettingsBlockingRulesViewModel(category: .keyword, service: BlockingSettingsService(transport: transport), session: MockBlockingSession())
        await model.load()
        transport.listResponse = try BlockingTestSupport.list([BlockingTestSupport.entry(.keyword, value: "new")], count: 2)
        add("new", to: model)
        await model.waitForOperations()
        XCTAssertEqual(model.state.value?.entries, [])
        XCTAssertFalse(model.canAdd)
        XCTAssertTrue(model.showConfirmationError)
        XCTAssertNil(model.successID)
        transport.error = URLError(.timedOut)
        model.showConfirmationError = false
        model.retryConfirmation()
        await model.waitForOperations()
        XCTAssertEqual(model.state.value?.entries, [])
        XCTAssertTrue(model.showConfirmationError)
        XCTAssertEqual(transport.writes.count, 1)
        XCTAssertEqual(transport.loads, 3)
        XCTAssertEqual(transport.lastPage, 0)
    }

    func testRealServiceUserDeletionUsesMappedUIDInsteadOfWireUUID() async throws {
        let transport = MockBlockingTransport()
        var entry = BlockingTestSupport.entry(.block, value: "wire-rule-uuid")
        entry["uid"] = 42
        transport.listResponse = try BlockingTestSupport.list([entry], count: 1)
        transport.mutationResponse = try BlockingTestSupport.decode(["success": true])
        let model = SettingsBlockingRulesViewModel(category: .block, service: BlockingSettingsService(transport: transport), session: MockBlockingSession())
        await model.load()
        let loaded = try XCTUnwrap(model.state.value?.entries.first)
        transport.listResponse = try BlockingTestSupport.list()
        model.remove(loaded)
        await model.waitForOperations()
        XCTAssertEqual(transport.writes, [.init(category: .block, target: "42", removing: true)])
        XCTAssertEqual(transport.loads, 2)
        XCTAssertEqual(transport.lastPage, 1)
        XCTAssertEqual(model.state.value?.entries, [])
        XCTAssertNotNil(model.successID)
    }

    func testRealServiceConfirmedWriteStaysSuccessfulWhenSynchronizationIsMalformed() async throws {
        let transport = MockBlockingTransport()
        transport.listResponse = try BlockingTestSupport.list()
        transport.mutationResponse = try BlockingTestSupport.decode(["success": true])
        let model = SettingsBlockingRulesViewModel(category: .keyword, service: BlockingSettingsService(transport: transport), session: MockBlockingSession())
        await model.load()
        transport.listResponse = nil
        add("confirmed", to: model)
        await model.waitForOperations()
        XCTAssertNotNil(model.successID)
        XCTAssertEqual(model.state.value?.entries.map(\.target), ["confirmed"])
        XCTAssertEqual(model.state.value?.total, 1)
        XCTAssertTrue(model.canAdd)
        XCTAssertFalse(model.showConfirmationError)
        XCTAssertEqual(transport.loads, 2)
        XCTAssertEqual(transport.writes.count, 1)
        XCTAssertEqual(transport.lastPage, 1)
    }
}
