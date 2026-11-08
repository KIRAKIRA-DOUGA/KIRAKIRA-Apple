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

## Accounts and Sessions

`AuthManager.shared` stores accounts in the Keychain and the selected account and guest mode in `UserDefaults`. `sessionRevision` increments only on explicit session transitions (`switchAccount(to:)`, `continueAsGuest()`), not on profile refreshes. Account-scoped work, such as loading or saving per-user settings, should capture the revision and credentials when it starts and discard its result if the session changed. Features must read account state through `AuthManager` rather than the Keychain or the account `UserDefaults` keys. Local app preferences belong in `AppSettings` via `@AppStorage`.

## Settings Navigation

Settings screens are pushed through `SettingsPath` values handled by `SettingsView`'s `navigationDestination`. Add a case to `SettingsPath` and a branch there instead of using inline `NavigationLink { }` destinations. Only when leaving would interrupt a state-changing operation that needs protection (such as a save in flight) should a child screen publish `SettingsOperationInProgressPreferenceKey` as true; `SettingsView` then disables the close button and interactive dismissal. Do not drive this preference or back-button hiding from a general `busy` flag that also includes read-only loading.

## Localization

`Localizable.xcstrings` uses `zh-Hans` as the source language and must stay complete for both `zh-Hans` and `en`. Keys are `SCREAMING_SNAKE_CASE`, such as `PRIVACY_FOLLOWERS_ONLY`. `STRING_CATALOG_GENERATE_SYMBOLS` exposes keys as symbols, so prefer `Text(.settingsPrivacy)` and `Label(.settingsPrivacy, systemImage:)` in SwiftUI, and use `String(localized: "KEY")` only where a `String` is required. Add both translations in the same change as the code that introduces a key, and call out localization changes in pull requests.

## Testing Guidelines

`KIRAKIRATests` is an XCTest unit-test target hosted in the app and included in the shared scheme (not parallelizable). When the app launches under XCTest, `KIRAKIRAApp` renders `Color.clear` instead of `MainView`, so hosted tests never restore real accounts or send production requests. Preserve this guard.

- Name files after the type under test, such as `PrivacySettingsServiceTests.swift`, and name methods after behaviors, such as `testRequestRejectsHTTPError()`.
- Mock at protocol boundaries (`PrivacySettingsServiceProtocol`, `PrivacySettingsTransport`, `PrivacySessionProviding`). Never hit the network, the real Keychain, or `UserDefaults.standard`. Use `AuthManager(accounts:defaults:accountStore:)` with an isolated `UserDefaults` suite for session tests.
- Use fixtures from `Support/` with obviously fake credentials (`example.invalid` emails, non-token strings).
- For ordering or cancellation tests, control timing with gates like `Support/PrivacyAsyncGate.swift` instead of `Task.sleep`.
- Favor deterministic unit tests, and add UI tests only for critical flows. No coverage threshold is enforced, but changed state transitions, cancellation, and error paths should be covered.

Run tests with Command-U in Xcode or with the `xcodebuild test` command above.

## Commit & Pull Request Guidelines

Recent commits use short, imperative summaries such as `Refine loading state handling`, `Fix refresh`, and `Use dark navigation bar in video player`. Keep each commit focused: commit unrelated UI tweaks separately from feature work, and avoid unrelated formatting churn. Pull requests should explain the user-visible effect, list verification performed, link relevant issues, and include screenshots or recordings for UI changes. Call out dependency, localization, entitlement, or deployment-target changes explicitly.
