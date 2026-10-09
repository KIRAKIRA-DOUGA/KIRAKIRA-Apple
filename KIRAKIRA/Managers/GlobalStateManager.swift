import Combine
import SwiftUI

@Observable
class GlobalStateManager {
    var mainTabSelection: MainTab = .home
    var isSplashFinished: Bool = false
    var isShowingSettings: Bool = false
    var settingsPath = NavigationPath()
    var isShowingLogin: Bool = false
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
