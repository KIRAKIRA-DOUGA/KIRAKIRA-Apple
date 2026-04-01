//
// User's comments, posts and other stuff user posted.
//
// TODO: 模块化，将点赞点踩分离，然后制作回复和点击按钮触发菜单等操作。

import SwiftUI

struct UserContentView<Content: View>: View {
    enum VoteAppearance {
        case thumb
        case arrow
    }

    let name: String
    let username: String?
    let avatarId: String?
    let date: Date?
    let index: Int?

    let voteAppearance: VoteAppearance?

    var countUpvote: Binding<Int>?
    var countDownvote: Binding<Int>?
    var upvoted: Binding<Bool>?
    var downvoted: Binding<Bool>?

    let handleUpvote: () -> Void
    let handleDownvote: () -> Void

    let content: Content

    init(
        name: String,
        username: String? = nil,
        avatarId: String? = nil,
        date: Date? = nil,
        index: Int? = nil,

        voteAppearance: VoteAppearance = .thumb,

        countUpvote: Binding<Int>? = nil,
        countDownvote: Binding<Int>? = nil,
        upvoted: Binding<Bool>? = nil,
        downvoted: Binding<Bool>? = nil,

        handleUpvote: @escaping () -> Void = {},
        handleDownvote: @escaping () -> Void = {},

        @ViewBuilder content: () -> Content
    ) {
        self.name = name
        self.username = username
        self.avatarId = avatarId
        self.date = date
        self.index = index

        self.voteAppearance = voteAppearance
        self.countUpvote = countUpvote
        self.countDownvote = countDownvote
        self.upvoted = upvoted
        self.downvoted = downvoted
        self.handleUpvote = handleUpvote
        self.handleDownvote = handleDownvote

        self.content = content()
    }

    @State private var isRelativeTime = true

    // TODO: upvote和downvote成功的时候播放sensoryFeedback的success，错误则播放error。

    private func upvote() {
        if upvoted?.wrappedValue != nil && countUpvote?.wrappedValue != nil {
            withAnimation {
                if downvoted?.wrappedValue == true {
                    downvoted!.wrappedValue = false
                    countDownvote!.wrappedValue -= 1
                }
                upvoted!.wrappedValue.toggle()
                countUpvote!.wrappedValue += upvoted!.wrappedValue ? 1 : -1
            }
        }
        handleUpvote()
    }

    private func downvote() {
        if downvoted?.wrappedValue != nil && countDownvote?.wrappedValue != nil {
            withAnimation {
                if upvoted?.wrappedValue == true {
                    upvoted!.wrappedValue = false
                    countUpvote!.wrappedValue -= 1
                }
                downvoted!.wrappedValue.toggle()
                countDownvote!.wrappedValue += downvoted!.wrappedValue ? 1 : -1
            }
        }
        handleDownvote()
    }

    var body: some View {
        let countUpvote = self.countUpvote?.wrappedValue ?? nil
        let countDownvote = self.countDownvote?.wrappedValue ?? nil
        let upvoted = self.upvoted?.wrappedValue ?? nil
        let downvoted = self.downvoted?.wrappedValue ?? nil

        HStack(alignment: .top) {
            if let avatarId {
                CFImageView(imageId: avatarId)
                    .frame(width: 40, height: 40)
                    .clipShape(.circle)
            }
            HStack {
                VStack(alignment: .leading, spacing: 12) {
                    HStack(alignment: .top) {
                        VStack(alignment: .leading) {
                            Text(verbatim: name)
                                .font(.subheadline)
                                .fontWeight(.medium)
                            if let username {
                                Text(verbatim: "@\(username)")
                                    .font(.caption)
                                    .fontDesign(.monospaced)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        Spacer()
                        if date != nil || index != nil {
                            HStack {
                                if let date {
                                    Button(action: { withAnimation { isRelativeTime.toggle() } }) {
                                        if isRelativeTime {
                                            Text(date, style: .relative)
                                        } else {
                                            Text(date.formatted(date: .long, time: .standard))
                                        }
                                    }.buttonStyle(.plain)
                                }
                                if let index {
                                    Text(verbatim: "#\(index)")
                                }
                            }
                            .font(.caption)
                            .monospacedDigit()
                            .foregroundStyle(.secondary)
                        }
                    }

                    content
                        .textSelection(.enabled)

                    HStack(spacing: 24) {
                        if countUpvote != nil || countDownvote != nil || upvoted != nil || downvoted != nil {
                            HStack(spacing: voteAppearance == .arrow ? 16 : 24) {
                                if countUpvote != nil || upvoted != nil {
                                    Button(action: { upvote() }) {
                                        Image(systemName: voteAppearance == .arrow ? "arrowshape.up" : "hand.thumbsup")
                                            .symbolVariant((upvoted ?? false) ? .fill : .none)
                                            .frame(width: 20, height: 20)

                                        if voteAppearance == .thumb && countUpvote != nil {
                                            Text(countUpvote!, format: .number)
                                                .monospacedDigit()
                                                .contentTransition(.numericText(value: Double(countUpvote!)))
                                        }
                                    }
                                    .sensoryFeedback(.impact(weight: .medium), trigger: upvoted ?? false) { oldValue, newValue in
                                        return newValue
                                    }
                                    .foregroundStyle(upvoted ?? false ? .accent : .primary)
                                }

                                if voteAppearance == .arrow {
                                    let score = (countUpvote ?? 0) - (countDownvote ?? 0)

                                    Text(verbatim: "\(score)")
                                        .monospacedDigit()
                                        .contentTransition(.numericText(value: Double(score)))
                                }

                                if countDownvote != nil || downvoted != nil {
                                    Button(action: { downvote() }) {
                                        Image(
                                            systemName: voteAppearance == .arrow ? "arrowshape.down" : "hand.thumbsdown"
                                        )
                                        .symbolVariant((downvoted ?? false) ? .fill : .none)
                                        .frame(width: 20, height: 20)

                                        if voteAppearance == .thumb && countDownvote != nil {
                                            Text(countDownvote!, format: .number)
                                                .monospacedDigit()
                                                .contentTransition(.numericText(value: Double(-countDownvote!)))
                                        }
                                    }
                                    .sensoryFeedback(.impact(weight: .medium), trigger: downvoted ?? false) { oldValue, newValue in
                                        return newValue
                                    }
                                    .foregroundStyle(downvoted ?? false ? .accent : .primary)
                                }
                            }
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

#Preview {
    UserContentView(
        name: "TEST USER",
        avatarId: "avatar-1-xiQgrY2SDDx68HbIH8LSSBZqDpbSOFBf-1722666535442",
        date: Date(),
        index: 233,
        voteAppearance: .arrow,
        //        countUpvote: .constant(12),
        //        countDownvote: .constant(3),
        //        upvoted: .constant(true),
        //        downvoted: .constant(false),
    ) {
        Text(verbatim: "TEST USER CONTENT")
    }
}
