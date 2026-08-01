# Project Instructions & Agent Guidelines

## 1. Changelog Maintenance & Version Updates
- **Automatic Changelog Update**: Whenever the application version is changed/bumped (e.g., in `pubspec.yaml` or build Gradle files), the changelog in [`lib/widgets/showChangelog.dart`](file:///d:/Projects/Android%20Apps/Spendwise-Expense-Tracker/lib/widgets/showChangelog.dart) MUST be updated.
- **Preserve Historical Logs**: **NEVER delete, truncate, or overwrite previous version changelog entries.** All past version release notes must remain intact to support full historical viewing on the Detailed Changelog screen.
- **Changelog Entry Structure**:
  - Prepend the new version block at the top of `getChangelogString()` using `< X.Y.Z` (e.g. `< 5.3.6`).
  - Use `(A)` for Android-specific improvements and `(i)` for iOS-specific improvements.
  - If a major feature or new navigation page is added, update `getMajorChanges()` to include a `MajorChanges` definition with an icon and direct route navigation.

## 2. Token Size Reduction & Efficiency Guidelines
- **Targeted Line Range Reading**: Large source files (such as `showChangelog.dart`, which is 2,600+ lines) should NEVER be loaded entirely into context unless strictly necessary. Use line-range viewing (e.g., lines 25–75 for top changelog entries, lines 2450–2550 for popup logic) to conserve LLM context tokens.
- **Concise Single-Line Summaries**: Keep changelog text entries succinct and clear. Single-line summaries minimize both file size and token consumption during future edits.
- **Localized Code Edits**: Perform exact line edits rather than replacing large chunks of code, ensuring low token overhead for diffs and pull request context windows.
