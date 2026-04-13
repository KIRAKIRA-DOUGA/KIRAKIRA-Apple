// 细致的你一定发现了「ProgressView.controlSize(.large)」和「UIActivityIndicatorView(style: .large)」看上去不一样。
// SwiftUI 每一瓣都比 UIKit 的大了一点，造成中心很小。
// 根据官方设计文档，它应该是长 UIKit 的样子才对，因此我们不使用 ProgressView。

import SwiftUI

private struct ActivityIndicator: UIViewRepresentable {
    func makeUIView(context: Context) -> UIActivityIndicatorView {
        let view = UIActivityIndicatorView(style: .large)
        return view
    }
    
    func updateUIView(_ uiView: UIActivityIndicatorView, context: Context) {
        uiView.startAnimating()
    }
}

struct LoadingView: View {
    @State private var isShowingProgress: Bool = false

    var body: some View {
        VStack {
            Spacer()
            if isShowingProgress {
                ActivityIndicator()
            }
            Spacer()
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                withAnimation {
                    isShowingProgress = true
                }
            }
        }
    }
}

#Preview {
    LoadingView()
}
