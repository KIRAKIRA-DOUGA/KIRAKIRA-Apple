import SwiftUI

struct HomeView: View {
    @StateObject private var viewModel = VideoViewModel()
    @State private var hasLoaded = false
    @EnvironmentObject var settingsManager: SettingsManager

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
            if settingsManager.videoDisplayStyle == .row {
                List(viewModel.videos) { video in
                    VideoItemView(video: video, style: .row)
                        .alignmentGuide(.listRowSeparatorLeading) { _ in
                            128 + 8  // Image width + spacing
                        }
                        .navigationLinkIndicatorVisibility(.hidden)
                }
                .listStyle(.plain)
            } else {
                let columns =
                if settingsManager.videoDisplayStyle == .card {
                    [GridItem(.adaptive(minimum: 240, maximum: 480))]
                } else if settingsManager.videoDisplayStyle == .smallCard {
                    [GridItem(.adaptive(minimum: 120, maximum: 240))]
                } else {
                    fatalError("Unreachable")
                }

                ScrollView {
                    LazyVGrid(
                        columns: columns,
                        alignment: .leading,
                        spacing: 16
                    ) {
                        ForEach(viewModel.videos) { video in
                            VideoItemView(video: video, style: settingsManager.videoDisplayStyle)
                                .frame(alignment: .top)
                        }
                    }
                    .padding()
                }
            }
        }
    }
}


#Preview {
    HomeView()
}
