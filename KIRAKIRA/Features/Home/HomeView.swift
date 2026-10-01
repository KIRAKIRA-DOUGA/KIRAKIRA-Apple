import SwiftUI

struct HomeView: View {
    @Environment(\.horizontalSizeClass) private var horizontalSize
    @Environment(GlobalStateManager.self) private var globalStateManager
    @State private var homeVideoViewModel = HomeVideoViewModel()
    let animationNamespace: Namespace.ID

    var body: some View {
        NavigationStack {
            HomeVideoListView(
                videos: homeVideoViewModel.state.value ?? [],
                animationNamespace: animationNamespace,
            )
            .opacity(homeVideoViewModel.state.value != nil && globalStateManager.isSplashFinished ? 1 : 0)
            .overlay {
                switch homeVideoViewModel.state {
                case .success where globalStateManager.isSplashFinished,
                    .loading(previous: .some) where globalStateManager.isSplashFinished:
                    EmptyView()
                case .idle, .loading, .success:
                    LoadingView()
                case .error(let msg):
                    ErrorView(errorMessage: msg)
                default:
                    EmptyView()
                }
            }
            .animation(.easeInOut(duration: 0.25), value: homeVideoViewModel.state)
            .animation(.easeInOut(duration: 0.25), value: globalStateManager.isSplashFinished)
            .navigationBarTitleDisplayMode(.large)
            .task {
                await homeVideoViewModel.fetch()
            }
            .refreshable {
                await homeVideoViewModel.fetch()
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    LogoIcon()
                        .frame(width: 48, height: 48)
                        .foregroundStyle(.accent)
                        .padding(.leading, -2)
                }
                .sharedBackgroundVisibility(.hidden)

                ToolbarItem(placement: .largeTitle) {
                    HStack {
                        Image("BrandingText")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(height: 28)
                            .padding(.vertical)

                        Spacer()
                    }
                    .foregroundStyle(.accent)
                }

                if horizontalSize == .compact {
                    ProfileToolbarItem()
                }
            }
        }
    }
}

#Preview(traits: .commonPreviewTrait) {
    @Previewable @State var isPlayerExpanded: Bool = true
    @Previewable @Namespace var animationNamespace

    HomeView(animationNamespace: animationNamespace)
}
