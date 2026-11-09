# Repository Guidelines

## Project Structure & Module Organization

`KIRAKIRA/` contains the SwiftUI application. `KIRAKIRAApp.swift` is the app entry point and `MainView.swift` owns top-level navigation.

- `Features/<Feature>/` holds screen-specific views and their view models, such as `Features/Settings/SettingsPrivacyView.swift` and `SettingsPrivacyViewModel.swift`. Keep feature-private helpers (small protocols, preference keys, route enums) in the feature that uses them; move them out only when a second feature needs them.
- `Components/` holds reusable UI and shared UI state such as `LoadingState.swift`, `States/LoadingView.swift`, and `States/ErrorView.swift`.
- `API/` holds networking: `APIService` (an actor and the only `URLSession` owner), `Endpoint` (paths, HTTP methods, and the base URL), `APIError`, and feature services such as `PrivacySettingsService` with their protocols, feature error types, and service operation results such as `PrivacySaveResult`.
- `Managers/` holds app-wide shared state and singletons, such as `AuthManager`, `GlobalStateManager`, and `ToastManager`.
- `Models/` holds data types, not only backend DTOs: request/response wire types use a `DTO` suffix; domain models and business value types/enums such as `PrivacySettings`, `PrivacyItem`, and `PrivacyVisibility` also belong here. Keep this layer focused on data, identity, validation, and mapping rather than screen presentation or service workflow state.
- Follow nearby code and the existing project structure before introducing new layering or file conventions. Small display-only extensions can live in the View file that uses them, with `fileprivate` members, as `FollowListKind` does in `UserFollowListView.swift` and the privacy enums do in `SettingsPrivacyView.swift`. Simple feature enums may also keep their display properties directly, as `Category` and `ViewStyle` do. Do not require separate `+Presentation.swift` files; split or extract code when its size or actual reuse warrants it.
- Keep closely related small types together: service outcomes such as `PrivacySaveResult` can live in `PrivacySettingsService.swift`; screen-only helpers can live with their View or ViewModel; related data models, enums, and DTOs can share a model file, as in `DanmakuModel.swift`, `UserProfileModel.swift`, and `PrivacySettingsModel.swift`. For a cohesive group of small models, prefer the existing `<Subject>Model.swift` convention rather than creating one file per enum or DTO. For example, keep `PrivacyItem`, `PrivacyVisibility`, `PrivacySettings`, and the privacy request/response DTOs together in `PrivacySettingsModel.swift`; split only when size, distinct responsibilities, or reuse makes it useful. DTOs and domain models may share small Codable value types when their representations match; a separate DTO-to-domain copy is not required solely for folder organization.
- `Styles/` holds format styles and preview helpers such as `.commonPreviewTrait`.
- `Resources/` holds `Assets.xcassets`, `AppIcon.icon`, `Localizable.xcstrings`, and `InfoPlist.xcstrings`.

`KIRAKIRATests/` mirrors the app folders (`API/`, `Features/<Feature>/`, `Managers/`, `Models/`). Put test doubles in `KIRAKIRATests/Mocks/` and shared fixtures or async helpers in `KIRAKIRATests/Support/`. Do not leave files at the test root.

Both targets use Xcode file-system synchronized groups, so adding, moving, or renaming files on disk needs no `project.pbxproj` edit. Edit the project file only for build settings, targets, or package changes.

Swift Package Manager dependencies (Kingfisher, SwiftUI-Flow, VariableBlur) are pinned in `KIRAKIRA.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved`.

## Related Repositories

- `/Users/aira/Documents/GitHub/KIRAKIRA-Rosales` is the backend serving `https://rosales.kirakira.moe`. Check `src/route/router.ts` and its controllers for request and response shapes before adding or changing an `Endpoint` or DTO. Preserve backend field names in `CodingKeys`, including misspellings such as `privaryId`.
- `/Users/aira/AndroidStudioProjects/KIRAKIRA-Compose` is the Android client. Use it as a behavioral reference for shared features. It has its own `AGENTS.md`; do not apply its conventions here.

## Build, Test, and Development Commands

- `open KIRAKIRA.xcodeproj` opens the project in Xcode. Select the shared `KIRAKIRA` scheme and run with Command-R.
- `xcodebuild -project KIRAKIRA.xcodeproj -scheme KIRAKIRA -configuration Debug -destination 'generic/platform=iOS Simulator' build` performs a command-line simulator build.
- `xcodebuild test -project KIRAKIRA.xcodeproj -scheme KIRAKIRA -destination 'platform=iOS Simulator,name=<installed iPhone>'` runs the unit tests. List installed simulators with `xcrun simctl list devices available`.
- `xcodebuild -project KIRAKIRA.xcodeproj -scheme KIRAKIRA -configuration Debug analyze` runs Xcode's static analyzer.
- `xcodebuild -resolvePackageDependencies -project KIRAKIRA.xcodeproj` refreshes the pinned Swift package graph.

The app targets iPhone, iPad, and Mac Catalyst (`TARGETED_DEVICE_FAMILY = 1,2,6`) with an iOS 26.2 deployment target. There is no native visionOS or macOS target, so avoid adding `os(visionOS)` branches. Keep `Package.resolved` changes only when intentionally updating dependencies. Result bundles (`*.xcresult/`) are git-ignored; write them outside the repository or let Xcode manage them.

## Coding Style & Naming Conventions

Use four-space indentation and standard Swift formatting: opening braces on the declaration line and trailing commas in multiline arguments when they improve diffs. Keep files focused, but follow existing practice by grouping closely related small types and extensions instead of enforcing one type per file. Name types in `UpperCamelCase` and properties/functions in `lowerCamelCase`. Match established suffixes such as `View`, `ViewModel`, `Manager`, `Service`, `Model`, and `DTO`. No SwiftLint or SwiftFormat configuration is committed, so use Xcode formatting and remove warnings before review.

## Concurrency

The app and test targets build in Swift 5 language mode with `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor`, and the app also enables approachable concurrency. Every declaration is therefore main-actor isolated unless marked otherwise.

- View models are `@MainActor @Observable final class`. Keep UI state on the main actor.
- Mark value types that are decoded, encoded, or passed into `APIService` or other actors as `nonisolated` (and `Sendable` where possible), as the privacy models do.
- Use actors for shared mutable services, and prefer structured concurrency (`async`/`await`, `.task`) over `DispatchQueue`.
- Inject dependencies through protocols with production defaults, such as `init(service: (any PrivacySettingsServiceProtocol)? = nil)`, so tests can substitute mocks without touching singletons.

## Refresh and Cancellation Handling

Treat task cancellation as control flow, not as a user-visible request failure. `URLSession` can report a cancelled request as `URLError.cancelled`; `APIService` normalizes that error to `CancellationError` so every feature receives the same cancellation type. Do not show `error.localizedDescription` for cancellation, because it produces messages such as “Cancelled” or “已取消”.

Use the existing `LoadingState` pattern in view models shared by `.task` and `.refreshable`:

```swift
state.beginLoading()

do {
    // Perform the request and update state.
} catch is CancellationError {
    state.cancelLoading()
} catch {
    state = .error(error.localizedDescription)
}
```

`cancelLoading()` restores previously loaded content when available and returns an initial cancelled load to `.idle`. Catch `CancellationError` before a general `catch`. For ordinary pull-to-refresh flows, follow this pattern rather than adding generation counters: counters ignore stale results but do not cancel their underlying requests and can make loading-state restoration inconsistent. Introduce explicit task ownership or latest-request-wins logic only when the feature genuinely permits overlapping requests and documents that behavior.

For ordinary full-page loading, reuse `Components/States/LoadingView.swift`, as `HomeView` does, rather than introducing a labeled spinner or extra loading copy. Refreshes should keep existing content visible when available. Read-only requests (initial loads, refreshes, retries, and synchronization reads) must not hide the back button, disable the close button, or block interactive dismissal. Let users leave immediately and handle cancellation and late results through the existing task lifecycle.

For full-page error states, always reuse `Components/States/ErrorView.swift` instead of building a feature-specific error view or another `ContentUnavailableView` with error labels and retry buttons. `ErrorView` already wraps `ContentUnavailableView` and reads `@Environment(\.refresh)` for retry; supply an awaited read-only retry with `.refreshable { await viewModel.load() }` (or the feature's equivalent async load method). A retry must not automatically replay a state-changing request. Keep ordinary empty and signed-out states distinct from errors, and preserve existing content for ordinary refresh failures when the feature supports it.

Attach pull-to-refresh to the actual `List` or `Form`, and await the read directly in `.refreshable { await viewModel.load() }`; do not launch an unstructured `Task` inside the refresh closure and return early. Keep short and empty content refreshable with `.scrollBounceBehavior(.always, axes: .vertical)` where needed. Calling `RefreshAction` programmatically does not guarantee the native pull-to-refresh indicator will appear; use a separate operation indicator for automatic synchronization instead of bridging UIKit solely to force that indicator.

## Mutation Results and Confirmation

- Distinguish confirmed success, definite rejection, and an uncertain write result at the service boundary. A timeout, malformed response, or cancellation after a write may have reached the server is not proof that the write failed. Never automatically replay an uncertain state-changing request; ordinary read failures must not create a pending-write state.
- Give post-write confirmation reads one owner. In the settings flows, services return the write outcome and the view model performs at most one automatic read for an unconfirmed result; do not also hide a confirmation read inside the save service. Release write-only dismissal protection before awaiting that read, while keeping a distinct confirming state for progress. Cancellation stops the automatic flow without an error alert; reconcile any remaining uncertainty on a later read.
- When confirmation remains unresolved or its read fails, preserve existing content and use a native alert with read-only retry and cancel, rather than replacing the page with an error or inserting an extra warning section. Dismissing the alert must not clear the pending operation or its duplicate-write protection; another failed retry must be able to present the alert again.
- Define confirmation by the feature's contract rather than treating any successful read as write success. Privacy reads restore actual server values and allow editing again, but show save success only when those values match the attempted change. Invitation creation keeps its pending safeguard until a new code appears relative to the captured baseline; an unchanged list does not prove failure. Do not copy one feature's resolution rule into another without checking its semantics.
- Keep explicitly confirmed writes successful even if a later synchronization read fails or is temporarily stale. Where needed, retain newly confirmed content until the server's read model catches up; do not turn a failed synchronization into a failed write or lose the confirmed result.

## Toolbar Actions and Feedback

For actions that require loaded account data, create the toolbar item only once the current signed-in session has a loaded value (`state.value != nil`), including a successfully loaded empty collection. Do not show an initially disabled action merely to enable it at the end of the first load. Keep the item present during subsequent refreshes using the previous loaded value, rather than toggling its visibility with `!state.isLoading`. Preserve native toolbar appearance transitions; do not broadly disable animations to work around an unverified visual cause.

Treat the toolbar item's first appearance separately from transitions between its action, progress, and success content. A symbol content transition does not animate insertion of the whole toolbar item. For settings screens, let SwiftUI insert the item directly when the loaded-data condition becomes true, consistently with invitations and privacy. Do not add mirrored presentation state, artificial delays, or whole-list animations solely to force an unverified toolbar appearance effect. Keep internal progress/success transitions local and respect Reduce Motion; verify native appearance on a device or presentation-only preview before claiming a visual result.

Prefer local progress and brief success feedback for small actions: a spinner while writing or confirming, then a checkmark for about two seconds before restoring the normal action or menu. Do not also show a success toast for the same acknowledgement. Keep action labels meaningful for VoiceOver and expose progress/success separately; a standalone success checkmark is not an action. Respect Reduce Motion and trigger success haptics only for confirmed success (or a completed local action such as copying), not for pending or cancelled requests.

Tie temporary feedback to a cancellable `.task(id:)` with an identity token, so an older timeout cannot clear newer feedback. Clear transient feedback on a new operation, session change, and disappearance. Timed UI feedback may sleep; request-ordering tests must use gates instead.

## Accounts and Sessions

`AuthManager.shared` stores accounts in the Keychain and the selected account and guest mode in `UserDefaults`. `sessionRevision` increments only on explicit session transitions (`switchAccount(to:)`, `continueAsGuest()`), not on profile refreshes. Account-scoped work, such as loading or saving per-user settings, should capture the revision and credentials when it starts and discard its result if the session changed. Features must read account state through `AuthManager` rather than the Keychain or the account `UserDefaults` keys. Local app preferences belong in `AppSettings` via `@AppStorage`.

For task-owning screens, invalidate operation identities as well as cancelling owned tasks on disappearance or a session transition. Check cancellation and operation/session identity before sending a queued mutation, and recheck identity after every suspension before changing data, progress flags, task handles, or feedback. A session revision alone does not protect against leaving and re-entering the same screen in the same session. Keep `.task` and `.refreshable` reads structured; explicitly owned button tasks need matching cancellation and cleanup. Discarding a late response prevents stale UI updates but is not the same as cancelling its underlying request.

## Settings Navigation

Settings screens are pushed through `SettingsPath` values handled by `SettingsView`'s `navigationDestination`. Add a case to `SettingsPath` and a branch there instead of using inline `NavigationLink { }` destinations. Only when leaving would interrupt a state-changing operation that needs protection (such as a save in flight) should a child screen publish `SettingsOperationInProgressPreferenceKey` as true; `SettingsView` then disables the close button and interactive dismissal. Do not drive this preference or back-button hiding from a general `busy` flag that also includes read-only loading.

For grouped settings screens, give the root content a full-size frame and a semantic `systemGroupedBackground` extending through the safe areas, so loading, error, signed-out, empty, and loaded states share the same background. Use an inset-grouped `List`/`Form` and hide its scroll-content background when the root owns that background; do not rely on a loaded list's default background to style the other states.

## Localization

`Localizable.xcstrings` uses `zh-Hans` as the source language and must stay complete for both `zh-Hans` and `en`. Keys are `SCREAMING_SNAKE_CASE`, such as `PRIVACY_FOLLOWERS_ONLY`. `STRING_CATALOG_GENERATE_SYMBOLS` exposes keys as symbols, so prefer `Text(.settingsPrivacy)` and `Label(.settingsPrivacy, systemImage:)` in SwiftUI, and use `String(localized: "KEY")` only where a `String` is required. Add both translations in the same change as the code that introduces a key, and call out localization changes in pull requests.

Reuse shared action keys such as `.errorTryAgain` and `.actionCancel` when the meaning matches, rather than adding feature-specific copies of “Retry” or “Cancel”. Remove obsolete keys only after checking both symbol and raw-key references across the repository; keep genuinely different actions such as synchronization distinct when their meaning requires it.

## Testing Guidelines

`KIRAKIRATests` is an XCTest unit-test target hosted in the app and included in the shared scheme (not parallelizable). When the app launches under XCTest, `KIRAKIRAApp` renders `Color.clear` instead of `MainView`, so hosted tests never restore real accounts or send production requests. Preserve this guard.

- Name files after the type under test, such as `PrivacySettingsServiceTests.swift`, and name methods after behaviors, such as `testRequestRejectsHTTPError()`.
- Mock at protocol boundaries (`PrivacySettingsServiceProtocol`, `PrivacySettingsTransport`, `PrivacySessionProviding`). Never hit the network, the real Keychain, or `UserDefaults.standard`. Use `AuthManager(accounts:defaults:accountStore:)` with an isolated `UserDefaults` suite for session tests.
- Use fixtures from `Support/` with obviously fake credentials (`example.invalid` emails, non-token strings).
- For ordering or cancellation tests, control timing with gates like `Support/PrivacyAsyncGate.swift` instead of `Task.sleep`.
- Favor deterministic unit tests, and add UI tests only for critical flows. No coverage threshold is enforced, but changed state transitions, cancellation, and error paths should be covered.
- For write/confirmation flows, test confirmed success, definite failure, unresolved results, cancellation (including before a queued write starts), dismissal of the retry alert, repeated read-only retries, session changes, and leaving/re-entering the same session. Assert read/write counts as well as state, and verify that old completions cannot clear a newer operation's progress or show feedback.
- Include view-model tests using the real feature service with a mock transport, not just a mock service, when confirmation crosses those layers. Cover matching and differing server values and read/authentication failures; this catches hidden duplicate reads and lost actual server state that isolated tests can miss.
- Keep previews presentation-only or inject fake dependencies; do not instantiate production account/network flows to display sample UI. A successful build or unit-test run does not establish native animation, alert, VoiceOver, or pull-gesture behavior. Report those checks separately and leave unobserved visual results explicitly unverified.

Run tests with Command-U in Xcode or with the `xcodebuild test` command above.

## Commit & Pull Request Guidelines

Recent commits use short, imperative summaries such as `Refine loading state handling`, `Fix refresh`, and `Use dark navigation bar in video player`. Keep each commit focused: commit unrelated UI tweaks separately from feature work, and avoid unrelated formatting churn. Pull requests should explain the user-visible effect, list verification performed, link relevant issues, and include screenshots or recordings for UI changes. Call out dependency, localization, entitlement, or deployment-target changes explicitly.
