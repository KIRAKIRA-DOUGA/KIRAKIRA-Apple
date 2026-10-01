import SwiftUI

struct DanmakuView: View {
    let videoId: Int
    let danmakuViewModel: DanmakuViewModel

    var body: some View {
        List(danmakuViewModel.state.value ?? []) { danmakuItem in
            HStack {
                Text(danmakuItem.time, format: .timeInterval)
                    .monospacedDigit()
                    .foregroundStyle(.secondary)
                Spacer()
                Text(danmakuItem.text)
                    .textSelection(.enabled)
            }
        }
        .overlay {
            switch danmakuViewModel.state {
            case .idle, .loading(previous: nil):
                LoadingView()
            case .error(let msg):
                ErrorView(errorMessage: msg)
            default:
                EmptyView()
            }
        }
        .animation(.easeInOut(duration: 0.25), value: danmakuViewModel.state)
        .listStyle(.plain)
        .refreshable {
            await danmakuViewModel.fetch(of: videoId)
        }
    }
}
