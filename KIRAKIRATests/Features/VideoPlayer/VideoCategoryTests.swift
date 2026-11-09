import XCTest
@testable import KIRAKIRA

@MainActor
final class VideoCategoryTests: XCTestCase {
    func testAllBackendCodesMapToExpectedCategories() {
        let mappings: [(String, VideoCategory)] = [
            ("anime", .anime),
            ("music", .music),
            ("otomad", .otomad),
            ("tech", .tech),
            ("design", .design),
            ("game", .game),
            ("misc", .misc),
        ]
        for (code, category) in mappings {
            XCTAssertEqual(VideoCategory(rawValue: code), category)
        }
        XCTAssertEqual(VideoCategory.allCases.map(\.rawValue), mappings.map(\.0))
    }

    func testUnknownCodesAreNotNormalizedOrMappedToOther() {
        for code in ["animation", "other", "hot", "latest", "future_category", "ANIME", "Music", " music", "music ", "", " \n\t", "**misc**"] {
            XCTAssertNil(VideoCategory(rawValue: code), code)
        }
    }

    func testSimplifiedChineseNames() {
        let expected: [(VideoCategory, String)] = [
            (.anime, "动画"),
            (.music, "音乐"),
            (.otomad, "音MAD"),
            (.tech, "科技"),
            (.design, "设计"),
            (.game, "游戏"),
            (.misc, "综合"),
        ]
        for (category, name) in expected {
            XCTAssertEqual(resolve(category.title, locale: "zh-Hans"), name, category.rawValue)
        }
    }

    func testEnglishNamesReuseExistingAppleTerminology() {
        let expected: [(VideoCategory, String)] = [
            (.anime, "Animation"),
            (.music, "Music"),
            (.otomad, "OtoMAD"),
            (.tech, "Technology"),
            (.design, "Design"),
            (.game, "Game"),
            (.misc, "Misc"),
        ]
        for (category, name) in expected {
            XCTAssertEqual(resolve(category.title, locale: "en"), name, category.rawValue)
        }
    }

    func testLocaleCanChangeWithoutChangingCategory() {
        let title = VideoCategory.misc.title
        XCTAssertEqual(resolve(title, locale: "en"), "Misc")
        XCTAssertEqual(resolve(title, locale: "zh-Hans"), "综合")
        XCTAssertEqual(resolve(title, locale: "en"), "Misc")
    }

    func testBrowseCategoryIdentityAndOtherTerminologyRemainUnchanged() {
        XCTAssertEqual(Category.allCases.map(\.rawValue), [
            "hot", "latest", "animation", "music", "otomad", "tech", "design", "game", "other",
        ])
        XCTAssertEqual(Category.animation.id, "animation")
        XCTAssertEqual(Category.other.id, "other")
        XCTAssertEqual(resolve(.categoryOther, locale: "zh-Hans"), "其他")
        XCTAssertEqual(resolve(.categoryOther, locale: "en"), "Other")
    }

    private func resolve(_ resource: LocalizedStringResource, locale: String) -> String {
        var resource = resource
        resource.locale = Locale(identifier: locale)
        return String(localized: resource)
    }
}
