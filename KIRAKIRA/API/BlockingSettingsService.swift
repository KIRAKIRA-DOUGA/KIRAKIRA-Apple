import Foundation

nonisolated enum BlockingMutationResult: Equatable, Sendable {
    case confirmed, unconfirmed
}

nonisolated enum BlockingSettingsError: Error, LocalizedError, Equatable {
    case invalidResponse, rejected, unauthorized, unsafeRegex, invalidInput

    var errorDescription: String? {
        switch self {
        case .invalidResponse: String(localized: "BLOCKING_ERROR_INVALID_RESPONSE")
        case .rejected: String(localized: "BLOCKING_ERROR_REJECTED")
        case .unauthorized: String(localized: "BLOCKING_ERROR_UNAUTHORIZED")
        case .unsafeRegex: String(localized: "BLOCKING_ERROR_UNSAFE_REGEX")
        case .invalidInput: String(localized: "BLOCKING_ERROR_INVALID_INPUT")
        }
    }

    static func isUnauthorized(_ error: Error) -> Bool {
        if case Self.unauthorized = error { return true }
        if case APIError.httpError(let status) = error { return status == 401 || status == 403 }
        if case APIError.requestFailed(let underlying) = error { return isUnauthorized(underlying) }
        return false
    }

    static func validate(success: Bool, message: String?) throws {
        guard !success else { return }
        // Rosales uses HTTP 200 and text messages, without structured authentication error codes.
        let prefixes = ["屏蔽用户失败", "隐藏用户失败", "屏蔽关键词失败", "屏蔽标签失败", "添加正则表达式失败",
                        "取消屏蔽用户失败", "显示用户失败", "取消屏蔽标签失败", "取消屏蔽关键词失败", "删除正则表达式失败", "获取黑名单失败"]
        if prefixes.contains(where: { message == "\($0)，用户 Token 不合法" || message == "\($0)，用户未登录" }) {
            throw Self.unauthorized
        }
        throw Self.rejected
    }
}

@MainActor
protocol BlockingSettingsServiceProtocol {
    func load(category: BlockingRuleCategory, page: Int, pageSize: Int, credentials: Credentials) async throws -> BlockingRulePage
    func change(category: BlockingRuleCategory, target: String, removing: Bool, credentials: Credentials) async throws -> BlockingMutationResult
    func lookupUser(uid: Int, credentials: Credentials) async throws -> BlockingUser
    func searchTags(query: String, credentials: Credentials) async throws -> [BlockingTag]
}

struct BlockingSettingsService: BlockingSettingsServiceProtocol {
    private let transport: any BlockingSettingsTransport

    init(transport: (any BlockingSettingsTransport)? = nil) {
        self.transport = transport ?? APIBlockingSettingsTransport()
    }

    func load(category: BlockingRuleCategory, page: Int, pageSize: Int, credentials: Credentials) async throws -> BlockingRulePage {
        guard page >= 0, page <= 9_007_199_254_740_991, BlockingInput.isSafeID(pageSize) else {
            throw BlockingSettingsError.invalidInput
        }
        return try await read {
            let response = try await transport.load(category: category, page: page, pageSize: pageSize, credentials: credentials)
            return try response.validated(category: category, page: page)
        }
    }

    func change(category: BlockingRuleCategory, target: String, removing: Bool, credentials: Credentials) async throws -> BlockingMutationResult {
        try Task.checkCancellation()
        if category.isUser || category == .tag {
            guard let id = BlockingInput.positiveID(target), !category.isUser || id != credentials.uid else {
                throw BlockingSettingsError.invalidInput
            }
        } else {
            // Never trim: a removal must address the exact stored rule.
            guard BlockingInput.isValidText(target) else { throw BlockingSettingsError.invalidInput }
        }
        do {
            let response = try await transport.change(category: category, target: target, removing: removing, credentials: credentials)
            try Task.checkCancellation()
            // Authentication remains distinct even when a malformed response also sets unsafeRegex.
            if !response.success {
                do { try BlockingSettingsError.validate(success: false, message: response.message) }
                catch BlockingSettingsError.unauthorized { throw BlockingSettingsError.unauthorized }
                catch {
                    if response.unsafeRegex == true { throw BlockingSettingsError.unsafeRegex }
                    throw error
                }
            }
            if response.unsafeRegex == true { throw BlockingSettingsError.unsafeRegex }
            return .confirmed
        } catch is CancellationError {
            throw CancellationError()
        } catch let error as URLError where error.code == .cancelled {
            throw CancellationError()
        } catch {
            try Task.checkCancellation()
            if BlockingSettingsError.isUnauthorized(error) { throw BlockingSettingsError.unauthorized }
            if Self.isDefiniteRejection(error) { throw error }
            // A committed write may have lost its response. Confirmation belongs to the view model.
            return .unconfirmed
        }
    }

    func lookupUser(uid: Int, credentials: Credentials) async throws -> BlockingUser {
        guard BlockingInput.isSafeID(uid) else { throw BlockingSettingsError.invalidInput }
        return try await read {
            try await transport.lookupUser(uid: uid, credentials: credentials).validated(uid: uid)
        }
    }

    func searchTags(query: String, credentials: Credentials) async throws -> [BlockingTag] {
        guard BlockingInput.isValidText(query) else { throw BlockingSettingsError.invalidInput }
        return try await read {
            let response = try await transport.searchTags(query: query, credentials: credentials)
            try BlockingSettingsError.validate(success: response.success, message: response.message)
            guard let tags = response.result, tags.allSatisfy({ BlockingInput.isSafeID($0.tagId) }) else {
                throw BlockingSettingsError.invalidResponse
            }
            var seen = Set<Int>()
            return tags.filter { seen.insert($0.tagId).inserted }
        }
    }

    private func read<T>(_ operation: () async throws -> T) async throws -> T {
        try Task.checkCancellation()
        do {
            let result = try await operation()
            try Task.checkCancellation()
            return result
        } catch is CancellationError {
            throw CancellationError()
        } catch let error as URLError where error.code == .cancelled {
            throw CancellationError()
        } catch {
            try Task.checkCancellation()
            if BlockingSettingsError.isUnauthorized(error) { throw BlockingSettingsError.unauthorized }
            throw error
        }
    }

    private static func isDefiniteRejection(_ error: Error) -> Bool {
        if let error = error as? BlockingSettingsError { return error != .invalidResponse }
        if case APIError.invalidURL = error { return true }
        if case APIError.requestFailed(let underlying) = error { return isDefiniteRejection(underlying) }
        if error is EncodingError { return true }
        if case APIError.httpError(let status) = error { return (400..<500).contains(status) && status != 408 }
        if let error = error as? URLError {
            return [.badURL, .unsupportedURL, .notConnectedToInternet, .cannotFindHost, .dnsLookupFailed].contains(error.code)
        }
        return false
    }
}

@MainActor
protocol BlockingSettingsTransport {
    func load(category: BlockingRuleCategory, page: Int, pageSize: Int, credentials: Credentials) async throws -> BlockingListResponseDTO
    func change(category: BlockingRuleCategory, target: String, removing: Bool, credentials: Credentials) async throws -> BlockingMutationResponseDTO
    func lookupUser(uid: Int, credentials: Credentials) async throws -> BlockingUserResponseDTO
    func searchTags(query: String, credentials: Credentials) async throws -> BlockingTagSearchResponseDTO
}

struct APIBlockingSettingsTransport: BlockingSettingsTransport {
    func load(category: BlockingRuleCategory, page: Int, pageSize: Int, credentials: Credentials) async throws -> BlockingListResponseDTO {
        try Task.checkCancellation()
        return try await APIService.shared.request(.getBlockingRules(category: category, page: page, pageSize: pageSize),
                                                   body: nil as String?, authenticatedWith: credentials)
    }
    func change(category: BlockingRuleCategory, target: String, removing: Bool, credentials: Credentials) async throws -> BlockingMutationResponseDTO {
        try Task.checkCancellation()
        let endpoint: Endpoint = removing ? .removeBlockingRule(category: category) : .addBlockingRule(category: category)
        return try await APIService.shared.request(endpoint, body: BlockingChangeRequestDTO(category: category, target: target),
                                                   authenticatedWith: credentials)
    }
    func lookupUser(uid: Int, credentials: Credentials) async throws -> BlockingUserResponseDTO {
        try Task.checkCancellation()
        return try await APIService.shared.request(.getUserInfo(uid: uid), body: nil as String?, authenticatedWith: credentials)
    }
    func searchTags(query: String, credentials: Credentials) async throws -> BlockingTagSearchResponseDTO {
        try Task.checkCancellation()
        return try await APIService.shared.request(.searchBlockingTags(query: query), body: nil as String?, authenticatedWith: credentials)
    }
}
