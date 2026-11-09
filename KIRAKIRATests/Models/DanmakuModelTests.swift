import XCTest
@testable import KIRAKIRA

@MainActor
final class DanmakuModelTests: XCTestCase {
    func testMissingNullAndEmptyDanmakuDecodeAsEmpty() throws {
        for json in [
            #"{"success":true}"#,
            #"{"success":true,"danmaku":null}"#,
            #"{"success":true,"danmaku":[]}"#,
        ] {
            XCTAssertTrue(try decode(json).danmaku.isEmpty)
        }
    }

    func testNonemptyDanmakuIsPreserved() throws {
        let response = try decode(##"{"success":true,"danmaku":[{"_id":"example-danmaku","text":"Example","color":"#FFFFFF","fontSize":"medium","mode":"rtl","time":1.5,"enableRainbow":false}]}"##)
        XCTAssertEqual(response.danmaku.count, 1)
        XCTAssertEqual(response.danmaku.first?.text, "Example")
        XCTAssertEqual(response.danmaku.first?.time, 1.5)
    }

    func testRejectedAndMalformedResponsesDoNotBecomeEmptyContent() {
        for json in [
            #"{"success":false}"#,
            #"{"success":false,"danmaku":[]}"#,
            #"{}"#,
            #"{"success":true,"danmaku":"invalid"}"#,
            #"{"success":true,"danmaku":[{}]}"#,
        ] {
            XCTAssertThrowsError(try decode(json))
        }
    }

    private func decode(_ json: String) throws -> DanmakuResponseDTO {
        try JSONDecoder().decode(DanmakuResponseDTO.self, from: Data(json.utf8))
    }
}
