import Foundation
@testable import KIRAKIRA

@MainActor
enum BlockingTestSupport {
    static var credentials: Credentials {
        Credentials(email: "blocking@example.invalid", token: "not-a-real-token", uid: 1, uuid: "blocking-fixture")
    }

    static func decode<T: Decodable>(_ object: [String: Any], as type: T.Type = T.self) throws -> T {
        try JSONDecoder().decode(type, from: JSONSerialization.data(withJSONObject: object))
    }

    static func entry(_ category: BlockingRuleCategory = .block, value: String = "fixture-user-uuid") -> [String: Any] {
        ["type": category.rawValue, "value": value, "createDateTime": 1_700_000_000_000]
    }

    static func list(_ entries: [[String: Any]] = [], count: Int? = 0) throws -> BlockingListResponseDTO {
        var object: [String: Any] = ["success": true, "result": entries]
        if let count { object["blocklistCount"] = count }
        return try decode(object)
    }
}
