import RichText
import SwiftUI
import SwiftUIIntrospect

struct CommentsView: View {
    let videoId: Int
    @Environment(GlobalStateManager.self) private var globalStateManager
    @State private var sendContent: String = ""
    @State private var commentViewModel = CommentViewModel()

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
                        await commentViewModel.fetchVideoComment(of: videoId)
                    }
                }
            } else {
                List(commentViewModel.comments) { comment in
                    CommentItemView(comment: comment)
                }
                .refreshable {
                    Task {
                        await commentViewModel.fetchVideoComment(of: videoId)
                    }
                }
            }
        }
        .task {
            await commentViewModel.fetchVideoComment(of: videoId)
        }
        .safeAreaBar(edge: .bottom) {
            SendTextField(
                text: $sendContent,
                prompt: .comment,
                onSend: { sendComment() },
                showAddButton: true
            )
            .padding(.horizontal)
            .padding(.bottom, globalStateManager.isShowingKeyboard ? 16 : 0)
        }
        .listStyle(.plain)
        .scrollDismissesKeyboard(.immediately)
    }
}

#Preview(traits: .commonPreviewTrait) {
    NavigationStack {
        CommentsView(videoId: 1)
    }
}
