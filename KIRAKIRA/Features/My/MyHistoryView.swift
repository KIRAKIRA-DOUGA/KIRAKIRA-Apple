import SwiftUI

struct MyHistoryView: View {
    @Environment(GlobalStateManager.self) private var globalStateManager
    @State private var authManager = AuthManager.shared
    @State private var historyManager = BrowsingHistoryManager.shared
    @State private var searchText = ""

    var body: some View {
        Group {
            if !authManager.isAuthenticated {
                loginUnavailableView
            } else {
                historyContent
            }
        }
        .navigationTitle(.userHistory)
        #if !os(macOS)
            .navigationBarTitleDisplayMode(.inline)
        #endif
        .searchable(text: $searchText, prompt: Text(.search))
        .refreshable {
            await historyManager.fetch()
        }
        .task(id: authManager.credentials?.id) {
            await historyManager.fetch()
        }
    }

    @ViewBuilder
    private var historyContent: some View {
        switch historyManager.state {
        case .idle, .loading(previous: nil):
            LoadingView()
        case .success(let items), .loading(previous: .some(let items)):
            if filtered(items).isEmpty {
                emptyHistoryView(isSearching: !searchText.isEmpty)
            } else {
                historyList(items: filtered(items))
            }
        case .empty:
            emptyHistoryView(isSearching: false)
        case .error(let message):
            ErrorView(errorMessage: message)
        }
    }

    private var loginUnavailableView: some View {
        ContentUnavailableView {
            Label(.userHistory, systemImage: "clock.arrow.trianglehead.counterclockwise.rotate.90")
        } description: {
            Text(.historyLoginPrompt)
        } actions: {
            Button(.logIn) {
                globalStateManager.isShowingLogin = true
            }
            .buttonStyle(.borderedProminent)
        }
    }

    private func emptyHistoryView(isSearching: Bool) -> some View {
        ContentUnavailableView {
            Label(
                isSearching
                    ? String(localized: .historyNoSearchResults)
                    : String(localized: .historyEmpty),
                systemImage: isSearching ? "magnifyingglass" : "clock"
            )
        } description: {
            Text(
                isSearching
                    ? String(localized: .historyTryOtherKeywords)
                    : String(localized: .historyEmptyDescription)
            )
        }
    }

    private func historyList(items: [BrowsingHistoryItem]) -> some View {
        List {
            ForEach(groupedByDay(items)) { section in
                Section {
                    ForEach(section.items) { item in
                        Button {
                            play(item)
                        } label: {
                            HistoryVideoRow(item: item)
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                    }
                } header: {
                    Text(section.date, format: .dateTime.year().month().day())
                }
            }
        }
        .listStyle(.plain)
    }

    private func filtered(_ items: [BrowsingHistoryItem]) -> [BrowsingHistoryItem] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return items }
        return items.filter {
            $0.title.localizedCaseInsensitiveContains(query)
                || ($0.uploader?.localizedCaseInsensitiveContains(query) == true)
        }
    }

    private func groupedByDay(_ items: [BrowsingHistoryItem]) -> [HistoryDaySection] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: items) {
            calendar.startOfDay(for: $0.lastUpdateDateTime)
        }
        return grouped
            .map { HistoryDaySection(date: $0.key, items: $0.value) }
            .sorted { $0.date > $1.date }
    }

    private func play(_ item: BrowsingHistoryItem) {
        globalStateManager.selectedVideo = item.videoId
        globalStateManager.activeTransitionSource = .none
        globalStateManager.isPlayerExpanded = true
    }
}

private struct HistoryDaySection: Identifiable {
    let date: Date
    let items: [BrowsingHistoryItem]

    var id: Date { date }
}

private struct HistoryVideoRow: View {
    let item: BrowsingHistoryItem

    var body: some View {
        HStack(spacing: 12) {
            thumbnail

            VStack(alignment: .leading, spacing: 6) {
                Text(item.title)
                    .font(.headline)
                    .lineLimit(2)

                if let uploader = item.uploader, !uploader.isEmpty {
                    Text(verbatim: "@\(uploader)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }

                HStack(spacing: 12) {
                    Label {
                        Text(item.lastUpdateDateTime, format: .smart)
                    } icon: {
                        Image(systemName: "clock.arrow.circlepath")
                    }

                    if let position = item.playbackPosition,
                        let duration = item.duration
                    {
                        Label {
                            Text(verbatim: "\(position.formatted(.timeInterval)) / \(duration.formatted(.timeInterval))")
                        } icon: {
                            Image(systemName: "play.fill")
                        }
                    }
                }
                .font(.caption2)
                .foregroundStyle(.secondary)
                .lineLimit(1)
            }
        }
        .padding(.vertical, 4)
    }

    private var thumbnail: some View {
        CFImageView(imageId: item.image)
            .frame(width: 128, height: 72)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(alignment: .bottomLeading) {
                if let progress = item.playbackProgress {
                    GeometryReader { geometry in
                        Capsule()
                            .fill(.tint)
                            .frame(width: geometry.size.width * progress, height: 3)
                    }
                    .frame(height: 3)
                    .padding(.horizontal, 5)
                    .padding(.bottom, 4)
                }
            }
    }
}

#Preview(traits: .commonPreviewTrait) {
    NavigationStack {
        MyHistoryView()
    }
}
