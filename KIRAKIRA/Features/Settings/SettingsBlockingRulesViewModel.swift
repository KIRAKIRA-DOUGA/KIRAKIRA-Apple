import Foundation

struct BlockingRuleEditor: Identifiable {
    let id = UUID()
    var input = ""
    var profile: BlockingUser?
    var tags: [BlockingTag]?
    var error: String?
}

@MainActor
@Observable
final class SettingsBlockingRulesViewModel {
    let category: BlockingRuleCategory
    private(set) var state: LoadingState<BlockingRulePage> = .idle
    private(set) var revision: Int?
    private(set) var isWriting = false
    private(set) var isConfirming = false
    private(set) var isAppending = false
    private(set) var isLookingUp = false
    private(set) var appendError: String?
    private(set) var message: String?
    private(set) var successID: UUID?
    private(set) var writingRuleID: String?
    var showConfirmationError = false
    var editor: BlockingRuleEditor?

    private let service: any BlockingSettingsServiceProtocol
    private let session: any BlockingSessionProviding
    private var requiresSignIn = false
    private var readLease: UUID?
    private var writeLease: UUID?
    private var lookupLease: UUID?
    @ObservationIgnored private var operationTask: Task<Void, Never>?
    @ObservationIgnored private var lookupTask: Task<Void, Never>?
    private struct Mutation {
        let target: String
        let removing: Bool
        let rule: BlockingRule
    }
    private var pending: Mutation?
    private var additions: [String: BlockingRule] = [:]
    private var removals: Set<String> = []
    // Offset pagination follows the raw server chain, never the overlaid display count.
    private var serverEntries: [BlockingRule] = []
    private var serverTotal = 0
    private var countEstimate: Int?
    private var nextPage = 2
    private var receivedCount = 0
    private var paginationNeedsRestart = false

    init(category: BlockingRuleCategory, service: (any BlockingSettingsServiceProtocol)? = nil, session: (any BlockingSessionProviding)? = nil) {
        self.category = category
        self.service = service ?? BlockingSettingsService()
        self.session = session ?? AuthManager.shared
    }

    var isCurrentSession: Bool { revision == session.sessionRevision }
    var isSignedIn: Bool { session.credentials != nil && !requiresSignIn }
    private var busy: Bool { isWriting || isConfirming || state.isLoading || isAppending || operationTask != nil }
    var canAdd: Bool { isCurrentSession && isSignedIn && state.value != nil && !busy && pending == nil }
    var canLoadMore: Bool {
        isCurrentSession && isSignedIn && state.value != nil && !busy
            && (paginationNeedsRestart || receivedCount < serverTotal)
    }

    func canRemove(_ rule: BlockingRule) -> Bool {
        canAdd && validTarget(rule) && state.value?.entries.contains(where: { $0.id == rule.id }) == true
    }

    func synchronizeSession() {
        guard !isCurrentSession else { return }
        disappear()
        revision = session.sessionRevision
        state = .idle
        requiresSignIn = false
        pending = nil
        additions = [:]
        removals = []
        countEstimate = nil
        serverEntries = []
        serverTotal = 0
        nextPage = 2
        receivedCount = 0
        paginationNeedsRestart = false
    }

    func load() async {
        synchronizeSession()
        guard isSignedIn, !isWriting, !isAppending, readLease == nil, !Task.isCancelled else { return }
        await read(full: pending != nil)
    }

    private func read(full: Bool) async {
        guard let credentials = session.credentials, isSignedIn, readLease == nil, !Task.isCancelled else { return }
        let expected = session.sessionRevision
        let lease = UUID()
        readLease = lease
        isConfirming = full
        showConfirmationError = false
        state.beginLoading()
        defer {
            if readLease == lease {
                readLease = nil
                isConfirming = false
            }
        }
        do {
            let page = try await service.load(category: category, page: full ? 0 : 1, pageSize: 20, credentials: credentials)
            try Task.checkCancellation()
            guard current(expected), readLease == lease else { return }
            let entries = unique(page.entries)
            if full {
                guard entries.count == page.total,
                      entries.allSatisfy({ $0.category == category && self.validTarget($0) }) else {
                    throw BlockingSettingsError.invalidResponse
                }
                if let mutation = pending {
                    let exists = entries.contains { $0.target == mutation.target }
                    if exists != mutation.removing {
                        pending = nil
                        successID = UUID()
                        if !mutation.removing { editor = nil }
                    }
                }
                receivedCount = entries.count
                nextPage = max(2, entries.count / 20 + 1)
            } else {
                receivedCount = page.entries.count
                nextPage = 2
            }
            serverEntries = entries
            serverTotal = page.total
            appendError = nil
            paginationNeedsRestart = false
            retireObservedOverlays()
            state = .success(renderedPage(page: page.page))
            showConfirmationError = pending != nil
        } catch {
            guard current(expected), readLease == lease else { return }
            handleReadError(error)
        }
    }

    func loadMore() {
        guard canLoadMore, let credentials = session.credentials else { return }
        if paginationNeedsRestart {
            operationTask = Task { [weak self] in
                guard let self else { return }
                await self.load()
                if !Task.isCancelled { self.operationTask = nil }
            }
            return
        }
        let expected = session.sessionRevision
        let lease = UUID()
        readLease = lease
        isAppending = true
        appendError = nil
        let requestedPage = nextPage
        operationTask = Task { [weak self, service, category] in
            guard let self else { return }
            defer {
                if self.readLease == lease {
                    self.readLease = nil
                    self.isAppending = false
                    self.operationTask = nil
                }
            }
            do {
                try Task.checkCancellation()
                guard self.current(expected), self.readLease == lease else { return }
                let page = try await service.load(category: category, page: requestedPage, pageSize: 20, credentials: credentials)
                try Task.checkCancellation()
                guard self.current(expected), self.readLease == lease else { return }
                self.receivedCount += page.entries.count
                self.nextPage += 1
                self.serverEntries = self.unique(self.serverEntries + page.entries)
                self.serverTotal = page.total
                self.retireObservedOverlays()
                self.state = .success(self.renderedPage(page: requestedPage))
                if page.entries.isEmpty { self.receivedCount = max(self.receivedCount, page.total) }
            } catch {
                guard self.current(expected), self.readLease == lease else { return }
                if error is CancellationError || Task.isCancelled { return }
                if BlockingSettingsError.isUnauthorized(error) { self.invalidateAuthorization() }
                else { self.appendError = error.localizedDescription }
            }
        }
    }

    func retryConfirmation() {
        guard pending != nil, !busy else { return }
        operationTask = Task { [weak self] in
            guard let self else { return }
            await self.load()
            // Disappearance/session changes clear this handle and invalidate readLease.
            if !Task.isCancelled { self.operationTask = nil }
        }
    }

    func openEditor() {
        guard canAdd else { return }
        clearMessage()
        successID = nil
        editor = BlockingRuleEditor()
    }

    func closeEditor(id: UUID? = nil) {
        guard !isWriting, id == nil || editor == nil || editor?.id == id else { return }
        lookupTask?.cancel()
        lookupTask = nil
        lookupLease = nil
        isLookingUp = false
        editor = nil
    }

    func inputChanged(_ input: String) {
        guard !isWriting, editor != nil else { return }
        lookupTask?.cancel()
        lookupTask = nil
        lookupLease = nil
        isLookingUp = false
        editor?.input = input
        editor?.profile = nil
        editor?.tags = nil
        editor?.error = nil
    }

    func submitEditor() {
        guard canAdd, var draft = editor else { return }
        let input = draft.input.trimmingCharacters(in: .whitespacesAndNewlines)
        if category.isUser {
            guard let uid = BlockingInput.positiveID(input) else {
                editor?.error = String(localized: "BLOCKING_INVALID_UID")
                return
            }
            guard uid != session.credentials?.uid else {
                editor?.error = String(localized: "BLOCKING_SELF_RULE")
                return
            }
            if let profile = draft.profile, profile.uid == uid {
                change(Mutation(target: String(uid), removing: false, rule: BlockingRule(category: category, value: "local-\(uid)", createdAt: Date(), uid: uid, username: profile.username, userNickname: profile.userNickname, avatar: profile.avatar)))
            } else {
                lookup(input: input, uid: uid)
            }
        } else if category == .tag {
            guard !input.isEmpty else { return }
            lookup(input: input, uid: nil)
        } else {
            guard !input.isEmpty, input.utf16.count <= 30 else {
                draft.error = String(localized: "BLOCKING_INVALID_RULE")
                editor = draft
                return
            }
            change(Mutation(target: input, removing: false, rule: BlockingRule(category: category, value: input, createdAt: Date())))
        }
    }

    func selectTag(_ tag: BlockingTag) {
        guard canAdd, tag.tagId > 0, editor?.tags?.contains(tag) == true else { return }
        change(Mutation(target: String(tag.tagId), removing: false, rule: BlockingRule(category: category, value: String(tag.tagId), createdAt: Date(), tag: tag)))
    }

    private func lookup(input: String, uid: Int?) {
        guard let credentials = session.credentials, let editorID = editor?.id, !isLookingUp else { return }
        let expected = session.sessionRevision
        let lease = UUID()
        lookupLease = lease
        isLookingUp = true
        editor?.error = nil
        lookupTask = Task { [weak self, service] in
            guard let self else { return }
            defer {
                if self.lookupLease == lease {
                    self.lookupLease = nil
                    self.lookupTask = nil
                    self.isLookingUp = false
                }
            }
            do {
                try Task.checkCancellation()
                guard self.current(expected), self.lookupLease == lease, self.editor?.id == editorID else { return }
                if let uid {
                    let profile = try await service.lookupUser(uid: uid, credentials: credentials)
                    try Task.checkCancellation()
                    guard self.current(expected), self.lookupLease == lease, self.editor?.id == editorID else { return }
                    guard profile.uid == uid else { throw BlockingSettingsError.invalidResponse }
                    self.editor?.profile = profile
                } else {
                    let tags = try await service.searchTags(query: input, credentials: credentials)
                    try Task.checkCancellation()
                    guard self.current(expected), self.lookupLease == lease, self.editor?.id == editorID else { return }
                    self.editor?.tags = tags
                }
            } catch {
                guard self.current(expected), self.lookupLease == lease, self.editor?.id == editorID else { return }
                if error is CancellationError || Task.isCancelled { return }
                if BlockingSettingsError.isUnauthorized(error) { self.invalidateAuthorization() }
                else { self.editor?.error = error.localizedDescription }
            }
        }
    }

    func remove(_ rule: BlockingRule) {
        guard canRemove(rule), let target = rule.target else { return }
        change(Mutation(target: target, removing: true, rule: rule))
    }

    private func change(_ mutation: Mutation) {
        guard canAdd, let credentials = session.credentials else { return }
        if !mutation.removing, state.value?.entries.contains(where: { $0.target == mutation.target }) == true {
            editor?.error = String(localized: "BLOCKING_ALREADY_EXISTS")
            return
        }
        let expected = session.sessionRevision
        let lease = UUID()
        writeLease = lease
        successID = nil
        clearMessage()
        showConfirmationError = false
        isWriting = true
        writingRuleID = mutation.removing ? mutation.rule.id : nil
        operationTask = Task { [weak self, service, category] in
            guard let self else { return }
            var sent = false
            var reconcile = false
            do {
                try Task.checkCancellation()
                guard self.current(expected), self.writeLease == lease else { return }
                sent = true
                self.paginationNeedsRestart = true
                self.pending = mutation
                let result = try await service.change(category: category, target: mutation.target, removing: mutation.removing, credentials: credentials)
                try Task.checkCancellation()
                guard self.current(expected), self.writeLease == lease else { return }
                if result == .confirmed {
                    self.pending = nil
                    self.applyConfirmed(mutation)
                }
                reconcile = true
            } catch {
                guard self.current(expected), self.writeLease == lease else { return }
                if error is CancellationError || Task.isCancelled {
                    if !sent { self.pending = nil }
                } else if BlockingSettingsError.isUnauthorized(error) {
                    self.invalidateAuthorization()
                    return
                } else {
                    self.pending = nil
                    if self.editor != nil { self.editor?.error = error.localizedDescription }
                    else { self.message = error.localizedDescription }
                }
            }
            guard self.current(expected), self.writeLease == lease else { return }
            self.isWriting = false
            self.writingRuleID = nil
            if reconcile, !Task.isCancelled { await self.read(full: self.pending != nil) }
            guard self.current(expected), self.writeLease == lease else { return }
            self.writeLease = nil
            self.operationTask = nil
        }
    }

    private func applyConfirmed(_ mutation: Mutation) {
        guard let previous = state.value else { return }
        countEstimate = max(0, previous.total + (mutation.removing ? -1 : 1))
        if mutation.removing {
            additions.removeValue(forKey: mutation.target)
            removals.insert(mutation.target)
        } else {
            removals.remove(mutation.target)
            additions[mutation.target] = mutation.rule
            editor = nil
        }
        state = .success(renderedPage(page: previous.page))
        successID = UUID()
    }

    private func validTarget(_ rule: BlockingRule) -> Bool {
        guard let target = rule.target else { return false }
        return category.isUser || category == .tag ? BlockingInput.positiveID(target) != nil : BlockingInput.isValidText(target)
    }

    private func retireObservedOverlays() {
        let targets = Set(serverEntries.compactMap(\.target))
        additions = additions.filter { !targets.contains($0.key) }
        // Absence on a partial page is never proof that a removal has synchronized.
        if serverEntries.count == serverTotal, serverEntries.allSatisfy(validTarget) {
            removals.formIntersection(targets)
        }
    }

    private func renderedPage(page: Int) -> BlockingRulePage {
        let entries = serverEntries.filter { rule in
            guard let target = rule.target else { return true }
            return !removals.contains(target) && additions[target] == nil
        }
        let visible = unique(additions.values.sorted { $0.createdAt > $1.createdAt } + entries)
        let targets = Set(serverEntries.compactMap(\.target))
        let total: Int
        if serverEntries.count == serverTotal {
            total = visible.count
        } else {
            // Without a server revision, a partial read cannot prove whether its count
            // already includes a local change. Bound uncertainty to outstanding targets,
            // rather than freezing an absolute count or blindly applying every delta.
            let lower = max(visible.count, serverTotal - removals.count)
            let upper = max(lower, serverTotal + additions.keys.filter { !targets.contains($0) }.count - removals.intersection(targets).count)
            total = min(upper, max(lower, countEstimate ?? serverTotal))
        }
        countEstimate = total
        return BlockingRulePage(entries: visible, total: total, page: page)
    }

    private func unique(_ entries: [BlockingRule]) -> [BlockingRule] {
        var seen = Set<String>()
        return entries.filter { seen.insert($0.id).inserted }
    }

    private func handleReadError(_ error: Error) {
        if error is CancellationError || Task.isCancelled { state.cancelLoading() }
        else if BlockingSettingsError.isUnauthorized(error) { invalidateAuthorization() }
        else if pending != nil {
            state.cancelLoading()
            showConfirmationError = true
        } else if state.value != nil {
            state.cancelLoading()
            message = error.localizedDescription
        } else { state = .error(error.localizedDescription) }
    }

    private func current(_ expected: Int) -> Bool {
        revision == expected && session.sessionRevision == expected
    }

    private func invalidateAuthorization() {
        disappear()
        requiresSignIn = true
        state = .idle
        pending = nil
        additions = [:]
        removals = []
        countEstimate = nil
        serverEntries = []
        serverTotal = 0
    }

    func disappear() {
        operationTask?.cancel()
        lookupTask?.cancel()
        operationTask = nil
        lookupTask = nil
        readLease = nil
        writeLease = nil
        lookupLease = nil
        isWriting = false
        isConfirming = false
        isAppending = false
        isLookingUp = false
        writingRuleID = nil
        appendError = nil
        showConfirmationError = false
        successID = nil
        editor = nil
        state.cancelLoading()
        clearMessage()
    }

    func clearMessage() { message = nil }

    func waitForOperations() async {
        await operationTask?.value
        await lookupTask?.value
    }
}
