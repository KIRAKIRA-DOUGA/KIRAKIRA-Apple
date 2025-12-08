import Flow
import SwiftUI

struct VideoListItemView: View {
    let video: ThumbVideoItem
    let style: ViewStyle

    var body: some View {
        switch style {
        case .row:
            rowLayout
        case .card, .smallCard:
            cardLayout
        }
    }

    @ViewBuilder
    private var rowLayout: some View {
        HStack(spacing: 8) {
            CFImageView(imageId: video.image)
                .frame(width: 128, height: 72)
                .clipShape(RoundedRectangle(cornerRadius: 12))

            VStack(alignment: .leading, spacing: 8) {
                Text(video.title)
                    .lineLimit(4)

                metadata
                    .labelReservedIconWidth(20)
            }
        }
    }

    @ViewBuilder
    private var cardLayout: some View {
        VStack(alignment: .leading, spacing: 8) {
            CFImageView(imageId: video.image)
                .aspectRatio(16 / 9, contentMode: .fit)
                .clipShape(RoundedRectangle(cornerRadius: 16))

            Text(video.title)
                .lineLimit(2, reservesSpace: true)
                .multilineTextAlignment(.leading)

            metadata
                .labelReservedIconWidth(16)
        }
    }

    @ViewBuilder
    private var metadata: some View {
        HFlow(rowSpacing: 4) {
            Label {
                Text(video.uploaderNickname ?? "Anonymous User")
            } icon: {
                Image(systemName: "person")
            }
            .lineLimit(1)

            LineBreak()

            if let watchedCount = video.watchedCount {
                Label {
                    Text(watchedCount, format: .number)
                } icon: {
                    Image(systemName: "play")
                }
                .lineLimit(1)
            }

            if let duration = video.duration {
                Label {
                    Text(duration, format: .timeInterval)
                } icon: {
                    Image(systemName: "clock")
                }
                .lineLimit(1)
            }

            if let uploadDate = video.uploadDate {
                Label {
                    Text(uploadDate, style: .date)
                } icon: {
                    Image(systemName: "calendar")
                }
                .lineLimit(1)
            }
        }
        .labelIconToTitleSpacing(4)
        .foregroundStyle(.secondary)
        .font(.caption)
    }
}

#Preview(traits: .commonPreviewTrait) {
    MainView()
}
