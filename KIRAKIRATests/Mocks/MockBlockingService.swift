import Foundation
@testable import KIRAKIRA

@MainActor
final class MockBlockingService: BlockingSettingsServiceProtocol {
    struct Read: Equatable {
        let category: BlockingRuleCategory
        let page: Int
        let pageSize: Int
        let uid: Int
    }

    struct Write: Equatable {
        let category: BlockingRuleCategory
        let target: String
        let removing: Bool
        let uid: Int
    }

    var loadHandler: (BlockingRuleCategory, Int, Int, Credentials) async throws -> BlockingRulePage = { _, page, _, _ in
        BlockingRulePage(entries: [], total: 0, page: page)
    }
    var changeHandler: (BlockingRuleCategory, String, Bool, Credentials) async throws -> BlockingMutationResult = { _, _, _, _ in .confirmed }
    var lookupHandler: (Int, Credentials) async throws -> BlockingUser = { uid, _ in BlockingUser(uid: uid) }
    var searchHandler: (String, Credentials) async throws -> [BlockingTag] = { _, _ in [] }
    private(set) var reads: [Read] = []
    private(set) var writes: [Write] = []
    private(set) var lookupUIDs: [Int] = []
    private(set) var searchQueries: [String] = []

    func load(category: BlockingRuleCategory, page: Int, pageSize: Int, credentials: Credentials) async throws -> BlockingRulePage {
        reads.append(Read(category: category, page: page, pageSize: pageSize, uid: credentials.uid))
        return try await loadHandler(category, page, pageSize, credentials)
    }

    func change(category: BlockingRuleCategory, target: String, removing: Bool, credentials: Credentials) async throws -> BlockingMutationResult {
        writes.append(Write(category: category, target: target, removing: removing, uid: credentials.uid))
        return try await changeHandler(category, target, removing, credentials)
    }

    func lookupUser(uid: Int, credentials: Credentials) async throws -> BlockingUser {
        lookupUIDs.append(uid)
        return try await lookupHandler(uid, credentials)
    }

    func searchTags(query: String, credentials: Credentials) async throws -> [BlockingTag] {
        searchQueries.append(query)
        return try await searchHandler(query, credentials)
    }
}
