import SwiftUI

struct ErrorView: View {
    let errorMessage: String
    let retry: () -> Void

    var body: some View {
        ContentUnavailableView {
            Label(errorMessage, systemImage: "exclamationmark.triangle.fill")
        } description: {
            Button(.errorTryAgain) {
                retry()
            }
            .buttonStyle(.bordered)
            .padding(.top)
        }
    }
}

#Preview {
    ErrorView(errorMessage: "测试错误", retry: {})
}
