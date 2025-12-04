import Observation
import SwiftUI
import UIKit

final class AppearanceManager {
    @AppSetting(\.globalColorScheme) private var selectedScheme

    @MainActor
    func updateWindowStyle() {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene else {
            return
        }

        for window in windowScene.windows {
            window.overrideUserInterfaceStyle = selectedScheme.uiColorScheme
        }
    }
}

extension GlobalColorScheme {
    var uiColorScheme: UIUserInterfaceStyle {
        switch self {
        case .auto:
            return .unspecified
        case .light:
            return .light
        case .dark:
            return .dark
        }
    }
}
