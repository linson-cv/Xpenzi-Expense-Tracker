# Xpenzi: Expense Tracker

Xpenzi: Expense Tracker is a full-fledged, feature-rich application designed to empower users in managing their finances effectively. Built using Flutter - with Drift's SQL package, and Firebase - this app offers a seamless and intuitive user experience across various devices.

---

## Features

### 💸 Budget Management

- Custom Budgets and Time Periods: Set up personalized budgets with flexible time periods, such as monthly, weekly, daily, or any custom time period that suits your financial planning needs. A custom time period is useful if you plan on setting a one-time travel budget!
- Added Budgets: Selectively add transactions to specific budgets, allowing you to focus on specific expense categories.
- Category Spending Limits per Budget: Set limits for each category within a budget, ensuring responsible spending.
- Past Budget History Viewing: Analyze your spending habits over time by accessing past budget history, enabling comparison and tracking of financial progress.
- Goals: Create spending and saving goals and put transactions towards different purchases or savings. Track your progress towards achieving your financial goals.

### 💰 Transaction Management

- Support for Different Transaction Types: Categorize transactions effectively based on types such as upcoming, subscription, repeating, debts (borrowed), and credit (lent). Each type behaves in certain ways in the interface. Pay your upcoming transactions when you're ready, or mark your lent out transactions as collected.
- Custom Categories: Create personalized categories to organize transactions according to your unique spending habits. Search through multiple icons and select the default option as expenses or income when adding transactions.
- Custom Titles: Automatically assign transactions with the same name to specific categories, saving time and ensuring consistency. These titles are stored in memory and popup when you add another transaction with a similar name.
- Search and Filters: Easily search and filter transactions based on various criteria such as date, category, amount, or custom tags, enabling quick access to information.
- Easy Editing: Long-press and swipe to select multiple budgets, edit accordingly as needed or delete multiple at once.

### 💱 Financial Flexibility & Multi-Currency Tools

- **Multiple Currencies and Accounts**: Manage finances across different currencies and accounts with up-to-date conversion rates for accurate calculations and effortless currency conversions.
- **Live Currency Converter on Amount Keypad**: Convert foreign payments on the fly directly inside the transaction amount keypad with intelligent search filtering by **Country Name**, **Currency Code**, and **Currency Name**.
- **Group by Color Account Layout**: Group accounts and wallets into color-tinted card containers with horizontal dividers, aligned total summary rows, and income/outcome indicators.
- **Account Type Visual Icons**: Easily distinguish wallets with automatic account type icons (Bank, Credit Card, Meal Card, Cash, Savings).

### 🔍 Intelligent Deep & Fuzzy Search

- **Deep & Synonym Settings Search**: Search settings, options, and preferences with instant synonym expansion and prefix token matching (e.g. searching `"passcode"`, `"fingerprint"`, `"color"`, `"revert"`, `"excel"`, `"gmail"` matches corresponding feature cards).

### 📳 Customizable Per-Action Haptic Feedback

- **Per-Action Vibration Feedback**: Granular haptic feedback toggles for Number Pad, Saving entries, Tab navigation, Popup dismissal, Button taps, and Delete warning actions, fully backed by OS hardware permissions.

### 📄 Export PDF Reports & Data Backup

- **High-Quality PDF Reports**: Generate and export printable PDF transaction statements with customizable date ranges and wallet filters.
- **Cross-Platform Compatibility**: Full import/export support for Cashew `.json` and `.csv` files.

### 🔒 Enhanced Security and Accessibility

- **Biometric Lock**: Secure budget data using biometric authentication, adding an extra layer of privacy.
- **Prominent User Profile**: Easily set display name for home screen greetings and personalized financial tracking.
- **Google Login**: Conveniently log in to the app using your Google account.

### 🎨 User Experience and Design

- **Material You Design**: Enjoy a visually appealing and modern interface following Material 3 design principles.
- **Synchronized Home Page Layout**: Consistent layout reset logic between initial app launch and reset actions.
- **Custom Accent Color**: Personalize the app by selecting a custom accent color or dynamic system color palette.
- **Light and Dark Mode**: Seamlessly switch between light and dark themes to optimize visibility and reduce eye strain.
- **Customizable Home Screen**: Tailor the home screen layout and widgets to display the financial information that matters most to you.
- **Detailed Graph Visuals**: Gain valuable insights into spending patterns through detailed and interactive graphs.

### ☁ Backup and Syncing

- **Cross-Device Sync**: Keep budget data synchronized across all devices.
- **Google Drive Backup**: Safeguard budget data by utilizing Google Drive's backup functionality.

### 💿 Smart Automation

- **Notifications**: Stay informed about important financial events and receive timely reminders for budget goals, transactions, and upcoming due dates.
- **Import CSV & Google Sheets**: Seamlessly import financial data by uploading CSV files or connecting Google Sheets tables.
- **App Links**: Automatically create transactions with pre-filled data using app linking.

---

## App Links

Automate transaction entry from external apps (e.g. **Tasker**, **Shortcuts**, **MacroDroid**, **Automate**, or Web scripts) using standard URL schemes.

### 🌐 URL Format & Endpoints

| Endpoint | Action | Example |
| :--- | :--- | :--- |
| `addTransaction` | Inserts the transaction directly into the database with a flash notification. | `xpenzi://addTransaction?title=Coffee&amount=-4.50&category=Dining` |
| `addTransactionRoute` | Opens the Add Transaction screen with fields pre-populated. | `xpenzi://addTransactionRoute?title=Dinner&amount=-35.00&account=Main` |

### 🛠 Supported Query Parameters

| Parameter | Type / Description | Example |
| :--- | :--- | :--- |
| `amount` | Transaction value (negative for expense, positive for income). | `amount=-14.99` |
| `title` / `name` | Transaction title or merchant name. | `title=Supermarket` |
| `note` / `notes` | Note or memo. | `note=Weekly+groceries` |
| `category` / `categoryPk` | Target category name or primary key. | `category=Groceries` |
| `subcategory` / `subcategoryPk` | Target subcategory name or primary key. | `subcategory=Fruits` |
| `account` / `wallet` / `walletPk` | Account/Wallet name or primary key. | `account=Bank+Account` |
| `date` / `dateCreated` | Date string (ISO 8601 or standard date format). | `date=2026-08-16` |
| `messageToParse` | Raw SMS or notification text to run through on-device parser. | `messageToParse=Paid+Rs.500+at+Store` |

---

## Bundled Packages

This repository contains, bundled in, modified versions of packages listed below. They can be found in the folder `/budget/packages`

- https://pub.dev/packages/implicitly_animated_reorderable_list
- https://pub.dev/packages/sliding_sheet

## Translations

To Update Translations:
1. Run `budget\assets\translations\generate-translations.py`
2. Restart the application

---

## Developer Notes

### Android Release

- To build an app-bundle Android release, run `flutter build appbundle --release` (Requires Android SDK).

### iOS Release

- To build an IPA iOS release, run `flutter build ipa` (Requires macOS).

### Firebase Deployment

- To deploy to firebase, run `firebase deploy`

### Migrate Database

1. Make any database changes to the schema and tables
2. Bump the schema version (`int schemaVersionGlobal = ...+1` in `tables.dart`)
3. `cd .\budget\`
4. Run `dart run build_runner build`
5. Export new schema (`dart run drift_dev schema dump lib\database\tables.dart drift_schemas//drift_schema_v[schemaVersion].json`)
6. Generate step-by-step migrations (`dart run drift_dev schema steps drift_schemas/ lib\database\schema_versions.dart`)
7. Implement migration strategy in `tables.dart`.
