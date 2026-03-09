import RichText
import SwiftUI

struct CommentsView: View {
    @State private var sendContent: String = ""
    @State private var countUpvote: Int = 9
    @State private var countDownvote: Int = 9
    @State private var upvoted: Bool = false
    @State private var downvoted: Bool = false
    @State private var isShowingSelectionSheet: Bool = false
    private var commentContent = String(
        "**Lorem ipsum dolor sit amet**, consectetur adipiscing elit. *Sed sagittis metus vel mi viverra tincidunt.* Cras vitae ex efficitur, luctus eros in, porttitor lorem. Nunc auctor tincidunt massa, et luctus lacus ultricies eget. Nulla felis turpis, dignissim sit amet efficitur non, tincidunt convallis enim. Mauris mollis tincidunt urna, sed eleifend erat rutrum id. Etiam libero quam, feugiat nec placerat a, mattis at ligula. Nunc pellentesque ultricies mauris vel volutpat. Sed faucibus volutpat est vitae dignissim. Quisque consectetur pretium risus non elementum. Suspendisse et ornare sem. Nullam ut metus faucibus, congue ante sed, fringilla tortor. Ut vel ipsum porta, dignissim nulla ac, ullamcorper lectus. Nunc turpis turpis, placerat rhoncus vestibulum vel, tristique porttitor nibh. Pellentesque aliquam dignissim auctor."
    )

    private func sendComment() {
        sendContent = ""
    }

    var body: some View {
        List(0..<30) { _ in
            UserContentView(
                name: "Endministrator",
                username: "endmin",
                avatarId: "avatar-1-xiQgrY2SDDx68HbIH8LSSBZqDpbSOFBf-1722666535442",
                date: Date(timeIntervalSince1970: 0),
                index: 2,
                voteAppearance: .arrow,
                countUpvote: $countUpvote,
                countDownvote: $countDownvote,
                upvoted: $upvoted,
                downvoted: $downvoted,
            ) {
                TextView {
                    Text(commentContent)
                }
            }
        }
        .listStyle(.plain)
        .safeAreaBar(edge: .bottom) {
            SendTextField(
                text: $sendContent,
                prompt: .comment,
                onSend: { sendComment() },
                showAddButton: true
            )
            .padding(.horizontal)
            .padding(.vertical, 2)
        }
        .scrollDismissesKeyboard(.interactively)
        //        .sheet(isPresented: $isShowingSelectionSheet) {
        //            NavigationStack {
        //                TextSelectView(text: $commentContent)
        //            }
        //        }
    }
}

#Preview {
    NavigationStack {
        CommentsView()
    }
}
