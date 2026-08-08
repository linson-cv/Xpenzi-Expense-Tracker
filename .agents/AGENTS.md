# Project Instructions & Agent Guidelines

## 1. Changelog Maintenance & Version Updates
- **Automatic Changelog Update**: Whenever the application version is changed/bumped (e.g., in `pubspec.yaml` or build Gradle files), the changelog in [`lib/widgets/showChangelog.dart`](file:///d:/Projects/Android%20Apps/Xpenzi-Expense-Tracker/lib/widgets/showChangelog.dart) MUST be updated.
- **Preserve Historical Logs**: **NEVER delete, truncate, or overwrite previous version changelog entries.** All past version release notes must remain intact to support full historical viewing on the Detailed Changelog screen.
- **Changelog Entry Structure**:
  - Prepend the new version block at the top of `getChangelogString()` using `< X.Y.Z` (e.g. `< 5.3.6`).
  - Use `(A)` for Android-specific improvements and `(i)` for iOS-specific improvements.
  - If a major feature or new navigation page is added, update `getMajorChanges()` to include a `MajorChanges` definition with an icon and direct route navigation.

## 2. Token Size Reduction & Efficiency Guidelines
- **Input Token Reduction**:
  - **Targeted Line Range Reading**: Large source files (such as `showChangelog.dart` [2,600+ lines] or `addTransactionPage.dart` [5,000+ lines]) MUST NEVER be loaded entirely into context. Use targeted line-range viewing (e.g. `StartLine`/`EndLine` ranges of 100–300 lines) to conserve LLM context tokens.
  - **Selective Searching**: Use targeted `grep_search` queries with specific file globs instead of listing entire directory structures.
  - **Avoid Heavy Data Reads**: Never read large asset files (e.g., full JSON dictionaries or database dumps) into LLM context unless strictly required for schema debugging.
- **Output Token Reduction**:
  - **Concise Summaries**: Keep model responses, changelog entries, and walkthroughs succinct, clear, and structured. Single-line summaries minimize token usage during future reads.
  - **Localized Code Edits**: Perform exact line replacement chunks rather than replacing large surrounding blocks of code.
  - **Direct File Operations**: Write generated scripts and documentation directly to artifact files on disk rather than streaming extensive code blocks into chat output.
  - **No Unrequested Code Sprawls**: Only output necessary diffs and summaries; do not repeat unmodified source code files.

## 3. Build & Compilation Execution Guidelines
- **Do Not Build Automatically**: NEVER launch expensive build or compilation tasks (such as `flutter build apk`, `flutter build appbundle`, `flutter build ipa`, `flutter build web`, etc.) automatically after modifying code or configuration files **unless explicitly requested by the user**. Apply code/config edits and report changes cleanly without initiating unrequested build tasks.

## 4. App Branding & Identity Context
- **App Name**: Xpenzi
- **Package ID**: `com.navlin.xpenzi`
- **Baseline Version**: `1.0.0+1`
- **Origin & Background**: Forked from open-source [Cashew](https://github.com/jameskokoska/Cashew). Maintained as an independent, feature-rich new application.
- **Upstream Repository**: https://github.com/jameskokoska/Cashew
- **Migration & Compatibility**: Maintain full backup/restore and import compatibility for Cashew `.json`/`.csv` files so migrating users can seamlessly transfer data to Xpenzi.

## 5. Architectural & Technical Overview

- **Database Architecture**: Built using **Drift (Moor)** with SQLite engine (`lib/database/tables.dart`). Schema Version: 46. Key tables: `Transactions`, `Wallets` (`TransactionWallet`), `Categories` (`TransactionCategory`), `Budgets`, `Objectives` (Goals/Loans), `DeleteLogs`.
- **State Management & Global Settings**: Driven by `appStateSettings` (`lib/struct/settings.dart`), `sharedPreferences`, and `databaseGlobal.dart`.
- **Localization**: Uses `easy_localization` with CSV/JSON translation dictionaries under `assets/translations/`.
- **UI Framework & Design System**: Responsive Flutter layout with custom navigation sidebar/bar (`navigationFramework.dart`, `navigationSidebar.dart`), Material 3 dynamic color palette (`colors.dart`), and customizable home widgets (`homePageWidgetDisplay`).
- **Core Feature Areas**:
  - Multi-wallet & Multi-currency management with real-time conversion.
  - Category & Subcategory spending limit tracking.
  - Recurring, Scheduled, & Subscriptions auto-payment engine.
  - Goals & Long-Term Loans (Lent / Borrowed tracking).
  - Data Import/Export: Backup JSON & CSV import/export wizards supporting legacy Cashew format.




