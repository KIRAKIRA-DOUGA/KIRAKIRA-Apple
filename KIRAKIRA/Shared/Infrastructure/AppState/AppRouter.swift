import SwiftUI

@Observable
final class AppRouter {
    var mainTabSelection: MainTab = .home
    var isShowingSettings = false
    var isShowingLogin = false
}

enum MainTab: Hashable {
    case home
    case feed
    case search

    // compact horizontal size only
    case me

    // regular horizontal size only
    case myNotifications
    case myMessages
    case myCollections
    case myHistory
    case myUserPage
}
