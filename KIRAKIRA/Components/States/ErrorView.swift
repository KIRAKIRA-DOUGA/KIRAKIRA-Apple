import SwiftUI

struct ErrorView: View {
    let errorMessage: String
    @Environment(\.refresh) private var refresh

    var body: some View {
        ContentUnavailableView {
            Label(errorMessage, systemImage: "xmark.octagon.fill")
                .symbolRenderingMode(.multicolor)
        } description: {
            Button(.errorTryAgain) {
                Task {
                    await refresh?()
                }
            }
            .padding(.top)
        }
    }
}

#Preview {
    ErrorView(errorMessage: "测试错误")
}
