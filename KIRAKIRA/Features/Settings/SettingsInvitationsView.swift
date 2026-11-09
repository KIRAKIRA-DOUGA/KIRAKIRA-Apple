import SwiftUI
import UIKit

struct SettingsInvitationsView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var authManager = AuthManager.shared
    @State private var model = SettingsInvitationsViewModel()
    @State private var creationFeedback: UUID?

    private var creating: Bool { model.isCurrentSession && model.isCreating }

    var body: some View {
        @Bindable var model = model

        Group {
            if !model.isCurrentSession {
                InvitationStatusView(status: .loading)
            } else if !model.isSignedIn || model.requiresSignIn {
                InvitationStatusView(status: .signedOut)
            } else if model.state.isInitialLoading || model.state == .idle {
                InvitationStatusView(status: .loading)
            } else if let message = model.state.errorMessage {
                InvitationStatusView(status: .error(message), retry: model.load)
            } else {
                InvitationsList(
                    invitations: model.visibleInvitations,
                    totalCount: model.invitations.count,
                    unusedCount: model.unusedCount,
                    usedCount: model.usedCount,
                    filter: $model.filter,
                    refresh: model.load,
                    copy: copy
                )
                .id(model.revision)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(uiColor: .systemGroupedBackground).ignoresSafeArea())
        .navigationTitle(.invitationCode)
        .navigationBarBackButtonHidden(creating)
        .toolbar {
            if model.isCurrentSession && model.isSignedIn && model.state.value != nil {
                ToolbarItem(placement: .primaryAction) {
                    InvitationCreationButton(
                        isCreating: creating || model.isConfirmingCreation,
                        completed: creationFeedback != nil,
                        enabled: model.canCreate,
                        action: model.requestCreation
                    )
                    .confirmationDialog(
                        .invitationConfirmTitle, isPresented: $model.confirmCreation, titleVisibility: .visible
                    ) {
                        Button(.invitationCheckStatus, action: model.refresh)
                        Button(.invitationGenerateAnyway, action: model.confirmCreate)
                        Button(.actionCancel, role: .cancel) {}
                    } message: {
                        Text(.invitationConfirmMessage)
                    }
                }
            }
        }
        .alert(.invitationConfirmationPending, isPresented: $model.showConfirmationError) {
            Button(.errorTryAgain, action: model.refresh)
            Button(.actionCancel, role: .cancel) {}
        } message: {
            Text(.invitationCreationUnconfirmed)
        }
        .interactiveDismissDisabled(creating)
        .preference(key: SettingsOperationInProgressPreferenceKey.self, value: creating)
        .task(id: authManager.sessionRevision) { await model.load() }
        .task(id: creationFeedback) {
            guard let feedback = creationFeedback else { return }
            do {
                try await Task.sleep(for: .seconds(2))
            } catch {
                return
            }
            guard creationFeedback == feedback else { return }
            withAnimation(reduceMotion ? nil : .snappy) {
                creationFeedback = nil
            }
        }
        .onChange(of: authManager.sessionRevision) {
            creationFeedback = nil
            model.synchronizeSession()
        }
        .onChange(of: model.isCreating) { _, isCreating in
            if isCreating { creationFeedback = nil }
        }
        .onChange(of: model.creationSucceeded) { _, succeeded in
            guard succeeded, model.isCurrentSession, model.isSignedIn else { return }
            withAnimation(reduceMotion ? nil : .snappy) {
                creationFeedback = UUID()
            }
        }
        .onChange(of: model.message) { _, message in
            guard let message else { return }
            if model.isCurrentSession && model.isSignedIn && !model.requiresSignIn {
                // Success is acknowledged in the button, like the image viewer.
                // Unresolved writes use an alert; ordinary failures and cooldowns use a toast.
                switch model.messageStyle {
                case .success:
                    break
                default:
                    ToastManager.shared.show(message, style: model.messageStyle)
                }
            }
            model.clearMessage()
        }
        .sensoryFeedback(.success, trigger: creationFeedback) { _, newValue in
            newValue != nil
        }
        .onDisappear {
            creationFeedback = nil
            model.disappear()
        }
    }

    private func copy(_ invitation: Invitation) -> Bool {
        guard model.canCopy(invitation) else { return false }
        UIPasteboard.general.string = invitation.code
        return true
    }
}

// MARK: - Toolbar action

private struct InvitationCreationButton: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    let isCreating: Bool
    let completed: Bool
    let enabled: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Group {
                if isCreating {
                    ProgressView()
                        .controlSize(.regular)
                        .transition(.opacity)
                } else {
                    Image(systemName: completed ? "checkmark" : "plus")
                        .contentTransition(reduceMotion ? .identity : .symbolEffect(.replace))
                        .transition(.opacity)
                }
            }
            .frame(width: 24, height: 24)
            .animation(reduceMotion ? nil : .easeInOut(duration: 0.2), value: isCreating)
        }
        .disabled(!enabled)
        .accessibilityLabel(Text(.invitationGenerate))
        .accessibilityValue(
            isCreating ? Text(.invitationCreating) : completed ? Text(.invitationCreated) : Text(verbatim: ""))
    }
}

// MARK: - Invitation list

private struct InvitationsList: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    let invitations: [Invitation]
    let totalCount: Int
    let unusedCount: Int
    let usedCount: Int
    @Binding var filter: InvitationFilter
    let refresh: () async -> Void
    let copy: (Invitation) -> Bool

    var body: some View {
        List {
            Section {
                InvitationSummary(
                    totalCount: totalCount,
                    unusedCount: unusedCount,
                    usedCount: usedCount
                )
            }
            .listSectionMargins(.bottom, .zero)

            Section {
                if dynamicTypeSize.isAccessibilitySize {
                    filterPicker.pickerStyle(.menu)
                } else {
                    filterPicker
                        .pickerStyle(.segmented)
                        .listRowBackground(Color.clear)
                        .listRowInsets(EdgeInsets())
                }
            }
            .listSectionMargins(.vertical, 8)

            Section {
                if invitations.isEmpty {
                    ContentUnavailableView {
                        Label(.invitationEmptyTitle, systemImage: "gift")
                    } description: {
                        if totalCount > 0 {
                            Text(.invitationFilterEmptyDescription)
                        }
                    }
                } else {
                    ForEach(invitations) { invitation in
                        InvitationRow(invitation: invitation) { copy(invitation) }
                    }
                }
            }
            .listSectionMargins(.top, .zero)
        }
        .listStyle(.insetGrouped)
        .scrollBounceBehavior(.always, axes: .vertical)
        .refreshable {
            await refresh()
        }
    }

    private var filterPicker: some View {
        Picker(.invitationFilter, selection: $filter) {
            ForEach(InvitationFilter.allCases) { filter in
                Text(filter.title).tag(filter)
            }
        }
    }
}

// MARK: - Statistics

private struct InvitationSummary: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    let totalCount: Int
    let unusedCount: Int
    let usedCount: Int

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            statistic(.invitationUnused, count: unusedCount, highlighted: true)
            Divider()
            statistic(.invitationTotal, count: totalCount)
            Divider()
            statistic(.invitationUsed, count: usedCount)
        }
        .animation(reduceMotion ? nil : .snappy, value: unusedCount)
        .animation(reduceMotion ? nil : .snappy, value: usedCount)
        .animation(reduceMotion ? nil : .snappy, value: totalCount)
    }

    private func statistic(_ title: LocalizedStringResource, count: Int, highlighted: Bool = false) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.subheadline)
                .foregroundStyle(highlighted ? Color.accentColor : Color.secondary)
                .fixedSize(horizontal: false, vertical: true)
            Text(count, format: .number)
                .font(.system(.largeTitle, design: .rounded).weight(.semibold))
                .foregroundStyle(highlighted ? Color.accentColor : Color.primary)
                .contentTransition(reduceMotion ? .identity : .numericText())
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
    }
}

private struct InvitationRow: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var copyFeedback: UUID?

    let invitation: Invitation
    let copy: () -> Bool

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(verbatim: invitation.code)
                    .font(.body.monospaced())
                    .fixedSize(horizontal: false, vertical: true)
                Text(invitation.used ? .invitationUsed : .invitationUnused)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Button {
                guard copy() else { return }
                withAnimation(reduceMotion ? nil : .snappy) {
                    copyFeedback = UUID()
                }
            } label: {
                Image(systemName: copyFeedback != nil ? "checkmark" : "document.on.document")
                    .contentTransition(reduceMotion ? .identity : .symbolEffect(.replace))
                    .frame(minWidth: 44, minHeight: 44)
                    .contentShape(.rect)
            }
            .buttonStyle(.borderless)
            .accessibilityLabel(Text(.invitationCopyCode(invitation.code)))
            .accessibilityValue(copyFeedback != nil ? Text(.invitationCopied) : Text(verbatim: ""))
        }
        .task(id: copyFeedback) {
            guard let feedback = copyFeedback else { return }
            do {
                try await Task.sleep(for: .seconds(2))
            } catch {
                return
            }
            guard copyFeedback == feedback else { return }
            withAnimation(reduceMotion ? nil : .snappy) {
                copyFeedback = nil
            }
        }
        .sensoryFeedback(.success, trigger: copyFeedback) { _, newValue in
            newValue != nil
        }
        .onDisappear { copyFeedback = nil }
    }
}

// MARK: - Loading and error states

private struct InvitationStatusView: View {
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
        case .signedOut:
            ContentUnavailableView {
                Label(.invitationSignInTitle, systemImage: "person.crop.circle.badge.exclamationmark")
            } description: {
                Text(.invitationSignInRequired)
            }
        case .error(let message):
            ErrorView(errorMessage: message)
                .refreshable {
                    await retry()
                }
        }
    }
}

extension InvitationFilter {
    fileprivate var title: LocalizedStringResource {
        switch self {
        case .all: .invitationAll
        case .unused: .invitationUnused
        case .used: .invitationUsed
        }
    }
}

// MARK: - Previews (presentation only; no service or account access)

private struct InvitationsPreview: View {
    @State private var filter: InvitationFilter = .all
    var empty = false
    var isCreating = false
    var completed = false

    private let invitations = [
        Invitation(code: "EXAMPLE-UNUSED-0001", createdAt: .distantPast, used: false),
        Invitation(code: "EXAMPLE-USED-0002", createdAt: .distantPast, used: true),
    ]

    var body: some View {
        NavigationStack {
            InvitationsList(
                invitations: empty
                    ? [] : invitations.filter { filter == .all || ($0.used ? filter == .used : filter == .unused) },
                totalCount: empty ? 0 : 2,
                unusedCount: empty ? 0 : 1,
                usedCount: empty ? 0 : 1,
                filter: $filter,
                refresh: {},
                copy: { _ in true }
            )
            .navigationTitle(.invitationCode)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    InvitationCreationButton(
                        isCreating: isCreating, completed: completed, enabled: !isCreating, action: {})
                }
            }
        }
    }
}

#Preview("数据 · 中文 · 浅色") {
    InvitationsPreview()
        .environment(\.locale, Locale(identifier: "zh-Hans"))
        .preferredColorScheme(.light)
}

#Preview("Data · English · Dark · Large Type") {
    InvitationsPreview()
        .environment(\.locale, Locale(identifier: "en"))
        .environment(\.dynamicTypeSize, .accessibility3)
        .preferredColorScheme(.dark)
}

#Preview("空列表") { InvitationsPreview(empty: true) }
#Preview("生成中") { InvitationsPreview(isCreating: true) }
#Preview("生成成功") { InvitationsPreview(completed: true) }
#Preview("确认中 · English") {
    InvitationsPreview(isCreating: true)
        .environment(\.locale, Locale(identifier: "en"))
}
#Preview("加载中") { InvitationStatusView(status: .loading) }
#Preview("加载失败") {
    InvitationStatusView(status: .error(String(localized: "INVITATION_REQUEST_FAILED")))
}
#Preview("需要登录") { InvitationStatusView(status: .signedOut) }
