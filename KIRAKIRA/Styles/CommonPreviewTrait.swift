import SwiftUI

struct CommonPreviewTrait: PreviewModifier {
    struct Context {
        let globalState: GlobalStateManager
        let defaults: UserDefaults
    }

    static func makeSharedContext() throws -> Context {
        let suiteName = "Preview.Common"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)

        return Context(
            globalState: GlobalStateManager(),
            defaults: defaults
        )
    }

    func body(content: Content, context: Context) -> some View {
        content
            .environment(context.globalState)
            .defaultAppStorage(context.defaults)
    }
}

extension PreviewTrait where T == Preview.ViewTraits {
    @MainActor static var commonPreviewTrait: Self = .modifier(CommonPreviewTrait())
}
