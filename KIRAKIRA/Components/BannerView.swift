import SwiftUI
import VariableBlur

struct BannerView: View {
    var body: some View {
        VStack {
            Image("DefaultBanner")
                .resizable()
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
