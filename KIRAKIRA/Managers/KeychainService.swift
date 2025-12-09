import OSLog
import Security

actor KeychainService {
    static let shared = KeychainService()

    private let serviceName = "moe.kirakira"
    private let accountName = "userToken"
    private let logger = Logger(subsystem: "moe.kirakira", category: "KeyChain")
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    private init() {}

    // A generic function to save any Codable data
    func save(_ item: Credentials) async {
        do {
            let data = try encoder.encode(item)
            save_raw(data)
        } catch {
            assertionFailure("Fail to encode item for keychain: \(error)")
        }
    }

    // A generic function to read any Codable data
    func read() async -> Credentials? {
        guard let data = read_raw() else {
            return nil
        }

        do {
            let item = try decoder.decode(Credentials.self, from: data)
            return item
        } catch {
            logger.error("Fail to decode item for keychain: \(error)")
            await clear()
            return nil
        }
    }

    // Delete data from Keychain
    func clear() async {
        let query =
            [
                kSecClass: kSecClassGenericPassword,
                kSecAttrService: serviceName,
                kSecAttrAccount: accountName,
            ] as [String: Any] as CFDictionary

        SecItemDelete(query)
    }

    // MARK: - Private Helper Functions

    private func save_raw(_ data: Data) {
        let query =
            [
                kSecClass: kSecClassGenericPassword,
                kSecAttrService: serviceName,
                kSecAttrAccount: accountName,
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

    private func read_raw() -> Data? {
        let query =
            [
                kSecClass: kSecClassGenericPassword,
                kSecAttrService: serviceName,
                kSecAttrAccount: accountName,
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
