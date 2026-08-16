import 'package:budget/database/tables.dart';
import 'package:budget/functions.dart';
import 'package:budget/pages/activityPage.dart';
import 'package:budget/pages/addCategoryPage.dart';
import 'package:budget/pages/creditDebtTransactionsPage.dart';
import 'package:budget/pages/editCategoriesPage.dart';
import 'package:budget/pages/editHomePage.dart';
import 'package:budget/pages/objectivesListPage.dart';
import 'package:budget/pages/settingsPage.dart';
import 'package:budget/pages/walletDetailsPage.dart';
import 'package:budget/struct/settings.dart';
import 'package:budget/widgets/navigationFramework.dart';
import 'package:budget/widgets/openBottomSheet.dart';
import 'package:budget/widgets/framework/popupFramework.dart';
import 'package:budget/widgets/openPopup.dart';
import 'package:budget/widgets/outlinedButtonStacked.dart';
import 'package:budget/widgets/textWidgets.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'listItem.dart';

// Device legend
// Apple rejected app update because Android was referenced... We use code names now!
// (i) = iOS
// (A) = Android

String getChangelogString() {
  return """
    < 1.2.3
    (A) Startup & Notification Engine Fix: Eliminated mutual recursive permission checking on app launch and background service registration
    (A) Dedicated Data Management & Reset: Placed data erase and cloud backup wipe into a dedicated top-level section in Settings and renamed backup section to Data, Backup & Sync
    < 1.2.2
    (A) Unified Notifications Screen: Redesigned notification settings with cohesive group cards matching app design aesthetics
    (A) Notification Background Capture & Battery Optimization: Added direct settings prompt to disable Android battery optimization for uninterrupted background transaction listening
    (A) Enhanced Direct Auto-Insert: Fixed amount sign formatting and category fallbacks for instant silent notification recording
    (A) Expanded Bank SMS Parser: Added comprehensive keyword coverage across international bank alerts, IMPS, NEFT, RTGS, NACH, POS, and mandates
    (A) Template Studio Save Fix: Hardened template creation & updates with UUID PK generation, validation guards, and error snackbars
    (A) Onboarding Selected Values Display: Live display of selected currency, language, and decimal precision on onboarding action buttons
    (A) Account Type Save Option: Instant activation of Save Changes button when selecting account type chips in account editor
    (A) Google Sign-In & Auth Resilience: Seamless sign-in handling with multi-environment OAuth configuration and graceful cancellation recovery
    < 1.2.1
    (A) Instant Theme Engine: Streamlined application state reconciliation for instantaneous, seamless theme and accent palette transitions
    (A) Universal Database Resilience: Eliminated all single-query exceptions across categories, budgets, and objectives with automatic fallback recovery
    (A) Enhanced System Back Navigation: Implemented 5-layer back hierarchy preventing premature app exits across dialogs, sheets, and tabs
    (A) Google Services & Web Configuration: Aligned client IDs and isolated platform options to the dedicated Xpenzi project
    < 1.2.0
    (A) Seamless Real-Time Theming: Eliminated MaterialApp element recreation so theme, accent color, and AMOLED Black switch smoothly without page reload or navigator reset
    (A) Stream Stability Enhancements: Fixed stream re-listening exceptions on global wallet providers during live configuration updates
    (A) Robust Scanner Template Editor: Fortified text selection bounds against inverted/invalid selection ranges and null-check crashes during save or back actions
    (A) Auto-Loaded Preset Scanner Engine: Automatically provisions global currency-agnostic templates when notification reading is initialized
    < 1.1.9
    (A) Universal Currency & NLP Engine: Added global currency symbol and keyword matching across international bank alerts, UPI transfers, NEFT, AutoPay, and card debits
    (A) Auto-loaded Global Preset Templates: Seamlessly initializes currency-agnostic bank and card scanner templates when Notification Access is enabled
    (A) Zero-Restart Theme Engine: Seamless instant theme, accent palette, and icon style switching without app reload or navigational disruption
    (A) Fixed onboarding freeze when bypassing Google sign-in by handling null-safety returns on Notification Permission requests
    (A) Fixed scanner template editor freeze on missing or null category references
    < 1.1.8
    (A) Zero-latency instant theme engine: Light, Dark, Black AMOLED, and accent palettes apply immediately on the same frame
    (A) Smart Auto-Detect review banner: Replaced disruptive popup dialogs with an elegant homepage review banner and non-intrusive notification snackbars
    (A) Upgraded Diagnostic & Error Logs: Added real-time text search, category tag filter chips, and 1-tap system sheet sharing
    (A) Diagnostic persistence engine: Automatically retains up to 500 logs across 30 days with global unhandled exception tracking
    (A) Enhanced haptic feedback engine: Fixed touch vibration on buttons and action keypads
    < 1.1.7
    (A) Smart transaction auto-detection prompt: Replaced abrupt page takeovers with a clean review popup and optional direct silent auto-insert
    (A) App-open auto-recorded transaction summary notification with 1-tap navigation to transactions list
    (A) Added Diagnostic & Error Logs hub with detailed exception logging, full stack traces, and 1-tap clipboard copying
    (A) Modernized Transactions sorting sheet with a compact 2x2 Material 3 card grid and context-aware direction toggles
    (A) Explore customization upgrades: Pinned static bottom edit toolbar and top-placed full-width Xpenzi Pro banner
    (A) Transactions header action polish: Pinned preferences settings button to the far right
    < 1.1.6
    (A) Instantaneous theme switching: Accent color, Material You, theme mode, and AMOLED Black apply immediately without restart
    (A) Highlighted active accent color palette swatch with contrasting ring and adaptive checkmark indicator
    (A) Connected icon style switching (Rounded vs. Outlined) to in-memory reload to ensure pristine navigation icons
    (A) Highlighted full-width Xpenzi Pro banner on Explore screen with authentic animated gradient background matching the Pro page
    (A) Added customizable Xpenzi Intelligence and Offline Intelligence shortcut cards to Explore screen
    (A) Streamlined Intelligent & Automation settings section with direct access to Offline Intelligence, Gemini AI, and Email Automation
    (A) Upgraded Transactions filter control with an intuitive settings gear button opening quick preferences modal
    (A) Automatically hid bottom navigation bar during Explore edit mode with dedicated floating action toolbar
    (A) Cleaned up redundant padding and synchronized UI spacing across all intelligent & settings subpages
    (A) Refreshed official app launcher and branding icon with the new minimalist Blue-X arrow emblem
    < 1.1.5
    (A) Added Offline Intelligence on-device notification parsing under Xpenzi Intelligence
    (A) Added live captured notification logs inspector, retention controls, and customizable parsing templates
    (A) Added 1-tap default preset installer for UPI alerts, Debit/Credit SMS, and Card transactions
    (A) Added direct Pinned Account Filter quick toggle button on Transactions List header
    (A) Added tactile vibration and jiggle wobble animation when editing Explore cards
    (A) Added dedicated Category Icon Pack & Gallery catalogue browser with 450+ HD icons and quick category filter tabs
    (A) Added dynamic context & day-aware greetings and weekly financial milestone subtitles on Home Screen
    (A) Added Offline Intelligence 1-tap shortcut to Explore screen grid and unified In-App FAQ reader
    (A) Added seamless Onboarding notification permission setup and resolved Google Sign-In authentication
    (A) Refreshed official app launcher icon with a sleek modern 2D minimalist X-Growth symbol
    < 1.1.4
    (A) Dedicated Transactions sorting modal by Date Created, Date Updated, Amount & Title
    (A) In-grid Explore page customization with live + and - action badges and 2-column reordering
    (A) Uniform equal sizing for all Explore cards including Transactions Search
    (A) Refined header edit pen icon on Explore and updated transactions navbar icon to receipt
    (A) Cleaned up Explore layout and consolidated search bar on Settings page
    < 1.1.3
    (A) Redesigned Explore screen with customizable 2-column grid cards, search, and live drag-to-reorder
    (A) Fixed account type persistence (Bank Account, Credit Card, Meal Card, Cash, Savings)
    (A) Added quick Sort action and Pinned Account Filter bar under Month Selector on Transactions
    (A) Revamped About screen with unified app hero header and streamlined credits
    < 1.1.2
    (A) Redesigned Calendar view with month selector, top totals banner, and compact daily amounts on day cells
    (A) Added In-App GitHub Markdown Viewer for native, offline-capable FAQ, User Guide & Policy reading
    (A) Live Currency Converter on keypad supporting country & currency code search
    (A) Simplified single-layer Settings page with real-time deep search and zero duplicate tiles
    (A) Home header icons upgrade: direct Edit Layout (✏️) and Settings (⚙️) buttons
    (A) Custom per-action haptic feedback toggles with vibration permission support
    (A) Enforced display name entry during onboarding when continuing without sign-in
    (A) Added Pro Icon Packs feature banner in category icon selection
    (A) Instant dismissal on Pro paywall "Unlock for Free" with always-visible back navigation
    < 1.1.1
    (A) Added interactive monthly Calendar view with income, expense & net per day
    (A) Calendar day-tap shows transaction detail panel with quick-add for selected date
    (A) Removed redundant Quick Action Dock — use the + FAB for all entry types
    (A) Scheduled shortcut now opens Scheduled Bills tab by default
    (A) Fixed Feedback submission email link for devices without a mail client
    (A) Updated all FAQ & Guide links to Xpenzi GitHub documentation
    (A) Added Currency, Language & Decimals selectors to Onboarding flow
    < 1.1.0
    (A) Added high-quality PDF Report Export with customizable date ranges and wallet selection
    (A) Removed hard floating navigation bar borders for a true seamless floating effect
    (A) Fixed Google Sign-In failures by properly decoupling old hardcoded Firebase references
    (A) Removed all lingering backend references to the original Cashew open-source tracker
    < 1.0.4
    (A) Fixed Pay Bill quick action to open Credit/Debt Transactions screen cleanly without stacked blank pages
    (A) Updated developer attribution to LN.Dev & support email to nav.lin.dev@gmail.com
    (A) Enhanced Amoled Black mode surface theme consistency across cards, scaffolds, & dialogs
    (A) Positioned Home Quick Action Dock as floating overlay with scroll pass-through
    (A) Resolved onboarding continuation freeze & added Google Sign-In error notification snackbars
    (A) Refined default home page widget selection to essential sections with fixed mandatory banner
    (A) Added home page 3-dot popup menu with direct Edit Home Screen navigation
    (A) Replaced home screen edit toggles with green plus & red delete buttons
    < 1.0.3
    (A) Added Xpenzi Intelligence with Google Gemini AI transaction parsing & prompt customizer
    (A) Added Local Natural Language Processing (NLP) offline engine for auto-detecting bank SMS & notifications
    (A) Added Notification Access Onboarding Banner on Home Screen for 1-tap permission setup
    (A) Added 1-Tap "Pay Bill" shortcut on Credit Card accounts launching direct transfer entry
    (A) Added Account Type Selector chips (Bank Account, Credit Card, Meal Card, Cash, Savings)
    (A) Added Unified Recurring Payments & Subscriptions Hub with Monthly & Annual projections
    (A) Added Mailbox Settings page for Google Sheets Inbox & Google Drive CSV Outbox
    (A) Decoupled Firebase Auth to ensure 100% offline startup & independent Google Sign-In
    (A) Fixed back navigation stack pop behavior preventing blank screen flashes
    < 1.0.2
    (A) Added sleek floating navigation dock with configurable label visibility toggle in settings
    (A) Fixed border color fallback eliminating red outlines around floating action elements
    (A) Reorganized Settings into 6 intuitive cards: General, Theme & Style, Transactions, Localization & Formatting, Notifications, and Data
    (A) Configured default Home Page layout order: Banner -> Account List -> Income & Expenses -> Overdue & Upcoming -> Loans -> Line Graph -> Transactions
    (A) Regenerated native Android, iOS, and Web launcher icons from app branding assets
    < 1.0.1
    (A) Added floating pill dock navigation bar with smooth selection animations
    (A) Enhanced pure AMOLED pitch-black dark theme engine with high-contrast outlines
    (A) Added Pinned Transactions quick actions on Floating Action Button (FAB)
    (A) Added Calendar quick-add transaction pre-fill on date selection
    (A) Added Category grid reordering and Subcategory icon display toggle setting
    (A) Added direct CSV Export shortcut on Transactions Search header
    (A) Added Animated Budget Containers performance toggle in Settings
    (A) Added Home Screen Quick Action Dock for 1-tap Expense, Income, Transfer & Pay Bill entry
    (A) Streamlined terminology & UX workflows for Savings Goals, Debts, and Accounts
    < 1.0.0
    Initial internal testing release
    Rebranded application baseline
end""";
}
// If they were not already seen by a user, they are shown at the top of the changelog
Map<String, List<MajorChanges>> getMajorChanges() {
  return {
    "< 1.1.7": [
      MajorChanges(
        "Instant Themes & Smart Auto-Detection",
        Icons.flash_on_rounded,
        info: [
          "0ms zero-latency instant theme engine for all modes & accent colors",
          "Non-intrusive auto-detected transaction confirmation & resume alerts",
          "Diagnostic & Error Logs hub with 1-tap exception copying",
          "Modernized compact 2x2 Material 3 transactions sort sheet",
        ],
        onTap: (context) {
          popRoute(context);
        },
      ),
    ],
    "< 1.1.6": [
      MajorChanges(
        "Instant Themes & Intelligent Automation",
        Icons.auto_awesome_rounded,
        info: [
          "Instantaneous theme mode, accent color, and AMOLED switching without restart",
          "Highlighted full-width Xpenzi Pro banner matching the Pro page background",
          "Dedicated Intelligence & Offline shortcuts directly inside Explore",
          "Enhanced color palette selection indicator with checkmark & contrast ring",
        ],
        onTap: (context) {
          popRoute(context);
        },
      ),
    ],
    "< 1.1.5": [
      MajorChanges(
        "Offline Intelligence & Icon Gallery",
        Icons.shield_rounded,
        info: [
          "100% private offline bank SMS & payment notification parsing",
          "Inspect captured notification logs & load default UPI/Bank templates",
          "Quick toggle for pinned account filters directly on Transactions header",
          "Preview 450+ category icons in the dedicated icon gallery browser",
        ],
        onTap: (context) {
          popRoute(context);
        },
      ),
    ],
    "< 1.1.4": [
      MajorChanges(
        "Smart Transactions Sort & In-Grid Explore Editing",
        Icons.sort_rounded,
        info: [
          "Sort transactions by Date Created, Date Updated, Amount, and Title",
          "Edit Explore cards directly in 2-column grid mode with + and - badges",
          "Uniform equal card sizing for all Explore shortcuts",
        ],
        onTap: (context) {
          popRoute(context);
        },
      ),
    ],
    "< 1.1.3": [
      MajorChanges(
        "Customizable Explore Screen",
        Icons.explore_rounded,
        info: [
          "Organize your shortcuts with customizable 2-column grid cards",
          "Drag-to-reorder cards and toggle visibility in real-time",
          "Always-on global search across cards and settings preferences",
        ],
        onTap: (context) {
          popRoute(context);
        },
      ),
    ],
    "< 1.1.1": [
      MajorChanges(
        "Monthly Calendar View",
        Icons.calendar_month_rounded,
        info: [
          "Visualise your spending day-by-day in a full monthly calendar",
          "Tap any date to see income, expense & net totals plus a transaction preview",
          "Quick-add a transaction pre-filled with the selected date",
        ],
      ),
    ],
    "< 1.1.0": [
      MajorChanges(
        "PDF Report Export",
        Icons.picture_as_pdf_rounded,
        info: [
          "Export your transaction reports in high-quality PDF format",
        ],
      ),
    ],
    "< 4.4.1": [
      MajorChanges(
        "major-change-1".tr(),
        Icons.arrow_drop_up_rounded,
        info: [
          "major-change-1-1".tr(),
        ],
      ),
      MajorChanges(
        "major-change-2".tr(),
        Icons.category_rounded,
        info: [
          "major-change-2-1".tr(),
        ],
      ),
      MajorChanges(
        "major-change-3".tr(),
        Icons.savings_rounded,
        info: [
          "major-change-3-1".tr(),
          "major-change-3-2".tr(),
        ],
        onTap: (context) {
          pushRoute(context, const ObjectivesListPage(backButton: true));
        },
      ),
      MajorChanges(
        "major-change-4".tr(),
        Icons.home_rounded,
        info: [
          "major-change-4-1".tr(),
          "major-change-4-2".tr(),
        ],
        onTap: (context) {
          pushRoute(context, const EditHomePage());
        },
      ),
      MajorChanges(
        "major-change-5".tr(),
        Icons.emoji_emotions_rounded,
        info: [
          "major-change-5-1".tr(),
        ],
        onTap: (context) {
          pushRoute(context, const EditCategoriesPage());
        },
      ),
      // MajorChanges(
      //   "major-change-6".tr(),
      //   Icons.bug_report_rounded,
      //   info: [
      //     "major-change-6-1".tr(),
      //   ],
      // ),
    ],
    "< 4.4.6": [
      MajorChanges(
        "major-change-7".tr(),
        Icons.timelapse_rounded,
        info: [
          "major-change-7-1".tr(),
        ],
        onTap: (context) {
          pushRoute(context, const WalletDetailsPage(wallet: null));
        },
      ),
      MajorChanges(
        "major-change-8".tr(),
        Icons.price_change_rounded,
      ),
    ],
    "< 4.5.1": [
      MajorChanges(
        "major-change-9".tr(),
        Icons.file_open_rounded,
        info: [
          "major-change-9-1".tr(),
        ],
        onTap: (context) {
          pushRoute(context, const SettingsPageFramework());
        },
      ),
      MajorChanges(
        "major-change-10".tr(),
        Icons.edit_rounded,
        info: [
          "major-change-10-1".tr(),
        ],
        onTap: (context) {
          pushRoute(context, const EditHomePage());
        },
      ),
    ],
    "< 4.6.6": [
      MajorChanges(
        "major-change-11".tr(),
        Icons.category_rounded,
        info: [
          "major-change-11-1".tr(),
        ],
        onTap: (context) {
          pushRoute(
            context,
            const AddCategoryPage(
              routesToPopAfterDelete: RoutesToPopAfterDelete.None,
            ),
          );
        },
      ),
      MajorChanges(
        "major-change-12".tr(),
        Icons.list_rounded,
        info: [
          "major-change-12-1".tr(),
        ],
        onTap: (context) {
          pushRoute(context, const EditHomePage());
        },
      ),
      MajorChanges(
        "major-change-6".tr(),
        Icons.bug_report_rounded,
        info: [
          "major-change-6-1".tr(),
        ],
      ),
    ],
    "< 4.7.9": [
      MajorChanges(
        "major-change-14".tr(),
        Icons.attach_file_rounded,
        info: [
          "major-change-14-1".tr(),
        ],
      ),
    ],
    "< 4.8.8": [
      MajorChanges(
        "major-change-15".tr(),
        Icons.add_box_rounded,
        info: [
          "major-change-15-1".tr(),
        ],
        onTap: (context) {
          openBottomSheet(
            context,
            const PopupFramework(
              child: AddMoreThingsPopup(),
            ),
          );
        },
      ),
    ],
    "< 4.8.9": [
      MajorChanges(
        "major-change-16".tr(),
        Icons.receipt_long_rounded,
        info: [
          "major-change-16-1".tr(),
        ],
        onTap: (context) {
          pushRoute(context, const WalletDetailsPage(wallet: null));
        },
      ),
    ],
    "< 5.0.3": [
      MajorChanges(
        "major-change-17".tr(),
        Icons.av_timer_rounded,
        info: [
          "major-change-17-1".tr(),
        ],
        onTap: (context) {
          pushRoute(
            context,
            const CreditDebtTransactions(
              isCredit: null,
            ),
          );
        },
      ),
    ],
    "< 5.3.0": [
      MajorChanges(
        "major-change-18".tr(),
        Icons.ballot_rounded,
        info: [
          "major-change-18-1".tr(),
        ],
        onTap: (context) {
          pushRoute(
            context,
            const ActivityPage(),
          );
        },
      ),
    ],
  };
}

bool showChangelog(
  BuildContext context, {
  bool forceShow = false,
  bool majorChangesOnly = false,
  Widget? extraWidget,
}) {
  String version = packageInfoGlobal?.version ?? "";

  List<Widget>? changelogPoints = getChangelogPointsWidgets(
    context,
    forceShow: forceShow,
    majorChangesOnly:
        !Localizations.localeOf(context).toString().toLowerCase().startsWith("en")
            ? true
            : majorChangesOnly,
  );

  updateSettings(
    "lastLoginVersion",
    version,
    pagesNeedingRefresh: [],
    updateGlobalState: false,
  );

  //Don't show changelog on first login and only show if english, unless forced
  if (changelogPoints != null &&
      changelogPoints.isNotEmpty &&
      (forceShow ||
          (appStateSettings["numLogins"] > 1
          //   &&  Localizations.localeOf(context).toString().toLowerCase() == "en"
          ))) {
    openBottomSheet(
      context,
      PopupFramework(
        title: "changelog".tr(),
        subtitle: getVersionString(),
        showCloseButton: true,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [(extraWidget ?? const SizedBox.shrink()), ...changelogPoints],
        ),
      ),
      showScrollbar: true,
    );
    return true;
  }
  return false;
}

List<Widget>? getChangelogPointsWidgets(BuildContext context,
    {bool forceShow = false, bool majorChangesOnly = false}) {
  String changelog = getChangelogString();
  Map<String, List<MajorChanges>> majorChanges = getMajorChanges();
  String version = packageInfoGlobal?.version ?? "";
  int versionInt = parseVersionInt(version);
  int lastLoginVersionInt =
      parseVersionInt(appStateSettings["lastLoginVersion"]);

  if (forceShow || lastLoginVersionInt != versionInt) {
    List<Widget> changelogPoints = [];
    List<Widget> majorChangelogPointsAtTop = [];

    int versionBookmark = versionInt;
    for (String string in changelog.split("\n")) {
      string = string.replaceFirst("    ", ""); // remove the indent

      // Skip android changes on iOS, skip iOS changes on Android
      if (getPlatform() == PlatformOS.isIOS && string.contains(("(A)"))) {
        continue;
      } else if (getPlatform() == PlatformOS.isAndroid &&
          string.contains(("(i)"))) {
        continue;
      }
      string = string.replaceAll("(A)", "Android");
      string = string.replaceAll("(i)", "iOS");

      if (string.startsWith("< ")) {
        if (forceShow) {
          changelogPoints.addAll(getAllMajorChangeWidgetsForVersion(
                  context, string, majorChanges) ??
              []);
        }

        versionBookmark = parseVersionInt(string.replaceAll("< ", ""));
        if (forceShow == false && versionBookmark <= lastLoginVersionInt) {
          continue;
        }

        majorChangelogPointsAtTop.addAll(
            getAllMajorChangeWidgetsForVersion(context, string, majorChanges) ??
                []);

        if (majorChangesOnly == true) {
          continue;
        }

        changelogPoints.add(Padding(
          padding: const EdgeInsetsDirectional.only(bottom: 5, top: 3),
          child: TextFont(
            text: string.replaceAll("< ", ""),
            fontSize: 25,
            maxLines: 10,
            fontWeight: FontWeight.bold,
          ),
        ));
        continue;
      }

      if (majorChangesOnly == true) {
        continue;
      }

      if (forceShow == false && versionBookmark <= lastLoginVersionInt) {
        continue;
      }

      if (string.trim() == "") {
        // this is an empty line
        changelogPoints.add(const SizedBox(
          height: 8,
        ));
      } else if (string.trim() != "end") {
        changelogPoints.add(Padding(
          padding: const EdgeInsetsDirectional.only(bottom: 5.5),
          child: TextFont(
            text: string,
            fontSize: 16.5,
            maxLines: 5,
          ),
        ));
      }
    }
    if (changelogPoints.isNotEmpty) {
      changelogPoints.add(
        const SizedBox(height: 10),
      );
    }

    if (!forceShow) changelogPoints.insertAll(0, majorChangelogPointsAtTop);
    return changelogPoints;
  }
  return null;
}

int parseVersionInt(String versionString) {
  try {
    String cleaned = versionString.trim().split(" ")[0].replaceAll(".", "");
    int parsedVersion = int.parse(cleaned);
    return parsedVersion;
  } catch (e) {
    print("Error parsing version number, defaulting to version 0.");
  }
  return 0;
}

String getVersionString() {
  String version = packageInfoGlobal?.version ?? "";
  String buildNumber = packageInfoGlobal?.buildNumber ?? "";
  return "v$version+$buildNumber, db-v$schemaVersionGlobal";
}

class MajorChanges {
  MajorChanges(this.title, this.icon, {this.info, this.onTap});

  String title;
  IconData icon;
  List<String>? info;
  Function(BuildContext context)? onTap;
}

List<Widget>? getAllMajorChangeWidgetsForVersion(BuildContext context,
    String version, Map<String, List<MajorChanges>> majorChanges) {
  if (majorChanges[version] == null) return null;
  return [
    const SizedBox(height: 5),
    for (MajorChanges majorChange in (majorChanges[version] ?? []))
      Padding(
        padding: const EdgeInsetsDirectional.only(
          bottom: 5,
          top: 5,
        ),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButtonStacked(
                filled: false,
                alignStart: true,
                alignBeside: true,
                padding: const EdgeInsetsDirectional.symmetric(
                    horizontal: 20, vertical: 20),
                text: majorChange.title.tr(),
                iconData: majorChange.icon,
                onTap: majorChange.onTap == null
                    ? null
                    : () => majorChange.onTap!(context),
                afterWidget: majorChange.info == null
                    ? null
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          for (String info in majorChange.info ?? [])
                            ListItem(
                              info.tr(),
                            ),
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
    const SizedBox(height: 10),
  ];
}
