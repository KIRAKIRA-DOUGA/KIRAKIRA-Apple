import XCTest
@testable import KIRAKIRA

@MainActor
final class CommentModelTests: XCTestCase {
    func testEmptyCommentsWithoutAggregateCountDecode() throws {
        let response = try decode(#"{"success":true,"videoCommentList":[]}"#)
        XCTAssertEqual(response.videoCommentCount, 0)
        XCTAssertTrue(response.videoCommentList.isEmpty)
    }

    func testMissingNullAndEmptyCommentsDecodeAsEmpty() throws {
        for json in [
            #"{"success":true}"#,
            #"{"success":true,"videoCommentCount":null,"videoCommentList":null}"#,
            #"{"success":true,"videoCommentCount":0,"videoCommentList":[]}"#,
        ] {
            let response = try decode(json)
            XCTAssertEqual(response.videoCommentCount, 0)
            XCTAssertTrue(response.videoCommentList.isEmpty)
        }
    }

    func testExplicitCountIsPreserved() throws {
        let response = try decode(#"{"success":true,"videoCommentCount":42,"videoCommentList":[]}"#)
        XCTAssertEqual(response.videoCommentCount, 42)
    }

    func testRejectedAndMalformedResponsesDoNotBecomeEmptyContent() {
        for json in [
            #"{"success":false,"videoCommentCount":0,"videoCommentList":[]}"#,
            #"{}"#,
            #"{"success":true,"videoCommentList":"invalid"}"#,
            #"{"success":true,"videoCommentList":[{}]}"#,
            #"{"success":true,"videoCommentCount":"invalid","videoCommentList":[]}"#,
        ] {
            XCTAssertThrowsError(try decode(json))
        }
    }

    private func decode(_ json: String) throws -> VideoRequestCommentDTO {
        try JSONDecoder().decode(VideoRequestCommentDTO.self, from: Data(json.utf8))
    }
}
