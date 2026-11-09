import XCTest
@testable import KIRAKIRA

@MainActor
final class InvitationTests: XCTestCase {
    func testDecodesOnlyRequiredBackendFieldsAndMilliseconds() async throws {
        let response = try InvitationTestSupport.list()
        let invitations = try response.validated(expectedUID: 1)
        XCTAssertEqual(invitations, [InvitationTestSupport.invitation()])
        XCTAssertEqual(invitations.first?.id, "fixture-code-a")
        XCTAssertEqual(invitations.first?.createdAt.timeIntervalSince1970, 1_700_000_000)
    }

    func testAssigneePresenceDeterminesUsedEvenIfZero() async throws {
        for assignee: Int? in [nil, 0, 2] {
            let response = try InvitationTestSupport.list([InvitationTestSupport.payload(assignee: assignee)])
            XCTAssertEqual(try response.validated(expectedUID: 1).first?.used, assignee != nil)
        }
        var payload = InvitationTestSupport.payload()
        payload["assignee"] = NSNull()
        payload["isPending"] = true
        payload["usedDateTime"] = 1_700_000_000_000
        let response = try InvitationTestSupport.list([payload])
        XCTAssertEqual(try response.validated(expectedUID: 1).first?.used, false)
    }

    func testSuccessfulMissingOrNullListIsInvalidButExplicitEmptyListIsValid() async throws {
        for object: [String: Any] in [
            ["success": true],
            ["success": true, "invitationCodeResult": NSNull()],
        ] {
            let response: InvitationListResponseDTO = try InvitationTestSupport.decode(object)
            XCTAssertThrowsError(try response.validated(expectedUID: 1)) { error in
                guard case InvitationError.invalidResponse = error else { return XCTFail("Expected invalid response") }
            }
        }
        let response = try InvitationTestSupport.list([])
        XCTAssertEqual(try response.validated(expectedUID: 1), [])
    }

    func testRejectsMismatchedOrInvalidCreatorAndBlankCodes() async throws {
        for payload in [
            InvitationTestSupport.payload(uid: 2),
            InvitationTestSupport.payload(uid: 0),
            InvitationTestSupport.payload(code: ""),
            InvitationTestSupport.payload(code: " \n\t "),
        ] {
            let response = try InvitationTestSupport.list([payload])
            XCTAssertThrowsError(try response.validated(expectedUID: 1))
        }
    }

    func testRejectsInvalidAndNonFiniteTimes() async throws {
        for milliseconds in [-1.0, .infinity, -.infinity, .nan, Double.greatestFiniteMagnitude] {
            let dto = InvitationDTO(creatorUid: 1, invitationCode: "fixture-code-a", generationDateTime: milliseconds, assignee: nil)
            XCTAssertThrowsError(try dto.validated(expectedUID: 1))
        }
        let dto = InvitationDTO(creatorUid: 1, invitationCode: "fixture-code-a", generationDateTime: 0, assignee: nil)
        XCTAssertEqual(try dto.validated(expectedUID: 1).createdAt.timeIntervalSince1970, 0)
    }

    func testMissingRequiredFieldsAndWrongTypesFailDecoding() async throws {
        for key in ["creatorUid", "invitationCode", "generationDateTime"] {
            var payload = InvitationTestSupport.payload()
            payload.removeValue(forKey: key)
            XCTAssertThrowsError(try InvitationTestSupport.list([payload]))
        }
        var payload = InvitationTestSupport.payload()
        payload["assignee"] = "not-an-integer"
        XCTAssertThrowsError(try InvitationTestSupport.list([payload]))
    }

    func testSortsUnusedFirstNewestFirstThenCodeAndDeduplicatesDeterministically() async {
        let a = InvitationTestSupport.invitation(code: "fixture-a", seconds: 100)
        let b = InvitationTestSupport.invitation(code: "fixture-b", seconds: 100)
        let newest = InvitationTestSupport.invitation(code: "fixture-newest", seconds: 200)
        let used = InvitationTestSupport.invitation(code: "fixture-used", seconds: 300, used: true)
        let olderDuplicate = InvitationTestSupport.invitation(code: "fixture-a", seconds: 50)
        let usedDuplicate = InvitationTestSupport.invitation(code: "fixture-a", seconds: 400, used: true)
        let input = [used, b, olderDuplicate, newest, a, usedDuplicate, a]
        XCTAssertEqual(Invitation.sorted(input), [newest, a, b, used])
        XCTAssertEqual(Invitation.sorted(Array(input.reversed())), [newest, a, b, used])
    }

    func testListValidationAlsoSortsAndDeduplicates() async throws {
        let response = try InvitationTestSupport.list([
            InvitationTestSupport.payload(code: "fixture-b"),
            InvitationTestSupport.payload(code: "fixture-a"),
            InvitationTestSupport.payload(code: "fixture-a"),
        ])
        XCTAssertEqual(try response.validated(expectedUID: 1).map(\.code), ["fixture-a", "fixture-b"])
    }
}
