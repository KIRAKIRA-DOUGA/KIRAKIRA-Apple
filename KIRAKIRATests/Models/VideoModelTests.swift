import XCTest
@testable import KIRAKIRA

@MainActor
final class VideoModelTests: XCTestCase {
    func testDetailResponseIncludesRealTagWireFields() throws {
        let response = try decode(tags: [[
            "tagId": 42,
            "tagNameList": [[
                "lang": "zhs",
                "tagName": [["name": "示例标签", "isDefault": true]],
            ]],
        ]])
        XCTAssertEqual(response.video.videoId, 7)
        XCTAssertEqual(response.video.title, "Example video")
        XCTAssertEqual(response.video.videoPart.first?.link, "https://example.invalid/example.mpd")
        XCTAssertEqual(response.video.description, "Example description")
        XCTAssertEqual(response.video.videoCategory, "other")
        XCTAssertEqual(response.video.copyright, "original")
        XCTAssertFalse(response.isBlocked)
        XCTAssertFalse(response.isBlockedByOther)
        XCTAssertFalse(response.isHidden)
        XCTAssertEqual(response.video.videoTagList?.first?.tagId, 42)
        XCTAssertEqual(response.video.tags.first?.displayName(locale: Locale(identifier: "zh-Hans")), "示例标签")
    }

    func testMissingNullAndEmptyTagsRemainCompatible() throws {
        XCTAssertNil(try decode().video.videoTagList)
        XCTAssertNil(try decode(tags: NSNull()).video.videoTagList)
        for response in [try decode(), try decode(tags: NSNull()), try decode(tags: [])] {
            XCTAssertTrue(response.video.tags.isEmpty)
        }
    }

    func testTagsPreserveFirstOccurrenceAndOrderAndExcludeNonpositiveIDs() throws {
        let response = try decode(tags: [
            ["tagId": 9, "tagNameList": [["lang": "en", "tagName": [["name": "First"]]]]],
            ["tagId": 0],
            ["tagId": 2],
            ["tagId": 9, "tagNameList": [["lang": "en", "tagName": [["name": "Duplicate"]]]]],
            ["tagId": -1],
            ["tagId": 5],
        ])
        XCTAssertEqual(response.video.videoTagList?.count, 6)
        XCTAssertEqual(response.video.tags.map(\.id), [9, 2, 5])
        XCTAssertEqual(response.video.tags.first?.displayName(locale: Locale(identifier: "en")), "First")
    }

    func testMalformedTagsFailDetailDecoding() {
        for tags: Any in ["not an array", [42], [["tagId": "42"]], [["tagId": 42, "tagNameList": "invalid"]]] {
            XCTAssertThrowsError(try decode(tags: tags))
        }
    }

    func testExistingVideoIdentityEqualityIsUnchanged() throws {
        XCTAssertEqual(try decode().video, try decode(tags: [["tagId": 42]]).video)
    }

    private func decode(tags: Any? = nil) throws -> GetVideoByKvidResponseDTO {
        var video: [String: Any] = [
            "videoId": 7,
            "videoPart": [["id": 1, "videoPartTitle": "Example part", "link": "https://example.invalid/example.mpd"]],
            "title": "Example video",
            "image": "example-image",
            "watchedCount": 12,
            "description": "Example description",
            "videoCategory": "other",
            "copyright": "original",
        ]
        video["videoTagList"] = tags
        let data = try JSONSerialization.data(withJSONObject: [
            "video": video,
            "isBlocked": false,
            "isBlockedByOther": false,
            "isHidden": false,
        ])
        return try JSONDecoder().decode(GetVideoByKvidResponseDTO.self, from: data)
    }
}
