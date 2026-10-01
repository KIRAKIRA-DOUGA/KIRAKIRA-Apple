import SwiftUI
import VariableBlur

struct BannerView: View {
    let imageId: String?

    init(imageId: String? = nil) {
        self.imageId = imageId
    }

    var body: some View {
        VStack {
            Group {
                if let imageId, !imageId.isEmpty {
                    CFImageView(imageId: imageId)
                } else {
                    Image("DefaultBanner")
                        .resizable()
                }
            }
                .aspectRatio(contentMode: .fill)
                .frame(
                    minWidth: 0,
                    minHeight: 200,
                    maxHeight: 200
                )
                .aspectRatio(contentMode: .fit)
                .clipped()
                .overlay(alignment: .bottom) {
                    VariableBlurView(
                        maxBlurRadius: 10,
                        direction: .blurredBottomClearTop
                    ).frame(height: 50)
                }
                .mask(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color.black,
                            Color.black.opacity(0),
                        ]),
                        startPoint: .center,
                        endPoint: .bottom
                    )
                )
                .backgroundExtensionEffect()
        }
    }
}

#Preview {
    BannerView()
}
