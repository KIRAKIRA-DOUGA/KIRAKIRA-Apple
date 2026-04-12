import SwiftUI

struct HomeView: View {
    @Environment(\.horizontalSizeClass) private var horizontalSize
    @Environment(GlobalStateManager.self) private var globalStateManager
    @State private var homeVideoViewModel = HomeVideoViewModel()
    let animationNamespace: Namespace.ID

    var body: some View {
        NavigationStack {
            Group {
                switch homeVideoViewModel.state {
                case .success(let videos) where globalStateManager.isSplashFinished,
                    .loading(previous: .some(let videos)) where globalStateManager.isSplashFinished:
                    HomeVideoListView(
                        videos: videos,
                        animationNamespace: animationNamespace,
                    )
                    .transition(.opacity)
                case .idle, .loading, .success:
                    LoadingView()
                case .error(let msg):
                    ErrorView(errorMessage: msg)
                default:
                    Color.clear
                }
            }
            .animation(.default, value: homeVideoViewModel.state)
            .animation(.default, value: globalStateManager.isSplashFinished)
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
                        .padding(.leading, -6)
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
