import CryptoKit
import Foundation
import OSLog

@Observable
final class AuthManager {
    var isAuthenticated: Bool = false
    var credentials: Credentials? = nil
    var isLoading: Bool = false
    var errorMessage: String? = nil

    private let logger = Logger(subsystem: "moe.kirakira", category: "Auth")

    private let apiService: APIServiceProtocol
    private let sessionStore: any AuthSessionStoring

    init(apiService: APIServiceProtocol, sessionStore: any AuthSessionStoring) {
        self.apiService = apiService
        self.sessionStore = sessionStore

        if let credentials = sessionStore.bootstrapCredentials {
            logger.info("AuthManager initialized with existing token")

            self.credentials = credentials
            self.isAuthenticated = true
        }
    }

    func login(email: String, password: String) async -> Bool {
        let previousCredentials = credentials

        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            logger.info("Attempting to login")
            let passwordHash = sha256(password)
            let requestDTO = UserLoginRequestDTO(email: email, passwordHash: passwordHash)
            let response: UserLoginResponseDTO = try await apiService.request(.login, body: requestDTO)
            logger.info("Login successful, saving credentials to Keychain")

            let credentials = Credentials(email: email, token: response.token, uid: response.uid, uuid: response.uuid)

            await sessionStore.store(credentials: credentials)

            self.credentials = credentials
            self.isAuthenticated = true

            return true
        } catch {
            logger.error("Login failed: \(error)")
            self.errorMessage = "Login failed. Please check your credentials."
            self.credentials = previousCredentials
            self.isAuthenticated = previousCredentials != nil
        }

        return false
    }

    func logout() async throws {
        logger.info("Logging out and clearing token")
        let _: UserLogoutResponseDTO = try await apiService.request(.logout)
        await sessionStore.clearCredentials()

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
