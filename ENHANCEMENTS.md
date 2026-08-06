# Xpenzi Feature Roadmap & Enhancements

This document outlines active feature implementations, strategic UX simplifications, and completed enhancements for **Xpenzi** (`com.navlin.xpenzi`).

---

## 🎯 Active & Upcoming Features

- All feature roadmap items are fully implemented!

---

## ✅ Completed Enhancements Archive

- **⚡ Local NLP Notification Extraction & Permission Onboarding**: Zero-API offline natural language & regex engine parsing amount, merchant title, category, and account from bank SMS/notifications with an optional homepage permission onboarding banner ([`lib/struct/localNlpParser.dart`](file:///d:/Projects/Android%20Apps/Spendwise-Expense-Tracker/lib/struct/localNlpParser.dart), [`lib/widgets/notificationPermissionBanner.dart`](file:///d:/Projects/Android%20Apps/Spendwise-Expense-Tracker/lib/widgets/notificationPermissionBanner.dart)).
- **🤖 Xpenzi Intelligence & Gemini AI Parsing**: Google Gemini API key configuration (`gemini-1.5-flash`, `gemini-1.5-pro`, `gemini-2.0-flash`), prompt extraction, notification/SMS auto-parsing, and privacy information toggles ([`lib/pages/aiSettingsPage.dart`](file:///d:/Projects/Android%20Apps/Spendwise-Expense-Tracker/lib/pages/aiSettingsPage.dart), [`lib/struct/geminiAi.dart`](file:///d:/Projects/Android%20Apps/Spendwise-Expense-Tracker/lib/struct/geminiAi.dart)).
- **📥 Mailbox (Google Sheets Inbox & Drive Outbox)**: Google Sheets mailbox link & template integration with Google Drive Outbox CSV export ([`lib/pages/mailboxPage.dart`](file:///d:/Projects/Android%20Apps/Spendwise-Expense-Tracker/lib/pages/mailboxPage.dart)).

- **💳 Enhanced Account Types & 1-Tap "Pay Bill"**: 1-Tap **"Pay Bill"** shortcut pre-filling a Transfer from Bank Account to Credit Card; credit card badge indicators ([`lib/widgets/walletEntry.dart`](file:///d:/Projects/Android%20Apps/Spendwise-Expense-Tracker/lib/widgets/walletEntry.dart)).
- **🔄 Unified "Recurring Payments & Subscriptions" Hub**: Combined Subscriptions and Scheduled Bills into a single streamlined view with a top **Monthly & Annual Recurring Projections Banner** ([`lib/pages/recurringHubPage.dart`](file:///d:/Projects/Android%20Apps/Spendwise-Expense-Tracker/lib/pages/recurringHubPage.dart)).
- **🎨 More Tab 2-Column & Grouped Settings Redesign**: Redesigned **More** tab with featured cards, 2-column quick tile grid, and 7 dedicated Group Settings sub-pages (`General`, `Theme & Style`, `Transactions`, `Localization`, `Notifications`, `Import & Export`, `About`) ([`lib/pages/settingsPage.dart`](file:///d:/Projects/Android%20Apps/Spendwise-Expense-Tracker/lib/pages/settingsPage.dart)).
- **📱 Native Launcher Icons**: Generated updated Xpenzi launcher icons across Android (`mipmap` buckets), iOS (`AppIcon.appiconset`), and Web using `flutter_launcher_icons` (`pubspec.yaml`).
- **🌊 Floating Dock Capsule Indicator**: Centered Material 3 stadium capsule active tab pill indicator (`width: 56`, `height: 32`, `borderRadius: 16`) with smooth animations ([`lib/widgets/floatingNavBar.dart`](file:///d:/Projects/Android%20Apps/Spendwise-Expense-Tracker/lib/widgets/floatingNavBar.dart)).
- **📊 Home Summary Tile Indicators**: Redesigned summary tiles with type indicators (`▼ Expense`, `▲ Income`, `📅 Upcoming`, `📅 Overdue`, `↗ Lent`, `↙ Borrowed`) and formatted `×count` / `All Time` subtitles ([`lib/widgets/transactionsAmountBox.dart`](file:///d:/Projects/Android%20Apps/Spendwise-Expense-Tracker/lib/widgets/transactionsAmountBox.dart)).
- **⚡ Home Screen Quick Action Dock**: Top 1-tap shortcut bar (`[ - Expense ]` `[ + Income ]` `[ ⇄ Transfer ]` `[ 💳 Pay Bill ]`) ([`lib/widgets/homeQuickActionDock.dart`](file:///d:/Projects/Android%20Apps/Spendwise-Expense-Tracker/lib/widgets/homeQuickActionDock.dart)).
- **🖤 AMOLED Pure Pitch-Black Mode**: True `#000000` dark theme with high-contrast `#262626` borders ([`lib/colors.dart`](file:///d:/Projects/Android%20Apps/Spendwise-Expense-Tracker/lib/colors.dart)).
- **📌 Pinned Transactions**: Long-press `+` FAB for quick transaction templates ([`lib/widgets/fab.dart`](file:///d:/Projects/Android%20Apps/Spendwise-Expense-Tracker/lib/widgets/fab.dart)).
- **📅 Calendar Quick-Add**: Double-press date cell pre-fills entry; added Bi-weekly & Quarterly frequencies ([`lib/widgets/util/showDatePicker.dart`](file:///d:/Projects/Android%20Apps/Spendwise-Expense-Tracker/lib/widgets/util/showDatePicker.dart)).
- **🔍 Search Direct CSV Export**: Direct CSV export shortcut on search header ([`lib/pages/transactionsSearchPage.dart`](file:///d:/Projects/Android%20Apps/Spendwise-Expense-Tracker/lib/pages/transactionsSearchPage.dart)).
- **🏷️ Category Grid Drag & Drop**: Reorderable category grid & subcategory icon display toggle ([`lib/widgets/selectCategory.dart`](file:///d:/Projects/Android%20Apps/Spendwise-Expense-Tracker/lib/widgets/selectCategory.dart)).
- **🏦 Account Archiving & Transfers**: Account archiving and subcategories for transfer entries ([`lib/pages/accountsPage.dart`](file:///d:/Projects/Android%20Apps/Spendwise-Expense-Tracker/lib/pages/accountsPage.dart)).
- **📊 Bill Splitter Multiplier**: Global multiplier & tip calculator ([`lib/pages/billSplitter.dart`](file:///d:/Projects/Android%20Apps/Spendwise-Expense-Tracker/lib/pages/billSplitter.dart)).
- **⚡ Animated Budget Containers Toggle**: Performance setting switch for budget card list scrolling ([`lib/pages/settingsPage.dart`](file:///d:/Projects/Android%20Apps/Spendwise-Expense-Tracker/lib/pages/settingsPage.dart)).
