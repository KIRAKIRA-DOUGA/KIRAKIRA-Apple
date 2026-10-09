import SwiftUI

enum Category: String, CaseIterable, Identifiable {
    case hot
    case latest
    case animation
    case music
    case otomad
    case tech
    case design
    case game
    case other

    var id: String { rawValue }

    var name: String {
        switch self {
        case .hot: String(localized: .hot)
        case .latest: String(localized: .latest)
        case .animation: String(localized: .categoryAnimation)
        case .music: String(localized: .categoryMusic)
        case .otomad: String(localized: .categoryOtomad)
        case .tech: String(localized: .categoryTech)
        case .design: String(localized: .categoryDesign)
        case .game: String(localized: .categoryGame)
        case .other: String(localized: .categoryOther)
        }
    }

    var systemImage: String {
        switch self {
        case .hot: "flame"
        case .latest: "plus.circle"
        case .animation: "circle.dotted.and.circle"
        case .music: "music.note"
        case .otomad: "waveform"
        case .tech: "cpu"
        case .design: "pencil.and.ruler"
        case .game: "gamecontroller"
        case .other: "square.grid.3x3"
        }
    }

    var color: Color {
        switch self {
        case .hot: .red
        case .latest: .red
        case .animation: .pink
        case .music: .purple
        case .otomad: .green
        case .tech: .blue
        case .design: .indigo
        case .game: .teal
        case .other: .accent
        }
    }
}
