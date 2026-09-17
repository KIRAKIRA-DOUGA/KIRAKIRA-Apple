import Combine
import SwiftUI

@Observable
class GlobalStateManager {
    var mainTabSelection: MainTab = .home
    var selectedCategory: Category = categories.first!
    var isSplashFinished: Bool = false
    var isShowingSettings: Bool = false
    var settingsPath = NavigationPath()
    var isShowingLogin: Bool = false
    var isShowingKeyboard: Bool = false
    var selectedVideo: Int?
    var isPlayerExpanded: Bool = false
    var activeTransitionSource: AnimationTransitionSource = .none

    func showSettings(destination: SettingsPath? = nil) {
        settingsPath = NavigationPath()
        if let destination {
            settingsPath.append(destination)
        }
        isShowingSettings = true
    }

    func resetSettingsNavigation() {
        settingsPath = NavigationPath()
    }
}

enum AnimationTransitionSource: Hashable {
    case video(Int)
    case none
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

struct Category: Identifiable, Hashable {
    var id = UUID()
    var name: String
    var systemImage: String
    var color: Color
}

let categories: [Category] = [
    // Wrap the keys in String(localized: ...)
    Category(name: String(localized: .hot), systemImage: "flame", color: .red),
    Category(name: String(localized: .latest), systemImage: "plus.circle", color: .red),
    Category(name: String(localized: .categoryAnimation), systemImage: "circle.dotted.and.circle", color: .pink),
    Category(name: String(localized: .categoryMusic), systemImage: "music.note", color: .purple),
    Category(name: String(localized: .categoryOtomad), systemImage: "waveform", color: .green),
    Category(name: String(localized: .categoryTech), systemImage: "cpu", color: .blue),
    Category(name: String(localized: .categoryDesign), systemImage: "pencil.and.ruler", color: .indigo),
    Category(name: String(localized: .categoryGame), systemImage: "gamecontroller", color: .teal),
    Category(name: String(localized: .categoryOther), systemImage: "square.grid.3x3", color: .accent),
]
