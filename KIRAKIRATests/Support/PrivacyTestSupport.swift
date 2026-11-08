import Foundation
@testable import KIRAKIRA

@MainActor
enum PrivacyTestSupport {
    static func credentials(uid: Int = 1, uuid: String = "test-session-a") -> Credentials {
        Credentials(email: "fixture@example.invalid", token: "fixture-not-a-token", uid: uid, uuid: uuid)
    }

    static func values(_ visibility: PrivacyVisibility = .public) -> [PrivacyItem: PrivacyVisibility] {
        Dictionary(uniqueKeysWithValues: PrivacyItem.allCases.map { ($0, visibility) })
    }

    static func settings(uid: Int = 1, visibility: PrivacyVisibility = .public) -> PrivacySettings {
        PrivacySettings(
            uid: uid,
            entries: PrivacyItem.allCases.map { .init(id: $0.rawValue, visibility: visibility) },
            linkedAccounts: []
        )
    }

    static func response(uid: Int? = 1, visibility: PrivacyVisibility = .public) throws -> PrivacySettingsResponseDTO {
        var settings: [String: Any] = [
            "userPrivaryVisibilitiesSetting": PrivacyItem.allCases.map {
                ["privaryId": $0.rawValue, "visibilitiesType": visibility.rawValue]
            },
            "userLinkedAccountsVisibilitiesSetting": []
        ]
        if let uid { settings["uid"] = uid }
        return try decode(["success": true, "userSettings": settings])
    }

    static func decode(_ object: [String: Any]) throws -> PrivacySettingsResponseDTO {
        try JSONDecoder().decode(PrivacySettingsResponseDTO.self, from: JSONSerialization.data(withJSONObject: object))
    }
}
