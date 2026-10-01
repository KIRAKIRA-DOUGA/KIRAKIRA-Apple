import CryptoKit
import Foundation
import OSLog
import Security

@Observable
final class AuthManager {
    static let shared = AuthManager()

    private(set) var accounts: [Credentials] = []
    private(set) var credentials: Credentials?
    var isLoading = false
    var isRefreshingProfiles = false
    var errorMessage: String?

    var isAuthenticated: Bool { credentials != nil }

    private let serviceName = "moe.kirakira"
    private let accountsKey = "userAccounts-v2"
    private let legacyAccountKey = "userToken"
    private let currentAccountDefaultsKey = "currentAccountUUID"
    private let guestModeDefaultsKey = "accountGuestMode"
    private let logger = Logger(subsystem: "moe.kirakira", category: "Auth")
    private let apiService = APIService.shared

    private init() {
        accounts = KeychainService.shared.read(
            service: serviceName,
            account: accountsKey,
            type: [Credentials].self
        ) ?? []

        if accounts.isEmpty,
            let legacy = KeychainService.shared.read(
                service: serviceName,
                account: legacyAccountKey,
                type: Credentials.self
            )
        {
            accounts = [legacy]
            persistAccounts()
            KeychainService.shared.delete(service: serviceName, account: legacyAccountKey)
        }

        guard !UserDefaults.standard.bool(forKey: guestModeDefaultsKey) else { return }
        let selectedID = UserDefaults.standard.string(forKey: currentAccountDefaultsKey)
        credentials = accounts.first { $0.uuid == selectedID } ?? accounts.first
    }

    func checkLoginMethod(email: String) async -> AuthenticatorType? {
        await perform {
            let response: CheckTwoFactorResponseDTO = try await apiService.request(.checkTwoFactor(email: email))
            guard response.success else { throw AuthFailure.server(response.message) }
            return response.have2FA ? (response.type ?? .none) : .none
        }
    }

    func login(
        email: String,
        password: String,
        clientOtp: String? = nil,
        verificationCode: String? = nil
    ) async -> Bool {
        let result: Credentials? = await perform {
            let request = UserLoginRequestDTO(
                email: email,
                passwordHash: sha256(password),
                clientOtp: clientOtp?.nilIfEmpty,
                verificationCode: verificationCode?.nilIfEmpty
            )
            let response: UserLoginResponseDTO = try await apiService.request(.login, body: request)
            guard response.success,
                let token = response.token,
                let uid = response.uid,
                let uuid = response.uuid
            else {
                let hint = response.passwordHint.map {
                    String.localizedStringWithFormat(
                        String(localized: "AUTH_LOGIN_FAILED_WITH_PASSWORD_HINT"),
                        response.message ?? String(localized: .authLoginFailed),
                        $0
                    )
                }
                throw AuthFailure.server(hint ?? response.message)
            }
            return Credentials(
                email: response.email ?? email,
                token: token,
                uid: uid,
                uuid: uuid,
                userDataBootstrapHint: response.userDataBootstrapHint
            )
        }
        guard let result else { return false }
        activate(result)
        await refreshAccountProfile(id: result.id)
        return true
    }

    func register(
        username: String,
        nickname: String,
        email: String,
        password: String,
        invitationCode: String,
        verificationCode: String
    ) async -> Bool {
        let result: Credentials? = await perform {
            let request = UserRegistrationRequestDTO(
                email: email,
                verificationCode: verificationCode,
                passwordHash: sha256(password),
                invitationCode: invitationCode,
                username: username,
                userNickname: nickname.nilIfEmpty
            )
            let response: UserRegistrationResponseDTO = try await apiService.request(.register, body: request)
            guard response.success,
                let token = response.token,
                let uid = response.uid,
                let uuid = response.uuid
            else { throw AuthFailure.server(response.message) }
            return Credentials(
                email: email,
                token: token,
                uid: uid,
                uuid: uuid,
                userDataBootstrapHint: response.userDataBootstrapHint,
                username: username,
                userNickname: nickname.nilIfEmpty
            )
        }
        guard let result else { return false }
        activate(result)
        await refreshAccountProfile(id: result.id)
        return true
    }

    func sendVerificationCode(email: String, purpose: VerificationPurpose) async -> Bool {
        let result: Bool? = await perform {
            let request = SendEmailVerificationCodeRequestDTO(
                email: email,
                clientLanguage: Locale.current.identifier,
                mailTemplate: purpose.mailTemplate,
                exclusiveBusinessName: purpose.rawValue
            )
            let response: SendEmailVerificationCodeResponseDTO = try await apiService.request(
                .sendEmailVerificationCode,
                body: request
            )
            guard response.success else {
                if response.isCoolingDown {
                    throw AuthFailure.server(String(localized: .authTooManyRequests))
                }
                if response.isMaxDailyCreateAttempts || response.isMaxDailyVerifierAttempts {
                    throw AuthFailure.server(String(localized: .authVerificationDailyLimit))
                }
                throw AuthFailure.server(response.message)
            }
            return true
        }
        return result == true
    }

    func isEmailAvailable(_ email: String) async -> Bool {
        let result: Bool? = await perform {
            let response: EmailExistsResponseDTO = try await apiService.request(.checkEmailExists(email: email))
            guard response.success else { throw AuthFailure.server(response.message) }
            guard !response.exists else {
                throw AuthFailure.server(String(localized: .authEmailAlreadyRegistered))
            }
            return true
        }
        return result == true
    }

    func isUsernameAvailable(_ username: String) async -> Bool {
        let result: Bool? = await perform {
            let response: UsernameResponseDTO = try await apiService.request(.checkUsername(username: username))
            guard response.success else { throw AuthFailure.server(response.message) }
            guard response.isAvailableUsername else {
                throw AuthFailure.server(String(localized: .authUsernameUnavailable))
            }
            return true
        }
        return result == true
    }

    func isInvitationCodeAvailable(_ invitationCode: String) async -> Bool {
        let result: Bool? = await perform {
            let request = InvitationCodeRequestDTO(invitationCode: invitationCode)
            let response: InvitationCodeResponseDTO = try await apiService.request(.checkInvitationCode, body: request)
            guard response.success, response.isAvailableInvitationCode else {
                throw AuthFailure.server(response.message ?? String(localized: .authInvitationCodeInvalid))
            }
            return true
        }
        return result == true
    }

    func switchAccount(to id: String) {
        guard let account = accounts.first(where: { $0.id == id }) else { return }
        credentials = account
        UserDefaults.standard.set(account.uuid, forKey: currentAccountDefaultsKey)
        UserDefaults.standard.set(false, forKey: guestModeDefaultsKey)
        errorMessage = nil
    }

    func continueAsGuest() {
        credentials = nil
        UserDefaults.standard.removeObject(forKey: currentAccountDefaultsKey)
        UserDefaults.standard.set(true, forKey: guestModeDefaultsKey)
        errorMessage = nil
    }

    func removeAccounts(at offsets: IndexSet) {
        let removedIDs = offsets.compactMap { accounts.indices.contains($0) ? accounts[$0].id : nil }
        for offset in offsets.sorted(by: >) where accounts.indices.contains(offset) {
            accounts.remove(at: offset)
        }
        if let currentID = credentials?.id, removedIDs.contains(currentID) {
            continueAsGuest()
        }
        persistAccounts()
    }

    func logout() async {
        let currentID = credentials?.id
        if currentID != nil {
            let _: UserLogoutResponseDTO? = try? await apiService.request(.logout)
            if let index = accounts.firstIndex(where: { $0.id == currentID }) {
                accounts.remove(at: index)
                persistAccounts()
            }
        }
        continueAsGuest()
    }

    func clearError() {
        errorMessage = nil
    }

    func refreshAccountProfiles() async {
        guard !isRefreshingProfiles else { return }
        isRefreshingProfiles = true
        defer { isRefreshingProfiles = false }

        for accountID in accounts.map(\.id) {
            await refreshAccountProfile(id: accountID)
        }
    }

    private func activate(_ account: Credentials) {
        accounts.removeAll { $0.uuid == account.uuid || $0.email.caseInsensitiveCompare(account.email) == .orderedSame }
        accounts.append(account)
        persistAccounts()
        switchAccount(to: account.id)
        logger.info("Stored and activated account \(account.uid)")
    }

    private func persistAccounts() {
        KeychainService.shared.save(accounts, service: serviceName, account: accountsKey)
    }

    private func refreshAccountProfile(id: String) async {
        guard let account = accounts.first(where: { $0.id == id }) else { return }
        do {
            let request = SelfUserInfoRequestDTO(uuid: account.uuid, token: account.token)
            let response: SelfUserInfoResponseDTO = try await apiService.request(
                .getSelfInfo,
                body: request,
                authenticatedWith: account
            )
            guard response.success, let profile = response.result else { return }

            let updatedAccount = account.updatingProfile(profile)
            storeUpdatedAccount(updatedAccount)

            let stats: FollowStatsResponseDTO = try await apiService.request(
                .getFollowStats(uid: account.uid),
                body: nil as String?,
                authenticatedWith: account
            )
            if stats.success {
                storeUpdatedAccount(updatedAccount.updatingFollowStats(stats))
            }
        } catch {
            logger.warning("Failed to refresh profile for account \(account.uid): \(error.localizedDescription)")
        }
    }

    private func storeUpdatedAccount(_ account: Credentials) {
        guard let index = accounts.firstIndex(where: { $0.id == account.id }) else { return }
        accounts[index] = account
        if credentials?.id == account.id { credentials = account }
        persistAccounts()
    }

    private func perform<T>(_ operation: () async throws -> T) async -> T? {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            return try await operation()
        } catch {
            logger.error("Authentication operation failed: \(error.localizedDescription)")
            errorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
            return nil
        }
    }

    private func sha256(_ input: String) -> String {
        SHA256.hash(data: Data(input.utf8)).map { String(format: "%02x", $0) }.joined()
    }
}

enum VerificationPurpose: String {
    case login
    case registration

    var mailTemplate: String {
        switch self {
        case .login: "SendLoginVerificationCode"
        case .registration: "SendRegistrationVerificationCode"
        }
    }
}

struct Credentials: Codable, Identifiable, Hashable {
    let email: String
    let token: String
    let uid: Int
    let uuid: String
    let userDataBootstrapHint: String?
    let username: String?
    let userNickname: String?
    let avatar: String?
    let userBannerImage: String?
    let signature: String?
    let userBirthday: String?
    let followingCount: Int?
    let followerCount: Int?

    var id: String { uuid }

    var cookieString: String {
        var cookies = "email=\(email); token=\(token); uid=\(uid); uuid=\(uuid)"
        if let userDataBootstrapHint { cookies += "; user-data-bootstrap-hint=\(userDataBootstrapHint)" }
        return cookies
    }

    private enum CodingKeys: String, CodingKey {
        case email, token, uid, uuid, userDataBootstrapHint, username, userNickname, avatar
        case userBannerImage, signature, userBirthday, followingCount, followerCount
    }

    init(
        email: String,
        token: String,
        uid: Int,
        uuid: String,
        userDataBootstrapHint: String? = nil,
        username: String? = nil,
        userNickname: String? = nil,
        avatar: String? = nil,
        userBannerImage: String? = nil,
        signature: String? = nil,
        userBirthday: String? = nil,
        followingCount: Int? = nil,
        followerCount: Int? = nil
    ) {
        self.email = email
        self.token = token
        self.uid = uid
        self.uuid = uuid
        self.userDataBootstrapHint = userDataBootstrapHint
        self.username = username
        self.userNickname = userNickname
        self.avatar = avatar
        self.userBannerImage = userBannerImage
        self.signature = signature
        self.userBirthday = userBirthday
        self.followingCount = followingCount
        self.followerCount = followerCount
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        email = try container.decode(String.self, forKey: .email)
        token = try container.decode(String.self, forKey: .token)
        uid = try container.decode(Int.self, forKey: .uid)
        uuid = try container.decode(String.self, forKey: .uuid)
        userDataBootstrapHint = try container.decodeIfPresent(String.self, forKey: .userDataBootstrapHint)
        username = try container.decodeIfPresent(String.self, forKey: .username)
        userNickname = try container.decodeIfPresent(String.self, forKey: .userNickname)
        avatar = try container.decodeIfPresent(String.self, forKey: .avatar)
        userBannerImage = try container.decodeIfPresent(String.self, forKey: .userBannerImage)
        signature = try container.decodeIfPresent(String.self, forKey: .signature)
        userBirthday = try container.decodeIfPresent(String.self, forKey: .userBirthday)
        followingCount = try container.decodeIfPresent(Int.self, forKey: .followingCount)
        followerCount = try container.decodeIfPresent(Int.self, forKey: .followerCount)
    }

    func updatingProfile(_ profile: AccountProfileDTO) -> Credentials {
        Credentials(
            email: email,
            token: token,
            uid: uid,
            uuid: uuid,
            userDataBootstrapHint: userDataBootstrapHint,
            username: profile.username ?? username,
            userNickname: profile.userNickname ?? userNickname,
            avatar: profile.avatar ?? avatar,
            userBannerImage: profile.userBannerImage ?? userBannerImage,
            signature: profile.signature ?? signature,
            userBirthday: profile.userBirthday ?? userBirthday,
            followingCount: followingCount,
            followerCount: followerCount
        )
    }

    func updatingFollowStats(_ stats: FollowStatsResponseDTO) -> Credentials {
        Credentials(
            email: email,
            token: token,
            uid: uid,
            uuid: uuid,
            userDataBootstrapHint: userDataBootstrapHint,
            username: username,
            userNickname: userNickname,
            avatar: avatar,
            userBannerImage: userBannerImage,
            signature: signature,
            userBirthday: userBirthday,
            followingCount: stats.followingCount ?? followingCount,
            followerCount: stats.followerCount ?? followerCount
        )
    }

    var displayName: String {
        if let userNickname, !userNickname.isEmpty { return userNickname }
        if let username, !username.isEmpty { return username }
        return email
    }
}

private enum AuthFailure: LocalizedError {
    case server(String?)

    var errorDescription: String? {
        switch self {
        case .server(let message): message ?? String(localized: .errorRequestFailed)
        }
    }
}

private extension String {
    var nilIfEmpty: String? { isEmpty ? nil : self }
}

private final class KeychainService {
    static let shared = KeychainService()
    private let logger = Logger(subsystem: "moe.kirakira", category: "KeyChain")
    private init() {}

    func save<T: Codable>(_ item: T, service: String, account: String) {
        do {
            save(try JSONEncoder().encode(item), service: service, account: account)
        } catch {
            logger.error("Failed to encode keychain item: \(error.localizedDescription)")
        }
    }

    func read<T: Codable>(service: String, account: String, type: T.Type) -> T? {
        guard let data = read(service: service, account: account) else { return nil }
        do {
            return try JSONDecoder().decode(type, from: data)
        } catch {
            logger.error("Failed to decode keychain item: \(error.localizedDescription)")
            return nil
        }
    }

    func delete(service: String, account: String) {
        let query = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: service,
            kSecAttrAccount: account,
        ] as [String: Any]
        SecItemDelete(query as CFDictionary)
    }

    private func save(_ data: Data, service: String, account: String) {
        let query = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: service,
            kSecAttrAccount: account,
        ] as [String: Any]
        SecItemDelete(query as CFDictionary)
        var addQuery = query
        addQuery[kSecValueData as String] = data
        let status = SecItemAdd(addQuery as CFDictionary, nil)
        if status != errSecSuccess { logger.error("Failed to save keychain item: \(status)") }
    }

    private func read(service: String, account: String) -> Data? {
        let query = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: service,
            kSecAttrAccount: account,
            kSecReturnData: true,
            kSecMatchLimit: kSecMatchLimitOne,
        ] as [String: Any]
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        return status == errSecSuccess ? result as? Data : nil
    }
}
