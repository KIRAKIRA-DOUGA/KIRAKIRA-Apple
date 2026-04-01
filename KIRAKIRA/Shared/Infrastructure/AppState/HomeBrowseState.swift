import SwiftUI

@Observable
final class HomeBrowseState {
    var selectedCategory: Category = categories.first!
}

struct Category: Identifiable, Hashable {
    var id = UUID()
    var name: String
    var systemImage: String
}

let categories: [Category] = [
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
