import Foundation
@testable import KIRAKIRA

@MainActor
final class MockBlockingTransport: BlockingSettingsTransport {
    struct Write: Equatable {
        let category: BlockingRuleCategory
        let target: String
        let removing: Bool
    }
    var listResponse: BlockingListResponseDTO?
    var mutationResponse: BlockingMutationResponseDTO?
    var userResponse: BlockingUserResponseDTO?
    var tagResponse: BlockingTagSearchResponseDTO?
    var error: Error?
    private(set) var loads = 0
    private(set) var writes: [Write] = []
    private(set) var lookups = 0
    private(set) var searches = 0
    private(set) var lastPage: Int?
    private(set) var lastPageSize: Int?

    func load(category: BlockingRuleCategory, page: Int, pageSize: Int, credentials: Credentials) async throws -> BlockingListResponseDTO {
        loads += 1
        lastPage = page
        lastPageSize = pageSize
        if let error { throw error }
        guard let listResponse else { throw BlockingSettingsError.invalidResponse }
        return listResponse
    }
    func change(category: BlockingRuleCategory, target: String, removing: Bool, credentials: Credentials) async throws -> BlockingMutationResponseDTO {
        writes.append(Write(category: category, target: target, removing: removing))
        if let error { throw error }
        guard let mutationResponse else { throw BlockingSettingsError.invalidResponse }
        return mutationResponse
    }
    func lookupUser(uid: Int, credentials: Credentials) async throws -> BlockingUserResponseDTO {
        lookups += 1
        if let error { throw error }
        guard let userResponse else { throw BlockingSettingsError.invalidResponse }
        return userResponse
    }
    func searchTags(query: String, credentials: Credentials) async throws -> BlockingTagSearchResponseDTO {
        searches += 1
        if let error { throw error }
        guard let tagResponse else { throw BlockingSettingsError.invalidResponse }
        return tagResponse
    }
}
