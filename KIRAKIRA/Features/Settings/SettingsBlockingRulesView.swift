import SwiftUI

struct SettingsBlockingRulesView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var authManager = AuthManager.shared
    @State private var model: SettingsBlockingRulesViewModel
    @State private var feedback: UUID?

    init(category: BlockingRuleCategory) {
        _model = State(initialValue: SettingsBlockingRulesViewModel(category: category))
    }

    private var writing: Bool { model.isCurrentSession && model.isWriting }
    private var loaded: Bool { model.isCurrentSession && model.isSignedIn && model.state.value != nil }
    private var toolbarProgress: Bool { writing && model.writingRuleID == nil || model.isConfirming }
    private var parentAlert: Binding<Bool> {
        Binding(get: { model.editor == nil && model.showConfirmationError }, set: { model.showConfirmationError = $0 })
    }

    var body: some View {
        @Bindable var model = model
        Group {
            if !model.isCurrentSession {
                LoadingView()
            } else if !model.isSignedIn {
                BlockingSignedOutView()
            } else if let page = model.state.value {
                rulesList(page)
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
        .navigationTitle(model.category.title)
        .navigationBarBackButtonHidden(writing)
        .interactiveDismissDisabled(writing)
        .preference(key: SettingsOperationInProgressPreferenceKey.self, value: writing)
        .toolbar {
            if loaded {
                ToolbarItem(placement: .primaryAction) {
                    BlockingToolbarAction(
                        inProgress: toolbarProgress,
                        confirming: model.isConfirming,
                        completed: feedback != nil,
                        enabled: model.canAdd,
                        action: model.openEditor
                    )
                }
            }
        }
        .sheet(item: $model.editor) { draft in
            BlockingEditorView(model: model, editorID: draft.id)
                .onDisappear { model.closeEditor(id: draft.id) }
        }
        .alert(.blockingConfirmationPending, isPresented: parentAlert) {
            Button(.errorTryAgain, action: model.retryConfirmation)
            Button(.actionCancel, role: .cancel) {}
        } message: {
            Text(.blockingConfirmationDescription)
        }
        .task(id: authManager.sessionRevision) { await model.load() }
        .task(id: feedback) {
            guard let token = feedback else { return }
            do { try await Task.sleep(for: .seconds(2)) } catch { return }
            guard feedback == token else { return }
            withAnimation(reduceMotion ? nil : .snappy) { feedback = nil }
        }
        .onChange(of: model.successID) { _, value in
            withAnimation(reduceMotion ? nil : .snappy) { feedback = value }
        }
        .onChange(of: authManager.sessionRevision) {
            feedback = nil
            model.synchronizeSession()
        }
        .onChange(of: model.message) { _, message in
            if let message, model.isCurrentSession, model.isSignedIn {
                ToastManager.shared.show(message, style: .error)
            }
            model.clearMessage()
        }
        .sensoryFeedback(.success, trigger: feedback) { _, value in value != nil }
        .onDisappear {
            feedback = nil
            model.disappear()
        }
    }

    private func rulesList(_ page: BlockingRulePage) -> some View {
        List {
            if page.entries.isEmpty {
                ContentUnavailableView {
                    Label(.blockingEmpty, systemImage: model.category.systemImage)
                }
            }
            ForEach(page.entries) { rule in
                BlockingRuleRow(rule: rule, writing: model.writingRuleID == rule.id)
                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                        if model.canRemove(rule) {
                            Button(.blockingRemove, systemImage: "trash", role: .destructive) { model.remove(rule) }
                        }
                    }
                    .contextMenu {
                        if model.canRemove(rule) {
                            Button(.blockingRemove, systemImage: "trash", role: .destructive) { model.remove(rule) }
                        }
                    }
                    .accessibilityActions {
                        if model.canRemove(rule) {
                            Button(.blockingRemove) { model.remove(rule) }
                        }
                    }
            }
            if let error = model.appendError {
                Section {
                    Text(error).foregroundStyle(.secondary)
                    Button(.errorTryAgain, action: model.loadMore)
                }
            } else if model.isAppending {
                ProgressView().frame(maxWidth: .infinity)
            } else if model.canLoadMore {
                Button(.blockingLoadMore, action: model.loadMore)
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .scrollBounceBehavior(.always, axes: .vertical)
        .refreshable { await model.load() }
    }
}

private struct BlockingToolbarAction: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    let inProgress: Bool
    let confirming: Bool
    let completed: Bool
    let enabled: Bool
    let action: () -> Void

    var body: some View {
        Group {
            if inProgress {
                ProgressView()
                    .controlSize(.regular)
                    .accessibilityLabel(confirming ? Text(.blockingConfirming) : Text(.blockingWriting))
                    .transition(.opacity)
            } else if completed {
                Image(systemName: "checkmark")
                    .accessibilityLabel(Text(.blockingSuccess))
                    .transition(.opacity)
            } else {
                Button(.blockingAdd, systemImage: "plus", action: action)
                    .disabled(!enabled)
                    .transition(.opacity)
            }
        }
        .frame(width: 24, height: 24)
        .animation(reduceMotion ? nil : .easeInOut(duration: 0.2), value: inProgress)
        .animation(reduceMotion ? nil : .easeInOut(duration: 0.2), value: completed)
    }
}

private struct BlockingRuleRow: View {
    @Environment(\.locale) private var locale
    let rule: BlockingRule
    var writing = false

    var body: some View {
        HStack(spacing: 12) {
            if rule.category.isUser {
                UserAvatarView(imageId: rule.avatar)
                    .frame(width: 40, height: 40)
                    .accessibilityHidden(true)
            }
            VStack(alignment: .leading, spacing: 4) {
                Text(rule.tag?.displayName(locale: locale) ?? rule.displayName)
                if rule.category.isUser, let uid = rule.uid {
                    Text(verbatim: "UID \(uid)").font(.caption).foregroundStyle(.secondary)
                }
                Text(rule.createdAt, format: .dateTime.year().month().day())
                    .font(.caption).foregroundStyle(.secondary)
            }
            Spacer(minLength: 8)
            if writing {
                ProgressView().accessibilityLabel(Text(.blockingWriting))
            }
        }
        .accessibilityElement(children: .combine)
    }
}

private struct BlockingEditorView: View {
    @Bindable var model: SettingsBlockingRulesViewModel
    let editorID: UUID

    private var input: Binding<String> {
        Binding(get: { model.editor?.id == editorID ? model.editor?.input ?? "" : "" }, set: { value in
            guard model.editor?.id == editorID else { return }
            model.inputChanged(value)
        })
    }
    private var alert: Binding<Bool> {
        Binding(get: { model.editor?.id == editorID && model.showConfirmationError }, set: { model.showConfirmationError = $0 })
    }
    private var inputTitle: LocalizedStringResource {
        model.category.isUser ? .blockingInputUid : model.category == .tag ? .blockingInputTag : .blockingInputText
    }
    private var actionTitle: LocalizedStringResource {
        if model.category.isUser { return model.editor?.profile == nil ? .blockingLookup : .blockingAdd }
        return model.category == .tag ? .blockingSearchTags : .blockingAdd
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField(inputTitle, text: input, axis: .vertical)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .keyboardType(model.category.isUser ? .numberPad : .default)
                        .disabled(model.isWriting || !model.canAdd)
                } footer: {
                    if model.category == .keyword || model.category == .regex {
                        Text(.blockingTextLimit)
                    }
                }
                if let profile = model.editor?.profile {
                    Section {
                        HStack(spacing: 12) {
                            UserAvatarView(imageId: profile.avatar).frame(width: 40, height: 40)
                                .accessibilityHidden(true)
                            VStack(alignment: .leading, spacing: 4) {
                                Text(profile.displayName)
                                Text(verbatim: "UID \(profile.uid)").font(.caption).foregroundStyle(.secondary)
                            }
                        }
                    }
                }
                if let tags = model.editor?.tags {
                    Section {
                        if tags.isEmpty { Text(.blockingEmpty).foregroundStyle(.secondary) }
                        ForEach(tags) { tag in
                            BlockingTagChoice(tag: tag, enabled: model.canAdd) { model.selectTag(tag) }
                        }
                    }
                }
                if let error = model.editor?.error {
                    Section { Text(error).foregroundStyle(.red) }
                }
                if model.isWriting || model.isConfirming || model.isLookingUp {
                    Section {
                        HStack(spacing: 12) {
                            ProgressView()
                            Text(model.isWriting ? .blockingWriting : model.isConfirming ? .blockingConfirming : model.category == .tag ? .blockingSearchTags : .blockingLookup)
                        }
                    }
                }
            }
            .navigationTitle(model.category.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(.actionCancel, role: .cancel) { model.closeEditor(id: editorID) }
                        .disabled(model.isWriting)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(actionTitle, action: model.submitEditor)
                        .disabled(!model.canAdd || model.isLookingUp || input.wrappedValue.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .alert(.blockingConfirmationPending, isPresented: alert) {
                Button(.errorTryAgain, action: model.retryConfirmation)
                Button(.actionCancel, role: .cancel) {}
            } message: { Text(.blockingConfirmationDescription) }
        }
        .interactiveDismissDisabled(model.isWriting)
    }
}

private struct BlockingTagChoice: View {
    @Environment(\.locale) private var locale
    let tag: BlockingTag
    let enabled: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) { Text(tag.displayName(locale: locale)) }
            .disabled(!enabled)
    }
}

// Presentation-only controls exercise toolbar insertion and feedback without accounts or requests.
private struct BlockingToolbarPreview: View {
    @State private var presented = false
    @State private var inProgress = false
    @State private var completed = false

    var body: some View {
        NavigationStack {
            List {
                Button {
                    presented.toggle()
                } label: {
                    Text(verbatim: "Show / hide loaded toolbar")
                }
                Button {
                    inProgress = true
                    completed = false
                } label: {
                    Text(verbatim: "Begin operation")
                }
                Button {
                    inProgress = false
                    completed = true
                } label: {
                    Text(verbatim: "Confirm success")
                }
                Button {
                    inProgress = false
                    completed = false
                } label: {
                    Text(verbatim: "Restore add action")
                }
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
            .background(Color(uiColor: .systemGroupedBackground).ignoresSafeArea())
            .navigationTitle(.blockingKeyword)
            .toolbar {
                if presented {
                    ToolbarItem(placement: .primaryAction) {
                        BlockingToolbarAction(
                            inProgress: inProgress,
                            confirming: false,
                            completed: completed,
                            enabled: true,
                            action: {
                                inProgress = true
                                completed = false
                            }
                        )
                    }
                }
            }
        }
    }
}

#Preview("Toolbar · Interactive") { BlockingToolbarPreview() }
#Preview("Toolbar · Dark") {
    BlockingToolbarPreview()
        .preferredColorScheme(.dark)
}

#Preview("用户与标签 · 中文") {
    List {
        BlockingRuleRow(rule: BlockingRule(category: .block, value: "example-user", createdAt: .distantPast, uid: 42, userNickname: "示例用户"))
        BlockingRuleRow(rule: BlockingRule(category: .hide, value: "missing-uid-example", createdAt: .distantPast, userNickname: "资料暂缺"))
        BlockingRuleRow(rule: BlockingRule(category: .tag, value: "7", createdAt: .distantPast, tag: BlockingTag(tagId: 7, tagNameList: [.init(lang: "zh-Hans", tagName: [.init(name: "示例标签", isDefault: true, isOriginalTagName: true)])])))
    }
    .environment(\.locale, Locale(identifier: "zh-Hans"))
}

#Preview("空列表") {
    List { ContentUnavailableView { Label(.blockingEmpty, systemImage: "nosign") } }
}

#Preview("加载中") {
    LoadingView()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(uiColor: .systemGroupedBackground).ignoresSafeArea())
}
#Preview("加载失败") {
    ErrorView(errorMessage: String(localized: "BLOCKING_ERROR_INVALID_RESPONSE"))
        .refreshable {}
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(uiColor: .systemGroupedBackground).ignoresSafeArea())
}
#Preview("需要登录") {
    BlockingSignedOutView()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(uiColor: .systemGroupedBackground).ignoresSafeArea())
}

#Preview("Keyword row · English · Dark") {
    List {
        BlockingRuleRow(rule: BlockingRule(category: .keyword, value: "Example keyword", createdAt: .distantPast))
        BlockingRuleRow(rule: BlockingRule(category: .regex, value: "example.*", createdAt: .distantPast), writing: true)
    }
    .environment(\.locale, Locale(identifier: "en"))
    .environment(\.dynamicTypeSize, .accessibility3)
    .preferredColorScheme(.dark)
}
