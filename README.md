# Spendwise: Expense Tracker

Spendwise: Expense Tracker is a full-fledged, feature-rich application designed to empower users in managing their finances effectively. Built using Flutter - with Drift's SQL package, and Firebase - this app offers a seamless and intuitive user experience across various devices.

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

### 💱 Financial Flexibility

- Multiple Currencies and Accounts: Manage finances across different currencies and accounts with up-to-date conversion rates for accurate calculations and effortless currency conversions. The interface shows the original amount added and the converted amount to the selected account.
- Switch Accounts and Currencies with Ease: On the homepage, easily select a different account and currency and everything will be converted automatically in an instant.

### 🔒 Enhanced Security and Accessibility

- Biometric Lock: Secure budget data using biometric authentication, adding an extra layer of privacy.
- Google Login: Conveniently log in to the app using your Google account, ensuring a streamlined and hassle-free authentication process.

### 🎨 User Experience and Design

- Material You Design: Enjoy a visually appealing and modern interface, following the principles of Material You design for a delightful user experience.
- Custom Accent Color: Personalize the app by selecting a custom accent color that suits your style, or follow that of the system.
- Light and Dark Mode: Seamlessly switch between light and dark themes to optimize visibility and reduce eye strain.
- Customizable Home Screen: Tailor the home screen layout and widgets to display the financial information that matters most to you, providing a personalized and efficient dashboard.
- Detailed Graph Visuals: Gain valuable insights into spending patterns through detailed and interactive graphs, visualizing financial data at a glance.
- Beautiful Adaptive UI: A responsive user interface that adapts flawlessly to both web and mobile platforms, providing an immersive and consistent user experience across devices.

### ☁ Backup and Syncing

- Cross-Device Sync: Keep budget data synchronized across all devices, ensuring access to financial information wherever you go.
- Google Drive Backup: Safeguard budget data by utilizing Google Drive's backup functionality, allowing easy restoration of data if needed.

### 💿 Smart Automation

- Notifications: Stay informed about important financial events and receive timely reminders for budget goals, transactions, and upcoming due dates.
- Import CSV Files: Seamlessly import financial data by uploading CSV files, facilitating a smooth transition from other applications or platforms.
- Import Google Sheets: Seamlessly import Google Sheets tables, quickly importing many transactions from a spreadsheet.
- App Links: Automatically create transactions with pre-filled data using app linking.

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
