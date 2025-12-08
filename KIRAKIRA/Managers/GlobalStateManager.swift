import Combine
import SwiftUI

@Observable
class GlobalStateManager {
    var mainTabSelection: MainTab = .home
    var selectedCategory: Category = categories.first!
    var isPlayerPlaying: Bool = false
    var selectedVideo: Int?
    var activeTransitionSource: AnimationTransitionSource = .miniPlayer
}

enum MainTab: Hashable {
    case home
    case feed
    case me
    case search
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
    Category(name: String(localized: "CATEGORY_POPULOAR"), systemImage: "flame.fill"),
    Category(name: String(localized: "CATEGORY_LATEST"), systemImage: "plus.circle.fill"),
    Category(name: String(localized: "CATEGORY_ANIMATION"), systemImage: "wand.and.rays"),
    Category(name: String(localized: "CATEGORY_MUSIC"), systemImage: "music.note"),
    Category(name: String(localized: "CATEGORY_OTOMAD"), systemImage: "scissors"),
    Category(name: String(localized: "CATEGORY_TECH"), systemImage: "cpu.fill"),
    Category(name: String(localized: "CATEGORY_DESIGN"), systemImage: "pencil.and.ruler.fill"),
    Category(name: String(localized: "CATEGORY_GAME"), systemImage: "gamecontroller.fill"),
    Category(name: String(localized: "CATEGORY_OTHER"), systemImage: "square.grid.3x3.fill"),
]
