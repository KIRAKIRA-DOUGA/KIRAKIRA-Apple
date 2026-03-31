import SwiftUI

struct FollowingFeedView: View {
    @Environment(GlobalStateManager.self) private var globalStateManager
    @Environment(\.horizontalSizeClass) private var horizontalSize
    @State private var authManager = AuthManager.shared

    var body: some View {
        NavigationStack {
            content
                .toolbar {
                    if horizontalSize == .compact {
                        ProfileToolbarItem()
                    }
                }
                .navigationTitle(.maintabFollowing)
                .toolbarTitleDisplayMode(.inlineLarge)
        }
    }

    @ViewBuilder
    private var content: some View {
        if authManager.isAuthenticated {
            followingFeed
        } else {
            loginPrompt
        }
    }
    
    @ViewBuilder
    private var followingFeed: some View {
        ScrollView {
            LazyVStack {
                ForEach(1...20, id: \.self) { _ in
                    // VideoListItemView()
                    EmptyView()
                }
            }.padding()
        }
    }

    @ViewBuilder
    private var loginPrompt: some View {
        ContentUnavailableView {
            Label(.maintabFollowing, systemImage: "rectangle.stack.fill")
        } description: {
            Text(.loginPromptFollowingFeed)
            Button(.logIn) {
                globalStateManager.isShowingLogin = true
            }
            .padding(.top)
        }
    }
}

#Preview(traits: .commonPreviewTrait) {
    MainView()
}
