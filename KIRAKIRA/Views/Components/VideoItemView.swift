import Flow
import SwiftUI

struct VideoItemView: View {
    let video: VideoListItemDTO
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

                Spacer()

                metadata
            }
        }
    }

    @ViewBuilder
    private var cardLayout: some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: 8) {
                CFImageView(imageId: video.image)
                    .aspectRatio(16 / 9, contentMode: .fit)
                    .clipShape(RoundedRectangle(cornerRadius: 16))

                Text(video.title)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
            }

            Spacer(minLength: 0)

            metadata
        }
        .frame(maxHeight: 480, alignment: .top)
    }

    @ViewBuilder
    private var metadata: some View {
        HFlow(rowSpacing: 4) {
            Label {
                Text(video.uploaderNickname)
            } icon: {
                Image(systemName: "person.fill")
            }
            .lineLimit(1)

            LineBreak()

            Label {
                Text("0")  // Views placeholder
            } icon: {
                Image(systemName: "play.fill")
            }
            .lineLimit(1)

            Label {
                Text("5:00")  // Duration placeholder
            } icon: {
                Image(systemName: "clock")
            }
            .lineLimit(1)

            Label {
                Text(video.uploadDate, style: .date)
            } icon: {
                Image(systemName: "calendar")
            }
            .lineLimit(1)
        }
        .labelIconToTitleSpacing(4)
        .labelReservedIconWidth(20)
        .foregroundStyle(.secondary)
        .font(.caption)
        .imageScale(.small)
    }
}
