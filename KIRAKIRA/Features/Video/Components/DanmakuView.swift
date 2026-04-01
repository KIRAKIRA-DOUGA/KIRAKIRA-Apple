import RichText
import SwiftUI

struct DanmakuView: View {
    let videoId: Int
    let danmakuViewModel: DanmakuListViewModel

    var body: some View {
        Group {
            if danmakuViewModel.isLoading {
                VStack {
                    Spacer()
                    ProgressView()
                    Spacer()
                }
            } else if let errorMessage = danmakuViewModel.errorMessage {
                ErrorView(errorMessage: errorMessage) {
                    Task {
                        await danmakuViewModel.loadIfNeeded(videoID: videoId)
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
                    await danmakuViewModel.load(videoID: videoId, isRefresh: true)
                }
            }
        }
        .listStyle(.plain)
        .task {
            await danmakuViewModel.loadIfNeeded(videoID: videoId)
        }
    }
}
