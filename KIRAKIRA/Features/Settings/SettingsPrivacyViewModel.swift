import Foundation

// MARK: - Session boundary

@MainActor
protocol PrivacySessionProviding: AnyObject {
    var sessionRevision: Int { get }
    var credentials: Credentials? { get }
}

extension AuthManager: PrivacySessionProviding {}

// MARK: - Privacy settings state

@MainActor
@Observable
final class SettingsPrivacyViewModel {
    private(set) var state: LoadingState<PrivacySettings> = .idle
    private(set) var values: [PrivacyItem: PrivacyVisibility] = [:]
    private(set) var isSaving = false
    private(set) var confirmationPending = false
    private(set) var requiresSignIn = false
    private(set) var revision: Int?
    var confirmReset = false
    private(set) var message: String?
    private(set) var savedMessage = false

    private let service: any PrivacySettingsServiceProtocol
    private let session: any PrivacySessionProviding
    @ObservationIgnored private(set) var saveTask: Task<Void, Never>?

    // Identity leases protect lifecycle cancellation (including disappear/reappear in one session).
    // Requests remain strictly exclusive; these are not latest-request-wins refresh generations.
    private final class Operation {}
    private var readOperation: Operation?
    private var saveOperation: Operation?

    init(service: (any PrivacySettingsServiceProtocol)? = nil, session: (any PrivacySessionProviding)? = nil) {
        self.service = service ?? PrivacySettingsService()
        self.session = session ?? AuthManager.shared
    }

    var isCurrentSession: Bool { revision == session.sessionRevision }
    var isSignedIn: Bool { session.credentials != nil && !requiresSignIn }
    var busy: Bool { state.isLoading || isSaving }
    var editable: Bool { isCurrentSession && isSignedIn && state.value != nil && !busy && !confirmationPending }
    var canReset: Bool { editable && values.values.contains { $0 != .public } }
    var uniformVisibility: PrivacyVisibility? {
        guard values.count == PrivacyItem.allCases.count, Set(values.values).count == 1 else { return nil }
        return values.values.first
    }

    /// Synchronous reset prevents one-frame disclosure before the new account's task starts.
    func synchronizeSession() {
        guard !isCurrentSession else { return }
        saveTask?.cancel()
        saveTask = nil
        readOperation = nil
        saveOperation = nil
        revision = session.sessionRevision
        state = .idle
        values = [:]
        isSaving = false
        confirmationPending = false
        requiresSignIn = false
        confirmReset = false
        clearMessage()
    }

    func load() async {
        synchronizeSession()
        guard let credentials = session.credentials, !requiresSignIn, !busy else { return }
        let expected = session.sessionRevision
        let operation = Operation()
        readOperation = operation
        confirmReset = false
        clearMessage()
        state.beginLoading()
        defer {
            if readOperation === operation { readOperation = nil }
        }
        do {
            let settings = try await service.load(credentials: credentials)
            try Task.checkCancellation()
            guard current(expected), readOperation === operation else { return }
            state = .success(settings)
            values = settings.values
            confirmationPending = false
        } catch is CancellationError {
            guard current(expected), readOperation === operation else { return }
            state.cancelLoading()
        } catch {
            guard current(expected), readOperation === operation else { return }
            if Task.isCancelled {
                state.cancelLoading()
                return
            }
            if PrivacySettingsError.isUnauthorized(error) {
                invalidateAuthorization()
            } else if state.value != nil {
                state.cancelLoading()
                message = error.localizedDescription
            } else {
                state = .error(error.localizedDescription)
            }
        }
    }

    func setVisibility(_ visibility: PrivacyVisibility, for item: PrivacyItem) {
        var updated = values
        updated[item] = visibility
        apply(updated)
    }

    func selectAll(_ visibility: PrivacyVisibility) {
        apply(Dictionary(uniqueKeysWithValues: PrivacyItem.allCases.map { ($0, visibility) }))
    }

    func requestReset() {
        guard canReset else { return }
        confirmReset = true
    }

    func reset() {
        // SwiftUI dismisses the confirmation binding before invoking its action.
        guard canReset else { return }
        confirmReset = false
        selectAll(.public)
    }

    private func apply(_ updated: [PrivacyItem: PrivacyVisibility]) {
        guard editable, let original = state.value, let credentials = session.credentials else { return }
        confirmReset = false
        guard updated != original.values else { return }
        let expected = session.sessionRevision
        let operation = Operation()
        saveOperation = operation
        clearMessage()
        values = updated
        isSaving = true
        saveTask = Task { [weak self, service] in
            do {
                let result = try await service.save(original: original, values: updated, credentials: credentials)
                try Task.checkCancellation()
                guard let self, self.current(expected), self.saveOperation === operation else { return }
                switch result {
                case .confirmed(let settings):
                    self.state = .success(settings)
                    self.values = settings.values
                    self.savedMessage = true
                    self.message = String(localized: .privacySaved)
                case .unconfirmed:
                    self.confirmationPending = true
                }
            } catch is CancellationError {
                guard let self, self.current(expected), self.saveOperation === operation else { return }
                self.confirmationPending = true
            } catch {
                guard let self, self.current(expected), self.saveOperation === operation else { return }
                if Task.isCancelled {
                    self.confirmationPending = true
                } else if PrivacySettingsError.isUnauthorized(error) {
                    self.invalidateAuthorization()
                } else {
                    self.values = original.values
                    self.message = error.localizedDescription
                }
            }
            guard let self, self.current(expected), self.saveOperation === operation else { return }
            self.isSaving = false
            self.saveOperation = nil
            self.saveTask = nil
        }
    }

    /// No notification or retry outlives the page. A cancelled write needs a fresh read on return.
    func disappear() {
        saveTask?.cancel()
        saveTask = nil
        saveOperation = nil
        if isSaving { confirmationPending = true }
        isSaving = false
        readOperation = nil
        state.cancelLoading()
        confirmReset = false
        clearMessage()
    }

    func waitForSave() async {
        await saveTask?.value
    }

    func clearMessage() {
        message = nil
        savedMessage = false
    }

    private func current(_ expected: Int) -> Bool {
        revision == expected && session.sessionRevision == expected
    }

    private func invalidateAuthorization() {
        requiresSignIn = true
        state = .idle
        values = [:]
        confirmReset = false
        confirmationPending = false
        clearMessage()
    }
}
