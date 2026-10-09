import SwiftUI

struct CommentsView<Header: View>: View {
    let videoId: Int
    let commentViewModel: CommentViewModel
    private let header: Header

    init(
        videoId: Int,
        commentViewModel: CommentViewModel,
        @ViewBuilder header: () -> Header = { EmptyView() }
    ) {
        self.videoId = videoId
        self.commentViewModel = commentViewModel
        self.header = header()
    }

    @State private var sendContent: String = ""

    private func sendComment() {
        sendContent = ""
    }

    var body: some View {
        scrollContent
            .overlay {
                switch commentViewModel.state {
                case .idle, .loading(previous: nil):
                    LoadingView()
                case .error(let msg):
                    ErrorView(errorMessage: msg)
                default:
                    EmptyView()
                }
            }
            .animation(.easeInOut(duration: 0.25), value: commentViewModel.state)
            .refreshable {
                await commentViewModel.fetch(of: videoId)
            }
            .safeAreaBar(edge: .bottom, spacing: 0) {
                SendTextField(
                    text: $sendContent,
                    prompt: .comment,
                    onSend: { sendComment() },
                    showAddButton: true
                )
            }
            .ignoresSafeArea(.container, edges: .bottom)
            .scrollDismissesKeyboard(.interactively)
    }

    private var scrollContent: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 0) {
                header
                commentRows
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .scrollBounceBehavior(.always)
    }

    private var commentRows: some View {
        ForEach(commentViewModel.state.value ?? []) { comment in
            VStack(spacing: 0) {
                CommentItemView(comment: comment)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)
                    .padding(.vertical, 12)
                Divider()
                    .padding(.leading)
            }
        }
    }
}

#Preview(traits: .commonPreviewTrait) {
    @Previewable @State var commentViewModel = CommentViewModel()
    NavigationStack {
        CommentsView(videoId: 1, commentViewModel: commentViewModel)
    }
    .task {
        await commentViewModel.fetch(of: 1)
    }
}
