import Combine
import SwiftUI

@Observable
class GlobalStateManager {
    var mainTabSelection: MainTab = .home
    var selectedCategory: Category = categories.first!
    var isPlayerPlaying: Bool = false
    var selectedVideo: Int?
    var activeTransitionSource: AnimationTransitionSource = .miniPlayer
    var isShowingSettings: Bool = false
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

enum AnimationTransitionSource: Hashable {
    case video(Int)
    case miniPlayer
}

struct Category: Identifiable, Hashable {
    var id = UUID()
    var name: String
    var systemImage: String
}

let categories: [Category] = [
    // Wrap the keys in String(localized: ...)
    Category(name: String(localized: .hot), systemImage: "flame.fill"),
    Category(name: String(localized: .latest), systemImage: "plus.circle.fill"),
    Category(name: String(localized: .categoryAnimation), systemImage: "wand.and.rays"),
    Category(name: String(localized: .categoryMusic), systemImage: "music.note"),
    Category(name: String(localized: .categoryOtomad), systemImage: "scissors"),
    Category(name: String(localized: .categoryTech), systemImage: "cpu.fill"),
    Category(name: String(localized: .categoryDesign), systemImage: "pencil.and.ruler.fill"),
    Category(name: String(localized: .categoryGame), systemImage: "gamecontroller.fill"),
    Category(name: String(localized: .categoryOther), systemImage: "square.grid.3x3.fill"),
]
