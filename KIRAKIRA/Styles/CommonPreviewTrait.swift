import SwiftUI

struct PreviewAppContext {
    let appRouter: AppRouter
    let appUIState: AppUIState
    let playbackState: PlaybackState
    let homeBrowseState: HomeBrowseState
    let dependencies: AppDependencies
}

struct CommonPreviewTrait: PreviewModifier {
    @MainActor
    static func makeSharedContext() throws -> PreviewAppContext {
        PreviewAppContext(
            appRouter: AppRouter(),
            appUIState: AppUIState(),
            playbackState: PlaybackState(),
            homeBrowseState: HomeBrowseState(),
            dependencies: AppDependencies(sessionStore: .shared)
        )
    }

    func body(content: Content, context: PreviewAppContext) -> some View {
        content
            .environment(context.appRouter)
            .environment(context.appUIState)
            .environment(context.playbackState)
            .environment(context.homeBrowseState)
            .environment(context.dependencies.authManager)
    }
}

extension PreviewTrait where T == Preview.ViewTraits {
    @MainActor static var commonPreviewTrait: Self = .modifier(CommonPreviewTrait())
}
