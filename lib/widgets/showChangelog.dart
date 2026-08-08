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
