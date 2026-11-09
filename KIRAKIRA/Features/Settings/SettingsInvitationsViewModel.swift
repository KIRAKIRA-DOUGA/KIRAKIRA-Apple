import Foundation

// MARK: - Session boundary

@MainActor
protocol InvitationSessionProviding: AnyObject {
    var sessionRevision: Int { get }
    var credentials: Credentials? { get }
}

extension AuthManager: InvitationSessionProviding {}

enum InvitationFilter: String, CaseIterable, Identifiable {
    case all
    case unused
    case used

    var id: String { rawValue }
}

// MARK: - Account-scoped invitations

@MainActor
@Observable
final class SettingsInvitationsViewModel {
    private(set) var state: LoadingState<[Invitation]> = .idle
    private(set) var isCreating = false
    private(set) var isConfirmingCreation = false
    var showConfirmationError = false
    private(set) var creationSucceeded = false
    private(set) var requiresSignIn = false
    private(set) var revision: Int?
    private(set) var message: String?
    private(set) var messageStyle: ToastStyle = .standard
    var filter: InvitationFilter = .all
    var confirmCreation = false

    private let service: any InvitationServiceProtocol
    private let session: any InvitationSessionProviding
    @ObservationIgnored private(set) var creationTask: Task<Void, Never>?
    @ObservationIgnored private(set) var refreshTask: Task<Void, Never>?

    // Leases invalidate late completions after leaving/re-entering the same session.
    // Reads and writes are exclusive, not a latest-request-wins refresh pipeline.
    private final class Operation {}
    private var readOperation: Operation?
    private var creationOperation: Operation?
    private var refreshOperation: Operation?
    private var creationBaseline: Set<String>?
    private var unconfirmedCodes: Set<String>?
    private var generated: [String: Invitation] = [:]

    init(service: (any InvitationServiceProtocol)? = nil, session: (any InvitationSessionProviding)? = nil) {
        self.service = service ?? InvitationService()
        self.session = session ?? AuthManager.shared
    }

    var isCurrentSession: Bool { revision == session.sessionRevision }
    var isSignedIn: Bool { session.credentials != nil && !requiresSignIn }
    var busy: Bool { state.isLoading || isCreating }
    var canCreate: Bool {
        isCurrentSession && isSignedIn && state.value != nil && !busy
            && creationTask == nil && refreshTask == nil
    }
    var confirmationPending: Bool { unconfirmedCodes != nil }
    var invitations: [Invitation] { isCurrentSession && isSignedIn ? state.value ?? [] : [] }
    var visibleInvitations: [Invitation] {
        invitations.filter { invitation in
            switch filter {
            case .all: true
            case .unused: !invitation.used
            case .used: invitation.used
            }
        }
    }
    var unusedCount: Int { invitations.filter { !$0.used }.count }
    var usedCount: Int { invitations.count - unusedCount }

    func canCopy(_ invitation: Invitation) -> Bool {
        isCurrentSession && isSignedIn && invitations.contains { $0.code == invitation.code }
    }

    func synchronizeSession() {
        guard !isCurrentSession else { return }
        cancelOperations()
        revision = session.sessionRevision
        state = .idle
        isCreating = false
        isConfirmingCreation = false
        showConfirmationError = false
        creationSucceeded = false
        requiresSignIn = false
        filter = .all
        confirmCreation = false
        creationBaseline = nil
        unconfirmedCodes = nil
        generated = [:]
        clearMessage()
    }

    func load() async {
        await read(clearFeedback: true)
    }

    /// Retry/check-state buttons own their tasks, unlike SwiftUI's structured .task/.refreshable.
    func refresh() {
        synchronizeSession()
        guard isSignedIn, !busy, refreshTask == nil, creationTask == nil else { return }
        let operation = Operation()
        refreshOperation = operation
        refreshTask = Task { [weak self] in
            guard let self, self.refreshOperation === operation, !Task.isCancelled else { return }
            await self.load()
            guard self.refreshOperation === operation else { return }
            self.refreshOperation = nil
            self.refreshTask = nil
        }
    }

    private func read(clearFeedback: Bool) async {
        synchronizeSession()
        guard let credentials = session.credentials, !requiresSignIn, !busy, !Task.isCancelled else { return }
        let expected = session.sessionRevision
        let operation = Operation()
        readOperation = operation
        isConfirmingCreation = confirmationPending
        showConfirmationError = false
        confirmCreation = false
        if clearFeedback { clearMessage() }
        state.beginLoading()
        defer {
            if readOperation === operation {
                readOperation = nil
                isConfirmingCreation = false
            }
        }
        do {
            let result = try await service.load(credentials: credentials)
            try Task.checkCancellation()
            guard current(expected), readOperation === operation else { return }
            if let before = unconfirmedCodes, result.contains(where: { !before.contains($0.code) }) {
                unconfirmedCodes = nil
                creationSucceeded = true
            }
            // An unchanged list does not prove that the POST failed. Keep the
            // retry safeguard and offer a read-only retry without replacing the list.
            showConfirmationError = confirmationPending
            // A confirmed POST must not disappear due to a temporarily stale or failed read.
            // Once the server lists it, its usage status is authoritative.
            for invitation in result { generated.removeValue(forKey: invitation.code) }
            state = .success(Invitation.sorted(result + Array(generated.values)))
        } catch is CancellationError {
            guard current(expected), readOperation === operation else { return }
            state.cancelLoading()
        } catch {
            guard current(expected), readOperation === operation else { return }
            if Task.isCancelled {
                state.cancelLoading()
            } else if InvitationError.isUnauthorized(error) {
                invalidateAuthorization()
            } else if confirmationPending {
                state.cancelLoading()
                showConfirmationError = true
            } else if state.value != nil {
                state.cancelLoading()
                showMessage(String(localized: "INVITATION_REQUEST_FAILED"), style: .error)
            } else {
                state = .error(String(localized: "INVITATION_REQUEST_FAILED"))
            }
        }
    }

    func requestCreation() {
        guard canCreate else { return }
        if confirmationPending {
            confirmCreation = true
        } else {
            create()
        }
    }

    func confirmCreate() {
        // SwiftUI clears the dialog binding before invoking the selected action.
        guard canCreate, confirmationPending else { return }
        confirmCreation = false
        create()
    }

    private func create() {
        guard canCreate, let credentials = session.credentials else { return }
        let expected = session.sessionRevision
        let operation = Operation()
        let before = Set(invitations.map(\.code))
        creationOperation = operation
        creationBaseline = before
        confirmCreation = false
        clearMessage()
        showConfirmationError = false
        creationSucceeded = false
        isCreating = true
        creationTask = Task { [weak self, service] in
            var shouldSynchronize = false
            do {
                try Task.checkCancellation()
                guard self?.current(expected) == true, self?.creationOperation === operation else { return }
                let result = try await service.create(credentials: credentials)
                try Task.checkCancellation()
                guard let self, self.current(expected), self.creationOperation === operation else { return }
                switch result {
                case .created(let invitation):
                    self.unconfirmedCodes = nil
                    self.generated[invitation.code] = invitation
                    self.state = .success(Invitation.sorted(self.invitations + [invitation]))
                    self.creationSucceeded = true
                    self.showMessage(String(localized: "INVITATION_CREATED"), style: .success)
                    shouldSynchronize = true
                case .coolingDown:
                    self.unconfirmedCodes = nil
                    self.showMessage(String(localized: "INVITATION_COOLING_DOWN"), style: .warning)
                case .unconfirmed:
                    self.unconfirmedCodes = before
                    shouldSynchronize = true
                }
            } catch is CancellationError {
                guard let self, self.current(expected), self.creationOperation === operation else { return }
                self.unconfirmedCodes = before
            } catch {
                guard let self, self.current(expected), self.creationOperation === operation else { return }
                if Task.isCancelled {
                    self.unconfirmedCodes = before
                } else if InvitationError.isUnauthorized(error) {
                    self.invalidateAuthorization()
                } else {
                    self.showMessage(String(localized: "INVITATION_REQUEST_FAILED"), style: .error)
                }
            }
            guard let self, self.current(expected), self.creationOperation === operation else { return }
            self.isCreating = false
            self.creationBaseline = nil
            // Release write-only dismissal protection before the read-only reconciliation.
            // Keep the task owned so disappearance can cancel the synchronization as well.
            if shouldSynchronize, !Task.isCancelled {
                await self.read(clearFeedback: false)
            }
            guard self.current(expected), self.creationOperation === operation else { return }
            self.creationOperation = nil
            self.creationTask = nil
        }
    }

    func disappear() {
        if isCreating { unconfirmedCodes = creationBaseline }
        cancelOperations()
        isCreating = false
        isConfirmingCreation = false
        showConfirmationError = false
        creationSucceeded = false
        creationBaseline = nil
        state.cancelLoading()
        confirmCreation = false
        clearMessage()
    }

    func clearMessage() {
        message = nil
        messageStyle = .standard
    }

    func waitForOperations() async {
        await creationTask?.value
        await refreshTask?.value
    }

    private func current(_ expected: Int) -> Bool {
        revision == expected && session.sessionRevision == expected
    }

    private func showMessage(_ text: String, style: ToastStyle) {
        messageStyle = style
        message = text
    }

    private func cancelOperations() {
        creationTask?.cancel()
        refreshTask?.cancel()
        creationTask = nil
        refreshTask = nil
        readOperation = nil
        creationOperation = nil
        refreshOperation = nil
    }

    private func invalidateAuthorization() {
        cancelOperations()
        requiresSignIn = true
        state = .idle
        isCreating = false
        isConfirmingCreation = false
        showConfirmationError = false
        creationSucceeded = false
        creationBaseline = nil
        unconfirmedCodes = nil
        generated = [:]
        confirmCreation = false
        clearMessage()
    }
}
