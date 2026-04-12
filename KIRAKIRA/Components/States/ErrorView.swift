import SwiftUI

struct ErrorView: View {
    let errorMessage: String
    let retry: () -> Void

    var body: some View {
        ContentUnavailableView {
            Label(errorMessage, systemImage: "xmark.octagon.fill")
                .symbolRenderingMode(.multicolor)
        } description: {
            Button(.errorTryAgain) {
                retry()
            }
            .padding(.top)
        }
    }
}

#Preview {
    ErrorView(errorMessage: "测试错误", retry: {})
}
