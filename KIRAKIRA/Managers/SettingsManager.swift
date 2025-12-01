import Combine
import SwiftUI

@MainActor
class SettingsManager: ObservableObject {
    static let shared = SettingsManager()

    @AppStorage("sidebarCustomization") var tabViewCustomization: TabViewCustomization
    @AppStorage("videoDisplayStyle") var videoDisplayStyle: ViewStyle = .card
    @AppStorage("isFirstLaunch") var isFirstLaunch: Bool = true

    private init() {}
}

enum ViewStyle: String, CaseIterable, Identifiable {
    case row
    case card
    case smallCard

    var id: String { rawValue }

    var displayName: LocalizedStringKey {
        switch self {
        case .row:
            return "Row"
        case .card:
            return "Card"
        case .smallCard:
            return "Small Card"
        }
    }
}
