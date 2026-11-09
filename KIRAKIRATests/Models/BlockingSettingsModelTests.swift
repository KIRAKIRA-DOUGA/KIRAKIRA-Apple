import XCTest
@testable import KIRAKIRA

@MainActor
final class BlockingSettingsModelTests: XCTestCase {
    func testEveryCategoryUsesExpectedWireField() throws {
        let fields = ["blockUid", "hideUid", "tagId", "blockKeyword", "blockRegex"]
        for (category, field) in zip(BlockingRuleCategory.allCases, fields) {
            let numeric = category.isUser || category == .tag
            let data = try JSONEncoder().encode(BlockingChangeRequestDTO(category: category, target: numeric ? "42" : " rule "))
            let object = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])
            XCTAssertEqual(object.count, 1)
            if numeric { XCTAssertEqual(object[field] as? Int, 42) }
            else { XCTAssertEqual(object[field] as? String, " rule ") }
        }
    }

    func testMissingUserUIDDoesNotTreatUUIDAsRemovableUID() {
        let rule = BlockingRule(category: .block, value: "42", createdAt: .distantPast)
        XCTAssertNil(rule.target)
        XCTAssertEqual(rule.id, "block:42")
        XCTAssertEqual(rule.displayName, "42")
        XCTAssertEqual(BlockingRule(category: .hide, value: "uuid", createdAt: .distantPast, uid: 42).target, "42")
        XCTAssertEqual(BlockingRule(category: .tag, value: "42", createdAt: .distantPast).target, "42")
        XCTAssertNil(BlockingRule(category: .tag, value: "-1", createdAt: .distantPast).target)
        XCTAssertEqual(BlockingRule(category: .keyword, value: " exact ", createdAt: .distantPast).target, " exact ")
    }

    func testListValidatesAllCategoriesAndMillisecondsAndDeduplicates() throws {
        for category in BlockingRuleCategory.allCases {
            let entry = BlockingTestSupport.entry(category)
            let page = try BlockingTestSupport.list([entry, entry], count: 1).validated(category: category, page: 0)
            XCTAssertEqual(page.entries.count, 1)
            XCTAssertEqual(page.total, 1)
            XCTAssertEqual(page.page, 0)
            XCTAssertEqual(page.entries[0].createdAt.timeIntervalSince1970, 1_700_000_000)
        }
    }

    func testOnlyEmptyResultMayOmitCount() throws {
        XCTAssertEqual(try BlockingTestSupport.list(count: nil).validated(category: .block, page: 1).total, 0)
        XCTAssertThrowsError(try BlockingTestSupport.list([BlockingTestSupport.entry()], count: nil).validated(category: .block, page: 1))
        let missing: BlockingListResponseDTO = try BlockingTestSupport.decode(["success": true])
        XCTAssertThrowsError(try missing.validated(category: .block, page: 1))
    }

    func testListRejectsWrongCategoryInvalidRequiredFieldsAndDate() throws {
        for key in ["type", "value", "createDateTime"] {
            var entry = BlockingTestSupport.entry()
            entry.removeValue(forKey: key)
            XCTAssertThrowsError(try BlockingTestSupport.list([entry], count: 1))
        }
        for replacement in ["yesterday", -1, 253_402_300_800_000] as [Any] {
            var entry = BlockingTestSupport.entry()
            entry["createDateTime"] = replacement
            XCTAssertThrowsError(try BlockingTestSupport.list([entry], count: 1).validated(category: .block, page: 1))
        }
        XCTAssertThrowsError(try BlockingTestSupport.list([BlockingTestSupport.entry(.hide)], count: 1).validated(category: .block, page: 1))
        XCTAssertThrowsError(try BlockingTestSupport.decode(["success": true, "blocklistCount": "1", "result": []], as: BlockingListResponseDTO.self))
    }

    func testPageZeroDoesNotClaimCompleteness() throws {
        let page = try BlockingTestSupport.list([BlockingTestSupport.entry()], count: 2).validated(category: .block, page: 0)
        XCTAssertEqual(page.entries.count, 1)
        XCTAssertEqual(page.total, 2)
    }

    func testTagNamesPreserveWireShapeAndChooseLocaleAndOriginal() throws {
        let tag: BlockingTag = try BlockingTestSupport.decode([
            "tagId": 42,
            "tagNameList": [
                ["lang": "en", "tagName": [["name": "English", "isDefault": true, "isOriginalTagName": false]]],
                ["lang": "ja", "tagName": [["name": "原名", "isDefault": true, "isOriginalTagName": true]]]
            ]
        ])
        XCTAssertEqual(tag.displayName(locale: Locale(identifier: "en_US")), "English")
        XCTAssertEqual(tag.displayName(locale: Locale(identifier: "fr_FR")), "原名")
        XCTAssertEqual(tag.originalName, "原名")
        XCTAssertEqual(try JSONDecoder().decode(BlockingTag.self, from: JSONEncoder().encode(tag)), tag)
    }

    func testUTF16AndSafeIntegerValidation() {
        XCTAssertTrue(BlockingInput.isValidText(String(repeating: "😀", count: 15)))
        XCTAssertFalse(BlockingInput.isValidText(String(repeating: "😀", count: 16)))
        XCTAssertFalse(BlockingInput.isValidText("  \n"))
        for input in ["0", "-1", "+1", " 1", "1.0", "９", "9007199254740992"] {
            XCTAssertNil(BlockingInput.positiveID(input))
        }
        XCTAssertEqual(BlockingInput.positiveID("42"), 42)
    }
}
