import SwiftUI

struct ErrorView: View {
    let errorMessage: String
    let retry: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.largeTitle)
                .foregroundStyle(.red)
            Text(errorMessage)
            Button("ERROR_TRY_AGAIN") {
                retry()
            }
            .buttonStyle(.borderedProminent)
        }
    }
}
