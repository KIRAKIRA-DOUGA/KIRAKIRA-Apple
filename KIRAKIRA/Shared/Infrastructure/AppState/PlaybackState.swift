import SwiftUI

@Observable
final class PlaybackState {
    var selectedVideo: Int?
    var activeTransitionSource: AnimationTransitionSource = .none
}

enum AnimationTransitionSource: Hashable {
    case video(Int)
    case none
}
