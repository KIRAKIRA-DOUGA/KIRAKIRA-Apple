import Foundation

nonisolated enum BlockingRuleCategory: String, CaseIterable, Identifiable, Codable, Sendable {
    case block, hide, tag, keyword, regex

    var id: String { rawValue }
    var isUser: Bool { self == .block || self == .hide }
}

nonisolated struct BlockingRule: Identifiable, Equatable, Sendable {
    let category: BlockingRuleCategory
    let value: String
    let createdAt: Date
    let uid: Int?
    let username: String?
    let userNickname: String?
    let avatar: String?
    let tag: BlockingTag?

    var id: String { "\(category.rawValue):\(value)" }
    var target: String? {
        if category.isUser { return uid.flatMap { BlockingInput.isSafeID($0) ? String($0) : nil } }
        if category == .tag {
            if let tag, BlockingInput.isSafeID(tag.tagId) { return String(tag.tagId) }
            return BlockingInput.positiveID(value).map(String.init)
        }
        return value
    }
    var displayName: String {
        if let userNickname, !userNickname.isEmpty { return userNickname }
        if let username, !username.isEmpty { return username }
        if let uid { return "UID \(uid)" }
        return value
    }

    init(category: BlockingRuleCategory, value: String, createdAt: Date, uid: Int? = nil,
         username: String? = nil, userNickname: String? = nil, avatar: String? = nil, tag: BlockingTag? = nil) {
        self.category = category
        self.value = value
        self.createdAt = createdAt
        self.uid = uid
        self.username = username
        self.userNickname = userNickname
        self.avatar = avatar
        self.tag = tag
    }
}

nonisolated struct BlockingRulePage: Equatable, Sendable {
    let entries: [BlockingRule]
    let total: Int
    let page: Int
}

nonisolated struct BlockingTag: Identifiable, Equatable, Sendable, Codable {
    struct LocalizedNames: Equatable, Sendable, Codable {
        let lang: String
        let tagName: [Name]
    }
    struct Name: Equatable, Sendable, Codable {
        let name: String
        let isDefault: Bool
        let isOriginalTagName: Bool
    }

    let tagId: Int
    let tagNameList: [LocalizedNames]
    var id: Int { tagId }
    var originalName: String? {
        tagNameList.flatMap(\.tagName).first { $0.isOriginalTagName && !$0.name.isEmpty }?.name
    }

    func displayName(locale: Locale) -> String {
        let identifier = locale.identifier.replacingOccurrences(of: "_", with: "-").lowercased()
        let language = locale.language.languageCode?.identifier.lowercased()
        let exact = tagNameList.first { $0.lang.replacingOccurrences(of: "_", with: "-").lowercased() == identifier }
        let matching = exact ?? tagNameList.first {
            $0.lang.lowercased().split(separator: "-").first.map(String.init) == language
        }
        let names = matching?.tagName.filter { !$0.name.isEmpty } ?? []
        return names.first(where: \.isDefault)?.name ?? names.first?.name ?? originalName
            ?? tagNameList.flatMap(\.tagName).first { !$0.name.isEmpty }?.name ?? String(tagId)
    }
}

nonisolated struct BlockingUser: Equatable, Sendable {
    let uid: Int
    let username: String?
    let userNickname: String?
    let avatar: String?

    init(uid: Int, username: String? = nil, userNickname: String? = nil, avatar: String? = nil) {
        self.uid = uid
        self.username = username
        self.userNickname = userNickname
        self.avatar = avatar
    }

    var displayName: String {
        if let userNickname, !userNickname.isEmpty { return userNickname }
        if let username, !username.isEmpty { return username }
        return "UID \(uid)"
    }
}

// IDs cross a JavaScript backend boundary; do not silently round oversized integers.
nonisolated enum BlockingInput {
    static func isSafeID(_ value: Int) -> Bool { value > 0 && value <= 9_007_199_254_740_991 }
    static func positiveID(_ value: String) -> Int? {
        guard !value.isEmpty, value.utf8.allSatisfy({ (48...57).contains($0) }),
              let number = Int(value), isSafeID(number) else { return nil }
        return number
    }
    static func isValidText(_ value: String) -> Bool {
        (1...30).contains(value.utf16.count) && !value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}

nonisolated struct BlockingListResponseDTO: Decodable, Sendable {
    struct Entry: Decodable, Sendable {
        let type: BlockingRuleCategory
        let value: String
        let createDateTime: Double
        let uid: Int?
        let username: String?
        let userNickname: String?
        let avatar: String?
        let tag: BlockingTag?
    }
    let success: Bool
    let message: String?
    let blocklistCount: Int?
    let result: [Entry]?

    func validated(category: BlockingRuleCategory, page: Int) throws -> BlockingRulePage {
        try BlockingSettingsError.validate(success: success, message: message)
        guard let result, let count = blocklistCount ?? (result.isEmpty ? 0 : nil), count >= 0 else {
            throw BlockingSettingsError.invalidResponse
        }
        var seen = Set<String>()
        let entries = try result.compactMap { entry -> BlockingRule? in
            guard entry.type == category, !entry.value.isEmpty,
                  entry.createDateTime.isFinite, entry.createDateTime >= 0,
                  entry.createDateTime <= 253_402_300_799_999,
                  entry.uid.map(BlockingInput.isSafeID) ?? true,
                  entry.tag.map({ BlockingInput.isSafeID($0.tagId) }) ?? true else {
                throw BlockingSettingsError.invalidResponse
            }
            let rule = BlockingRule(category: category, value: entry.value,
                                    createdAt: Date(timeIntervalSince1970: entry.createDateTime / 1000),
                                    uid: entry.uid, username: entry.username, userNickname: entry.userNickname,
                                    avatar: entry.avatar, tag: entry.tag)
            return seen.insert(rule.id).inserted ? rule : nil
        }
        guard count >= entries.count else { throw BlockingSettingsError.invalidResponse }
        return BlockingRulePage(entries: entries, total: count, page: page)
    }
}

nonisolated struct BlockingMutationResponseDTO: Decodable, Sendable {
    let success: Bool
    let message: String?
    let unsafeRegex: Bool?
}

nonisolated struct BlockingUserResponseDTO: Decodable, Sendable {
    struct Profile: Decodable, Sendable {
        let uid: Int?
        let username: String?
        let userNickname: String?
        let avatar: String?
    }
    let success: Bool
    let message: String?
    let result: Profile?
    let isBlocked: Bool?

    func validated(uid: Int) throws -> BlockingUser {
        try BlockingSettingsError.validate(success: success, message: message)
        let hasProfileIdentity = result.map {
            $0.uid == uid || !($0.username ?? "").isEmpty || !($0.userNickname ?? "").isEmpty
        } ?? false
        guard hasProfileIdentity || isBlocked == true else { throw BlockingSettingsError.invalidResponse }
        if let responseUID = result?.uid, responseUID != uid { throw BlockingSettingsError.invalidResponse }
        return BlockingUser(uid: uid, username: result?.username, userNickname: result?.userNickname, avatar: result?.avatar)
    }
}

nonisolated struct BlockingTagSearchResponseDTO: Decodable, Sendable {
    let success: Bool
    let message: String?
    let result: [BlockingTag]?
}

nonisolated struct BlockingChangeRequestDTO: Encodable, Equatable, Sendable {
    let category: BlockingRuleCategory
    let target: String

    enum CodingKeys: String, CodingKey { case blockUid, hideUid, tagId, blockKeyword, blockRegex }
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch category {
        case .block, .hide, .tag:
            guard let id = BlockingInput.positiveID(target) else { throw BlockingSettingsError.invalidInput }
            let key: CodingKeys = category == .block ? .blockUid : (category == .hide ? .hideUid : .tagId)
            try container.encode(id, forKey: key)
        case .keyword: try container.encode(target, forKey: .blockKeyword)
        case .regex: try container.encode(target, forKey: .blockRegex)
        }
    }
}
