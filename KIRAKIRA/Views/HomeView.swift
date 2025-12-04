import SwiftUI

struct HomeView: View {
    @State private var viewModel = VideoViewModel()
    @State private var hasLoaded = false
    @Binding var isPlayerExpanded: Bool
    let animationNamespace: Namespace.ID

    var body: some View {
        NavigationStack {
            content
                .navigationTitle("KIRAKIRA")
                .task {
                    if !hasLoaded {
                        await viewModel.fetchHomeVideos()
                        hasLoaded = true
                    }
                }
                .refreshable {
                    await viewModel.fetchHomeVideos()
                }
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        LogoIcon()
                            .frame(width: 40, height: 40)
                            .foregroundStyle(.accent)
                            .padding(.leading, -8)
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
            VStack(spacing: 16) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.largeTitle)
                    .foregroundStyle(.red)
                Text(errorMessage)
                Button("Try Again") {
                    Task {
                        await viewModel.fetchHomeVideos()
                    }
                }
                .buttonStyle(.borderedProminent)
            }
        } else {
            HomeVideoListView(
                videos: viewModel.videos,
                isPlayerExpanded: $isPlayerExpanded,
                animationNamespace: animationNamespace
            )
        }
    }
}

#Preview(traits: .commonPreviewTrait) {
    @Previewable @State var isPlayerExpanded: Bool = true
    @Previewable @Namespace var animationNamspace

    HomeView(isPlayerExpanded: $isPlayerExpanded, animationNamespace: animationNamspace)
}
