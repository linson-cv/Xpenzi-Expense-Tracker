# Project Instructions & Agent Guidelines

## 1. Changelog & Versioning
- **Automatic Changelog**: Update [`lib/widgets/showChangelog.dart`](file:///d:/Projects/Android%20Apps/Xpenzi-Expense-Tracker/lib/widgets/showChangelog.dart) whenever bumping app version.
- **Preserve History**: Never delete or truncate prior changelogs.
- **Format**: Prepend `< X.Y.Z` at the top of `getChangelogString()`. Use `(A)` for Android and `(i)` for iOS notes.

## 2. Token Efficiency & Context Management
- **Targeted File Reading**: Never load large source files (>500 lines) fully. Read specific 50–200 line slices via `StartLine`/`EndLine`.
- **Targeted Search**: Use specific `grep_search` globs/queries instead of directory tree dumps.
- **Concise Outputs**: Keep chat responses, diffs, and summaries tight and structured.

## 3. Build & Execution Rules
- **No Automatic Builds**: Never run `flutter build` commands (`apk`, `appbundle`, `ipa`, `web`) unless explicitly requested by the user. Use `flutter analyze` for verification.

## 4. App Identity & Compatibility
- **App Name**: Xpenzi (`com.navlin.xpenzi`)
- **Baseline**: Forked from [Cashew](https://github.com/jameskokoska/Cashew).
- **Compatibility**: Maintain full backup/restore and CSV/JSON import compatibility with legacy Cashew files.

## 5. Architecture & Stack
- **Database**: Drift (SQLite) in `lib/database/tables.dart`. Schema version: 46.
- **State & Preferences**: `appStateSettings` (`lib/struct/settings.dart`), `sharedPreferences`, `databaseGlobal.dart`.
- **Localization**: `easy_localization` with CSV/JSON maps in `assets/translations/`.
- **Core Modules**: Multi-wallet/currency, On-device offline SMS & notification intelligence, Gemini AI categorization, Goals/Loans, and Google Drive cloud backups.
