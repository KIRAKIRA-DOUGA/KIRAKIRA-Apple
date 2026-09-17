import SwiftUI

struct UserFollowListView: View {
    let uid: Int
    let kind: FollowListKind
    let animationNamespace: Namespace.ID

    @State private var viewModel = FollowListViewModel()

    var body: some View {
        Group {
            switch viewModel.state {
            case .idle, .loading(previous: nil):
                LoadingView()
            case .success(let users), .loading(previous: .some(let users)):
                userList(users)
            case .empty:
                ContentUnavailableView(
                    kind.emptyTitle,
                    systemImage: "person.2"
                )
            case .error(let message):
                ErrorView(errorMessage: message)
            }
        }
        .navigationTitle(kind.title)
        #if !os(macOS)
            .navigationBarTitleDisplayMode(.inline)
        #endif
        .task(id: kind) {
            await viewModel.load(uid: uid, kind: kind)
        }
        .refreshable {
            await viewModel.load(uid: uid, kind: kind)
        }
    }

    private func userList(_ users: [FollowListUser]) -> some View {
        List {
            Section {
                ForEach(users) { user in
                    NavigationLink {
                        UserView(uid: user.uid, animationNamespace: animationNamespace)
                    } label: {
                        FollowListUserRow(user: user)
                    }
                    .task {
                        await viewModel.loadMoreIfNeeded(currentItem: user)
                    }
                }
                
                if viewModel.isLoadingMore {
                    HStack {
                        Spacer()
                        ProgressView()
                            .controlSize(.small)
                        Spacer()
                    }
                    .listRowSeparator(.hidden)
                }
            }
            .listSectionSeparator(.hidden)
        }
        .listStyle(.plain)
    }
}

private struct FollowListUserRow: View {
    let user: FollowListUser

    var body: some View {
        HStack(spacing: 12) {
            UserAvatarView(imageId: user.avatar)
                .frame(width: 48, height: 48)

            VStack(alignment: .leading, spacing: 2) {
                Text(verbatim: user.displayName)
                    .fontWeight(.semibold)
                    .lineLimit(1)

                if let username = user.username, !username.isEmpty {
                    Text(verbatim: "@\(username)")
                        .font(.caption)
                        .fontDesign(.monospaced)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }
        }
    }
}

extension FollowListKind {
    fileprivate var title: String {
        switch self {
        case .following: String(localized: .userFollowingListTitle)
        case .followers: String(localized: .userFollowersListTitle)
        }
    }

    fileprivate var emptyTitle: String {
        switch self {
        case .following: String(localized: .userFollowingListEmpty)
        case .followers: String(localized: .userFollowersListEmpty)
        }
    }
}

#Preview {
    @Previewable @Namespace var animationNamespace
    NavigationStack {
        UserFollowListView(uid: 1, kind: .followers, animationNamespace: animationNamespace)
    }
    .environment(GlobalStateManager())
}
