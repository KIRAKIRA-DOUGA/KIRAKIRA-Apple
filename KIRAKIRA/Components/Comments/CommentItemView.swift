import RichText
import SwiftUI

struct CommentItemView: View {
    let comment: VideoCommentDTO
    @State private var isRelativeTime: Bool = false

    var body: some View {
        HStack(alignment: .top) {
            if let avatar = comment.userInfo.avatar {
                CFImageView(imageId: avatar)
                    .frame(width: 40, height: 40)
                    .clipShape(.circle)
            } else {
                Image(systemName: "person.crop.circle")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 40, height: 40)
            }

            HStack {
                VStack(alignment: .leading, spacing: 12) {
                    HStack(alignment: .top) {
                        VStack(alignment: .leading) {
                            Text(verbatim: comment.userInfo.userNickname)
                                .font(.subheadline)
                                .fontWeight(.medium)
                            Text(verbatim: "@\(comment.userInfo.username)")
                                .font(.caption)
                                .fontDesign(.monospaced)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        HStack {
                            Text(comment.emitTime, format: .smart)

                            Text(verbatim: "#\(comment.commentIndex)")
                                .monospacedDigit()
                        }
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    }

                    TextView(comment.text)
                        .font(.body)

                    HStack(spacing: 24) {
                        HStack(spacing: 16) {
                            Button(action: { }) {
                                Image(systemName: "arrowshape.up")
                                    .symbolVariant(comment.isUpvote ? .fill : .none)
                            }
                            .sensoryFeedback(.impact(weight: .medium), trigger: comment.isUpvote) {
                                oldValue, newValue in
                                return newValue == true
                            }
                            .foregroundStyle(comment.isUpvote ? .accent : .primary)

                            Text(comment.score, format: .number)
                                .monospacedDigit()
                                .contentTransition(.numericText(value: Double(comment.score)))

                            Button(action: { }) {
                                Image(systemName: "arrowshape.down")
                                    .symbolVariant(comment.isDownvote ? .fill : .none)
                            }
                            .sensoryFeedback(.impact(weight: .medium), trigger: comment.isDownvote) {
                                oldValue, newValue in
                                return newValue == true
                            }
                            .foregroundStyle(comment.isDownvote ? .accent : .primary)
                        }

                        Spacer()

                        Button(action: {}) {
                            Label(.reply, systemImage: "arrowshape.turn.up.left")
                                .labelStyle(.iconOnly)
                        }

                        Menu {
                            Button(.report, systemImage: "exclamationmark.bubble", action: {})
                        } label: {
                            Label(.menuMore, systemImage: "ellipsis")
                                .labelStyle(.iconOnly)
                        }
                    }
                    .buttonStyle(.plain)
                    .contentTransition(.symbolEffect(.replace.offUp.byLayer))
                }
            }
        }
    }
}
