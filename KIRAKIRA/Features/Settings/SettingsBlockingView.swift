import SwiftUI

struct SettingsBlockingView: View {
    @State private var authManager = AuthManager.shared
    @State private var model = SettingsBlockingViewModel()

    var body: some View {
        Group {
            if !model.isCurrentSession {
                LoadingView()
            } else if !model.isSignedIn {
                BlockingSignedOutView()
            } else if let counts = model.state.value {
                BlockingOverviewList(counts: counts, refresh: model.load)
                    .id(model.revision)
            } else if let error = model.state.errorMessage {
                ErrorView(errorMessage: error)
                    .refreshable { await model.load() }
            } else {
                LoadingView()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(uiColor: .systemGroupedBackground).ignoresSafeArea())
        .navigationTitle(.settingsBlockAndHide)
        .task(id: authManager.sessionRevision) { await model.load() }
        .onChange(of: authManager.sessionRevision) { model.synchronizeSession() }
        .onChange(of: model.message) { _, message in
            if let message, model.isCurrentSession, model.isSignedIn {
                ToastManager.shared.show(message, style: .error)
            }
            model.clearMessage()
        }
        .onDisappear { model.disappear() }
    }
}

private struct BlockingOverviewList: View {
    let counts: BlockingCounts
    let refresh: () async -> Void

    var body: some View {
        List {
            Section(.blockingUsers) {
                categoryRow(.block)
                categoryRow(.hide)
            }
            Section(.blockingContent) {
                categoryRow(.tag)
                categoryRow(.keyword)
                categoryRow(.regex)
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .scrollBounceBehavior(.always, axes: .vertical)
        .refreshable { await refresh() }
    }

    private func categoryRow(_ category: BlockingRuleCategory) -> some View {
        NavigationLink(value: SettingsPath.blockingRules(category)) {
            LabeledContent {
                Text(counts.values[category] ?? 0, format: .number)
                    .foregroundStyle(.secondary)
            } label: {
                Label(category.title, systemImage: category.systemImage)
            }
        }
    }
}

struct BlockingSignedOutView: View {
    var body: some View {
        ContentUnavailableView {
            Label(.logIn, systemImage: "person.crop.circle.badge.exclamationmark")
        }
    }
}

extension BlockingRuleCategory {
    var title: LocalizedStringResource {
        switch self {
        case .block: .blockingBlock
        case .hide: .blockingHide
        case .tag: .blockingTag
        case .keyword: .blockingKeyword
        case .regex: .blockingRegex
        }
    }

    var systemImage: String {
        switch self {
        case .block: "person.crop.circle.badge.xmark"
        case .hide: "eye.slash"
        case .tag: "tag"
        case .keyword: "text.word.spacing"
        case .regex: "curlybraces"
        }
    }
}

#Preview("Overview · 中文") {
    NavigationStack {
        BlockingOverviewList(counts: BlockingCounts(values: [.block: 2, .hide: 0, .tag: 3, .keyword: 8, .regex: 1]), refresh: {})
            .background(Color(uiColor: .systemGroupedBackground).ignoresSafeArea())
            .navigationTitle(.settingsBlockAndHide)
    }
    .environment(\.locale, Locale(identifier: "zh-Hans"))
}

#Preview("Overview · English · Large Type") {
    NavigationStack {
        BlockingOverviewList(counts: BlockingCounts(values: [:]), refresh: {})
            .background(Color(uiColor: .systemGroupedBackground).ignoresSafeArea())
            .navigationTitle(.settingsBlockAndHide)
    }
    .environment(\.locale, Locale(identifier: "en"))
    .environment(\.dynamicTypeSize, .accessibility3)
    .preferredColorScheme(.dark)
}
