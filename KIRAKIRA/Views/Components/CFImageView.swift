import Kingfisher
import SwiftUI
import os

struct CFImageView: View {
    let imageId: String

    @Environment(\.displayScale) var displayScale

    var body: some View {
        GeometryReader { geometry in
            KFImage(buildURL(for: geometry.size))
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
    private func buildURL(for size: CGSize) -> URL? {
        let baseURL = URL(string: "https://kirafile.com/cdn-cgi/imagedelivery/Gyz90amG54C4b_dtJiRpYg/")!
            .appendingPathComponent(imageId)
        let pixelWidth: Int? =
            switch ceil(size.width * displayScale) {
            case 0..<240: 240
            case 240..<480: 480
            case 480..<720: 720
            case 720..<1080: 1080
            case 1080..<2160: 2160
            default: nil
            }

        if let pixelWidth {
            return baseURL.appendingPathComponent("/w=\(pixelWidth),f=auto")
        } else {
            return baseURL.appendingPathComponent("/f=auto")
        }

    }
}

#Preview {
    CFImageView(imageId: "video-cover-1-bgIW1F8TToVkXmH0xY5GoiUWuHWtt0j8-1722614549190")
}
