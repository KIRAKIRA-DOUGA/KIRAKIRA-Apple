import Foundation

@MainActor
protocol BlockingSessionProviding: AnyObject {
    var sessionRevision: Int { get }
    var credentials: Credentials? { get }
}

extension AuthManager: BlockingSessionProviding {}

struct BlockingCounts: Equatable {
    let values: [BlockingRuleCategory: Int]
}

@MainActor
@Observable
final class SettingsBlockingViewModel {
    private(set) var state: LoadingState<BlockingCounts> = .idle
    private(set) var revision: Int?
    private(set) var message: String?
    private var requiresSignIn = false
    private let service: any BlockingSettingsServiceProtocol
    private let session: any BlockingSessionProviding
    private var lease: UUID?

    init(service: (any BlockingSettingsServiceProtocol)? = nil, session: (any BlockingSessionProviding)? = nil) {
        self.service = service ?? BlockingSettingsService()
        self.session = session ?? AuthManager.shared
    }

    var isCurrentSession: Bool { revision == session.sessionRevision }
    var isSignedIn: Bool { session.credentials != nil && !requiresSignIn }

    func synchronizeSession() {
        guard !isCurrentSession else { return }
        disappear()
        revision = session.sessionRevision
        state = .idle
        requiresSignIn = false
    }

    func load() async {
        synchronizeSession()
        guard let credentials = session.credentials, isSignedIn, !state.isLoading, !Task.isCancelled else { return }
        let expected = session.sessionRevision
        let operation = UUID()
        lease = operation
        state.beginLoading()
        clearMessage()
        do {
            var counts: [BlockingRuleCategory: Int] = [:]
            for category in BlockingRuleCategory.allCases {
                try Task.checkCancellation()
                guard lease == operation, revision == expected, session.sessionRevision == expected else { return }
                counts[category] = try await service.load(category: category, page: 1, pageSize: 1, credentials: credentials).total
            }
            try Task.checkCancellation()
            guard lease == operation, revision == expected, session.sessionRevision == expected else { return }
            state = .success(BlockingCounts(values: counts))
        } catch {
            guard lease == operation, revision == expected, session.sessionRevision == expected else { return }
            if error is CancellationError || Task.isCancelled {
                state.cancelLoading()
            } else if BlockingSettingsError.isUnauthorized(error) {
                requiresSignIn = true
                state = .idle
            } else if state.value != nil {
                state.cancelLoading()
                message = error.localizedDescription
            } else {
                state = .error(error.localizedDescription)
            }
        }
        if lease == operation { lease = nil }
    }

    func disappear() {
        lease = nil
        state.cancelLoading()
        clearMessage()
    }

    func clearMessage() { message = nil }
}
