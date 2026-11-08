import XCTest
@testable import KIRAKIRA

@MainActor
final class PrivacySettingsTests: XCTestCase {
    func testWireIDsAndVisibilityValues() async {
        XCTAssertEqual(PrivacyItem.allCases.map(\.rawValue), ["privary.birthday", "privary.age", "privary.follow", "privary.fans", "privary.favorites"])
        XCTAssertEqual(PrivacyVisibility.allCases.map(\.rawValue), ["public", "following", "private"])
    }

    func testMissingArraysDefaultToPublic() async throws {
        let response = try PrivacyTestSupport.decode(["success": true, "userSettings": ["uid": 1]])
        let settings = try response.validated(expectedUID: 1)
        XCTAssertEqual(settings.values, PrivacyTestSupport.values())
    }

    func testRequiresMatchingPositiveUIDAndSettings() async throws {
        for object: [String: Any] in [
            ["success": true],
            ["success": true, "userSettings": [:]],
            ["success": true, "userSettings": ["uid": 0]],
            ["success": true, "userSettings": ["uid": 2]],
            ["success": false, "userSettings": ["uid": 1]]
        ] {
            let response = try PrivacyTestSupport.decode(object)
            XCTAssertThrowsError(try response.validated(expectedUID: 1))
        }
    }

    func testRejectsInvalidVisibility() async {
        XCTAssertThrowsError(try PrivacyTestSupport.decode([
            "success": true,
            "userSettings": ["uid": 1, "userPrivaryVisibilitiesSetting": [["privaryId": "privary.age", "visibilitiesType": "followers"]]]
        ]))
    }

    func testRejectsDuplicateAndBlankIDs() async throws {
        for entries in [
            [["privaryId": "privary.age", "visibilitiesType": "public"], ["privaryId": "privary.age", "visibilitiesType": "private"]],
            [["privaryId": " ", "visibilitiesType": "public"]]
        ] {
            let response = try PrivacyTestSupport.decode(["success": true, "userSettings": ["uid": 1, "userPrivaryVisibilitiesSetting": entries]])
            XCTAssertThrowsError(try response.validated(expectedUID: 1))
        }
        let response = try PrivacyTestSupport.decode([
            "success": true,
            "userSettings": ["uid": 1, "userLinkedAccountsVisibilitiesSetting": [
                ["platformId": "platform.github", "visibilitiesType": "public"],
                ["platformId": "platform.github", "visibilitiesType": "private"]
            ]]
        ])
        XCTAssertThrowsError(try response.validated(expectedUID: 1))
    }

    func testUpdatePreservesUnknownAndLinkedEntriesAndOnlyEncodesPrivacy() async throws {
        let unknown = PrivacySettings.Entry(id: "privary.future", visibility: .following)
        let linked = PrivacySettings.LinkedAccount(platformID: "platform.github", visibility: .private)
        let original = PrivacySettings(uid: 1, entries: [unknown], linkedAccounts: [linked])
        let body = try PrivacySettingsUpdateDTO(original: original, values: PrivacyTestSupport.values(.private))
        XCTAssertEqual(body.entries.first, unknown)
        XCTAssertEqual(body.entries.count, 6)
        XCTAssertEqual(body.linkedAccounts, [linked])
        let json = try XCTUnwrap(JSONSerialization.jsonObject(with: JSONEncoder().encode(body)) as? [String: Any])
        XCTAssertEqual(Set(json.keys), ["userPrivaryVisibilitiesSetting", "userLinkedAccountsVisibilitiesSetting"])
        let entries = try XCTUnwrap(json["userPrivaryVisibilitiesSetting"] as? [[String: String]])
        XCTAssertEqual(entries.last, ["privaryId": "privary.favorites", "visibilitiesType": "private"])
        XCTAssertThrowsError(try PrivacySettingsUpdateDTO(original: original, values: [:]))
    }
}
