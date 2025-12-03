import SwiftUI

struct HomeView: View {
    @State private var viewModel = VideoViewModel()
    @State private var hasLoaded = false
    let animationNamespace: Namespace.ID

    var body: some View {
        NavigationStack {
            content
                .navigationTitle("KIRAKIRA")
                .toolbarTitleDisplayMode(.inlineLarge)
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
                    ToolbarItem(placement: .largeTitle) {
                        HStack {
                            LogoIcon()
                                .frame(width: 32, height: 32)

                            Text("KIRAKIRA")
                                .font(.largeTitle)
                                .fontWeight(.semibold)

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
                ProgressView("Loading videos...")
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
            HomeVideoListView(videos: viewModel.videos, animationNamespace: animationNamespace)
        }
    }
}

#Preview(traits: .commonPreviewTrait) {
    @Previewable @Namespace var animationNamspace

    HomeView(animationNamespace: animationNamspace)
}
