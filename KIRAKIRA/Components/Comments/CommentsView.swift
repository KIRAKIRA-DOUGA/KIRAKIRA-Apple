import RichText
import SwiftUI

struct CommentsView: View {
    let videoId: Int
    let commentViewModel: CommentViewModel
    @Environment(GlobalStateManager.self) private var globalStateManager
    @State private var sendContent: String = ""

    private func sendComment() {
        sendContent = ""
    }

    var body: some View {
        Group {
            switch commentViewModel.state {
            case .idle, .loading(previous: nil):
                LoadingView()
            case .success(let comments), .loading(previous: .some(let comments)):
                List(comments) { comment in
                    CommentItemView(comment: comment)
                }
            case .error(let msg):
                ErrorView(errorMessage: msg)
            default:
                Color.clear
            }
        }
        .task {
            await commentViewModel.fetch(of: videoId)
        }
        .refreshable {
            await commentViewModel.fetch(of: videoId)
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
        CommentsView(videoId: 1, commentViewModel: CommentViewModel())
    }
}
