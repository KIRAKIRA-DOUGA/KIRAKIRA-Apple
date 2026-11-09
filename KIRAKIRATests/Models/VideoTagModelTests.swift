import XCTest
@testable import KIRAKIRA

@MainActor
final class VideoTagModelTests: XCTestCase {
    func testWireFieldsAndCodableRoundTrip() throws {
        let tag = try decode(#"{"tagId":42,"tagNameList":[{"lang":"en","tagName":[{"name":"Example","isDefault":true,"isOriginalTagName":true}]}]}"#)
        XCTAssertEqual(tag.id, 42)
        XCTAssertEqual(tag.tagNameList.first?.lang, "en")
        XCTAssertEqual(tag.tagNameList.first?.tagName.first, .init(name: "Example", isDefault: true, isOriginalTagName: true))
        XCTAssertEqual(try JSONDecoder().decode(VideoTag.self, from: JSONEncoder().encode(tag)), tag)
    }

    func testMissingAndNullArraysAndFlagsUseDefaults() throws {
        for json in [#"{"tagId":42}"#, #"{"tagId":42,"tagNameList":null}"#, #"{"tagId":42,"tagNameList":[]}"#] {
            XCTAssertEqual(try decode(json).tagNameList, [])
        }
        for field in ["", ",\"tagName\":null", ",\"tagName\":[]"] {
            let tag = try decode("{\"tagId\":42,\"tagNameList\":[{\"lang\":\"en\"\(field)}]}")
            XCTAssertEqual(tag.tagNameList.first?.tagName, [])
        }
        for fields in ["", ",\"isDefault\":null,\"isOriginalTagName\":null"] {
            let tag = try decode("{\"tagId\":42,\"tagNameList\":[{\"lang\":\"en\",\"tagName\":[{\"name\":\"Example\"\(fields)}]}]}")
            XCTAssertEqual(tag.tagNameList.first?.tagName.first, .init(name: "Example"))
        }
    }

    func testChineseLocalesUseAndroidWireLanguages() {
        let tag = makeTag([
            .init(lang: "en", tagName: [.init(name: "English")]),
            .init(lang: "zhs", tagName: [.init(name: "简体")]),
            .init(lang: "zht", tagName: [.init(name: "繁體")]),
        ])
        for identifier in ["zh", "zh-Hans", "zh-CN", "zh-SG", "zh_Hans_CN"] {
            XCTAssertEqual(tag.displayName(locale: Locale(identifier: identifier)), "简体", identifier)
        }
        for identifier in ["zh-Hant", "zh-TW", "zh-HK", "zh-MO", "zh-Hans-TW"] {
            XCTAssertEqual(tag.displayName(locale: Locale(identifier: identifier)), "繁體", identifier)
        }
    }

    func testLanguageCodePrecedesExactLocaleAndExactPrecedesOther() {
        let groups: [VideoTag.LocalizedNames] = [
            .init(lang: "other", tagName: [.init(name: "Other")]),
            .init(lang: "EN_us", tagName: [.init(name: "US English")]),
            .init(lang: "en", tagName: [.init(name: "English")]),
        ]
        let locale = Locale(identifier: "en-US")
        XCTAssertEqual(makeTag(groups).displayName(locale: locale), "English")
        XCTAssertEqual(makeTag(Array(groups.prefix(2))).displayName(locale: locale), "US English")
    }

    func testChineseAliasesDoNotConfuseScripts() {
        let groups: [VideoTag.LocalizedNames] = [
            .init(lang: "other", tagName: [.init(name: "Other")]),
            .init(lang: "zh-Hant", tagName: [.init(name: "繁體別名")]),
            .init(lang: "zh-Hans", tagName: [.init(name: "简体别名")]),
        ]
        XCTAssertEqual(makeTag(groups).displayName(locale: Locale(identifier: "zh-CN")), "简体别名")
        XCTAssertEqual(makeTag(groups).displayName(locale: Locale(identifier: "zh-TW")), "繁體別名")
        XCTAssertEqual(makeTag(Array(groups.prefix(2))).displayName(locale: Locale(identifier: "zh-CN")), "Other")
        let wire = groups + [.init(lang: "zhs", tagName: [.init(name: "Wire")])]
        XCTAssertEqual(makeTag(wire).displayName(locale: Locale(identifier: "zh-Hans")), "Wire")
    }

    func testFallbackUsesOtherThenFirstGroupNotOriginalName() {
        let groups: [VideoTag.LocalizedNames] = [
            .init(lang: "en", tagName: [.init(name: "First")]),
            .init(lang: "ja", tagName: [.init(name: "Original", isOriginalTagName: true)]),
            .init(lang: "other", tagName: [.init(name: "Other")]),
        ]
        let locale = Locale(identifier: "fr-FR")
        XCTAssertEqual(makeTag(groups).displayName(locale: locale), "Other")
        XCTAssertEqual(makeTag(Array(groups.prefix(2))).displayName(locale: locale), "First")
    }

    func testNonblankDefaultThenFirstNonblankNamePreservesOriginalText() {
        let names: [VideoTag.Name] = [
            .init(name: " \n", isDefault: true),
            .init(name: "First"),
            .init(name: " Default ", isDefault: true),
            .init(name: "Another default", isDefault: true),
        ]
        let locale = Locale(identifier: "en")
        XCTAssertEqual(makeTag([.init(lang: "en", tagName: names)]).displayName(locale: locale), " Default ")
        XCTAssertEqual(makeTag([.init(lang: "en", tagName: Array(names.prefix(2)))]).displayName(locale: locale), "First")
    }

    func testEmptySelectedGroupDoesNotFallThroughAndIDIsNotGrouped() {
        let locale = Locale(identifier: "en-US")
        for names: [VideoTag.Name] in [[], [.init(name: " \n\t", isDefault: true)]] {
            let tag = VideoTag(tagId: 12345, tagNameList: [
                .init(lang: "en", tagName: names),
                .init(lang: "other", tagName: [.init(name: "Not selected")]),
            ])
            XCTAssertEqual(tag.displayName(locale: locale), "#12345")
        }
        XCTAssertEqual(VideoTag(tagId: 12345).displayName(locale: locale), "#12345")
    }

    func testDuplicateLanguageGroupsUseFirstMatch() {
        let tag = makeTag([
            .init(lang: "en", tagName: [.init(name: "First")]),
            .init(lang: "en", tagName: [.init(name: "Second")]),
        ])
        XCTAssertEqual(tag.displayName(locale: Locale(identifier: "en")), "First")
    }

    func testMalformedRequiredFieldsAndWrongTypesThrow() {
        for json in [
            #"{}"#,
            #"{"tagId":"42"}"#,
            #"{"tagId":42,"tagNameList":{}}"#,
            #"{"tagId":42,"tagNameList":[{"lang":7}]}"#,
            #"{"tagId":42,"tagNameList":[{"lang":"en","tagName":{}}]}"#,
            #"{"tagId":42,"tagNameList":[{"lang":"en","tagName":[{}]}]}"#,
            #"{"tagId":42,"tagNameList":[{"lang":"en","tagName":[{"name":5}]}]}"#,
            #"{"tagId":42,"tagNameList":[{"lang":"en","tagName":[{"name":"Name","isDefault":"true"}]}]}"#,
            #"{"tagId":42,"tagNameList":[{"lang":"en","tagName":[{"name":"Name","isOriginalTagName":1}]}]}"#,
        ] {
            XCTAssertThrowsError(try decode(json), json)
        }
    }

    private func decode(_ json: String) throws -> VideoTag {
        try JSONDecoder().decode(VideoTag.self, from: Data(json.utf8))
    }

    private func makeTag(_ groups: [VideoTag.LocalizedNames]) -> VideoTag {
        VideoTag(tagId: 42, tagNameList: groups)
    }
}
