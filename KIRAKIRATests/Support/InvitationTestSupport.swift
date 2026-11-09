import Foundation
@testable import KIRAKIRA

@MainActor
enum InvitationTestSupport {
    static func credentials(uid: Int = 1, uuid: String = "invitation-fixture-session") -> Credentials {
        Credentials(email: "invitation@example.invalid", token: "invitation-fixture-not-a-token", uid: uid, uuid: uuid)
    }

    static func invitation(code: String = "fixture-code-a", seconds: Double = 1_700_000_000, used: Bool = false) -> Invitation {
        Invitation(code: code, createdAt: Date(timeIntervalSince1970: seconds), used: used)
    }

    static func payload(uid: Int = 1, code: String = "fixture-code-a", milliseconds: Double = 1_700_000_000_000, assignee: Int? = nil) -> [String: Any] {
        var object: [String: Any] = [
            "creatorUid": uid,
            "invitationCode": code,
            "generationDateTime": milliseconds,
        ]
        if let assignee { object["assignee"] = assignee }
        return object
    }

    static func list(_ payloads: [[String: Any]]? = nil) throws -> InvitationListResponseDTO {
        try decode(["success": true, "invitationCodeResult": payloads ?? [payload()]])
    }

    static func creation() throws -> InvitationCreationResponseDTO {
        try decode(["success": true, "isCoolingDown": false, "invitationCodeResult": payload()])
    }

    static func decode<T: Decodable>(_ object: [String: Any]) throws -> T {
        try JSONDecoder().decode(T.self, from: JSONSerialization.data(withJSONObject: object))
    }
}
