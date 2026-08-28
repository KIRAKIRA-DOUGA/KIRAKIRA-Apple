enum LoadingState<T: Equatable>: Equatable {
    case idle
    case loading(previous: T? = nil)
    case success(T)
    case empty
    case error(String)

    var isLoading: Bool {
        if case .loading = self { return true }
        return false
    }

    var isInitialLoading: Bool {
        guard case .loading(let previous) = self else { return false }
        return previous == nil
    }

    var isRefreshing: Bool {
        guard case .loading(let previous) = self else { return false }
        return previous != nil
    }

    var value: T? {
        switch self {
        case .success(let value):
            return value
        case .loading(let previous):
            return previous
        default:
            return nil
        }
    }

    var errorMessage: String? {
        guard case .error(let msg) = self else { return nil }
        return msg
    }

    mutating func beginLoading() {
        self = .loading(previous: value)
    }

    mutating func cancelLoading() {
        switch self {
        case .loading(let previous):
            if let previous {
                self = .success(previous)
            } else {
                self = .idle
            }
        default:
            break
        }
    }
}
