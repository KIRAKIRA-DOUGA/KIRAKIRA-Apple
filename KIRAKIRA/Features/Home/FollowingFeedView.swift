import SwiftUI

struct FollowingFeedView: View {
    @Environment(AppRouter.self) private var appRouter
    @Environment(AuthManager.self) private var authManager
    @Environment(\.horizontalSizeClass) private var horizontalSize

    var body: some View {
        content
            .toolbar {
                if horizontalSize == .compact {
                    ProfileToolbarItem()
                }
            }
            .navigationTitle(.maintabFollowing)
            .toolbarTitleDisplayMode(.inlineLarge)
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
                appRouter.isShowingLogin = true
            }
            .padding(.top)
        }
    }
}

#Preview(traits: .commonPreviewTrait) {
    MainView(dependencies: AppDependencies(sessionStore: .shared))
}
