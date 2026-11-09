import Foundation

enum VideoCategory: String, CaseIterable {
    case anime
    case music
    case otomad
    case tech
    case design
    case game
    case misc

    var title: LocalizedStringResource {
        switch self {
        case .anime: .categoryAnimation
        case .music: .categoryMusic
        case .otomad: .categoryOtomad
        case .tech: .categoryTech
        case .design: .categoryDesign
        case .game: .categoryGame
        case .misc: .categoryMisc
        }
    }
}
