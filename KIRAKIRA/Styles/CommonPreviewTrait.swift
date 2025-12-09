import SwiftUI

struct CommonPreviewTrait: PreviewModifier {
    static func makeSharedContext() throws -> GlobalStateManager {
        return GlobalStateManager()
    }

    func body(content: Content, context: GlobalStateManager) -> some View {
        content
            .environment(context)
    }
}

extension PreviewTrait where T == Preview.ViewTraits {
    @MainActor static var commonPreviewTrait: Self = .modifier(CommonPreviewTrait())
}
