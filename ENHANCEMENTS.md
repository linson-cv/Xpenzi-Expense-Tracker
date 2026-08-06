## 1. 💳 Account Types in Accounts / Wallets (`AccountType`)

### Overview
Introduces explicit **Account Types** to categorize accounts cleanly (e.g. Credit Card, Meal Card, Bank Account, Savings, Cash, E-Wallet) and provide card-specific indicators and features.

### Key Details & Specs
* **Account Types Supported**:
  * 💳 **Credit Card**: Credit limit, statement cycle, and billing due indicators.
  * 🍔 **Meal / Food Card**: Meal allowance badge & category tracking.
  * 🏦 **Bank Account / Checking**: Standard checking account.
  * 💰 **Savings Account**: Savings goal badge.
  * 💵 **Cash**: Cash wallet.
  * 📱 **E-Wallet**: Digital payment wallet (PayTM, Google Pay, Apple Pay, PayPal).
* **UI Badges**: Display distinct icons and type badges on account cards in the Accounts page and Account Picker.
* **Files Impacted**:
  * `lib/database/tables.dart`
  * `lib/pages/addWalletPage.dart`
  * `lib/widgets/walletEntry.dart`
  * `lib/pages/accountsPage.dart`

---

## 2. 🔄 Unified Recurring & Subscriptions Engine

### Overview
Removes the UX confusion caused by having separate "Repetitive Transactions" and "Subscriptions" pages by merging them into a single, clean **"Recurring Payments & Subscriptions"** hub.

### Key Details & Specs
* **Unified Interface**: Single list view displaying all recurring transactions, auto-pay bills, and subscriptions.
* **Subscription Tagging**: Optional "Subscription" tag badge (e.g., Netflix, Spotify, Internet) to distinguish fixed subscriptions from variable recurring bills without requiring separate confusing pages.
* **Projection Summary**: Top banner displaying estimated monthly and annual recurring expense totals.
* **Files Impacted**:
  * `lib/pages/recurringTransactionsPage.dart` *(New Hub)*
  * `lib/widgets/navigationFramework.dart`
  * `lib/pages/settingsPage.dart`

---

## 3. 🌊 Floating Navigation Bar (`floatingNavBar.dart`)

### Overview
Replaces or supplements the traditional anchored bottom navigation bar with a modern, floating pill-style dock navigation container.

### Key Details & Specs
* **Container Geometry**: Floating container with rounded corners (`BorderRadius.circular(28)`) and floating margins (`EdgeInsets.only(left: 16, right: 16, bottom: 16)`).
* **Visual Style**: Elevated card background with dynamic theme colors, subtle drop shadow, and glassmorphic translucency.
* **Animations**: Animated tab selection indicator pill, smooth icon scaling, and optional haptic feedback on tab changes.
* **Settings Toggle**: `appStateSettings["floatingNavBar"]` toggle under **Settings -> Appearance**.
* **Files Impacted**:
  * `lib/widgets/floatingNavBar.dart` *(New Component)*
  * `lib/widgets/bottomNavBar.dart`
  * `lib/widgets/navigationFramework.dart`

---

## 2. 🖤 AMOLED Pure Pitch-Black Mode

### Overview
Upgrades the dark theme engine to offer a true pitch-black (`#000000`) AMOLED experience optimized for OLED screens, reducing power consumption and providing high contrast.

### Key Details & Specs
* **Pure Black Surfaces**: Scaffold background, card containers, dialog popups, and bottom sheets set to `#000000` when AMOLED mode is active.
* **High-Contrast Accents**: Subtle border outlines (`Color(0xFF262626)` / `Color(0xFF333333)`) applied around cards and modal sheets for clear visual separation.
* **Settings Toggle**: `appStateSettings["amoledMode"]` / `appStateSettings["forceFullDarkBackground"]` under **Settings -> Appearance**.
* **Files Impacted**:
  * `lib/colors.dart`
  * `lib/struct/defaultPreferences.dart`
  * `lib/pages/settingsPage.dart`

---

## 3. ⚙️ Reorganized & Category-Grouped Settings

### Overview
Restructures the settings interface from a continuous single-list view into intuitive, card-grouped visual categories with modern Material 3 headers.

### Category Structure
1. 🎨 **Appearance & Themes**:
   * Light / Dark / System Theme Mode
   * Pure AMOLED Pitch-Black Mode
   * Primary Accent Color Picker & Material You Dynamic Colors
   * Floating Navigation Bar Toggle
   * Font Scale & Custom Font File Selection
2. ⚡ **Transactions & Controls**:
   * Transaction Row Layout (Compact vs. Detailed View)
   * Add Transaction Flow Customization (Reorder or disable prompts)
   * Haptic Feedback Settings
   * Automatic Decimal Placement & Precision Rules
3. 🌐 **Currency & Formatting**:
   * Date Format Selector (e.g. `YYYY/MM/DD`, `DD/MM/YYYY`, `MM/DD/YYYY`)
   * Date Picker Type (System vs. Custom Sheet)
   * Currency Symbol Display & Exchange Rate Customization
4. 🔒 **Security & Privacy**:
   * Biometric Unlock & Pattern Lock
   * Auto-Lock Timeout on App Close
5. 💾 **Data & Backups**:
   * CSV Data Import / Export Wizard
   * Database Backup & Restore (`.sql` / `.sqlite`)
   * Cloud Backup & Google Drive Sync Settings

### Files Impacted
* `lib/pages/settingsPage.dart`
* `lib/widgets/settingsContainers.dart`

---

## 4. 📌 Pinned Transactions & Shortcuts

### Overview
Allows users to quickly pin frequent or repetitive transaction templates for 1-tap entry.

### Key Details & Specs
* **Pin Action**: Long-press `+` (Add Transaction FAB) or transaction entry to pin to home screen.
* **Home Screen Widget**: Dedicated "Pinned Transactions" card section on the home page.
* **Files Impacted**:
  * `lib/widgets/fab.dart`
  * `lib/pages/homePage/homePage.dart`
  * `lib/struct/defaultPreferences.dart`

---

## 5. 📅 Calendar & Recurring Transactions Engine

### Overview
Enhanced Calendar view with daily/monthly spending banners and flexible recurring frequencies.

### Key Details & Specs
* **Quick Add**: Double-press any date cell in the calendar to immediately open transaction entry pre-filled for that day.
* **Banner Summary**: Toggle between Daily Net Spending Total and Monthly Spending Banners.
* **Recurring Frequencies**: Extended support for **Bi-weekly** and **Quarterly** recurring transaction schedules.
* **Files Impacted**:
  * `lib/pages/activityPage.dart`
  * `lib/struct/upcomingTransactionsFunctions.dart`

---

## 6. 🔍 Search, Filter & Calculation Enhancements

### Overview
Advanced search logic, logical operator filtering, and real-time amount calculation tools.

### Key Details & Specs
* **Logical Operator Filters**: Support `&&` (AND) and `||` (OR) in "Notes contains" and "Title contains" filters.
* **Inline Calculation Evaluation**: Real-time evaluation of partial math calculations while typing in amount fields with copy/paste calculation support.
* **Search Page Direct Export**: Ability to export search results directly to CSV from the Search Transactions page.
* **Files Impacted**:
  * `lib/pages/transactionsSearchPage.dart`
  * `lib/widgets/selectAmount.dart`

---

## 7. 🏷️ Category Grid & Subcategory Customizations

### Overview
Drag-and-drop category grid management, subcategory icon options, and custom category background shapes.

### Key Details & Specs
* **Drag & Drop Grid**: Reorder category items via drag-and-drop grid selection.
* **Subcategory Icons**: Setting to display subcategory icons instead of primary category icons in transaction list rows.
* **Category Icon Shapes**: Customizable background shapes and icon pack selections.
* **Files Impacted**:
  * `lib/pages/editCategoriesPage.dart`
  * `lib/widgets/categoryIcon.dart`

---

## 8. 🏦 Accounts & Transfer Improvements

### Overview
Account color grouping, account archiving, and subcategory assignment for transfers.

### Key Details & Specs
* **Account Color Grouping**: Group accounts by color and view aggregated totals on the home page accounts list.
* **Account Archiving**: Ability to archive inactive accounts to hide them from transaction entry while preserving historical records.
* **Transfer Subcategories**: Subcategory selection support for Transfer and Balance Correction entries.
* **Files Impacted**:
  * `lib/pages/accountsPage.dart`
  * `lib/pages/addTransactionPage.dart`

---

## 9. 🤖 AI Transaction Parsing (Xpenzi Intelligence)

### Overview
Experimental AI transaction parsing feature to process notifications and receipts automatically.

### Key Details & Specs
* **Notification Parsing**: Auto-detect amount, category, and title from incoming notification templates.
* **Experimental Setting**: Disabled by default; toggleable in **Settings -> Experimental Features**.
* **Files Impacted**:
  * `lib/pages/autoTransactionsPageEmail.dart`
  * `lib/struct/settings.dart`

---

## 10. 📊 Bill Splitter & Widget Customizations

### Overview
Bill Splitter tool enhancements and Android Home Screen widget styling.

### Key Details & Specs
* **Bill Splitter Multiplier**: Global multiplier and tip calculator for splitting bills.
* **Android Home Screen Widgets**: Custom theme colors, layout scaling, and Net Worth widget providers.
* **Files Impacted**:
  * `lib/pages/billSplitter.dart`
  * `android/app/src/main/kotlin/com/example/budget/`

---

## 11. ⚡ Performance Optimizations, Reliability & Key Bug Fixes

### Overview
Comprehensive performance tuning, animation offloading, keyboard/layout responsiveness, and critical bug fixes from the 6.x series.

### Performance & Stability Enhancements
* **Animation Offloading**: Automatically unload heavy animations when widgets or pages are off-screen to maximize FPS and conserve battery.
* **Animated Budget Containers**: Performance setting to disable complex container animations for high-speed list scrolling.
* **Sync & Backup Reliability**: Enhanced background data sync algorithm and automatic backup freshness check on app resume.
* **Keyboard & Bottom Sheet Focus**: Improved keyboard autofocus on launch, smooth bottom sheet resizing, and keyboard dismissal.
* **Safe Area Layout Padding**: Refined bottom inset and safe area calculations for edge-to-edge screens and gesture bars.

### Key Bug Fixes Included
* **Budget Progress Calculations**: Fixed skipped transactions incorrectly affecting upcoming budget percentages and budget banner total additions.
* **Custom Budget Date Ranges**: Fixed custom time-period line graph date ranges and daily spending metric calculations.
* **Month-End Recurring Transactions**: Fixed repetitive transactions with end dates at month-end overflowing into the next month.
* **Subcategory Archiving Status**: Fixed archived subcategories defaulting to non-archived status during edits.
* **Upcoming Section Filters**: Corrected homepage upcoming section filters to evaluate future days instead of past days.
* **Net Worth Spending Graph Baseline**: Fixed spending graph starting point to match overall net worth baseline.
* **Title Edit Guard**: Added a discard changes confirmation popup when editing category titles.

---

## 12. 🗑️ Feature Removals & UX Simplifications

### Overview
Streamlining the user interface by removing redundant sub-pages, eliminating confusing terminology, and replacing multi-step prompt flows with single-sheet actions.

### Key Simplification Changes
* **Remove Redundant "Edit X" Sub-Pages**: Eliminate separate *Edit Categories*, *Edit Budgets*, *Edit Wallets*, *Edit Objectives*, and *Edit Associated Titles* sub-pages from the More menu. Enable editing directly on the respective main screens instead.
* **Rename "Objectives" to "Savings Goals & Debts"**: Replace the technical database term *"Objectives"* with clear user-facing labels: **Savings Goals** and **Loans & Debts**.
* **Streamline Add Transaction Flow**: Replace sequential modal sheets (up to 5 popups) with a clean, single **Add Transaction Sheet**:
  * Large amount field on top.
  * Quick horizontal chip selectors for Category, Account, and Date.
  * Optional expandable "More Details" section.
* **Consolidate Niche Toggles**: Group niche settings (`fadeTransactionNameOverflows`, `circularProgressRotation`, `nonCompactTransactions`) into a collapsible **"Advanced Visual Tuning"** menu to prevent main settings clutter.

---

## 13. 💡 High-Value Strategic Enhancements

### Overview
Adding proactive financial tools, card-specific automation, and quick-action shortcuts to elevate everyday app usability.

### Key Details & Specs
* **💳 Credit Card "Pay Bill" Quick Action**: Display outstanding balance & available credit limit on Credit Card accounts with a 1-tap **"Pay Card Bill"** button that pre-fills a Transfer from Bank Account to Credit Card.
* **🍔 Meal Card Auto-Category Filter**: When a Meal Card is selected as the payment account, automatically pre-select or suggest **Food & Dining** or **Groceries** as the category.
* **⚡ Home Screen Quick Action Dock**: Top 1-tap shortcut bar on the Home Screen featuring:
  `[ + Expense ]` `[ + Income ]` `[ ⇄ Transfer ]` `[ 💳 Pay Bill ]`
* **🔍 Smart Search Tags**: Intuitive tag-based search filters (`#Food`, `@CreditCard`, `> 100`) replacing code operator syntax (`&&`, `||`).

---

## Next Steps for Development

1. **Review**: Review the complete roadmap in [ENHANCEMENTS.md](file:///d:/Projects/Android%20Apps/Spendwise-Expense-Tracker/ENHANCEMENTS.md).
2. **Implementation**: Begin step-by-step coding starting with the **Floating Navigation Bar** and **AMOLED Black Mode**.
