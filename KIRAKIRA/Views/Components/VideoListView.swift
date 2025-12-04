import SwiftUI

struct VideoListView<Header: View>: View {
    @Environment(GlobalStateManager.self) private var globalStateManager
    @AppSetting(\.videoDisplayStyle) private var videoDisplayStyle
    let videos: [VideoListItemDTO]
    @Binding var isPlayerExpanded: Bool
    let animationNamespace: Namespace.ID
    @ViewBuilder let header: Header?

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
            if let header {
                header
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
            if let header {
                header
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
        content
            .matchedTransitionSource(id: AnimationTransitionSource.video(video.videoId), in: animationNamespace)
    }

    private func play(_ video: VideoListItemDTO) {
        globalStateManager.selectedVideo = video.videoId
        globalStateManager.activeTransitionSource = .video(video.videoId)
        isPlayerExpanded = true
    }
}
