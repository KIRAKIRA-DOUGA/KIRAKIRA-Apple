import Foundation

@Observable
final class MyScreenModel {
    var dashboard: CurrentUserDashboard?
    var isLoading = false
    var errorMessage: String?

    private let repository: ProfileRepository

    init(repository: ProfileRepository) {
        self.repository = repository
    }

    func loadIfAuthenticated(_ isAuthenticated: Bool) async {
        guard isAuthenticated else {
            dashboard = nil
            errorMessage = nil
            isLoading = false
            return
        }

        await load()
    }

    func load() async {
        isLoading = true
        errorMessage = nil

        do {
            dashboard = try await repository.currentUserDashboard()
        } catch {
            dashboard = nil
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }
}
