import Foundation

/// Ignores cancellation intentionally, allowing tests to deliver a stale server response.
@MainActor
final class BlockingAsyncGate<Value> {
    private var continuation: CheckedContinuation<Value, Error>?
    private var startWaiters: [CheckedContinuation<Void, Never>] = []
    private var started = false

    func value() async throws -> Value {
        try await withCheckedThrowingContinuation { continuation in
            precondition(!started, "Use a separate gate for each request")
            started = true
            self.continuation = continuation
            let waiters = startWaiters
            startWaiters = []
            waiters.forEach { $0.resume() }
        }
    }

    func waitUntilStarted() async {
        if started { return }
        await withCheckedContinuation { startWaiters.append($0) }
    }

    func resume(_ result: Result<Value, Error>) {
        precondition(continuation != nil, "Wait for the request to start before resuming")
        let pending = continuation
        continuation = nil
        pending?.resume(with: result)
    }
}
