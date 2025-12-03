import Combine
import SwiftUI

@Observable
class GlobalStateManager {
    var mainTabSelection: MainTab = .home
    var selectedCategory: Category = categories.first!
    var isPlayerExpanded: Bool = false
    var playingVideo: Int? // Video ID
}

enum MainTab: Hashable {
    case home
    case feed
    case messages
    case me
    case search
}

struct Category: Identifiable, Hashable {
    var id = UUID()
    var name: String
    var systemImage: String
}

let categories: [Category] = [
    Category(name: "Popular", systemImage: "flame"),
    Category(name: "Animation", systemImage: "wand.and.rays"),
    Category(name: "Music", systemImage: "music.note"),
    Category(name: "MAD", systemImage: "scissors"),
    Category(name: "Tech", systemImage: "cpu.fill"),
    Category(name: "Design", systemImage: "pencil.and.ruler.fill"),
    Category(name: "Game", systemImage: "gamecontroller.fill"),
    Category(name: "Other", systemImage: "square.grid.3x3.fill"),
]
