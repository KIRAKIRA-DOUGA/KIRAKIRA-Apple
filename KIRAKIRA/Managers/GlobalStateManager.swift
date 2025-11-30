import Combine
import SwiftUI

class GlobalStateManager: ObservableObject {
    static var shared = GlobalStateManager()

    @Published var mainTabSelection: MainTab = .home

    private init() {}
}

enum MainTab: Hashable {
    case home
    case feed
    case messages
    case me
    case search
    case category(String)
}
