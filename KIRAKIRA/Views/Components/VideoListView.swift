import SwiftUI

struct VideoListView: View {
    @EnvironmentObject private var settingsManager: SettingsManager
    let videos: [VideoListItemDTO]

    var body: some View {
        if settingsManager.videoDisplayStyle == .row {
            List(videos) { video in
                VideoListItemView(video: video, style: .row)
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
                    ForEach(videos) { video in
                        VideoListItemView(video: video, style: settingsManager.videoDisplayStyle)
                            .frame(alignment: .top)
                    }
                }
                .padding()
            }
        }
    }
}
