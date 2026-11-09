import Foundation

nonisolated struct Invitation: Identifiable, Equatable, Sendable {
    let code: String
    let createdAt: Date
    let used: Bool

    var id: String { code }

    static func sorted(_ invitations: [Invitation]) -> [Invitation] {
        var seen: Set<String> = []
        return invitations.sorted { lhs, rhs in
            if lhs.used != rhs.used { return !lhs.used }
            if lhs.createdAt != rhs.createdAt { return lhs.createdAt > rhs.createdAt }
            return lhs.code < rhs.code
        }.filter { seen.insert($0.code).inserted }
    }
}

nonisolated struct InvitationDTO: Decodable, Sendable {
    let creatorUid: Int
    let invitationCode: String
    let generationDateTime: Double
    let assignee: Int?

    func validated(expectedUID: Int) throws -> Invitation {
        let seconds = generationDateTime / 1_000
        guard creatorUid > 0, creatorUid == expectedUID,
            !invitationCode.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
            generationDateTime.isFinite, seconds >= 0,
            seconds <= Date.distantFuture.timeIntervalSince1970
        else { throw InvitationError.invalidResponse }
        return Invitation(
            code: invitationCode,
            createdAt: Date(timeIntervalSince1970: seconds),
            used: assignee != nil
        )
    }
}

nonisolated struct InvitationListResponseDTO: Decodable, Sendable {
    let success: Bool
    let message: String?
    let invitationCodeResult: [InvitationDTO]?

    func validated(expectedUID: Int) throws -> [Invitation] {
        try InvitationError.validateSuccess(success, message: message)
        guard let invitationCodeResult else { throw InvitationError.invalidResponse }
        return Invitation.sorted(try invitationCodeResult.map { try $0.validated(expectedUID: expectedUID) })
    }
}

nonisolated struct InvitationCreationResponseDTO: Decodable, Sendable {
    let success: Bool
    let isCoolingDown: Bool
    let message: String?
    let invitationCodeResult: InvitationDTO?

    enum CodingKeys: String, CodingKey {
        case success, isCoolingDown, message, invitationCodeResult
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        success = try container.decode(Bool.self, forKey: .success)
        message = try container.decodeIfPresent(String.self, forKey: .message)
        // A definite rejection must not become uncertain because its unused payload is malformed.
        if success {
            isCoolingDown = try container.decode(Bool.self, forKey: .isCoolingDown)
            if isCoolingDown {
                invitationCodeResult = nil
            } else {
                invitationCodeResult = try container.decodeIfPresent(InvitationDTO.self, forKey: .invitationCodeResult)
            }
        } else {
            isCoolingDown = false
            invitationCodeResult = nil
        }
    }
}
