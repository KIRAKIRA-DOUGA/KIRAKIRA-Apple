import Foundation
import OSLog
import Security

protocol AuthSessionProviding: Sendable {
    var bootstrapCredentials: Credentials? { get }
    func currentCredentials() async -> Credentials?
    func cookieHeader() async -> String?
}

protocol AuthSessionStoring: AuthSessionProviding {
    func store(credentials: Credentials) async
    func clearCredentials() async
}

protocol CredentialsPersisting: Sendable {
    nonisolated func loadCredentials() -> Credentials?
    nonisolated func saveCredentials(_ credentials: Credentials)
    nonisolated func deleteCredentials()
}

actor AuthSessionStore: AuthSessionStoring {
    static let shared = AuthSessionStore()

    nonisolated let bootstrapCredentials: Credentials?

    private let persistence: any CredentialsPersisting
    private var credentials: Credentials?

    init(persistence: any CredentialsPersisting = KeychainCredentialsPersistence()) {
        let bootstrapCredentials = persistence.loadCredentials()
        self.bootstrapCredentials = bootstrapCredentials
        self.persistence = persistence
        self.credentials = bootstrapCredentials
    }

    func currentCredentials() -> Credentials? {
        credentials
    }

    func cookieHeader() -> String? {
        credentials?.cookieString
    }

    func store(credentials: Credentials) {
        self.credentials = credentials
        persistence.saveCredentials(credentials)
    }

    func clearCredentials() {
        credentials = nil
        persistence.deleteCredentials()
    }
}

final class KeychainCredentialsPersistence: CredentialsPersisting, @unchecked Sendable {
    private nonisolated static let logger = Logger(subsystem: "moe.kirakira", category: "Keychain")
    private let serviceName = "moe.kirakira"
    private let accountName = "userToken"

    nonisolated init() {}

    nonisolated func loadCredentials() -> Credentials? {
        guard let data = read(service: serviceName, account: accountName) else {
            return nil
        }

        do {
            return try JSONDecoder().decode(Credentials.self, from: data)
        } catch {
            Self.logger.error("Fail to decode credentials from keychain: \(error)")
            deleteCredentials()
            return nil
        }
    }

    nonisolated func saveCredentials(_ credentials: Credentials) {
        do {
            let data = try JSONEncoder().encode(credentials)
            save(data, service: serviceName, account: accountName)
        } catch {
            assertionFailure("Failed to encode credentials for keychain: \(error)")
        }
    }

    nonisolated func deleteCredentials() {
        let query =
            [
                kSecClass: kSecClassGenericPassword,
                kSecAttrService: serviceName,
                kSecAttrAccount: accountName,
            ] as [String: Any] as CFDictionary

        SecItemDelete(query)
    }

    private nonisolated func save(_ data: Data, service: String, account: String) {
        let query =
            [
                kSecClass: kSecClassGenericPassword,
                kSecAttrService: service,
                kSecAttrAccount: account,
            ] as [String: Any]

        SecItemDelete(query as CFDictionary)

        var addQuery = query
        addQuery[kSecValueData as String] = data

        let status = SecItemAdd(addQuery as CFDictionary, nil)

        if status != errSecSuccess {
            Self.logger.error("Error saving to keychain: \(status)")
        }
    }

    private nonisolated func read(service: String, account: String) -> Data? {
        let query =
            [
                kSecClass: kSecClassGenericPassword,
                kSecAttrService: service,
                kSecAttrAccount: account,
                kSecReturnData: true,
                kSecMatchLimit: kSecMatchLimitOne,
            ] as [String: Any]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        if status == errSecSuccess {
            return result as? Data
        }

        if status != errSecItemNotFound {
            Self.logger.error("Error reading from keychain: \(status)")
        }

        return nil
    }
}
