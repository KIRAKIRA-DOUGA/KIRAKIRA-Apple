import RichText
import SwiftUI
import SwiftUIIntrospect

struct CommentsView: View {
    let videoId: Int
    let commentViewModel: CommentListViewModel
    @Environment(AppUIState.self) private var appUIState
    @State private var sendContent: String = ""

    private func sendComment() {
        sendContent = ""
    }

    var body: some View {
        Group {
            if commentViewModel.isLoading {
                VStack {
                    Spacer()
                    ProgressView()
                    Spacer()
                }
            } else if let errorMessage = commentViewModel.errorMessage {
                ErrorView(errorMessage: errorMessage) {
                    Task {
                        await commentViewModel.load(videoID: videoId)
                    }
                }
            } else {
                List(commentViewModel.comments) { comment in
                    CommentItemView(comment: comment)
                }
                .refreshable {
                    await commentViewModel.load(videoID: videoId, isRefresh: true)
                }
            }
        }
        .task {
            await commentViewModel.loadIfNeeded(videoID: videoId)
        }
        .safeAreaBar(edge: .bottom) {
            SendTextField(
                text: $sendContent,
                prompt: .comment,
                onSend: { sendComment() },
                showAddButton: true
            )
            .padding(.horizontal)
            .padding(.bottom, appUIState.isShowingKeyboard ? 16 : 0)
        }
        .listStyle(.plain)
        .scrollDismissesKeyboard(.immediately)
    }
}

#Preview(traits: .commonPreviewTrait) {
    NavigationStack {
        CommentsView(
            videoId: 1,
            commentViewModel: CommentListViewModel(repository: AppDependencies(sessionStore: .shared).videoRepository)
        )
    }
}
