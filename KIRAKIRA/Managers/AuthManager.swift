import Combine
import CryptoKit
import Foundation
import OSLog
import Security

@MainActor
class AuthManager: ObservableObject {
    static let shared = AuthManager()

    @Published var isAuthenticated: Bool = false
    @Published var credentials: Credentials? = nil
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil

    private let serviceName = "moe.kirakira"
    private let accountName = "userToken"

    private let logger = Logger(subsystem: "moe.kirakira", category: "Auth")

    private let apiService = APIService.shared

    private init() {
        if let credentials = KeychainService.shared.read(
            service: serviceName,
            account: accountName,
            type: Credentials.self
        ) {
            logger.info("AuthManager initialized with existing token")

            self.credentials = credentials
            self.isAuthenticated = true
        }
    }

    func login(email: String, password: String) async -> Bool {
        isLoading = true
        errorMessage = nil

        do {
            logger.info("Attempting to login")
            let passwordHash = sha256(password)
            let requestDTO = UserLoginRequestDTO(email: email, passwordHash: passwordHash)
            let response: UserLoginResponseDTO = try await apiService.request(.login, body: requestDTO)
            logger.info("Login successful, saving credentials to Keychain")

            let credentials = Credentials(email: email, token: response.token, uid: response.uid, UUID: response.UUID)

            KeychainService.shared.save(credentials, service: serviceName, account: accountName)

            self.credentials = credentials
            self.isAuthenticated = true

            return true
        } catch {
            logger.error("Login failed: \(error)")
            self.errorMessage = "Login failed. Please check your credentials."
            self.isAuthenticated = false
            self.credentials = nil
        }

        isLoading = false
        return false
    }

    func logout() async throws {
        logger.info("Logging out and clearing token")
        let _: UserLogoutResponseDTO = try await apiService.request(.logout)
        KeychainService.shared.delete(service: serviceName, account: accountName)

        self.credentials = nil
        self.isAuthenticated = false
    }

    func sha256(_ input: String) -> String {
        let inputData = Data(input.utf8)
        let hashed = SHA256.hash(data: inputData)
        let hashString = hashed.compactMap { String(format: "%02x", $0) }.joined()

        return hashString
    }
}

struct Credentials: Codable {
    let email: String
    let token: String
    let uid: Int
    let UUID: String

    var cookieString: String {
        "email=\(email); token=\(token); uid=\(uid); uuid=\(UUID)"
    }
}

private class KeychainService {
    static let shared = KeychainService()
    private let logger = Logger(subsystem: "moe.kirakira", category: "KeyChain")
    private init() {}

    // A generic function to save any Codable data
    func save<T: Codable>(_ item: T, service: String, account: String) {
        do {
            let data = try JSONEncoder().encode(item)
            save(data, service: service, account: account)
        } catch {
            assertionFailure("Fail to encode item for keychain: \(error)")
        }
    }

    // A generic function to read any Codable data
    func read<T: Codable>(service: String, account: String, type: T.Type) -> T? {
        guard let data = read(service: service, account: account) else {
            return nil
        }

        do {
            let item = try JSONDecoder().decode(type, from: data)
            return item
        } catch {
            logger.error("Fail to decode item for keychain: \(error)")
            delete(service: service, account: account)
            return nil
        }
    }

    // Delete data from Keychain
    func delete(service: String, account: String) {
        let query =
            [
                kSecClass: kSecClassGenericPassword,
                kSecAttrService: service,
                kSecAttrAccount: account,
            ] as [String: Any] as CFDictionary

        SecItemDelete(query)
    }

    // MARK: - Private Helper Functions

    private func save(_ data: Data, service: String, account: String) {
        let query =
            [
                kSecClass: kSecClassGenericPassword,
                kSecAttrService: service,
                kSecAttrAccount: account,
            ] as [String: Any]

        // Delete any existing item first
        SecItemDelete(query as CFDictionary)

        // Add the new item
        var addQuery = query
        addQuery[kSecValueData as String] = data

        let status = SecItemAdd(addQuery as CFDictionary, nil)

        if status != errSecSuccess {
            print("Error saving to keychain: \(status)")
        }
    }

    private func read(service: String, account: String) -> Data? {
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
        } else {
            // It's common for there to be no item, so only print for unexpected errors
            if status != errSecItemNotFound {
                print("Error reading from keychain: \(status)")
            }
            return nil
        }
    }
}
