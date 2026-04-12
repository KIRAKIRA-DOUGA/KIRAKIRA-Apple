import SwiftUI

struct HomeView: View {
    @Environment(\.horizontalSizeClass) private var horizontalSize
    @State private var homeVideoViewModel = HomeVideoViewModel()
    let animationNamespace: Namespace.ID

    var body: some View {
        NavigationStack {
            content
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

    @ViewBuilder
    private var content: some View {
        Group {
            switch homeVideoViewModel.state {
            case .idle, .loading(previous: nil):
                LoadingView()
            case .success(let videos), .loading(previous: .some(let videos)):
                HomeVideoListView(
                    videos: videos,
                    animationNamespace: animationNamespace,
                )
            case .error(let msg):
                ErrorView(errorMessage: msg)
            default:
                Color.clear
            }
        }
        .animation(.default, value: homeVideoViewModel.state)
    }
}

#Preview(traits: .commonPreviewTrait) {
    @Previewable @State var isPlayerExpanded: Bool = true
    @Previewable @Namespace var animationNamespace

    HomeView(animationNamespace: animationNamespace)
}
