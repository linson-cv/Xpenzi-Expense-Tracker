# Xpenzi Feature Roadmap & Enhancements

This document outlines active feature implementations, strategic UX simplifications, and completed enhancements for **Xpenzi** (`com.navlin.xpenzi`).

---

## 🎯 Active & Upcoming Features

### 1. 💳 Account Types (Credit Card, Meal Card, Bank, Cash, Savings)
- **Credit Card Accounts**:
  - Track **Available Credit Limit**, **Statement Balance**, and **Due Date Alerts**.
  - 1-Tap **"Pay Card Bill"** shortcut pre-filling a Transfer from Bank Account to Credit Card.
- **Meal / Prepaid Cards**:
  - Track monthly meal allowance with auto-category pre-selection (**Food & Dining** / **Groceries**) upon entry.
- **Badges & Visuals**:
  - Distinct type icons & badges on account cards in the Accounts page and Account Picker.
- **Files**: `lib/database/tables.dart`, `lib/pages/addWalletPage.dart`, `lib/widgets/walletEntry.dart`, `lib/pages/accountsPage.dart`

---

### 2. 🔄 Unified "Recurring Payments & Subscriptions" Hub
- **Single Streamlined Interface**: Combines repetitive bills and active subscriptions into one unified list.
- **Subscription Tagging**: Optional "Subscription" tag badge (e.g. *Netflix*, *Spotify*, *Cloud Storage*).
- **Projections Banner**: Top summary showing monthly and annual recurring expense estimates.
- **Files**: `lib/pages/recurringTransactionsPage.dart`, `lib/widgets/navigationFramework.dart`

---

### 3. 🤖 AI Transaction Parsing (Xpenzi Intelligence)
- **Notification & Receipt Parsing**: Auto-detect amount, category, and title from incoming payment notifications.
- **Experimental Setting**: Disabled by default; toggleable in **Settings -> Experimental Features**.
- **Files**: `lib/pages/autoTransactionsPageEmail.dart`, `lib/struct/settings.dart`

---

### 4. 🗑️ UX Simplifications & Streamlined Workflows `[COMPLETED ✅]`
- **Direct Screen Editing**: Replace separate "Edit Categories", "Edit Budgets", and "Edit Wallets" sub-pages with direct edit controls on main screens.
- **User-Friendly Terminology**: Replace database term *"Objectives"* with clear **Savings Goals** and **Loans & Debts** ([`lib/pages/objectivesListPage.dart`](file:///d:/Projects/Android%20Apps/Spendwise-Expense-Tracker/lib/pages/objectivesListPage.dart)).
- **1-Sheet Add Transaction View**: Replace sequential modal sheets with a unified transaction entry sheet.

---

## ✅ Completed Enhancements Archive

- **⚡ Home Screen Quick Action Dock**: Top 1-tap shortcut bar (`[ - Expense ]` `[ + Income ]` `[ ⇄ Transfer ]` `[ 💳 Pay Bill ]`) ([`lib/widgets/homeQuickActionDock.dart`](file:///d:/Projects/Android%20Apps/Spendwise-Expense-Tracker/lib/widgets/homeQuickActionDock.dart)).
- **🗂️ Reorganized Settings Page**: Visual 6-category cards with AMOLED pitch-black support ([`lib/pages/settingsPage.dart`](file:///d:/Projects/Android%20Apps/Spendwise-Expense-Tracker/lib/pages/settingsPage.dart)).
- **🌊 Floating Navigation Bar**: Modern 32px floating pill dock widget with haptic feedback ([`lib/widgets/floatingNavBar.dart`](file:///d:/Projects/Android%20Apps/Spendwise-Expense-Tracker/lib/widgets/floatingNavBar.dart)).
- **🖤 AMOLED Pure Pitch-Black Mode**: True `#000000` dark theme with high-contrast `#262626` borders ([`lib/colors.dart`](file:///d:/Projects/Android%20Apps/Spendwise-Expense-Tracker/lib/colors.dart)).
- **📌 Pinned Transactions**: Long-press `+` FAB for quick transaction templates ([`lib/widgets/fab.dart`](file:///d:/Projects/Android%20Apps/Spendwise-Expense-Tracker/lib/widgets/fab.dart)).
- **📅 Calendar Quick-Add**: Double-press date cell pre-fills entry; added Bi-weekly & Quarterly frequencies ([`lib/widgets/util/showDatePicker.dart`](file:///d:/Projects/Android%20Apps/Spendwise-Expense-Tracker/lib/widgets/util/showDatePicker.dart)).
- **🔍 Search Direct CSV Export**: Direct CSV export shortcut on search header ([`lib/pages/transactionsSearchPage.dart`](file:///d:/Projects/Android%20Apps/Spendwise-Expense-Tracker/lib/pages/transactionsSearchPage.dart)).
- **🏷️ Category Grid Drag & Drop**: Reorderable category grid & subcategory icon display toggle ([`lib/widgets/selectCategory.dart`](file:///d:/Projects/Android%20Apps/Spendwise-Expense-Tracker/lib/widgets/selectCategory.dart)).
- **🏦 Account Archiving & Transfers**: Account archiving and subcategories for transfer entries ([`lib/pages/accountsPage.dart`](file:///d:/Projects/Android%20Apps/Spendwise-Expense-Tracker/lib/pages/accountsPage.dart)).
- **📊 Bill Splitter Multiplier**: Global multiplier & tip calculator ([`lib/pages/billSplitter.dart`](file:///d:/Projects/Android%20Apps/Spendwise-Expense-Tracker/lib/pages/billSplitter.dart)).
- **⚡ Animated Budget Containers Toggle**: Performance setting switch for budget card list scrolling ([`lib/pages/settingsPage.dart`](file:///d:/Projects/Android%20Apps/Spendwise-Expense-Tracker/lib/pages/settingsPage.dart)).
