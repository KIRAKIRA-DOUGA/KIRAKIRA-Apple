import SwiftUI

struct FollowingFeedView: View {
    @Environment(GlobalStateManager.self) private var globalStateManager
    @Environment(\.horizontalSizeClass) private var horizontalSize

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack {
                    ForEach(1...20, id: \.self) { _ in
                        // VideoListItemView()
                        EmptyView()
                    }
                }.padding()
            }
            .navigationTitle(.maintabFollowing)
            .toolbarTitleDisplayMode(.inlineLarge)
            .toolbar {
                if horizontalSize == .compact {
                    ProfileToolbarItem()
                }
            }
        }
    }
}

#Preview(traits: .commonPreviewTrait) {
    MainView()
}
