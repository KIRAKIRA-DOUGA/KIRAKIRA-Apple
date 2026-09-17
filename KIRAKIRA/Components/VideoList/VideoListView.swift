import SwiftUI

struct VideoListView<Header: View>: View {
    @Environment(GlobalStateManager.self) private var globalStateManager
    @AppSetting(\.videoDisplayStyle) private var videoDisplayStyle
    let videos: [ThumbVideoItem]
    let animationNamespace: Namespace.ID
    let uploaderNameOverride: String?
    let headerHorizontalPadding: Bool
    let isEmbedded: Bool
    @ViewBuilder let header: Header

    init(
        videos: [ThumbVideoItem],
        animationNamespace: Namespace.ID,
        uploaderNameOverride: String? = nil,
        headerHorizontalPadding: Bool = true,
        isEmbedded: Bool = false,
        @ViewBuilder header: () -> Header
    ) {
        self.videos = videos
        self.animationNamespace = animationNamespace
        self.uploaderNameOverride = uploaderNameOverride
        self.headerHorizontalPadding = headerHorizontalPadding
        self.isEmbedded = isEmbedded
        self.header = header()
    }

    @ViewBuilder
    var body: some View {
        if isEmbedded {
            embeddedContent
        } else {
            switch videoDisplayStyle {
            case .row:
                rowList
            case .card, .smallCard:
                gridList
            }
        }
    }

    @ViewBuilder
    private var embeddedContent: some View {
        header

        switch videoDisplayStyle {
        case .row:
            LazyVStack(spacing: 0) {
                ForEach(videos) { video in
                    Button {
                        play(video)
                    } label: {
                        videoContent(for: video, style: .row)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal)
                    .padding(.vertical, 8)

                    if video.id != videos.last?.id {
                        Divider()
                            .padding(.leading, 152)
                    }
                }
            }
        case .card, .smallCard:
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
            .padding(.horizontal)
            .padding(.bottom)
        }
    }

    private var rowList: some View {
        List {
            header
                .listRowSeparator(.hidden)

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
            if headerHorizontalPadding {
                header
                    .padding(.horizontal)
            } else {
                header
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
    private func videoContent(for video: ThumbVideoItem, style: ViewStyle) -> some View {
        let content = VideoListItemView(
            video: video,
            style: style,
            uploaderNameOverride: uploaderNameOverride
        )
        content
            .matchedTransitionSource(id: AnimationTransitionSource.video(video.videoId), in: animationNamespace)
    }
    
    private func play(_ video: ThumbVideoItem) {
        globalStateManager.selectedVideo = video.videoId
        globalStateManager.activeTransitionSource = .video(video.videoId)
        globalStateManager.isPlayerExpanded = true
    }
}
