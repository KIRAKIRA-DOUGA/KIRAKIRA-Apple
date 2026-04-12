import SwiftUI
import SwiftUIIntrospect

struct LoadingView: View {
    @State private var isShowingProgress: Bool = false

    var body: some View {
        VStack {
            Spacer()
            if isShowingProgress {
                ProgressView()
                    .introspect(.progressView(style: .circular), on: .iOS(.v26)) { UIActivityIndicatorView in
                        UIActivityIndicatorView.style = .large
                    }  // 细致的你一定发现了设置controlSize为.large的和UIKit层的设置了style为.large的看上去不一样，UIKit每一瓣都比SwiftUI的小一像素。
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
