import Foundation

@MainActor
final class AppDependencies {
    let sessionStore: AuthSessionStore
    let apiService: APIService
    let authManager: AuthManager
    let homeRepository: HomeRepository
    let videoRepository: VideoRepository
    let profileRepository: ProfileRepository

    init(sessionStore: AuthSessionStore) {
        self.sessionStore = sessionStore

        let apiService = APIService(sessionStore: sessionStore)
        self.apiService = apiService
        self.authManager = AuthManager(apiService: apiService, sessionStore: sessionStore)
        self.homeRepository = LiveHomeRepository(apiService: apiService)
        self.videoRepository = LiveVideoRepository(apiService: apiService)
        self.profileRepository = LiveProfileRepository(sessionStore: sessionStore)
    }
}
