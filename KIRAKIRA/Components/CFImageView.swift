import Kingfisher
import SwiftUI
import os

enum CFImageURLBuilder {
    private static let deliveryBaseURL = URL(
        string: "https://kirafile.com/cdn-cgi/imagedelivery/Gyz90amG54C4b_dtJiRpYg/"
    )!

    static func url(for imageId: String?, pixelWidth: Int? = nil) -> URL? {
        guard let imageId, !imageId.isEmpty else { return nil }

        let baseURL = deliveryBaseURL.appendingPathComponent(imageId)
        if let pixelWidth {
            return baseURL.appendingPathComponent("w=\(pixelWidth),f=auto")
        }
        return baseURL.appendingPathComponent("f=auto")
    }
}

struct CFImageView: View {
    let imageId: String?

    @Environment(\.displayScale) var displayScale

    var body: some View {
        GeometryReader { geometry in
            KFImage(buildURL(for: geometry.size, lowResolution: false))
                .placeholder {
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                }
                .cancelOnDisappear(true)
                .fade(duration: 0.25)
                .resizable(resizingMode: .stretch)
        }
    }

    /// Constructs the final Cloudflare URL with size and format variants.
    private func buildURL(for size: CGSize, lowResolution: Bool?) -> URL? {
        let pixelWidth: Int? =
            switch ceil(size.width * displayScale) {
            case 0..<240: 240
            case 240..<480: 480
            case 480..<720: 720
            case 720..<1080: 1080
            case 1080..<2160: 2160
            default: nil
            }

        return CFImageURLBuilder.url(for: imageId, pixelWidth: pixelWidth)
    }
}

struct UserAvatarView: View {
    let imageId: String?

    var body: some View {
        Group {
            if let imageId, !imageId.isEmpty {
                CFImageView(imageId: imageId)
            } else {
                Image(systemName: "person.crop.circle.fill")
                    .resizable()
                    .scaledToFit()
                    .foregroundStyle(.secondary)
            }
        }
        .clipShape(Circle())
    }
}

#Preview {
    CFImageView(imageId: "video-cover-1-bgIW1F8TToVkXmH0xY5GoiUWuHWtt0j8-1722614549190")
}
