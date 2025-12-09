import CryptoKit
import Foundation
import OSLog

@Observable
class AuthManager {
    var authState: AuthState = .unchecked
    var isLoading: Bool = false
    var errorMessage: String? = nil

    private let logger = Logger(subsystem: "moe.kirakira", category: "Auth")

    private let apiService = APIService.shared
    private let keychainService = KeychainService.shared

    enum AuthState {
        case unchecked
        case authenticated
        case unauthenticated
    }

    func check() async {
        if let credentials = await keychainService.read() {
            logger.info("AuthManager checked with existing token")
            await apiService.setCookie(credentials.cookieString)
            self.authState = .authenticated
        } else {
            logger.info("AuthManager checked with no token")
            await apiService.setCookie(nil)
            self.authState = .unauthenticated
        }
    }

    func login(email: String, password: String) async -> Bool {
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
            await apiService.setCookie(credentials.cookieString)
            await keychainService.save(credentials)
            self.authState = .authenticated
            return true
        } catch {
            logger.error("Login failed: \(error)")
            self.errorMessage = "Login failed. Please check your credentials."
            self.authState = .unauthenticated
            return false
        }
    }

    func logout() async {
        logger.info("Logging out and clearing token")
        do {
            let _: UserLogoutResponseDTO = try await apiService.request(.logout)
        } catch {
            logger.warning("Logging out partial failure due to cannot log out on API")
        }
        await apiService.setCookie(nil)
        await keychainService.clear()
        self.authState = .unauthenticated
    }

    private func sha256(_ input: String) -> String {
        let inputData = Data(input.utf8)
        let hashed = SHA256.hash(data: inputData)
        let hashString = hashed.compactMap { String(format: "%02x", $0) }.joined()

        return hashString
    }

}
