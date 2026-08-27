import SwiftUI
import RichText

struct DanmakuView: View {
    let videoId: Int
    let danmakuViewModel: DanmakuViewModel

    var body: some View {
        ZStack {
            switch danmakuViewModel.state {
            case .idle, .loading(previous: nil):
                LoadingView()
            case .success(let danmaku), .loading(previous: .some(let danmaku)):
                List(danmaku) { danmakuItem in
                    HStack {
                        Text(danmakuItem.time, format: .timeInterval)
                            .monospacedDigit()
                            .foregroundStyle(.secondary)
                        Spacer()
                        TextView(danmakuItem.text)
                    }
                }
            case .error(let msg):
                ErrorView(errorMessage: msg)
            default:
                Color.clear
            }
        }
        .animation(.easeInOut(duration: 0.25), value: danmakuViewModel.state)
        .listStyle(.plain)
        .refreshable {
            await danmakuViewModel.fetch(of: videoId)
        }
        .task {
            await danmakuViewModel.fetch(of: videoId)
        }
    }
}
