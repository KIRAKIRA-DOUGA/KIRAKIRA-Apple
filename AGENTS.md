# Repository Guidelines

## Project Structure & Module Organization

`KIRAKIRA/` contains the SwiftUI application. `KIRAKIRAApp.swift` is the app entry point and `MainView.swift` owns top-level navigation. Organize screen-specific code under `Features/<Feature>/`, reusable UI under `Components/`, network code under `API/`, shared state under `Managers/`, data types under `Models/`, and formatting or preview helpers under `Styles/`. Images, colors, localization, the launch storyboard, and app icons live in `KIRAKIRA/Resources/`. Swift Package Manager dependencies are pinned in `KIRAKIRA.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved`.

## Build, Test, and Development Commands

- `open KIRAKIRA.xcodeproj` opens the project in Xcode. Select the shared `KIRAKIRA` scheme and run with Command-R.
- `xcodebuild -project KIRAKIRA.xcodeproj -scheme KIRAKIRA -configuration Debug -destination 'generic/platform=iOS Simulator' build` performs a command-line simulator build.
- `xcodebuild -project KIRAKIRA.xcodeproj -scheme KIRAKIRA -configuration Debug analyze` runs Xcode's static analyzer.
- `xcodebuild -resolvePackageDependencies -project KIRAKIRA.xcodeproj` refreshes the pinned Swift package graph.

The project targets iPhone, iPad, and Apple Vision. Keep `Package.resolved` changes when intentionally updating dependencies.

## Coding Style & Naming Conventions

Use four-space indentation and standard Swift formatting: opening braces on the declaration line, trailing commas in multiline arguments when they improve diffs, and one primary type per file. Name types in `UpperCamelCase` and properties/functions in `lowerCamelCase`. Match established suffixes such as `View`, `ViewModel`, `Manager`, `Model`, and `DTO`. Keep UI state on `@MainActor`; prefer structured concurrency (`async`/`await`) and actors for shared mutable services. No SwiftLint or SwiftFormat configuration is committed, so use Xcode formatting and remove warnings before review.

## Refresh and Cancellation Handling

Treat task cancellation as control flow, not as a user-visible request failure. `URLSession` can report a cancelled request as `URLError.cancelled`; normalize that error to `CancellationError` in `APIService` so every feature receives the same cancellation type. Do not show `error.localizedDescription` for cancellation, because it produces messages such as “Cancelled” or “已取消”.

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

## Testing Guidelines

There is currently no checked-in test target. New logic should add an XCTest target named `KIRAKIRATests`, mirroring source folders, with files such as `APIServiceTests.swift` and methods such as `testRequestRejectsHTTPError()`. Favor deterministic unit tests with mocked API boundaries; add UI tests only for critical flows. Run tests from Xcode with Command-U or with `xcodebuild test` against an installed simulator. No coverage threshold is enforced, but changed state transitions and error paths should be covered.

## Commit & Pull Request Guidelines

Recent commits use short, imperative summaries such as `Refine loading state handling` and `Fix refresh`. Keep each commit focused and avoid unrelated formatting churn. Pull requests should explain the user-visible effect, list verification performed, link relevant issues, and include screenshots or recordings for UI changes. Call out dependency, localization, entitlement, or deployment-target changes explicitly.
