import SwiftUI

struct HomeView: View {
    @Environment(\.horizontalSizeClass) private var horizontalSize
    @State private var viewModel: HomeFeedViewModel
    @State private var hasLoaded = false
    @Binding var isPlayerExpanded: Bool
    let animationNamespace: Namespace.ID

    init(
        isPlayerExpanded: Binding<Bool>,
        animationNamespace: Namespace.ID,
        repository: HomeRepository
    ) {
        _isPlayerExpanded = isPlayerExpanded
        self.animationNamespace = animationNamespace
        _viewModel = State(initialValue: HomeFeedViewModel(repository: repository))
    }

    var body: some View {
        content
            .navigationBarTitleDisplayMode(.large)
            .task {
                if !hasLoaded {
                    await viewModel.fetchHomeVideos()
                    hasLoaded = true
                }
            }
            .refreshable {
                await viewModel.fetchHomeVideos(isRefresh: true)
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

    @ViewBuilder
    private var content: some View {
        if viewModel.isLoading {
            VStack {
                Spacer()
                ProgressView()
                Spacer()
            }
        } else if let errorMessage = viewModel.errorMessage {
            ErrorView(errorMessage: errorMessage) {
                Task {
                    await viewModel.fetchHomeVideos()
                }
            }
        } else {
            HomeVideoListView(
                videos: viewModel.videos,
                isPlayerExpanded: $isPlayerExpanded,
                animationNamespace: animationNamespace,
            )
        }
    }
}

#Preview(traits: .commonPreviewTrait) {
    @Previewable @State var isPlayerExpanded: Bool = true
    @Previewable @Namespace var animationNamespace

    HomeView(
        isPlayerExpanded: $isPlayerExpanded,
        animationNamespace: animationNamespace,
        repository: AppDependencies(sessionStore: .shared).homeRepository
    )
}
