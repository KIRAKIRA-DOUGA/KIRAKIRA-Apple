import XCTest
@testable import KIRAKIRA

@MainActor
final class SettingsInvitationsViewModelTests: XCTestCase {
    private func invitation(_ code: String = "KIRA-TEST-0001", used: Bool = false, time: TimeInterval = 1) -> Invitation {
        Invitation(code: code, createdAt: Date(timeIntervalSince1970: time), used: used)
    }

    func testLoadSortsCountsAndFiltersWithoutAdditionalRequests() async {
        let service = MockInvitationService()
        let older = invitation()
        let newer = invitation("KIRA-TEST-0002", time: 2)
        let used = invitation("KIRA-TEST-0003", used: true, time: 3)
        service.loadHandler = { _ in [used, older, newer] }
        let model = SettingsInvitationsViewModel(service: service, session: MockInvitationSession())
        await model.load()
        XCTAssertEqual(model.invitations, [newer, older, used])
        XCTAssertEqual(model.unusedCount, 2)
        XCTAssertEqual(model.usedCount, 1)
        XCTAssertTrue(model.canCreate)
        model.filter = .unused
        XCTAssertEqual(model.visibleInvitations, [newer, older])
        model.filter = .used
        XCTAssertEqual(model.visibleInvitations, [used])
        model.filter = .all
        XCTAssertEqual(model.visibleInvitations.count, 3)
        XCTAssertEqual(service.reads.count, 1)
        XCTAssertTrue(model.canCopy(used))
    }

    func testCreationSuccessFeedbackIsIndependentOfReadOnlySynchronization() async {
        let service = MockInvitationService()
        let session = MockInvitationSession()
        let model = SettingsInvitationsViewModel(service: service, session: session)
        await model.load()
        XCTAssertFalse(model.creationSucceeded)
        let code = invitation()
        let readGate = InvitationAsyncGate<[Invitation]>()
        service.createHandler = { _ in .created(code) }
        service.loadHandler = { _ in try await readGate.value() }
        model.requestCreation()
        await readGate.waitUntilStarted()
        XCTAssertTrue(model.creationSucceeded)
        XCTAssertFalse(model.isCreating, "Spinner must finish when POST succeeds, not after a later GET")
        readGate.resume(.failure(URLError(.timedOut)))
        await model.waitForOperations()
        XCTAssertTrue(model.creationSucceeded, "A failed sync must not turn a confirmed generation into a failure")
        service.loadHandler = { _ in [code] }
        await model.load()
        XCTAssertTrue(model.creationSucceeded)
        model.clearMessage()
        XCTAssertTrue(model.creationSucceeded, "Toast consumption must not consume the button feedback")

        let writeGate = InvitationAsyncGate<InvitationCreationResult>()
        service.createHandler = { _ in try await writeGate.value() }
        model.requestCreation()
        XCTAssertFalse(model.creationSucceeded, "Each new attempt resets the previous completion")
        await writeGate.waitUntilStarted()
        writeGate.resume(.success(.coolingDown))
        await model.waitForOperations()
        XCTAssertFalse(model.creationSucceeded)
    }

    func testCoolingUnconfirmedFailedAndCancelledCreationNeverSignalSuccess() async {
        let service = MockInvitationService()
        let model = SettingsInvitationsViewModel(service: service, session: MockInvitationSession())
        await model.load()
        let handlers: [(Credentials) async throws -> InvitationCreationResult] = [
            { _ in .coolingDown },
            { _ in throw InvitationError.rejected },
            { _ in throw CancellationError() },
            { _ in .unconfirmed },
        ]
        for handler in handlers {
            service.createHandler = handler
            if model.confirmationPending {
                model.requestCreation()
                model.confirmCreation = false
                model.confirmCreate()
            } else {
                model.requestCreation()
            }
            await model.waitForOperations()
            XCTAssertFalse(model.creationSucceeded)
            XCTAssertFalse(model.isCreating)
        }
        XCTAssertEqual(service.creations.count, handlers.count)
    }

    func testSessionChangesDisappearanceAndUnauthorizedReadResetSuccessFeedback() async {
        let service = MockInvitationService()
        let session = MockInvitationSession()
        let model = SettingsInvitationsViewModel(service: service, session: session)
        let code = invitation()
        service.createHandler = { _ in .created(code) }
        for reset in 0..<3 {
            service.loadHandler = { _ in [] }
            await model.load()
            model.requestCreation()
            await model.waitForOperations()
            XCTAssertTrue(model.creationSucceeded)
            switch reset {
            case 0:
                model.disappear()
            case 1:
                session.transition(to: session.credentials)
                model.synchronizeSession()
            default:
                service.loadHandler = { _ in throw InvitationError.unauthorized }
                await model.load()
            }
            XCTAssertFalse(model.creationSucceeded)
        }
    }

    func testEmptyListIsLoadedAndCanGenerate() async {
        let model = SettingsInvitationsViewModel(service: MockInvitationService(), session: MockInvitationSession())
        await model.load()
        XCTAssertEqual(model.state, .success([]))
        XCTAssertTrue(model.canCreate)
        XCTAssertEqual(model.unusedCount, 0)
    }

    func testInitialFailureRetriesAndDoesNotAllowGeneration() async {
        let service = MockInvitationService()
        service.loadHandler = { _ in throw URLError(.timedOut) }
        let model = SettingsInvitationsViewModel(service: service, session: MockInvitationSession())
        await model.load()
        XCTAssertNotNil(model.state.errorMessage)
        XCTAssertFalse(model.showConfirmationError, "Initial load errors are not uncertain creation results")
        XCTAssertFalse(model.canCreate)
        model.requestCreation()
        XCTAssertTrue(service.creations.isEmpty)
        service.loadHandler = { _ in [] }
        model.refresh()
        await model.waitForOperations()
        XCTAssertTrue(model.canCreate)
    }

    func testInitialCancellationReturnsIdleAndRefreshCancellationRestoresContent() async {
        let service = MockInvitationService()
        let model = SettingsInvitationsViewModel(service: service, session: MockInvitationSession())
        service.loadHandler = { _ in throw CancellationError() }
        await model.load()
        XCTAssertEqual(model.state, .idle)
        XCTAssertNil(model.message)
        let code = invitation()
        service.loadHandler = { _ in [code] }
        await model.load()
        service.loadHandler = { _ in throw CancellationError() }
        await model.load()
        XCTAssertEqual(model.state, .success([code]))
        XCTAssertNil(model.message)
    }

    func testRefreshPreservesContentAndExcludesGeneration() async {
        let service = MockInvitationService()
        let code = invitation()
        service.loadHandler = { _ in [code] }
        let model = SettingsInvitationsViewModel(service: service, session: MockInvitationSession())
        await model.load()
        let gate = InvitationAsyncGate<[Invitation]>()
        service.loadHandler = { _ in try await gate.value() }
        let read = Task { await model.load() }
        await gate.waitUntilStarted()
        XCTAssertEqual(model.invitations, [code])
        XCTAssertTrue(model.state.isRefreshing)
        XCTAssertFalse(model.isCreating)
        XCTAssertFalse(model.canCreate)
        model.requestCreation()
        await model.load()
        XCTAssertEqual(service.reads.count, 2)
        XCTAssertTrue(service.creations.isEmpty)
        gate.resume(.failure(URLError(.notConnectedToInternet)))
        await read.value
        XCTAssertEqual(model.state, .success([code]))
        XCTAssertNotNil(model.message)
        XCTAssertFalse(model.showConfirmationError, "Ordinary refresh failure must not show the creation confirmation alert")
        XCTAssertTrue(model.canCreate)
    }

    func testCancelledReadIgnoresRacingNetworkFailure() async {
        let service = MockInvitationService()
        let model = SettingsInvitationsViewModel(service: service, session: MockInvitationSession())
        await model.load()
        let gate = InvitationAsyncGate<[Invitation]>()
        service.loadHandler = { _ in try await gate.value() }
        let read = Task { await model.load() }
        await gate.waitUntilStarted()
        read.cancel()
        gate.resume(.failure(URLError(.timedOut)))
        await read.value
        XCTAssertEqual(model.state, .success([]))
        XCTAssertNil(model.message)
    }

    func testCreationExcludesDuplicateWritesAndReadsAndUsesCapturedCredentials() async {
        let service = MockInvitationService()
        let session = MockInvitationSession()
        let credentials = session.credentials
        let gate = InvitationAsyncGate<InvitationCreationResult>()
        service.createHandler = { _ in try await gate.value() }
        let model = SettingsInvitationsViewModel(service: service, session: session)
        await model.load()
        model.requestCreation()
        await gate.waitUntilStarted()
        XCTAssertTrue(model.isCreating)
        XCTAssertFalse(model.canCreate)
        model.requestCreation()
        model.refresh()
        await model.load()
        XCTAssertEqual(service.creations.count, 1)
        XCTAssertEqual(service.reads.count, 1)
        XCTAssertEqual(service.creations.first, credentials)
        gate.resume(.success(.coolingDown))
        await model.waitForOperations()
        XCTAssertFalse(model.busy)
        XCTAssertTrue(model.canCreate)
        XCTAssertFalse(model.confirmationPending)
        XCTAssertNotNil(model.message)
        XCTAssertEqual(service.reads.count, 1)
    }

    func testConfirmedCodeIsVisibleDuringReconciliationAndSurvivesStaleListAndReadFailure() async {
        let service = MockInvitationService()
        let model = SettingsInvitationsViewModel(service: service, session: MockInvitationSession())
        await model.load()
        let newCode = invitation()
        let readGate = InvitationAsyncGate<[Invitation]>()
        service.createHandler = { _ in .created(newCode) }
        service.loadHandler = { _ in try await readGate.value() }
        model.requestCreation()
        await readGate.waitUntilStarted()
        XCTAssertFalse(model.isCreating, "Read-only synchronization must not protect dismissal")
        XCTAssertTrue(model.state.isRefreshing)
        XCTAssertEqual(model.invitations, [newCode])
        XCTAssertNotNil(model.message, "The success feedback must not be cleared by the follow-up read")
        readGate.resume(.success([]))
        await model.waitForOperations()
        XCTAssertEqual(model.invitations, [newCode])
        service.loadHandler = { _ in throw URLError(.timedOut) }
        await model.load()
        XCTAssertEqual(model.invitations, [newCode])
        let used = invitation(used: true)
        service.loadHandler = { _ in [used] }
        await model.load()
        XCTAssertEqual(model.invitations, [used])
        XCTAssertEqual(model.usedCount, 1)
        service.loadHandler = { _ in [] }
        await model.load()
        XCTAssertTrue(model.invitations.isEmpty, "Once listed, the server is authoritative")
        XCTAssertEqual(service.creations.count, 1)
    }

    func testUnconfirmedCreationSilentlyChecksAndSignalsSuccessWhenNewCodeAppears() async {
        let service = MockInvitationService()
        let oldCode = invitation()
        let newCode = invitation("KIRA-TEST-0002", time: 2)
        service.loadHandler = { _ in [oldCode] }
        let model = SettingsInvitationsViewModel(service: service, session: MockInvitationSession())
        await model.load()
        let gate = InvitationAsyncGate<[Invitation]>()
        service.createHandler = { _ in .unconfirmed }
        service.loadHandler = { _ in try await gate.value() }
        model.requestCreation()
        await gate.waitUntilStarted()
        XCTAssertFalse(model.isCreating, "Read-only confirmation must allow leaving")
        XCTAssertTrue(model.isConfirmingCreation, "The toolbar spinner must continue through confirmation")
        XCTAssertTrue(model.busy)
        XCTAssertFalse(model.canCreate)
        XCTAssertFalse(model.creationSucceeded)
        XCTAssertFalse(model.showConfirmationError)
        XCTAssertNil(model.message, "Do not show a warning before automatic confirmation finishes")
        XCTAssertEqual(model.invitations, [oldCode])
        model.requestCreation()
        model.refresh()
        await model.load()
        XCTAssertEqual(service.reads.count, 2)
        XCTAssertEqual(service.creations.count, 1)
        gate.resume(.success([oldCode, newCode]))
        await model.waitForOperations()
        XCTAssertFalse(model.isConfirmingCreation)
        XCTAssertFalse(model.confirmationPending)
        XCTAssertTrue(model.creationSucceeded)
        XCTAssertFalse(model.showConfirmationError)
        XCTAssertNil(model.message)
        XCTAssertEqual(model.invitations, [newCode, oldCode])
        XCTAssertEqual(service.creations.count, 1)
    }

    func testUnresolvedOrFailedConfirmationShowsAlertWithoutToastOrReposting() async {
        for readFails in [false, true] {
            let service = MockInvitationService()
            let code = invitation()
            service.loadHandler = { _ in [code] }
            let model = SettingsInvitationsViewModel(service: service, session: MockInvitationSession())
            await model.load()
            let gate = InvitationAsyncGate<[Invitation]>()
            service.createHandler = { _ in .unconfirmed }
            service.loadHandler = { _ in try await gate.value() }
            model.requestCreation()
            await gate.waitUntilStarted()
            XCTAssertTrue(model.isConfirmingCreation)
            XCTAssertFalse(model.showConfirmationError)
            if readFails {
                gate.resume(.failure(URLError(.timedOut)))
            } else {
                gate.resume(.success([code]))
            }
            await model.waitForOperations()
            XCTAssertTrue(model.showConfirmationError)
            XCTAssertNil(model.message)
            XCTAssertTrue(model.confirmationPending)
            XCTAssertFalse(model.isConfirmingCreation)
            XCTAssertFalse(model.creationSucceeded)
            XCTAssertFalse(model.busy)
            XCTAssertEqual(model.invitations, [code], "The confirmation alert must leave the existing list intact")
            XCTAssertEqual(service.reads.count, 2)
            XCTAssertEqual(service.creations.count, 1)
            model.requestCreation()
            XCTAssertTrue(model.confirmCreation, "A new POST still requires explicit confirmation")
        }
    }

    func testDismissingConfirmationAlertPreservesContentAndFailedRetriesPresentAgain() async {
        let service = MockInvitationService()
        let code = invitation()
        service.loadHandler = { _ in [code] }
        let model = SettingsInvitationsViewModel(service: service, session: MockInvitationSession())
        await model.load()
        service.createHandler = { _ in .unconfirmed }
        model.requestCreation()
        await model.waitForOperations()
        XCTAssertTrue(model.showConfirmationError)
        model.showConfirmationError = false
        XCTAssertEqual(model.state, .success([code]))
        XCTAssertTrue(model.confirmationPending, "Dismissing the alert must not remove the duplicate-write safeguard")
        XCTAssertEqual(service.reads.count, 2)
        XCTAssertEqual(service.creations.count, 1)

        service.loadHandler = { _ in throw URLError(.timedOut) }
        model.refresh()
        await model.waitForOperations()
        XCTAssertTrue(model.showConfirmationError, "An identical retry failure must present the alert again")
        XCTAssertEqual(model.state, .success([code]))
        XCTAssertFalse(model.isConfirmingCreation)
        XCTAssertNil(model.message)
        model.showConfirmationError = false

        service.loadHandler = { _ in [code] }
        model.refresh()
        await model.waitForOperations()
        XCTAssertTrue(model.showConfirmationError, "An unchanged list still needs confirmation")
        XCTAssertEqual(model.state, .success([code]))
        XCTAssertFalse(model.creationSucceeded)
        XCTAssertEqual(service.reads.count, 4)
        XCTAssertEqual(service.creations.count, 1)
    }

    func testConfirmationErrorRetryOnlyReadsAndClearsErrorWhenResolved() async {
        let service = MockInvitationService()
        let model = SettingsInvitationsViewModel(service: service, session: MockInvitationSession())
        await model.load()
        service.createHandler = { _ in .unconfirmed }
        model.requestCreation()
        await model.waitForOperations()
        XCTAssertTrue(model.showConfirmationError)
        let gate = InvitationAsyncGate<[Invitation]>()
        service.loadHandler = { _ in try await gate.value() }
        model.refresh()
        await gate.waitUntilStarted()
        XCTAssertTrue(model.isConfirmingCreation)
        XCTAssertFalse(model.isCreating)
        XCTAssertFalse(model.canCreate)
        let code = invitation()
        gate.resume(.success([code]))
        await model.waitForOperations()
        XCTAssertFalse(model.showConfirmationError)
        XCTAssertFalse(model.confirmationPending)
        XCTAssertFalse(model.isConfirmingCreation)
        XCTAssertTrue(model.creationSucceeded)
        XCTAssertEqual(model.invitations, [code])
        XCTAssertEqual(service.creations.count, 1)
        XCTAssertEqual(service.reads.count, 3)
    }

    func testCancelledConfirmationRestoresContentWithoutErrorOrSuccess() async {
        let service = MockInvitationService()
        let code = invitation()
        service.loadHandler = { _ in [code] }
        let model = SettingsInvitationsViewModel(service: service, session: MockInvitationSession())
        await model.load()
        let gate = InvitationAsyncGate<[Invitation]>()
        service.createHandler = { _ in .unconfirmed }
        service.loadHandler = { _ in try await gate.value() }
        model.requestCreation()
        await gate.waitUntilStarted()
        model.creationTask?.cancel()
        gate.resume(.failure(URLError(.timedOut)))
        await model.waitForOperations()
        XCTAssertFalse(model.isConfirmingCreation)
        XCTAssertFalse(model.busy)
        XCTAssertFalse(model.creationSucceeded)
        XCTAssertTrue(model.confirmationPending)
        XCTAssertFalse(model.showConfirmationError)
        XCTAssertNil(model.message)
        XCTAssertEqual(model.state, .success([code]))
        XCTAssertEqual(service.creations.count, 1)
    }

    func testLeavingOrChangingSessionDuringConfirmationSuppressesLateSuccessAndError() async {
        for changeSession in [false, true] {
            for readFails in [false, true] {
                let service = MockInvitationService()
                let session = MockInvitationSession()
                let model = SettingsInvitationsViewModel(service: service, session: session)
                await model.load()
                let gate = InvitationAsyncGate<[Invitation]>()
                service.createHandler = { _ in .unconfirmed }
                service.loadHandler = { _ in try await gate.value() }
                model.requestCreation()
                await gate.waitUntilStarted()
                let oldTask = model.creationTask
                if changeSession {
                    session.transition(to: nil)
                    model.synchronizeSession()
                } else {
                    model.disappear()
                }
                XCTAssertFalse(model.isConfirmingCreation)
                XCTAssertFalse(model.busy)
                if readFails {
                    gate.resume(.failure(URLError(.timedOut)))
                } else {
                    gate.resume(.success([invitation()]))
                }
                await oldTask?.value
                XCTAssertFalse(model.showConfirmationError)
                XCTAssertNil(model.message)
                XCTAssertFalse(model.creationSucceeded)
                XCTAssertTrue(model.invitations.isEmpty)
                XCTAssertEqual(model.confirmationPending, !changeSession)
                XCTAssertEqual(service.creations.count, 1)
            }
        }
    }

    func testUnconfirmedCreationChecksOnlyAndRequiresExplicitRetry() async {
        let service = MockInvitationService()
        service.createHandler = { _ in .unconfirmed }
        let model = SettingsInvitationsViewModel(service: service, session: MockInvitationSession())
        await model.load()
        model.requestCreation()
        await model.waitForOperations()
        XCTAssertTrue(model.confirmationPending)
        XCTAssertEqual(service.creations.count, 1)
        XCTAssertEqual(service.reads.count, 2)
        model.requestCreation()
        XCTAssertTrue(model.confirmCreation)
        XCTAssertEqual(service.creations.count, 1)
        model.refresh()
        await model.waitForOperations()
        XCTAssertFalse(model.confirmCreation)
        XCTAssertTrue(model.confirmationPending, "No new code is not proof of a failed write")
        XCTAssertEqual(service.creations.count, 1)
        model.requestCreation()
        model.confirmCreation = false
        service.createHandler = { _ in .coolingDown }
        model.confirmCreate()
        await model.waitForOperations()
        XCTAssertEqual(service.creations.count, 2)
        XCTAssertFalse(model.confirmationPending)
    }

    func testNewCodeInReadResolvesUnconfirmedWriteWithoutResending() async {
        let service = MockInvitationService()
        service.createHandler = { _ in .unconfirmed }
        let model = SettingsInvitationsViewModel(service: service, session: MockInvitationSession())
        await model.load()
        model.requestCreation()
        await model.waitForOperations()
        let code = invitation()
        service.loadHandler = { _ in [code] }
        await model.load()
        XCTAssertFalse(model.confirmationPending)
        XCTAssertEqual(model.invitations, [code])
        XCTAssertEqual(service.creations.count, 1)
    }

    func testDefiniteCreationFailureDoesNotReconcileOrMarkPending() async {
        let service = MockInvitationService()
        service.createHandler = { _ in throw InvitationError.rejected }
        let model = SettingsInvitationsViewModel(service: service, session: MockInvitationSession())
        await model.load()
        model.requestCreation()
        await model.waitForOperations()
        XCTAssertFalse(model.confirmationPending)
        XCTAssertEqual(service.creations.count, 1)
        XCTAssertEqual(service.reads.count, 1)
        XCTAssertNotNil(model.message)
        XCTAssertTrue(model.canCreate)
    }

    func testCancelledCreationStaysPendingWithoutErrorOrAutomaticRetry() async {
        let service = MockInvitationService()
        service.createHandler = { _ in throw CancellationError() }
        let model = SettingsInvitationsViewModel(service: service, session: MockInvitationSession())
        await model.load()
        model.requestCreation()
        await model.waitForOperations()
        XCTAssertTrue(model.confirmationPending)
        XCTAssertNil(model.message)
        XCTAssertFalse(model.isCreating)
        XCTAssertEqual(service.reads.count, 1)
        XCTAssertEqual(service.creations.count, 1)
    }

    func testCancelledCreationWithRacingFailureDoesNotShowError() async {
        let service = MockInvitationService()
        let gate = InvitationAsyncGate<InvitationCreationResult>()
        service.createHandler = { _ in try await gate.value() }
        let model = SettingsInvitationsViewModel(service: service, session: MockInvitationSession())
        await model.load()
        model.requestCreation()
        await gate.waitUntilStarted()
        model.creationTask?.cancel()
        gate.resume(.failure(URLError(.timedOut)))
        await model.waitForOperations()
        XCTAssertTrue(model.confirmationPending)
        XCTAssertNil(model.message)
        XCTAssertFalse(model.busy)
    }

    func testUnauthorizedReadAndWriteClearDataAndStopFurtherWork() async {
        for onWrite in [false, true] {
            let service = MockInvitationService()
            let code = invitation()
            service.loadHandler = { _ in [code] }
            let model = SettingsInvitationsViewModel(service: service, session: MockInvitationSession())
            await model.load()
            if onWrite {
                service.createHandler = { _ in throw InvitationError.unauthorized }
                model.requestCreation()
                await model.waitForOperations()
            } else {
                service.loadHandler = { _ in throw InvitationError.unauthorized }
                await model.load()
            }
            XCTAssertTrue(model.requiresSignIn)
            XCTAssertFalse(model.isSignedIn)
            XCTAssertTrue(model.invitations.isEmpty)
            XCTAssertEqual(model.state, .idle)
            XCTAssertFalse(model.canCopy(code))
            XCTAssertFalse(model.busy)
            XCTAssertFalse(model.confirmationPending)
            XCTAssertNil(model.message)
            let readCount = service.reads.count
            let writeCount = service.creations.count
            await model.load()
            model.requestCreation()
            XCTAssertEqual(service.reads.count, readCount)
            XCTAssertEqual(service.creations.count, writeCount)
        }
    }

    func testGuestTransitionClearsStateFilterAndPresentations() async {
        let service = MockInvitationService()
        let code = invitation()
        service.loadHandler = { _ in [code] }
        let session = MockInvitationSession()
        let model = SettingsInvitationsViewModel(service: service, session: session)
        await model.load()
        model.filter = .used
        model.confirmCreation = true
        session.transition(to: nil)
        XCTAssertFalse(model.isCurrentSession)
        XCTAssertTrue(model.invitations.isEmpty)
        XCTAssertFalse(model.canCopy(code))
        model.synchronizeSession()
        XCTAssertEqual(model.filter, .all)
        XCTAssertFalse(model.confirmCreation)
        XCTAssertEqual(model.state, .idle)
        await model.load()
        XCTAssertEqual(service.reads.count, 1)
    }

    func testReadAtoBtoAIgnoresLateResponse() async {
        let service = MockInvitationService()
        let session = MockInvitationSession()
        let original = session.credentials
        let model = SettingsInvitationsViewModel(service: service, session: session)
        let gate = InvitationAsyncGate<[Invitation]>()
        service.loadHandler = { _ in try await gate.value() }
        let oldRead = Task { await model.load() }
        await gate.waitUntilStarted()
        session.transition(to: Credentials(email: "b@example.invalid", token: "not-a-credential", uid: 2, uuid: "test-b"))
        model.synchronizeSession()
        session.transition(to: original)
        service.loadHandler = { _ in [] }
        await model.load()
        gate.resume(.success([invitation()]))
        await oldRead.value
        XCTAssertEqual(model.state, .success([]))
        XCTAssertEqual(model.revision, 2)
    }

    func testOldCreationCannotClearNewSessionsCreationOrShowFeedback() async {
        let service = MockInvitationService()
        let session = MockInvitationSession()
        let model = SettingsInvitationsViewModel(service: service, session: session)
        let oldGate = InvitationAsyncGate<InvitationCreationResult>()
        let newGate = InvitationAsyncGate<InvitationCreationResult>()
        await model.load()
        service.createHandler = { _ in try await oldGate.value() }
        model.requestCreation()
        await oldGate.waitUntilStarted()
        let oldTask = model.creationTask
        session.transition(to: Credentials(email: "b@example.invalid", token: "not-a-credential", uid: 2, uuid: "test-b"))
        await model.load()
        service.createHandler = { _ in try await newGate.value() }
        model.requestCreation()
        await newGate.waitUntilStarted()
        oldGate.resume(.success(.created(invitation())))
        await oldTask?.value
        XCTAssertTrue(model.isCreating)
        XCTAssertTrue(model.invitations.isEmpty)
        XCTAssertNil(model.message)
        newGate.resume(.success(.coolingDown))
        await model.waitForOperations()
        XCTAssertFalse(model.busy)
        XCTAssertTrue(model.invitations.isEmpty)
    }

    func testDisappearReappearIgnoresOldReadInSameSession() async {
        let service = MockInvitationService()
        let model = SettingsInvitationsViewModel(service: service, session: MockInvitationSession())
        let gate = InvitationAsyncGate<[Invitation]>()
        service.loadHandler = { _ in try await gate.value() }
        let oldRead = Task { await model.load() }
        await gate.waitUntilStarted()
        model.disappear()
        service.loadHandler = { _ in [] }
        await model.load()
        gate.resume(.success([invitation()]))
        await oldRead.value
        XCTAssertEqual(model.state, .success([]))
        XCTAssertNil(model.message)
    }

    func testDisappearDuringWritePreservesPendingAndSuppressesLateResult() async {
        let service = MockInvitationService()
        let model = SettingsInvitationsViewModel(service: service, session: MockInvitationSession())
        await model.load()
        let gate = InvitationAsyncGate<InvitationCreationResult>()
        service.createHandler = { _ in try await gate.value() }
        model.requestCreation()
        await gate.waitUntilStarted()
        let oldTask = model.creationTask
        model.disappear()
        XCTAssertTrue(model.confirmationPending)
        XCTAssertFalse(model.busy)
        gate.resume(.success(.created(invitation())))
        await oldTask?.value
        XCTAssertNil(model.message)
        XCTAssertTrue(model.invitations.isEmpty)
        await model.load()
        XCTAssertTrue(model.confirmationPending)
        XCTAssertEqual(service.creations.count, 1)
        model.requestCreation()
        XCTAssertTrue(model.confirmCreation)
    }

    func testCancelledBeforeTaskStartsNeverCallsCreationService() async {
        for changeSession in [false, true] {
            let service = MockInvitationService()
            let session = MockInvitationSession()
            let model = SettingsInvitationsViewModel(service: service, session: session)
            await model.load()
            model.requestCreation()
            let queued = model.creationTask
            if changeSession {
                session.transition(to: nil)
                model.synchronizeSession()
            } else {
                model.disappear()
            }
            await queued?.value
            XCTAssertTrue(service.creations.isEmpty)
            XCTAssertNil(model.message)
            XCTAssertFalse(model.busy)
        }
    }

    func testQueuedButtonRefreshPreventsImmediateCreationAndDuplicateRefresh() async {
        let service = MockInvitationService()
        let model = SettingsInvitationsViewModel(service: service, session: MockInvitationSession())
        await model.load()
        model.refresh()
        model.refresh()
        model.requestCreation()
        await model.waitForOperations()
        XCTAssertEqual(service.reads.count, 2)
        XCTAssertTrue(service.creations.isEmpty)
        XCTAssertTrue(model.canCreate)
    }

    func testDisappearDuringReconciliationKeepsConfirmedCodeAndCancelsRead() async {
        let service = MockInvitationService()
        let session = MockInvitationSession()
        let model = SettingsInvitationsViewModel(service: service, session: session)
        await model.load()
        let code = invitation()
        let gate = InvitationAsyncGate<[Invitation]>()
        service.createHandler = { _ in .created(code) }
        service.loadHandler = { _ in try await gate.value() }
        model.requestCreation()
        await gate.waitUntilStarted()
        let oldTask = model.creationTask
        XCTAssertFalse(model.isCreating)
        model.disappear()
        XCTAssertEqual(model.invitations, [code])
        XCTAssertFalse(model.confirmationPending)
        XCTAssertNil(model.message)
        gate.resume(.success([]))
        await oldTask?.value
        service.loadHandler = { _ in [] }
        await model.load()
        XCTAssertEqual(model.invitations, [code])
        session.transition(to: Credentials(email: "b@example.invalid", token: "not-a-credential", uid: 2, uuid: "test-b"))
        await model.load()
        XCTAssertTrue(model.invitations.isEmpty, "Confirmed local codes must not cross sessions")
    }

    func testOldCreationCannotAffectNewWriteAfterReenteringSameSession() async {
        let service = MockInvitationService()
        let model = SettingsInvitationsViewModel(service: service, session: MockInvitationSession())
        await model.load()
        let oldGate = InvitationAsyncGate<InvitationCreationResult>()
        let newGate = InvitationAsyncGate<InvitationCreationResult>()
        service.createHandler = { _ in try await oldGate.value() }
        model.requestCreation()
        await oldGate.waitUntilStarted()
        let oldTask = model.creationTask
        model.disappear()
        await model.load()
        service.createHandler = { _ in try await newGate.value() }
        model.requestCreation()
        XCTAssertTrue(model.confirmCreation)
        model.confirmCreation = false
        model.confirmCreate()
        await newGate.waitUntilStarted()
        oldGate.resume(.success(.created(invitation())))
        await oldTask?.value
        XCTAssertTrue(model.isCreating)
        XCTAssertNil(model.message)
        XCTAssertTrue(model.invitations.isEmpty)
        newGate.resume(.success(.coolingDown))
        await model.waitForOperations()
        XCTAssertFalse(model.isCreating)
        XCTAssertFalse(model.confirmationPending)
    }

    func testDisappearCancelsOwnedRefreshAndIgnoresItsLateResponse() async {
        let service = MockInvitationService()
        let model = SettingsInvitationsViewModel(service: service, session: MockInvitationSession())
        await model.load()
        let gate = InvitationAsyncGate<[Invitation]>()
        service.loadHandler = { _ in try await gate.value() }
        model.refresh()
        await gate.waitUntilStarted()
        let oldTask = model.refreshTask
        model.disappear()
        gate.resume(.success([invitation()]))
        await oldTask?.value
        XCTAssertEqual(model.state, .success([]))
        XCTAssertNil(model.message)
        XCTAssertNil(model.refreshTask)
    }
}
