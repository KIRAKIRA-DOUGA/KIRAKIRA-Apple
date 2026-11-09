import XCTest
@testable import KIRAKIRA

@MainActor
final class SettingsPrivacyViewModelTests: XCTestCase {
    func testInitialLoadAndSameValueDoNotWrite() async {
        let service = MockPrivacyService()
        let model = SettingsPrivacyViewModel(service: service, session: MockPrivacySession())
        await model.load()
        XCTAssertTrue(model.editable)
        XCTAssertEqual(model.uniformVisibility, .public)
        model.selectAll(.public)
        await model.waitForSave()
        XCTAssertTrue(service.savedValues.isEmpty)
        XCTAssertNil(model.message)
    }

    func testInitialLoadCancellationReturnsIdleAndRefreshCancellationRestoresContent() async {
        let service = MockPrivacyService()
        let model = SettingsPrivacyViewModel(service: service, session: MockPrivacySession())
        service.loadHandler = { _ in throw CancellationError() }
        await model.load()
        XCTAssertEqual(model.state, .idle)
        XCTAssertNil(model.message)
        service.loadHandler = { _ in PrivacyTestSupport.settings() }
        await model.load()
        service.loadHandler = { _ in throw CancellationError() }
        await model.load()
        XCTAssertEqual(model.state, .success(PrivacyTestSupport.settings()))
        XCTAssertNil(model.message)
    }

    func testRefreshFailureKeepsConfirmedValues() async {
        let service = MockPrivacyService()
        let model = SettingsPrivacyViewModel(service: service, session: MockPrivacySession())
        await model.load()
        service.loadHandler = { _ in throw URLError(.notConnectedToInternet) }
        await model.load()
        XCTAssertEqual(model.state, .success(PrivacyTestSupport.settings()))
        XCTAssertNotNil(model.message)
        XCTAssertTrue(model.editable)
    }

    func testInitialFailureHasRetryableError() async {
        let service = MockPrivacyService()
        service.loadHandler = { _ in throw URLError(.notConnectedToInternet) }
        let model = SettingsPrivacyViewModel(service: service, session: MockPrivacySession())
        await model.load()
        XCTAssertNotNil(model.state.errorMessage)
        XCTAssertFalse(model.editable)
        service.loadHandler = { _ in PrivacyTestSupport.settings() }
        await model.load()
        XCTAssertTrue(model.editable)
    }

    func testSingleSelectionBatchAndResetUseOneSaveEach() async {
        let service = MockPrivacyService()
        let model = SettingsPrivacyViewModel(service: service, session: MockPrivacySession())
        await model.load()
        model.setVisibility(.private, for: .birthday)
        await model.waitForSave()
        XCTAssertEqual(model.values[.birthday], .private)
        XCTAssertNil(model.uniformVisibility)
        XCTAssertTrue(model.savedMessage)
        model.selectAll(.following)
        await model.waitForSave()
        XCTAssertEqual(model.uniformVisibility, .following)
        model.requestReset()
        XCTAssertTrue(model.confirmReset)
        // The presentation binding can be dismissed before the confirmed action executes.
        model.confirmReset = false
        model.reset()
        await model.waitForSave()
        XCTAssertEqual(model.values, PrivacyTestSupport.values())
        XCTAssertFalse(model.canReset)
        XCTAssertEqual(service.savedValues.count, 3)
    }

    func testSameSingleSelectionDoesNotWrite() async {
        let service = MockPrivacyService()
        let model = SettingsPrivacyViewModel(service: service, session: MockPrivacySession())
        await model.load()
        model.setVisibility(.public, for: .age)
        await model.waitForSave()
        XCTAssertTrue(service.savedValues.isEmpty)
        XCTAssertNil(model.message)
    }

    func testSaveExcludesOtherSavesRefreshAndSuccessUntilConfirmed() async {
        let gate = PrivacyAsyncGate<PrivacySaveResult>()
        let service = MockPrivacyService()
        service.saveHandler = { _, _, _ in try await gate.value() }
        let model = SettingsPrivacyViewModel(service: service, session: MockPrivacySession())
        await model.load()
        model.selectAll(.private)
        await gate.waitUntilStarted()
        XCTAssertTrue(model.busy)
        XCTAssertFalse(model.editable)
        XCTAssertNil(model.message)
        model.selectAll(.following)
        model.requestReset()
        await model.load()
        XCTAssertFalse(model.confirmReset)
        XCTAssertEqual(service.loadCount, 1)
        XCTAssertEqual(service.savedValues.count, 1)
        gate.resume(.success(.confirmed(PrivacyTestSupport.settings(visibility: .private))))
        await model.waitForSave()
        XCTAssertFalse(model.busy)
        XCTAssertTrue(model.savedMessage)
    }

    func testDefiniteSaveFailureRollsBack() async {
        let service = MockPrivacyService()
        service.saveHandler = { _, _, _ in throw PrivacySettingsError.rejected }
        let model = SettingsPrivacyViewModel(service: service, session: MockPrivacySession())
        await model.load()
        model.selectAll(.private)
        await model.waitForSave()
        XCTAssertEqual(model.values, PrivacyTestSupport.values())
        XCTAssertTrue(model.editable)
        XCTAssertNotNil(model.message)
        XCTAssertFalse(model.savedMessage)
    }

    func testUnconfirmedWriteBlocksEditingAndReadUsesActualServerValues() async {
        let service = MockPrivacyService()
        service.saveHandler = { _, _, _ in .unconfirmed }
        let model = SettingsPrivacyViewModel(service: service, session: MockPrivacySession())
        await model.load()
        service.loadHandler = { _ in throw URLError(.timedOut) }
        model.selectAll(.private)
        await model.waitForSave()
        XCTAssertTrue(model.confirmationPending)
        XCTAssertTrue(model.showConfirmationError)
        XCTAssertFalse(model.editable)
        XCTAssertNil(model.message)
        model.selectAll(.following)
        XCTAssertEqual(service.savedValues.count, 1)
        service.loadHandler = { _ in throw URLError(.timedOut) }
        await model.load()
        XCTAssertTrue(model.confirmationPending)
        service.loadHandler = { _ in PrivacyTestSupport.settings(visibility: .following) }
        await model.load()
        XCTAssertFalse(model.confirmationPending)
        XCTAssertTrue(model.editable)
        XCTAssertEqual(model.uniformVisibility, .following)
        XCTAssertEqual(service.savedValues.count, 1)
    }

    func testCancelledSaveIsPendingWithoutCancelledMessage() async {
        let service = MockPrivacyService()
        service.saveHandler = { _, _, _ in throw CancellationError() }
        let model = SettingsPrivacyViewModel(service: service, session: MockPrivacySession())
        await model.load()
        model.selectAll(.private)
        await model.waitForSave()
        XCTAssertTrue(model.confirmationPending)
        XCTAssertNil(model.message)
        XCTAssertFalse(model.busy)
    }

    func testUnauthorizedClearsDataAndStopsEditing() async {
        let service = MockPrivacyService()
        let model = SettingsPrivacyViewModel(service: service, session: MockPrivacySession())
        await model.load()
        service.saveHandler = { _, _, _ in throw PrivacySettingsError.unauthorized }
        model.selectAll(.private)
        await model.waitForSave()
        XCTAssertTrue(model.requiresSignIn)
        XCTAssertFalse(model.editable)
        XCTAssertTrue(model.values.isEmpty)
        XCTAssertNil(model.state.value)
        XCTAssertNil(model.message)
    }

    func testHTTP200ReadAuthenticationFailureClearsDataAndStopsFurtherLoads() async {
        for initiallyLoaded in [false, true] {
            let transport = MockPrivacyTransport()
            let service = PrivacySettingsService(transport: transport)
            let model = SettingsPrivacyViewModel(service: service, session: MockPrivacySession())
            if initiallyLoaded { await model.load() }
            transport.readHandler = { _ in
                try PrivacyTestSupport.decode([
                    "success": false,
                    "message": "获取用户个性设置失败，用户验证时未通过"
                ])
            }
            await model.load()
            XCTAssertTrue(model.requiresSignIn)
            XCTAssertFalse(model.editable)
            XCTAssertTrue(model.values.isEmpty)
            XCTAssertEqual(model.state, .idle)
            XCTAssertFalse(model.busy)
            XCTAssertNil(model.message)
            let readCount = transport.reads.count
            await model.load()
            XCTAssertEqual(transport.reads.count, readCount)
        }
    }

    func testHTTP200SaveAuthenticationFailureClearsDataInsteadOfRestoringEditing() async {
        let transport = MockPrivacyTransport()
        let service = PrivacySettingsService(transport: transport)
        let model = SettingsPrivacyViewModel(service: service, session: MockPrivacySession())
        await model.load()
        transport.updateHandler = { _, _ in
            try PrivacyTestSupport.decode([
                "success": false,
                "message": "更新或创建用户设置失败，非法用户！"
            ])
        }
        model.selectAll(.private)
        await model.waitForSave()
        XCTAssertTrue(model.requiresSignIn)
        XCTAssertFalse(model.editable)
        XCTAssertTrue(model.values.isEmpty)
        XCTAssertEqual(model.state, .idle)
        XCTAssertFalse(model.busy)
        XCTAssertFalse(model.confirmationPending)
        XCTAssertFalse(model.savedMessage)
        XCTAssertNil(model.message)
        model.selectAll(.following)
        XCTAssertEqual(transport.updates.count, 1)
    }

    func testReadAtoBtoAIgnoresLateResponse() async {
        let gate = PrivacyAsyncGate<PrivacySettings>()
        let service = MockPrivacyService()
        let session = MockPrivacySession()
        let model = SettingsPrivacyViewModel(service: service, session: session)
        service.loadHandler = { _ in try await gate.value() }
        let oldRead = Task { await model.load() }
        await gate.waitUntilStarted()
        session.transition(to: PrivacyTestSupport.credentials(uid: 2, uuid: "test-session-b"))
        model.synchronizeSession()
        XCTAssertTrue(model.values.isEmpty)
        session.transition(to: PrivacyTestSupport.credentials())
        service.loadHandler = { _ in PrivacyTestSupport.settings(visibility: .following) }
        await model.load()
        gate.resume(.success(PrivacyTestSupport.settings(visibility: .private)))
        await oldRead.value
        XCTAssertEqual(model.uniformVisibility, .following)
        XCTAssertEqual(model.revision, 2)
    }

    func testOldSaveCannotClearNewSessionsBusyOrShowSuccess() async {
        let oldGate = PrivacyAsyncGate<PrivacySaveResult>()
        let newGate = PrivacyAsyncGate<PrivacySaveResult>()
        let service = MockPrivacyService()
        let session = MockPrivacySession()
        let model = SettingsPrivacyViewModel(service: service, session: session)
        await model.load()
        service.saveHandler = { _, _, _ in try await oldGate.value() }
        model.selectAll(.private)
        await oldGate.waitUntilStarted()
        let oldSaveFinished = model.saveTask
        session.transition(to: PrivacyTestSupport.credentials(uid: 2, uuid: "test-session-b"))
        await model.load()
        service.saveHandler = { _, _, _ in try await newGate.value() }
        model.selectAll(.following)
        await newGate.waitUntilStarted()
        oldGate.resume(.success(.confirmed(PrivacyTestSupport.settings(visibility: .private))))
        await oldSaveFinished?.value
        XCTAssertTrue(model.isSaving)
        XCTAssertNil(model.message)
        newGate.resume(.success(.confirmed(PrivacyTestSupport.settings(uid: 2, visibility: .following))))
        await model.waitForSave()
        XCTAssertFalse(model.busy)
        XCTAssertEqual(model.state.value?.uid, 2)
        XCTAssertEqual(model.uniformVisibility, .following)
    }

    func testDisappearCancelsWriteAndSuppressesLateFeedback() async {
        let gate = PrivacyAsyncGate<PrivacySaveResult>()
        let service = MockPrivacyService()
        let model = SettingsPrivacyViewModel(service: service, session: MockPrivacySession())
        await model.load()
        service.saveHandler = { _, _, _ in try await gate.value() }
        model.selectAll(.private)
        await gate.waitUntilStarted()
        let finished = model.saveTask
        model.disappear()
        XCTAssertTrue(model.confirmationPending)
        XCTAssertFalse(model.busy)
        gate.resume(.success(.confirmed(PrivacyTestSupport.settings(visibility: .private))))
        await finished?.value
        XCTAssertNil(model.message)
        await model.load()
        XCTAssertEqual(model.uniformVisibility, .public)
        XCTAssertTrue(model.editable)
    }

    func testCancelledRefreshDoesNotSurfaceRacingNetworkFailure() async {
        let service = MockPrivacyService()
        let gate = PrivacyAsyncGate<PrivacySettings>()
        let model = SettingsPrivacyViewModel(service: service, session: MockPrivacySession())
        await model.load()
        service.loadHandler = { _ in try await gate.value() }
        let refresh = Task { await model.load() }
        await gate.waitUntilStarted()
        refresh.cancel()
        gate.resume(.failure(URLError(.timedOut)))
        await refresh.value
        XCTAssertEqual(model.state, .success(PrivacyTestSupport.settings()))
        XCTAssertNil(model.message)
    }

    func testDisappearReappearInSameSessionIgnoresOldRead() async {
        let service = MockPrivacyService()
        let gate = PrivacyAsyncGate<PrivacySettings>()
        let model = SettingsPrivacyViewModel(service: service, session: MockPrivacySession())
        service.loadHandler = { _ in try await gate.value() }
        let oldRead = Task { await model.load() }
        await gate.waitUntilStarted()
        model.disappear()
        service.loadHandler = { _ in PrivacyTestSupport.settings(visibility: .following) }
        await model.load()
        gate.resume(.success(PrivacyTestSupport.settings(visibility: .private)))
        await oldRead.value
        XCTAssertEqual(model.uniformVisibility, .following)
        XCTAssertTrue(model.editable)
    }

    func testCancelledWriteWithRacingFailureStaysPendingWithoutMessage() async {
        let service = MockPrivacyService()
        let gate = PrivacyAsyncGate<PrivacySaveResult>()
        let model = SettingsPrivacyViewModel(service: service, session: MockPrivacySession())
        await model.load()
        service.saveHandler = { _, _, _ in try await gate.value() }
        model.selectAll(.private)
        await gate.waitUntilStarted()
        model.saveTask?.cancel()
        gate.resume(.failure(URLError(.timedOut)))
        await model.waitForSave()
        XCTAssertTrue(model.confirmationPending)
        XCTAssertNil(model.message)
        XCTAssertFalse(model.isSaving)
    }

    func testUnconfirmedSaveAutomaticallyReadsOnceAndConfirmsMatchingValues() async {
        let service = MockPrivacyService()
        let gate = PrivacyAsyncGate<PrivacySettings>()
        let model = SettingsPrivacyViewModel(service: service, session: MockPrivacySession())
        await model.load()
        service.saveHandler = { _, _, _ in .unconfirmed }
        service.loadHandler = { _ in try await gate.value() }
        model.selectAll(.private)
        await gate.waitUntilStarted()
        XCTAssertFalse(model.isSaving)
        XCTAssertTrue(model.isConfirmingSave)
        XCTAssertTrue(model.confirmationPending)
        XCTAssertFalse(model.editable)
        XCTAssertFalse(model.saveSucceeded)
        XCTAssertFalse(model.showConfirmationError)
        XCTAssertNil(model.message)
        XCTAssertEqual(model.state.value, PrivacyTestSupport.settings())
        XCTAssertEqual(model.values, PrivacyTestSupport.values(.private))
        gate.resume(.success(PrivacyTestSupport.settings(visibility: .private)))
        await model.waitForSave()
        XCTAssertFalse(model.isConfirmingSave)
        XCTAssertFalse(model.confirmationPending)
        XCTAssertTrue(model.saveSucceeded)
        XCTAssertTrue(model.editable)
        XCTAssertNil(model.message)
        XCTAssertEqual(service.loadCount, 2)
        XCTAssertEqual(service.savedValues.count, 1)
    }

    func testConfirmationUsesActualValuesWithoutFalselyAcknowledgingSave() async {
        let service = MockPrivacyService()
        let model = SettingsPrivacyViewModel(service: service, session: MockPrivacySession())
        await model.load()
        service.saveHandler = { _, _, _ in .unconfirmed }
        service.loadHandler = { _ in PrivacyTestSupport.settings(visibility: .following) }
        model.selectAll(.private)
        await model.waitForSave()
        XCTAssertEqual(model.uniformVisibility, .following)
        XCTAssertTrue(model.editable)
        XCTAssertFalse(model.confirmationPending)
        XCTAssertFalse(model.saveSucceeded)
        XCTAssertFalse(model.showConfirmationError)
        XCTAssertEqual(service.loadCount, 2)
        XCTAssertEqual(service.savedValues.count, 1)
    }

    func testConfirmationAlertCanBeDismissedAndReadRetriesNeverResave() async {
        let service = MockPrivacyService()
        let model = SettingsPrivacyViewModel(service: service, session: MockPrivacySession())
        await model.load()
        service.saveHandler = { _, _, _ in .unconfirmed }
        service.loadHandler = { _ in throw URLError(.timedOut) }
        model.selectAll(.private)
        await model.waitForSave()
        XCTAssertTrue(model.showConfirmationError)
        XCTAssertNil(model.message)
        XCTAssertEqual(model.state.value, PrivacyTestSupport.settings())
        model.showConfirmationError = false
        XCTAssertTrue(model.confirmationPending)
        XCTAssertFalse(model.editable)
        model.selectAll(.following)
        await model.load()
        XCTAssertTrue(model.showConfirmationError)
        XCTAssertTrue(model.confirmationPending)
        XCTAssertNil(model.message)
        XCTAssertEqual(service.loadCount, 3)
        XCTAssertEqual(service.savedValues.count, 1)
        service.loadHandler = { _ in PrivacyTestSupport.settings(visibility: .private) }
        await model.load()
        XCTAssertFalse(model.showConfirmationError)
        XCTAssertTrue(model.saveSucceeded)
        XCTAssertTrue(model.editable)
        XCTAssertEqual(service.savedValues.count, 1)
    }

    func testCancelledConfirmationPreservesPendingAndSuppressesAlert() async {
        let service = MockPrivacyService()
        let gate = PrivacyAsyncGate<PrivacySettings>()
        let model = SettingsPrivacyViewModel(service: service, session: MockPrivacySession())
        await model.load()
        service.saveHandler = { _, _, _ in .unconfirmed }
        service.loadHandler = { _ in try await gate.value() }
        model.selectAll(.private)
        await gate.waitUntilStarted()
        model.saveTask?.cancel()
        gate.resume(.failure(URLError(.timedOut)))
        await model.waitForSave()
        XCTAssertFalse(model.isConfirmingSave)
        XCTAssertTrue(model.confirmationPending)
        XCTAssertFalse(model.showConfirmationError)
        XCTAssertFalse(model.saveSucceeded)
        XCTAssertNil(model.message)
        XCTAssertNotNil(model.state.value)
    }

    func testLeavingDuringConfirmationIgnoresLateResponseAndCanReadOnReturn() async {
        let service = MockPrivacyService()
        let gate = PrivacyAsyncGate<PrivacySettings>()
        let model = SettingsPrivacyViewModel(service: service, session: MockPrivacySession())
        await model.load()
        service.saveHandler = { _, _, _ in .unconfirmed }
        service.loadHandler = { _ in try await gate.value() }
        model.selectAll(.private)
        await gate.waitUntilStarted()
        let finished = model.saveTask
        model.disappear()
        XCTAssertFalse(model.isConfirmingSave)
        XCTAssertFalse(model.isSaving)
        XCTAssertTrue(model.confirmationPending)
        service.loadHandler = { _ in PrivacyTestSupport.settings(visibility: .following) }
        await model.load()
        gate.resume(.success(PrivacyTestSupport.settings(visibility: .private)))
        await finished?.value
        XCTAssertEqual(model.uniformVisibility, .following)
        XCTAssertFalse(model.saveSucceeded)
        XCTAssertFalse(model.showConfirmationError)
        XCTAssertTrue(model.editable)
    }

    func testSessionTransitionDuringConfirmationSuppressesOldFeedback() async {
        let service = MockPrivacyService()
        let session = MockPrivacySession()
        let gate = PrivacyAsyncGate<PrivacySettings>()
        let model = SettingsPrivacyViewModel(service: service, session: session)
        await model.load()
        service.saveHandler = { _, _, _ in .unconfirmed }
        service.loadHandler = { _ in try await gate.value() }
        model.selectAll(.private)
        await gate.waitUntilStarted()
        let finished = model.saveTask
        session.transition(to: PrivacyTestSupport.credentials(uid: 2, uuid: "test-session-b"))
        model.synchronizeSession()
        service.loadHandler = { _ in PrivacyTestSupport.settings(uid: 2, visibility: .following) }
        await model.load()
        gate.resume(.success(PrivacyTestSupport.settings(visibility: .private)))
        await finished?.value
        XCTAssertEqual(model.state.value?.uid, 2)
        XCTAssertEqual(model.uniformVisibility, .following)
        XCTAssertFalse(model.isConfirmingSave)
        XCTAssertFalse(model.confirmationPending)
        XCTAssertFalse(model.saveSucceeded)
        XCTAssertFalse(model.showConfirmationError)
        XCTAssertNil(model.message)
    }

    func testRealServiceMissingUIDHasOneReadOnlyConfirmationOutsideSaving() async throws {
        for actual: PrivacyVisibility? in [.private, .following, nil] {
            let transport = MockPrivacyTransport()
            let gate = PrivacyAsyncGate<PrivacySettingsResponseDTO>()
            let model = SettingsPrivacyViewModel(
                service: PrivacySettingsService(transport: transport),
                session: MockPrivacySession()
            )
            await model.load()
            transport.updateHandler = { _, _ in try PrivacyTestSupport.response(uid: nil, visibility: .private) }
            transport.readHandler = { _ in try await gate.value() }
            model.selectAll(.private)
            await gate.waitUntilStarted()
            XCTAssertFalse(model.isSaving)
            XCTAssertTrue(model.isConfirmingSave)
            XCTAssertEqual(transport.updates.count, 1)
            XCTAssertEqual(transport.reads.count, 2)
            XCTAssertEqual(transport.updates.first?.1, transport.reads.last)
            if let actual {
                gate.resume(.success(try PrivacyTestSupport.response(visibility: actual)))
            } else {
                gate.resume(.failure(URLError(.timedOut)))
            }
            await model.waitForSave()
            XCTAssertEqual(transport.updates.count, 1)
            XCTAssertEqual(transport.reads.count, 2)
            XCTAssertFalse(model.isConfirmingSave)
            XCTAssertEqual(model.showConfirmationError, actual == nil)
            XCTAssertEqual(model.confirmationPending, actual == nil)
            XCTAssertEqual(model.saveSucceeded, actual == .private)
            XCTAssertEqual(model.uniformVisibility, actual ?? .private)
            XCTAssertNil(model.message)
        }
    }

    func testRealServiceConfirmationUnauthorizedClearsData() async {
        let transport = MockPrivacyTransport()
        let model = SettingsPrivacyViewModel(
            service: PrivacySettingsService(transport: transport),
            session: MockPrivacySession()
        )
        await model.load()
        transport.updateHandler = { _, _ in try PrivacyTestSupport.response(uid: nil, visibility: .private) }
        transport.readHandler = { _ in
            try PrivacyTestSupport.decode([
                "success": false,
                "message": "获取用户个性设置失败，用户验证时未通过"
            ])
        }
        model.selectAll(.private)
        await model.waitForSave()
        XCTAssertTrue(model.requiresSignIn)
        XCTAssertTrue(model.values.isEmpty)
        XCTAssertFalse(model.confirmationPending)
        XCTAssertFalse(model.showConfirmationError)
        XCTAssertFalse(model.saveSucceeded)
        XCTAssertFalse(model.isSaving)
        XCTAssertFalse(model.isConfirmingSave)
        XCTAssertEqual(transport.updates.count, 1)
        XCTAssertEqual(transport.reads.count, 2)
    }

    func testCancelledBeforeSaveStartsDoesNotSendRequest() async {
        let service = MockPrivacyService()
        let model = SettingsPrivacyViewModel(service: service, session: MockPrivacySession())
        await model.load()
        model.selectAll(.private)
        model.saveTask?.cancel()
        await model.waitForSave()
        XCTAssertTrue(service.savedValues.isEmpty)
        XCTAssertFalse(model.isSaving)
        XCTAssertFalse(model.isConfirmingSave)
        XCTAssertFalse(model.showConfirmationError)
        XCTAssertNil(model.message)
    }

    func testGuestAndSessionChangeClearPresentationsAndValues() async {
        let service = MockPrivacyService()
        let session = MockPrivacySession()
        let model = SettingsPrivacyViewModel(service: service, session: session)
        await model.load()
        session.transition(to: nil)
        XCTAssertFalse(model.isCurrentSession)
        model.synchronizeSession()
        XCTAssertFalse(model.confirmReset)
        XCTAssertTrue(model.values.isEmpty)
        await model.load()
        XCTAssertEqual(service.loadCount, 1)
        XCTAssertFalse(model.isSignedIn)
    }
}
