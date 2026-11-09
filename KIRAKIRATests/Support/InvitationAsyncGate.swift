import Foundation

/// Allows deterministic cancellation and late-result tests without sleeps or network requests.
@MainActor
final class InvitationAsyncGate<Value> {
    private var continuation: CheckedContinuation<Value, Error>?
    private var startWaiter: CheckedContinuation<Void, Never>?

    func value() async throws -> Value {
        try await withCheckedThrowingContinuation { continuation in
            self.continuation = continuation
            startWaiter?.resume()
            startWaiter = nil
        }
    }

    func waitUntilStarted() async {
        if continuation != nil { return }
        await withCheckedContinuation { startWaiter = $0 }
    }

    func resume(_ result: Result<Value, Error>) {
        let pending = continuation
        continuation = nil
        pending?.resume(with: result)
    }
}
