import SwiftUI

struct VideoListView<Header: View>: View {
    @Environment(GlobalStateManager.self) private var globalStateManager
    @AppSetting(\.videoDisplayStyle) private var videoDisplayStyle
    let videos: [VideoListItemDTO]
    private let animationNamespace: Namespace.ID?
    private let header: () -> Header?

    init(
        videos: [VideoListItemDTO],
        animationNamespace: Namespace.ID? = nil,
        @ViewBuilder header: @escaping () -> Header? = { nil }
    ) {
        self.videos = videos
        self.animationNamespace = animationNamespace
        self.header = header
    }

    var body: some View {
        switch videoDisplayStyle {
        case .row:
            rowList
        case .card, .smallCard:
            gridList
        }
    }

    private var rowList: some View {
        List {
            if let headerView = header() {
                headerView
                    .listRowSeparator(.hidden)
            }

            ForEach(videos) { video in
                Button {
                    play(video)
                } label: {
                    videoContent(for: video, style: .row)
                        .alignmentGuide(.listRowSeparatorLeading) { _ in
                            128 + 8  // Image width + spacing
                        }
                        .navigationLinkIndicatorVisibility(.hidden)
                }
            }
        }
        .listStyle(.plain)
    }

    private var gridList: some View {
        ScrollView {
            if let headerView = header() {
                headerView
                    .padding(.horizontal)
            }

            LazyVGrid(
                columns: gridColumns,
                alignment: .leading,
                spacing: 16
            ) {
                ForEach(videos) { video in
                    Button {
                        play(video)
                    } label: {
                        videoContent(for: video, style: videoDisplayStyle)
                            .frame(alignment: .top)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding()
        }
    }

    private var gridColumns: [GridItem] {
        switch videoDisplayStyle {
        case .card:
            return [GridItem(.adaptive(minimum: 240, maximum: 480))]
        case .smallCard:
            return [GridItem(.adaptive(minimum: 120, maximum: 240))]
        case .row:
            return []
        }
    }

    @ViewBuilder
    private func videoContent(for video: VideoListItemDTO, style: ViewStyle) -> some View {
        let content = VideoListItemView(video: video, style: style)
        if let animationNamespace {
            content
                .matchedTransitionSource(id: video.videoId, in: animationNamespace)
        } else {
            content
        }
    }

    private func play(_ video: VideoListItemDTO) {
        globalStateManager.playingVideo = video.videoId
        globalStateManager.isPlayerExpanded = true
    }
}

extension VideoListView where Header == EmptyView {
    init(videos: [VideoListItemDTO], animationNamespace: Namespace.ID? = nil) {
        self.init(videos: videos, animationNamespace: animationNamespace) {
            EmptyView()
        }
    }
}
