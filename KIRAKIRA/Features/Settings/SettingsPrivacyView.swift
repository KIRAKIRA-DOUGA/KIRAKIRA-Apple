import SwiftUI

struct SettingsPrivacyView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var authManager = AuthManager.shared
    @State private var model = SettingsPrivacyViewModel()
    @State private var saveFeedback: UUID?

    private var savingOrConfirming: Bool { model.isCurrentSession && (model.isSaving || model.isConfirmingSave) }
    private var saving: Bool { model.isCurrentSession && model.isSaving }
    private var loaded: Bool { model.isCurrentSession && model.isSignedIn && model.state.value != nil }

    var body: some View {
        @Bindable var model = model

        Group {
            if !model.isCurrentSession {
                PrivacyStatusView(status: .loading)
            } else if !model.isSignedIn {
                PrivacyStatusView(status: .signedOut)
            } else if model.state.isInitialLoading || model.state == .idle {
                PrivacyStatusView(status: .loading)
            } else if let message = model.state.errorMessage {
                ErrorView(errorMessage: message)
                    .refreshable { await model.load() }
            } else {
                Form {
                    if model.state.value != nil {
                        PrivacySettingsForm(
                            values: model.values,
                            enabled: model.editable,
                            onSelect: model.setVisibility
                        )
                    }
                }
                .scrollContentBackground(.hidden)
                .scrollBounceBehavior(.always, axes: .vertical)
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
            if loaded {
                ToolbarItem(placement: .primaryAction) {
                    Group {
                        if savingOrConfirming {
                            ProgressView()
                                .controlSize(.regular)
                                .accessibilityLabel(model.isSaving ? Text(.privacySaving) : Text(.privacyConfirming))
                                .transition(.opacity)
                        } else if saveFeedback != nil {
                            Image(systemName: "checkmark")
                                .accessibilityLabel(Text(.privacySaved))
                                .transition(.opacity)
                        } else {
                            actionsMenu
                                .transition(.opacity)
                        }
                    }
                    .frame(width: 24, height: 24)
                    .animation(reduceMotion ? nil : .easeInOut(duration: 0.2), value: savingOrConfirming)
                }
            }
        }
        .alert(.privacyConfirmationPending, isPresented: $model.showConfirmationError) {
            Button(.errorTryAgain) { Task { await model.load() } }
            Button(.actionCancel, role: .cancel) {}
        } message: {
            Text(.privacyConfirmationDescription)
        }
        .task(id: authManager.sessionRevision) { await model.load() }
        .task(id: saveFeedback) {
            guard let feedback = saveFeedback else { return }
            do {
                try await Task.sleep(for: .seconds(2))
            } catch {
                return
            }
            guard saveFeedback == feedback else { return }
            withAnimation(reduceMotion ? nil : .snappy) {
                saveFeedback = nil
            }
        }
        .onChange(of: authManager.sessionRevision) {
            saveFeedback = nil
            model.synchronizeSession()
        }
        .onChange(of: savingOrConfirming) { _, inProgress in
            if inProgress { saveFeedback = nil }
        }
        .onChange(of: model.saveSucceeded) { _, succeeded in
            guard succeeded, model.isCurrentSession, model.isSignedIn else { return }
            withAnimation(reduceMotion ? nil : .snappy) {
                saveFeedback = UUID()
            }
        }
        .onChange(of: model.message) { _, message in
            guard let message else { return }
            if model.isCurrentSession && model.isSignedIn && !model.savedMessage {
                ToastManager.shared.show(message, style: .error)
            }
            model.clearMessage()
        }
        .sensoryFeedback(.success, trigger: saveFeedback) { _, newValue in
            newValue != nil
        }
        .onDisappear {
            saveFeedback = nil
            model.disappear()
        }
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

// MARK: - Loading and signed-out states

private struct PrivacyStatusView: View {
    enum Status {
        case loading
        case signedOut
    }

    let status: Status

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
#Preview("加载失败") { ErrorView(errorMessage: String(localized: "ERROR_NETWORK_REQUEST_FAILED")) }
#Preview("游客") { PrivacyStatusView(status: .signedOut) }
