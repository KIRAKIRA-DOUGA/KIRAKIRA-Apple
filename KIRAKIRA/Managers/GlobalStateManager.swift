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

struct Category: Identifiable, Hashable {
    var id = UUID()
    var name: String
    var systemImage: String
}

enum AnimationTransitionSource: Hashable {
    case video(Int)
    case miniPlayer
}

let categories: [Category] = [
    Category(name: "CATEGORY_POPULOAR", systemImage: "flame.fill"),
    Category(name: "CATEGORY_LATEST", systemImage: "plus.circle.fill"),
    Category(name: "CATEGORY_ANIMATION", systemImage: "wand.and.rays"),
    Category(name: "CATEGORY_MUSIC", systemImage: "music.note"),
    Category(name: "CATEGORY_MAD", systemImage: "scissors"),
    Category(name: "GATEGOTY_TECH", systemImage: "cpu.fill"),
    Category(name: "CATEGOTY_DESIGN", systemImage: "pencil.and.ruler.fill"),
    Category(name: "CATEGOTY_GAME", systemImage: "gamecontroller.fill"),
    Category(name: "CATEGORY_OTHER", systemImage: "square.grid.3x3.fill"),
]


