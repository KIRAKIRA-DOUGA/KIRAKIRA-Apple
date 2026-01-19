import SwiftUI

struct LaunchScreenView: View {
    var isShowing = true
    var isHitAllowed = true

    var body: some View {
        GeometryReader { proxy in
            let baseLogoWidth: CGFloat = 128
            let coverScale = (hypot(proxy.size.width, proxy.size.height) / baseLogoWidth) * 4

            ZStack {
                Rectangle()
                    .foregroundStyle(.launchScreenBackground)

                ZStack {
                    Image("Logo")
                        .resizable()
                        .foregroundStyle(.black)
                        .aspectRatio(contentMode: .fit)
                        .frame(width: baseLogoWidth)
                        .blendMode(.destinationOut)

                    // 白色层
                    Image("Logo")
                        .resizable()
                        .foregroundStyle(.launchScreenForeground)
                        .aspectRatio(contentMode: .fit)
                        .frame(width: baseLogoWidth)
                        .opacity(isShowing ? 1.0 : 0.0)
                }
                .scaleEffect(isShowing ? 1.0 : coverScale, anchor: .init(x: 0.285, y: 0.615))
                .animation(
                    .timingCurve(
                        .bezier(
                            startControlPoint: .init(x: 0.9, y: -0.05),
                            endControlPoint: .init(x: 0.9, y: 0.0)
                        ),
                        duration: 0.5
                    ),
                    value: isShowing
                )

                // debug用按钮 调试完记得注释掉
//                VStack {
//                    Spacer()
//                    Button(action: {
//                        var transaction = Transaction()
//                        transaction.disablesAnimations = true
//                        withTransaction(transaction) {
//                            isShowing = true
//                        }
//                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
//                            isShowing = false
//                        }
//                    }) {
//                        Image(systemName: "play.fill")
//                    }
//                    .controlSize(.large)
//                    .buttonBorderShape(.circle)
//                    .buttonStyle(.glass)
//                    .padding()
//                }
            }
            .allowsHitTesting(isHitAllowed)
            .ignoresSafeArea()
            .compositingGroup()
        }
    }
}

#Preview {
    LaunchScreenView()
}
