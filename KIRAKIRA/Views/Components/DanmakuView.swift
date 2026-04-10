import SwiftUI
import RichText

struct DanmakuView: View {
    let videoId: Int
    let danmakuViewModel: DanmakuViewModel

    var body: some View {
        Group {
            if danmakuViewModel.isLoading {
                VStack {
                    Spacer()
                    ProgressView()
                        .controlSize(.large)
                    Spacer()
                }
            } else if let errorMessage = danmakuViewModel.errorMessage {
                ErrorView(errorMessage: errorMessage) {
                    Task {
                        await danmakuViewModel.fetchVideoDanmakuIfNeeded(of: videoId)
                    }
                }
            } else {
                List(danmakuViewModel.danmaku) { danmakuItem in
                    HStack {
                        Text(danmakuItem.time, format: .timeInterval)
                            .monospacedDigit()
                            .foregroundStyle(.secondary)
                        Spacer()
                        TextView(danmakuItem.text)
                    }
                }
                .refreshable {
                    await danmakuViewModel.fetchVideoDanmaku(of: videoId, isRefresh: true)
                }
            }
        }
        .listStyle(.plain)
        .task {
            await danmakuViewModel.fetchVideoDanmaku(of: videoId)
        }
    }
}
