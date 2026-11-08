import SwiftUI

struct SettingsPrivacyView: View {
    @State private var authManager = AuthManager.shared
    @State private var model = SettingsPrivacyViewModel()

    private var busy: Bool { model.isCurrentSession && model.busy }
    private var saving: Bool { model.isCurrentSession && model.isSaving }
    private var loaded: Bool { model.isCurrentSession && model.isSignedIn && model.state.value != nil }

    var body: some View {
        Group {
            if !model.isCurrentSession {
                PrivacyStatusView(status: .loading)
            } else if !model.isSignedIn {
                PrivacyStatusView(status: .signedOut)
            } else if model.state.isInitialLoading || model.state == .idle {
                PrivacyStatusView(status: .loading)
            } else if let message = model.state.errorMessage {
                PrivacyStatusView(status: .error(message), retry: model.load)
            } else {
                Form {
                    if model.confirmationPending {
                        PrivacyConfirmationSection(syncing: busy, sync: model.load)
                    }
                    if model.state.value != nil {
                        PrivacySettingsForm(
                            values: model.values,
                            enabled: model.editable,
                            onSelect: model.setVisibility
                        )
                    }
                }
                .scrollContentBackground(.hidden)
                .refreshable { await model.load() }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(uiColor: .systemGroupedBackground).ignoresSafeArea())
        .navigationTitle(.settingsPrivacy)
        .navigationBarBackButtonHidden(saving)
        .interactiveDismissDisabled(saving)
        .preference(key: SettingsOperationInProgressPreferenceKey.self, value: saving)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                if model.isCurrentSession && model.isSaving {
                    ProgressView()
                        .accessibilityLabel(Text(.privacySaving))
                } else if loaded {
                    actionsMenu
                }
            }
        }
        .task(id: authManager.sessionRevision) { await model.load() }
        .onChange(of: authManager.sessionRevision) { model.synchronizeSession() }
        .onChange(of: model.message) { _, message in
            guard let message, model.isCurrentSession else { return }
            ToastManager.shared.show(message, style: model.savedMessage ? .success : .error)
            model.clearMessage()
        }
        .onDisappear { model.disappear() }
    }

    private var actionsMenu: some View {
        @Bindable var model = model

        return Menu(.menuMore, systemImage: "ellipsis") {
            Picker(selection: uniformVisibility) {
                ForEach(PrivacyVisibility.allCases) { visibility in
                    Label(visibility.title, systemImage: visibility.systemImage)
                        .tag(visibility as PrivacyVisibility?)
                }
            } label: {
                Label(.privacySetAll, systemImage: "checklist")
            }
            .pickerStyle(.menu)
            .accessibilityHint(Text(.privacySetAllHint))

            Section {
                Button(.privacyReset, systemImage: "arrow.counterclockwise", role: .destructive, action: model.requestReset)
                    .disabled(!model.canReset)
            }
        }
        .disabled(!model.editable)
        .confirmationDialog(.privacyResetTitle, isPresented: $model.confirmReset, titleVisibility: .visible) {
            Button(.privacyReset, role: .destructive, action: model.reset)
            Button(.actionCancel, role: .cancel) {}
        } message: {
            Text(.privacyResetMessage)
        }
    }

    /// Reads the shared visibility, or `nil` when the items differ; writing applies one value to every item.
    private var uniformVisibility: Binding<PrivacyVisibility?> {
        Binding {
            model.uniformVisibility
        } set: { visibility in
            if let visibility { model.selectAll(visibility) }
        }
    }
}

// MARK: - Privacy form

private struct PrivacySettingsForm: View {
    let values: [PrivacyItem: PrivacyVisibility]
    let enabled: Bool
    let onSelect: (PrivacyVisibility, PrivacyItem) -> Void

    var body: some View {
        Group {
            Section {
                privacyPicker(.birthday)
                privacyPicker(.age)
            } header: {
                Text(.privacyPersonalInformation)
            }

            Section {
                privacyPicker(.following)
                privacyPicker(.followers)
                privacyPicker(.favorites)
            } header: {
                Text(.privacySocialCollections)
            }
        }
        .disabled(!enabled)
    }

    private func privacyPicker(_ item: PrivacyItem) -> some View {
        let selection = Binding {
            values[item] ?? .public
        } set: { visibility in
            onSelect(visibility, item)
        }

        return Picker(selection: selection) {
            ForEach(PrivacyVisibility.allCases) { visibility in
                Label(visibility.title, systemImage: visibility.systemImage)
                    .tag(visibility)
            }
        } label: {
            Label(item.title, systemImage: item.systemImage)
        }
        .pickerStyle(.menu)
    }
}

// MARK: - Unconfirmed write

private struct PrivacyConfirmationSection: View {
    let syncing: Bool
    let sync: () async -> Void

    var body: some View {
        Section {
            Label {
                Text(.privacyConfirmationPending)
            } icon: {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(.orange)
            }

            Button {
                Task { await sync() }
            } label: {
                HStack {
                    Label(.privacyRetrySync, systemImage: "arrow.trianglehead.2.clockwise")
                    Spacer()
                    if syncing {
                        ProgressView()
                    }
                }
            }
            .disabled(syncing)
        } footer: {
            Text(.privacyConfirmationDescription)
        }
    }
}

// MARK: - Loading and error states

private struct PrivacyStatusView: View {
    enum Status {
        case loading
        case signedOut
        case error(String)
    }

    let status: Status
    var retry: () async -> Void = {}

    var body: some View {
        switch status {
        case .loading:
            LoadingView()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .accessibilityLabel(Text(.privacyLoading))
        case .signedOut:
            ContentUnavailableView {
                Label(.privacySignInTitle, systemImage: "hand.raised")
            } description: {
                Text(.privacySignInRequired)
            }
        case .error(let message):
            ContentUnavailableView {
                Label(.privacyLoadFailed, systemImage: "exclamationmark.triangle")
            } description: {
                Text(verbatim: message)
            } actions: {
                Button(.privacyRetry) { Task { await retry() } }
                    .buttonStyle(.borderedProminent)
            }
        }
    }
}

// MARK: - Display values

extension PrivacyItem {
    fileprivate var title: LocalizedStringResource {
        switch self {
        case .birthday: .settingsProfileBirthday
        case .age: .privacyAge
        case .following: .privacyFollowing
        case .followers: .privacyFollowers
        case .favorites: .userCollections
        }
    }

    fileprivate var systemImage: String {
        switch self {
        case .birthday: "birthday.cake"
        case .age: "calendar"
        case .following: "person.badge.plus"
        case .followers: "person.2"
        case .favorites: "star"
        }
    }
}

extension PrivacyVisibility {
    fileprivate var title: LocalizedStringResource {
        switch self {
        case .public: .privacyPublic
        case .following: .privacyFollowersOnly
        case .private: .privacyHidden
        }
    }

    fileprivate var systemImage: String {
        switch self {
        case .public: "eye"
        case .following: "person.badge.plus"
        case .private: "eye.slash"
        }
    }
}

// MARK: - Previews

#Preview("混合可见性") {
    NavigationStack {
        Form {
            PrivacySettingsForm(
                values: [.birthday: .private, .age: .following, .following: .public, .followers: .public, .favorites: .private],
                enabled: true,
                onSelect: { _, _ in }
            )
        }
        .navigationTitle(.settingsPrivacy)
    }
}

#Preview("全部公开 · 深色 · 大字体") {
    NavigationStack {
        Form {
            PrivacySettingsForm(
                values: Dictionary(uniqueKeysWithValues: PrivacyItem.allCases.map { ($0, .public) }),
                enabled: true,
                onSelect: { _, _ in }
            )
        }
        .navigationTitle(.settingsPrivacy)
    }
    .environment(\.colorScheme, .dark)
    .environment(\.dynamicTypeSize, .accessibility3)
}

#Preview("待确认 · English") {
    NavigationStack {
        Form {
            PrivacyConfirmationSection(syncing: false, sync: {})
            PrivacySettingsForm(
                values: Dictionary(uniqueKeysWithValues: PrivacyItem.allCases.map { ($0, .private) }),
                enabled: false,
                onSelect: { _, _ in }
            )
        }
        .navigationTitle(.settingsPrivacy)
    }
    .environment(\.locale, Locale(identifier: "en"))
}

#Preview("加载中") { PrivacyStatusView(status: .loading) }
#Preview("加载失败") { PrivacyStatusView(status: .error(String(localized: "ERROR_NETWORK_REQUEST_FAILED"))) }
#Preview("游客") { PrivacyStatusView(status: .signedOut) }
