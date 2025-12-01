import SwiftUI

struct HomeView: View {
    @StateObject private var viewModel = VideoViewModel()
    @State private var hasLoaded = false
    let animationNamespace: Namespace.ID

    var body: some View {
        NavigationStack {
            content
                .navigationTitle("Home")
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
                #if os(macOS)
                    .toolbar {
                        ToolbarItem {
                            Button {
                                Task {
                                    await viewModel.fetchHomeVideos()
                                }
                            } label: {
                                Label("Refresh", systemImage: "arrow.clockwise")
                            }
                        }
                    }
                #endif
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
