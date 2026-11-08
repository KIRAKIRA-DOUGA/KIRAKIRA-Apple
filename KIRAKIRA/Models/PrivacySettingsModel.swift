import Foundation

nonisolated enum PrivacyItem: String, CaseIterable, Identifiable, Sendable {
    case birthday = "privary.birthday"
    case age = "privary.age"
    case following = "privary.follow"
    case followers = "privary.fans"
    case favorites = "privary.favorites"

    var id: String { rawValue }
}

nonisolated enum PrivacyVisibility: String, Codable, CaseIterable, Identifiable, Sendable {
    case `public`
    case following
    case `private`

    var id: String { rawValue }
}

nonisolated struct PrivacySettings: Equatable, Sendable {
    struct Entry: Codable, Equatable, Sendable {
        let id: String
        let visibility: PrivacyVisibility

        enum CodingKeys: String, CodingKey {
            case id = "privaryId"
            case visibility = "visibilitiesType"
        }
    }

    struct LinkedAccount: Codable, Equatable, Sendable {
        let platformID: String
        let visibility: PrivacyVisibility

        enum CodingKeys: String, CodingKey {
            case platformID = "platformId"
            case visibility = "visibilitiesType"
        }
    }

    let uid: Int
    let entries: [Entry]
    let linkedAccounts: [LinkedAccount]

    var values: [PrivacyItem: PrivacyVisibility] {
        Dictionary(uniqueKeysWithValues: PrivacyItem.allCases.map { item in
            (item, entries.first { $0.id == item.rawValue }?.visibility ?? .public)
        })
    }
}

// MARK: - Read and update responses

nonisolated struct PrivacySettingsResponseDTO: Decodable, Sendable {
    struct Settings: Decodable, Sendable {
        let uid: Int?
        let entries: [PrivacySettings.Entry]
        let linkedAccounts: [PrivacySettings.LinkedAccount]

        enum CodingKeys: String, CodingKey {
            case uid
            case entries = "userPrivaryVisibilitiesSetting"
            case linkedAccounts = "userLinkedAccountsVisibilitiesSetting"
        }

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            uid = try container.decodeIfPresent(Int.self, forKey: .uid)
            entries = try container.decodeIfPresent([PrivacySettings.Entry].self, forKey: .entries) ?? []
            linkedAccounts = try container.decodeIfPresent([PrivacySettings.LinkedAccount].self, forKey: .linkedAccounts) ?? []
        }

        func validated(expectedUID: Int) throws -> PrivacySettings {
            guard let uid, uid > 0, uid == expectedUID,
                entries.allSatisfy({ !$0.id.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }),
                linkedAccounts.allSatisfy({ !$0.platformID.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }),
                Set(entries.map(\.id)).count == entries.count,
                Set(linkedAccounts.map(\.platformID)).count == linkedAccounts.count
            else { throw PrivacySettingsError.invalidResponse }
            return PrivacySettings(uid: uid, entries: entries, linkedAccounts: linkedAccounts)
        }
    }

    let success: Bool
    let userSettings: Settings?
    let message: String?

    func validateSuccess() throws {
        guard !success else { return }
        // Rosales returns HTTP 200 for these authentication failures and has no structured error code.
        // Match only its known messages so unrelated business failures remain retryable rejections.
        switch message {
        case "获取用户个性设置失败，用户验证时未通过", "更新或创建用户设置失败，非法用户！":
            throw PrivacySettingsError.unauthorized
        default:
            throw PrivacySettingsError.rejected
        }
    }

    func validated(expectedUID: Int) throws -> PrivacySettings {
        try validateSuccess()
        guard let userSettings else { throw PrivacySettingsError.invalidResponse }
        return try userSettings.validated(expectedUID: expectedUID)
    }
}

// MARK: - Update request

nonisolated struct PrivacySettingsUpdateDTO: Encodable, Equatable, Sendable {
    let entries: [PrivacySettings.Entry]
    let linkedAccounts: [PrivacySettings.LinkedAccount]

    enum CodingKeys: String, CodingKey {
        case entries = "userPrivaryVisibilitiesSetting"
        case linkedAccounts = "userLinkedAccountsVisibilitiesSetting"
    }

    init(original: PrivacySettings, values: [PrivacyItem: PrivacyVisibility]) throws {
        guard Set(values.keys) == Set(PrivacyItem.allCases) else {
            throw PrivacySettingsError.invalidResponse
        }
        entries = original.entries.filter { PrivacyItem(rawValue: $0.id) == nil }
            + PrivacyItem.allCases.compactMap { item in
                values[item].map { PrivacySettings.Entry(id: item.rawValue, visibility: $0) }
            }
        linkedAccounts = original.linkedAccounts
    }
}
