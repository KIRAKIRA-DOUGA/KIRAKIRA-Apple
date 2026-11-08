import Foundation
@testable import KIRAKIRA

@MainActor
final class MockPrivacyService: PrivacySettingsServiceProtocol {
    var loadHandler: (Credentials) async throws -> PrivacySettings = { credentials in
        PrivacyTestSupport.settings(uid: credentials.uid)
    }
    var saveHandler: (PrivacySettings, [PrivacyItem: PrivacyVisibility], Credentials) async throws -> PrivacySaveResult = { original, values, _ in
        .confirmed(PrivacySettings(
            uid: original.uid,
            entries: PrivacyItem.allCases.compactMap { item in
                values[item].map { .init(id: item.rawValue, visibility: $0) }
            },
            linkedAccounts: original.linkedAccounts
        ))
    }
    private(set) var loadCount = 0
    private(set) var savedValues: [[PrivacyItem: PrivacyVisibility]] = []

    func load(credentials: Credentials) async throws -> PrivacySettings {
        loadCount += 1
        return try await loadHandler(credentials)
    }

    func save(original: PrivacySettings, values: [PrivacyItem: PrivacyVisibility], credentials: Credentials) async throws -> PrivacySaveResult {
        savedValues.append(values)
        return try await saveHandler(original, values, credentials)
    }
}
