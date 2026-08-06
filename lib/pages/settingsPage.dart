import 'package:budget/colors.dart';
import 'package:budget/database/tables.dart' hide AppSettings;
import 'package:budget/pages/aboutPage.dart';
import 'package:budget/pages/addTransactionPage.dart';
import 'package:budget/pages/billSplitter.dart';
import 'package:budget/pages/budgetsListPage.dart';
import 'package:budget/pages/creditDebtTransactionsPage.dart';
import 'package:budget/pages/editHomePage.dart';
import 'package:budget/pages/editObjectivesPage.dart';
import 'package:budget/pages/homePage/homePageNetWorth.dart';
import 'package:budget/pages/objectivesListPage.dart';
import 'package:budget/pages/premiumPage.dart';
import 'package:budget/pages/transactionsListPage.dart';
import 'package:budget/struct/currencyFunctions.dart';
import 'package:budget/struct/defaultPreferences.dart';
import 'package:budget/struct/languageMap.dart';
import 'package:budget/struct/navBarIconsData.dart';
import 'package:budget/widgets/animatedExpanded.dart';
import 'package:budget/widgets/dropdownSelect.dart';
import 'package:budget/widgets/exportDB.dart';
import 'package:budget/widgets/importCSV.dart';
import 'package:budget/widgets/exportCSV.dart';
import 'package:budget/pages/autoTransactionsPageEmail.dart';
import 'package:budget/pages/activityPage.dart';
import 'package:budget/pages/editAssociatedTitlesPage.dart';
import 'package:budget/pages/editBudgetPage.dart';
import 'package:budget/pages/editCategoriesPage.dart';
import 'package:budget/pages/editWalletsPage.dart';
import 'package:budget/pages/exchangeRatesPage.dart';
import 'package:budget/pages/notificationsPage.dart';
import 'package:budget/pages/recurringHubPage.dart';
import 'package:budget/pages/aiSettingsPage.dart';
import 'package:budget/pages/mailboxPage.dart';
import 'package:budget/widgets/accountAndBackup.dart';
import 'package:budget/widgets/importDB.dart';
import 'package:budget/widgets/navigationFramework.dart';
import 'package:budget/widgets/notificationsSettings.dart';
import 'package:budget/widgets/openBottomSheet.dart';
import 'package:budget/widgets/framework/pageFramework.dart';
import 'package:budget/widgets/openPopup.dart';
import 'package:budget/widgets/openSnackbar.dart';
import 'package:budget/widgets/globalSnackbar.dart';
import 'package:budget/widgets/radioItems.dart';
import 'package:budget/widgets/ratingPopup.dart';
import 'package:budget/widgets/restartApp.dart';
import 'package:budget/widgets/selectAmount.dart';
import 'package:budget/widgets/selectColor.dart';
import 'package:budget/widgets/settingsContainers.dart';
import 'package:budget/pages/walletDetailsPage.dart';
import 'package:budget/struct/initializeBiometrics.dart';
import 'package:budget/widgets/sliderSelector.dart';
import 'package:budget/widgets/tappable.dart';
import 'package:budget/widgets/textWidgets.dart';
import 'package:budget/widgets/util/checkWidgetLaunch.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:budget/main.dart';
import 'package:flutter/services.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';
import 'package:provider/provider.dart';
import 'package:budget/functions.dart';
import 'package:budget/struct/settings.dart';
import 'package:budget/widgets/framework/popupFramework.dart';
import 'package:app_settings/app_settings.dart';
import 'package:budget/widgets/outlinedButtonStacked.dart';

//To get SHA1 Key run
// ./gradlew signingReport
//in budget\Android
//Generate new OAuth and put JSON in budget\android\app folder

class MoreActionsPage extends StatefulWidget {
  const MoreActionsPage({
    super.key,
  });

  @override
  State<MoreActionsPage> createState() => MoreActionsPageState();
}

class MoreActionsPageState extends State<MoreActionsPage> {
  GlobalKey<PageFrameworkState> pageState = GlobalKey();

  void refreshState() {
    print("refresh settings");
    setState(() {});
  }

  void scrollToTop() {
    pageState.currentState?.scrollToTop();
  }

  @override
  Widget build(BuildContext context) {
    return OrientationBuilder(builder: (context, _) {
      return PageFramework(
        key: pageState,
        title: "more-actions".tr(),
        backButton: false,
        horizontalPaddingConstrained: true,
        actions: [
          CustomPopupMenuButton(
            showButtons: true,
            keepOutFirst: true,
            items: [
              if (appStateSettings["showFAQAndHelpLink"] == true)
                DropdownItemMenu(
                  id: "open-faq",
                  label: "faq".tr(),
                  icon: appStateSettings["outlinedIcons"]
                      ? Icons.live_help_outlined
                      : Icons.live_help_rounded,
                  action: () {
                    openUrl("https://spendwiseapp.web.app/faq.html");
                  },
                ),
            ],
          ),
        ],
        listWidgets: const [
          Padding(
            padding: EdgeInsetsDirectional.only(bottom: 8.0),
            child: PremiumBanner(),
          ),
          MorePages()
        ],
      );
    });
  }
}

class MorePages extends StatelessWidget {
  const MorePages({super.key});

  @override
  Widget build(BuildContext context) {
    bool hasSideNavigation = getIsFullScreen(context);

    return Padding(
      padding: const EdgeInsetsDirectional.symmetric(horizontal: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Featured Container 1: Settings & Customization
          SettingsContainerOpenPage(
            openPage: SettingsPageFramework(
              key: settingsPageFrameworkStateKey,
            ),
            title: "Settings & Customization",
            description: "Theme, Language, Import/Export CSV",
            icon: appStateSettings["outlinedIcons"]
                ? Icons.settings_outlined
                : Icons.settings_rounded,
            isOutlined: true,
            isWideOutlined: true,
          ),
          const SizedBox(height: 6),
          // Featured Container 2: All Spending Summary
          SettingsContainerOpenPage(
            openPage: const WalletDetailsPage(wallet: null),
            title: navBarIconsData["allSpending"]!.labelLong.tr(),
            description: "Your spending statistics all in one place",
            icon: navBarIconsData["allSpending"]!.iconData,
            isOutlined: true,
            isWideOutlined: true,
          ),
          const SizedBox(height: 8),
          // 2-Column Grid
          Row(
            children: [
              Expanded(
                child: SettingsContainerOpenPage(
                  openPage: const AboutPage(),
                  title: "about-app".tr(namedArgs: {"app": globalAppName}),
                  icon: navBarIconsData["about"]!.iconData,
                  isOutlined: true,
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsetsDirectional.symmetric(horizontal: 2),
                  child: SettingsContainer(
                    onTap: () {
                      openBottomSheet(context, const RatingPopup(), fullSnap: true);
                    },
                    title: "Beta Feedback",
                    icon: appStateSettings["outlinedIcons"]
                        ? Icons.rate_review_outlined
                        : Icons.rate_review_rounded,
                    isOutlined: true,
                  ),
                ),
              ),
            ],
          ),
          Row(
            children: [
              Expanded(
                child: SettingsContainer(
                  onTap: () {
                    openUrl("https://spendwiseapp.web.app/faq.html");
                  },
                  title: "Guide / FAQ",
                  icon: appStateSettings["outlinedIcons"]
                      ? Icons.help_outline
                      : Icons.help_rounded,
                  isOutlined: true,
                ),
              ),
              Expanded(
                child: GoogleAccountLoginButton(
                  key: settingsGoogleAccountLoginButtonKey,
                ),
              ),
            ],
          ),
          Row(
            children: [
              Expanded(
                child: SettingsContainerOpenPage(
                  openPage: const ActivityPage(),
                  title: "Calendar",
                  icon: appStateSettings["outlinedIcons"]
                      ? Icons.calendar_month_outlined
                      : Icons.calendar_month_rounded,
                  isOutlined: true,
                ),
              ),
              Expanded(
                child: SettingsContainerOpenPage(
                  openPage: const ActivityPage(),
                  title: "Activity Log",
                  icon: appStateSettings["outlinedIcons"]
                      ? Icons.receipt_long_outlined
                      : Icons.receipt_long_rounded,
                  isOutlined: true,
                ),
              ),
            ],
          ),
          Row(
            children: [
              Expanded(
                child: SettingsContainerOpenPage(
                  openPage: const RecurringHubPage(),
                  title: navBarIconsData["subscriptions"]!.label.tr(),
                  icon: navBarIconsData["subscriptions"]!.iconData,
                  isOutlined: true,
                ),
              ),
              Expanded(
                child: SettingsContainerOpenPage(
                  openPage: const RecurringHubPage(),
                  title: navBarIconsData["scheduled"]!.label.tr(),
                  icon: navBarIconsData["scheduled"]!.iconData,
                  isOutlined: true,
                ),
              ),
            ],
          ),
          Row(
            children: [
              Expanded(
                child: SettingsContainerOpenPage(
                  openPage: const ObjectivesListPage(backButton: true),
                  title: navBarIconsData["goals"]!.label.tr(),
                  icon: navBarIconsData["goals"]!.iconData,
                  isOutlined: true,
                ),
              ),
              Expanded(
                child: SettingsContainerOpenPage(
                  openPage: const CreditDebtTransactions(isCredit: null),
                  title: navBarIconsData["loans"]!.label.tr(),
                  icon: navBarIconsData["loans"]!.iconData,
                  isOutlined: true,
                ),
              ),
            ],
          ),
          Row(
            children: [
              Expanded(
                child: SettingsContainerOpenPage(
                  openPage: const EditWalletsPage(),
                  title: "Accounts",
                  icon: navBarIconsData["accountDetails"]!.iconData,
                  isOutlined: true,
                ),
              ),
              Expanded(
                child: SettingsContainerOpenPage(
                  openPage: appStateSettings["customNavBarShortcut0"] != "budgets" &&
                          appStateSettings["customNavBarShortcut1"] != "budgets" &&
                          appStateSettings["customNavBarShortcut2"] != "budgets"
                      ? const BudgetsListPage(enableBackButton: true)
                      : const EditBudgetPage(),
                  title: "Budgets",
                  icon: navBarIconsData["budgetDetails"]!.iconData,
                  isOutlined: true,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          // Bottom Container: Edit, Delete, and Reorder Data
          SettingsContainerOpenPage(
            openPage: const EditDataOverviewPage(),
            title: "Edit, Delete, and Reorder Data",
            description: "For accounts, categories, titles, budgets, goals, loans",
            icon: appStateSettings["outlinedIcons"]
                ? Icons.edit_note_outlined
                : Icons.edit_note_rounded,
            isOutlined: true,
            isWideOutlined: true,
          ),
        ],
      ),
    );
  }
}

class EnterName extends StatelessWidget {
  const EnterName({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return SettingsContainer(
      title: "username".tr(),
      icon: Icons.edit,
      onTap: () {
        enterNameBottomSheet(context);
      },
    );
  }
}

Future<String> enterNameBottomSheet(context,
    {bool updatePageWhenSet = true}) async {
  return await openBottomSheet(
    context,
    popupWithKeyboard: true,
    PopupFramework(
      title: "enter-name".tr(),
      child: SelectText(
        buttonLabel: "set-name".tr(),
        icon: appStateSettings["outlinedIcons"]
            ? Icons.person_outlined
            : Icons.person_rounded,
        setSelectedText: (_) {},
        nextWithInput: (text) {
          updateSettings("username", text.trim(),
              pagesNeedingRefresh: updatePageWhenSet ? [0] : [],
              updateGlobalState: false);
        },
        selectedText: appStateSettings["username"],
        placeholder: "nickname".tr(),
        autoFocus: true,
      ),
    ),
  );
}

class SettingsPageFramework extends StatefulWidget {
  const SettingsPageFramework({super.key});

  @override
  State<SettingsPageFramework> createState() => SettingsPageFrameworkState();
}

class SettingsPageFrameworkState extends State<SettingsPageFramework> {
  void refreshState() {
    print("refresh settings framework");
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return PageFramework(
      title: "settings".tr(),
      dragDownToDismiss: true,
      listWidgets: const [SettingsPageContent()],
    );
  }
}

class SettingsPageContent extends StatelessWidget {
  const SettingsPageContent({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Main Settings Category Groups
        SettingsGroupCard(
          title: "Settings",
          icon: Icons.settings_rounded,
          children: [
            SettingsContainerOpenPage(
              openPage: const GeneralSettingsSubPage(),
              title: "General Settings",
              description: "Biometric lock, haptic feedback, edit data",
              icon: appStateSettings["outlinedIcons"]
                  ? Icons.tune_outlined
                  : Icons.tune_rounded,
            ),
            SettingsContainerOpenPage(
              openPage: const ThemeStyleSettingsSubPage(),
              title: "Theme & Style",
              description: "Theme color, icon style, animations, font",
              icon: appStateSettings["outlinedIcons"]
                  ? Icons.palette_outlined
                  : Icons.palette_rounded,
            ),
            SettingsContainerOpenPage(
              openPage: const TransactionsSettingsSubPage(),
              title: "Transactions",
              description: "New transaction, scheduled transactions",
              icon: navBarIconsData["transactions"]!.iconData,
            ),
            SettingsContainerOpenPage(
              openPage: const LocalizationSettingsSubPage(),
              title: "Localization & Formatting",
              description: "Language, currency, formatting",
              icon: appStateSettings["outlinedIcons"]
                  ? Icons.language_outlined
                  : Icons.language_rounded,
            ),
            SettingsContainerOpenPage(
              openPage: const NotificationsPage(),
              title: "Notifications",
              description: "Daily & upcoming transaction reminders",
              icon: appStateSettings["outlinedIcons"]
                  ? Icons.notifications_outlined
                  : Icons.notifications_rounded,
            ),
            SettingsContainerOpenPage(
              openPage: const ImportExportSettingsSubPage(),
              title: "Import & Export Data",
              description: "Import CSV, backup data",
              icon: appStateSettings["outlinedIcons"]
                  ? Icons.sd_storage_outlined
                  : Icons.sd_storage_rounded,
            ),
            SettingsContainerOpenPage(
              openPage: const AboutPage(),
              title: "about-app".tr(namedArgs: {"app": globalAppName}),
              description: "App version, changelog, licensing info",
              icon: appStateSettings["outlinedIcons"]
                  ? Icons.info_outline
                  : Icons.info_rounded,
            ),
          ],
        ),

        // Tools & Extras Section
        SettingsGroupCard(
          title: "Tools & Extras",
          icon: appStateSettings["outlinedIcons"]
              ? Icons.extension_outlined
              : Icons.extension_rounded,
          children: [
            SettingsContainerOpenPage(
              openPage: const BillSplitter(),
              title: "Bill Splitter",
              icon: appStateSettings["outlinedIcons"]
                  ? Icons.summarize_outlined
                  : Icons.summarize_rounded,
            ),
            SettingsContainerOpenPage(
              openPage: const AutoTransactionsPageEmail(),
              title: "Advanced Automation",
              icon: appStateSettings["outlinedIcons"]
                  ? Icons.auto_awesome_outlined
                  : Icons.auto_awesome_rounded,
            ),
            SettingsContainerOpenPage(
              openPage: const MoreOptionsPagePreferences(),
              title: "Experimental Features",
              icon: appStateSettings["outlinedIcons"]
                  ? Icons.science_outlined
                  : Icons.science_rounded,
            ),
          ],
        ),
      ],
    );
  }
}

// Dedicated Group Settings Sub-Pages

// Dedicated Group Settings Sub-Pages

class GeneralSettingsSubPage extends StatelessWidget {
  const GeneralSettingsSubPage({super.key});

  @override
  Widget build(BuildContext context) {
    return PageFramework(
      title: "general".tr(),
      dragDownToDismiss: true,
      listWidgets: [
        // Security & Preferences Section
        SettingsGroupCard(
          title: "preferences".tr(),
          icon: appStateSettings["outlinedIcons"]
              ? Icons.tune_outlined
              : Icons.tune_rounded,
          children: [
            const BiometricsSettingToggle(),
            const NumberPadHapticFeedbackSetting(),
            SettingsContainerOpenPage(
              openPage: const EditHomePage(),
              title: "edit-home-page".tr(),
              icon: appStateSettings["outlinedIcons"]
                  ? Icons.home_outlined
                  : Icons.home_rounded,
            ),
            SettingsContainerSwitch(
              title: "Floating Navigation Bar",
              description: "Display floating dock at the bottom of the screen",
              onSwitched: (value) {
                updateSettings("floatingNavBar", value, updateGlobalState: true);
              },
              initialValue: appStateSettings["floatingNavBar"] ?? true,
              icon: appStateSettings["outlinedIcons"]
                  ? Icons.dock_outlined
                  : Icons.dock_rounded,
            ),
            if (appStateSettings["floatingNavBar"] == true)
              SettingsContainerSwitch(
                title: "Floating Bar Labels",
                description: "Show text labels under icons on the floating bar",
                onSwitched: (value) {
                  updateSettings("showFloatingNavBarLabels", value, updateGlobalState: true);
                },
                initialValue: appStateSettings["showFloatingNavBarLabels"] ?? true,
                icon: appStateSettings["outlinedIcons"]
                    ? Icons.label_outlined
                    : Icons.label_rounded,
              ),
            SettingsContainer(
              title: "Reset Home Page Layout",
              description: "Restore standard widget arrangement for home screen",
              icon: appStateSettings["outlinedIcons"]
                  ? Icons.restart_alt_outlined
                  : Icons.restart_alt_rounded,
              onTap: () async {
                await updateSettings(
                  "homePageOrder",
                  [
                    "wallets",
                    "walletsList",
                    "allSpendingSummary",
                    "overdueUpcoming",
                    "creditDebts",
                    "objectiveLoans",
                    "spendingGraph",
                    "transactionsList",
                    "budgets",
                    "objectives",
                    "netWorth",
                    "pieChart",
                    "heatMap",
                  ],
                  updateGlobalState: false,
                );
                await updateSettings("showWalletSwitcher", true, updateGlobalState: false);
                await updateSettings("showWalletList", true, updateGlobalState: false);
                await updateSettings("showAllSpendingSummary", true, updateGlobalState: false);
                await updateSettings("showOverdueUpcoming", true, updateGlobalState: false);
                await updateSettings("showCreditDebt", true, updateGlobalState: false);
                await updateSettings("showObjectiveLoans", true, updateGlobalState: false);
                await updateSettings("showSpendingGraph", true, updateGlobalState: false);
                await updateSettings("showTransactionsList", true, updateGlobalState: false);
                await updateSettings("showPinnedBudgets", true, updateGlobalState: false);
                await updateSettings("showObjectives", true, updateGlobalState: true);

                homePageStateKey.currentState?.refreshState();
                if (context.mounted) {
                  openSnackbar(
                    SnackbarMessage(
                      title: "Home Page Reset",
                      description: "Home page layout restored to default",
                      icon: Icons.check_circle_rounded,
                    ),
                  );
                }
              },
            ),
          ],
        ),

        // Widgets Section
        SettingsGroupCard(
          title: "widgets".tr(),
          icon: appStateSettings["outlinedIcons"]
              ? Icons.widgets_outlined
              : Icons.widgets_rounded,
          children: const [
            WidgetSettings(),
          ],
        ),

        // Edit Data Section
        SettingsGroupCard(
          title: "data".tr(),
          icon: appStateSettings["outlinedIcons"]
              ? Icons.edit_note_outlined
              : Icons.edit_note_rounded,
          children: [
            SettingsContainerOpenPage(
              openPage: const EditWalletsPage(),
              title: navBarIconsData["accountDetails"]!.label.tr(),
              icon: navBarIconsData["accountDetails"]!.iconData,
            ),
            SettingsContainerOpenPage(
              openPage: const EditBudgetPage(),
              title: navBarIconsData["budgetDetails"]!.label.tr(),
              icon: navBarIconsData["budgetDetails"]!.iconData,
            ),
            SettingsContainerOpenPage(
              openPage: const EditCategoriesPage(),
              title: navBarIconsData["categoriesDetails"]!.label.tr(),
              icon: navBarIconsData["categoriesDetails"]!.iconData,
            ),
            SettingsContainerOpenPage(
              openPage: const EditAssociatedTitlesPage(),
              title: navBarIconsData["titlesDetails"]!.label.tr(),
              icon: navBarIconsData["titlesDetails"]!.iconData,
            ),
          ],
        ),
      ],
    );
  }
}

class ThemeStyleSettingsSubPage extends StatelessWidget {
  const ThemeStyleSettingsSubPage({super.key});

  @override
  Widget build(BuildContext context) {
    return PageFramework(
      title: "Theme & Style",
      dragDownToDismiss: true,
      listWidgets: [
        // Theme Section
        SettingsGroupCard(
          title: "Theme",
          icon: Icons.palette_rounded,
          children: [
            Builder(
              builder: (context) {
                late Color? selectedColor =
                    HexColor(appStateSettings["accentColor"]);

                return SettingsContainer(
                  onTap: () {
                    openBottomSheet(
                      context,
                      useParentContextForTheme: false,
                      PopupFramework(
                        title: "select-color".tr(),
                        child: Column(
                          children: [
                            getPlatform() == PlatformOS.isIOS
                                ? Padding(
                                    padding: const EdgeInsetsDirectional.only(bottom: 8.0),
                                    child: SettingsContainerSwitch(
                                      title: "colorful-interface".tr(),
                                      onSwitched: (value) {
                                        updateSettings("materialYou", value,
                                            updateGlobalState: true);
                                      },
                                      initialValue: appStateSettings["materialYou"],
                                      icon: appStateSettings["outlinedIcons"]
                                          ? Icons.brush_outlined
                                          : Icons.brush_rounded,
                                      enableBorderRadius: true,
                                    ),
                                  )
                                : const SizedBox.shrink(),
                            SelectColor(
                              selectableColorsList: selectableAccentColors(context),
                              includeThemeColor: false,
                              selectedColor: selectedColor,
                              setSelectedColor: (color) {
                                selectedColor = color;
                                updateSettings("accentColor", toHexString(color),
                                    updateGlobalState: true);
                                updateSettings("accentSystemColor", false,
                                    updateGlobalState: true);
                                updateWidgetColorsAndText(context);
                              },
                              useSystemColorPrompt: true,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                  title: "accent-color".tr(),
                  description: "accent-color-description".tr(),
                  icon: appStateSettings["outlinedIcons"]
                      ? Icons.color_lens_outlined
                      : Icons.color_lens_rounded,
                );
              },
            ),
            getPlatform() == PlatformOS.isIOS
                ? const SizedBox.shrink()
                : SettingsContainerSwitch(
                    title: "material-you".tr(),
                    description: "material-you-description".tr(),
                    onSwitched: (value) {
                      updateSettings("materialYou", value, updateGlobalState: true);
                    },
                    initialValue: appStateSettings["materialYou"],
                    icon: appStateSettings["outlinedIcons"]
                        ? Icons.brush_outlined
                        : Icons.brush_rounded,
                  ),
            const ThemeSettingsDropdown(),
          ],
        ),

        // Style Section
        SettingsGroupCard(
          title: "Style",
          icon: appStateSettings["outlinedIcons"]
              ? Icons.style_outlined
              : Icons.style_rounded,
          children: [
            SettingsContainerDropdown(
              title: "Icon Style",
              icon: appStateSettings["outlinedIcons"]
                  ? Icons.star_outline_rounded
                  : Icons.star_rounded,
              initial: appStateSettings["outlinedIcons"] ? "Outlined" : "Rounded",
              items: const ["Rounded", "Outlined"],
              onChanged: (value) {
                updateSettings("outlinedIcons", value == "Outlined", updateGlobalState: true);
              },
              getLabel: (item) => item,
            ),
            SettingsContainerDropdown(
              title: "Net Total Style",
              icon: appStateSettings["outlinedIcons"]
                  ? Icons.calculate_outlined
                  : Icons.calculate_rounded,
              initial: appStateSettings["netTotalsColorful"] ? "Colorful" : "Simple",
              items: const ["Simple", "Colorful"],
              onChanged: (value) {
                updateSettings("netTotalsColorful", value == "Colorful", updateGlobalState: true);
              },
              getLabel: (item) => item,
            ),
            SettingsContainerOpenPage(
              openPage: const MoreOptionsPagePreferences(),
              title: "more-options".tr(),
              description: "more-options-description".tr(),
              icon: appStateSettings["outlinedIcons"]
                  ? Icons.style_outlined
                  : Icons.style_rounded,
            ),
          ],
        ),

        // Animations Section
        SettingsGroupCard(
          title: "Animations",
          icon: appStateSettings["outlinedIcons"]
              ? Icons.animation_outlined
              : Icons.animation_rounded,
          children: [
            const AppAnimationSetting(),
            const CountingNumberAnimationSetting(),
            SettingsContainerSwitch(
              title: "Animated Budget Background",
              description: "Disabling can increase performance",
              initialValue: appStateSettings["animatedBudgetContainers"] ?? true,
              icon: appStateSettings["outlinedIcons"]
                  ? Icons.auto_awesome_motion_outlined
                  : Icons.auto_awesome_motion_rounded,
              onSwitched: (value) {
                updateSettings("animatedBudgetContainers", value, updateGlobalState: true);
              },
            ),
          ],
        ),

        // Layout Section
        SettingsGroupCard(
          title: "Layout",
          icon: appStateSettings["outlinedIcons"]
              ? Icons.space_dashboard_outlined
              : Icons.space_dashboard_rounded,
          children: const [
            HeaderHeightSetting(),
          ],
        ),

        // Text & Font Section
        SettingsGroupCard(
          title: "Text",
          icon: appStateSettings["outlinedIcons"]
              ? Icons.text_fields_outlined
              : Icons.text_fields_rounded,
          children: const [
            FontPickerSetting(),
            IncreaseTextContrastSetting(),
          ],
        ),
      ],
    );
  }
}

class TransactionsSettingsSubPage extends StatelessWidget {
  const TransactionsSettingsSubPage({super.key});

  @override
  Widget build(BuildContext context) {
    return PageFramework(
      title: "transactions".tr(),
      dragDownToDismiss: true,
      listWidgets: [
        // Add New Transactions Section
        SettingsGroupCard(
          title: "Add New Transactions",
          icon: Icons.add_circle_outline_rounded,
          children: [
            SettingsContainerSwitch(
              title: "Transfer Balance Tab",
              description: "On 'Add New Transaction' page",
              initialValue: appStateSettings["showTransactionsBalanceTransferTab"] ?? true,
              icon: appStateSettings["outlinedIcons"]
                  ? Icons.swap_horiz_outlined
                  : Icons.swap_horiz_rounded,
              onSwitched: (value) {
                updateSettings("showTransactionsBalanceTransferTab", value, updateGlobalState: true);
              },
            ),
            SettingsContainerSwitch(
              title: "Add Attachments Button",
              description: "Show under the notes section",
              initialValue: appStateSettings["askForTransactionNoteWithTitle"] ?? false,
              icon: appStateSettings["outlinedIcons"]
                  ? Icons.attach_file_outlined
                  : Icons.attach_file_rounded,
              onSwitched: (value) {
                updateSettings("askForTransactionNoteWithTitle", value, updateGlobalState: true);
              },
            ),
            SettingsContainerSwitch(
              title: "Automatically Add Titles",
              description: "When a transaction is added",
              initialValue: appStateSettings["autoAddAssociatedTitles"] ?? true,
              icon: appStateSettings["outlinedIcons"]
                  ? Icons.title_outlined
                  : Icons.title_rounded,
              onSwitched: (value) {
                updateSettings("autoAddAssociatedTitles", value, updateGlobalState: true);
              },
            ),
            SettingsContainerSwitch(
              title: "Initial Input Prompts",
              description: "When first adding a transaction",
              initialValue: appStateSettings["askForTransactionTitle"] ?? true,
              icon: appStateSettings["outlinedIcons"]
                  ? Icons.edit_note_outlined
                  : Icons.edit_note_rounded,
              onSwitched: (value) {
                updateSettings("askForTransactionTitle", value, updateGlobalState: true);
              },
            ),
          ],
        ),

        // Scheduled Transactions Section
        SettingsGroupCard(
          title: "Scheduled Transactions",
          icon: navBarIconsData["scheduled"]!.iconData,
          children: [
            SettingsContainerSwitch(
              title: "Automatically Pay Transactions",
              description: "Automatically mark overdue transactions as paid",
              initialValue: appStateSettings["automaticallyPayUpcoming"] ?? true,
              icon: appStateSettings["outlinedIcons"]
                  ? Icons.event_available_outlined
                  : Icons.event_available_rounded,
              onSwitched: (value) {
                updateSettings("automaticallyPayUpcoming", value, updateGlobalState: true);
              },
            ),
            SettingsContainerDropdown(
              title: "Paid Date",
              description: "When a transaction is manually marked",
              icon: appStateSettings["outlinedIcons"]
                  ? Icons.calendar_today_outlined
                  : Icons.calendar_today_rounded,
              initial: appStateSettings["markAsPaidOnOriginalDay"] == true
                  ? "Original Date"
                  : "Current Date",
              items: const ["Current Date", "Original Date"],
              onChanged: (value) {
                updateSettings("markAsPaidOnOriginalDay", value == "Original Date", updateGlobalState: true);
              },
              getLabel: (item) => item,
            ),
            SettingsContainerOpenPage(
              openPage: const RecurringHubPage(),
              title: navBarIconsData["subscriptions"]!.label.tr(),
              icon: navBarIconsData["subscriptions"]!.iconData,
            ),
            SettingsContainerOpenPage(
              openPage: const RecurringHubPage(),
              title: navBarIconsData["scheduled"]!.label.tr(),
              icon: navBarIconsData["scheduled"]!.iconData,
            ),
          ],
        ),

        // Smart Automation & Intelligence Section
        SettingsGroupCard(
          title: "Xpenzi Intelligence & Automation",
          icon: Icons.auto_awesome_rounded,
          children: [
            SettingsContainerOpenPage(
              openPage: const AiSettingsPage(),
              title: "Xpenzi Intelligence",
              description: "Configure Google Gemini AI for smart transaction parsing",
              icon: Icons.psychology_rounded,
            ),
            SettingsContainerOpenPage(
              openPage: const AutoTransactionsPageNotifications(),
              title: "Notification Transactions",
              description: "Auto-create transactions from incoming SMS & app alerts",
              icon: Icons.notifications_active_rounded,
            ),
            SettingsContainerOpenPage(
              openPage: const MailboxPage(),
              title: "Mailbox",
              description: "Google Sheets Inbox & Drive CSV Outbox synchronization",
              icon: Icons.mark_email_unread_rounded,
            ),
          ],
        ),

        // Pinned & Logs Section
        SettingsGroupCard(
          title: "Pinned Transactions",
          icon: Icons.push_pin_outlined,
          children: [
            SettingsContainerOpenPage(
              openPage: const ActivityPage(),
              title: "transaction-activity-log".tr(),
              icon: appStateSettings["outlinedIcons"]
                  ? Icons.ballot_outlined
                  : Icons.ballot_rounded,
            ),
          ],
        ),
      ],
    );
  }
}

class LocalizationSettingsSubPage extends StatelessWidget {
  const LocalizationSettingsSubPage({super.key});

  @override
  Widget build(BuildContext context) {
    return PageFramework(
      title: "Localization",
      dragDownToDismiss: true,
      listWidgets: [
        // Language Section
        SettingsGroupCard(
          title: "Language",
          icon: Icons.language_rounded,
          children: [
            SettingsContainer(
              title: "language".tr(),
              icon: appStateSettings["outlinedIcons"]
                  ? Icons.language_outlined
                  : Icons.language_rounded,
              afterWidget: Tappable(
                color: Theme.of(context).colorScheme.secondaryContainer,
                borderRadius: 10,
                child: Padding(
                  padding: const EdgeInsetsDirectional.symmetric(
                      horizontal: 16, vertical: 10),
                  child: TextFont(
                    text: languageDisplayFilter(
                        appStateSettings["locale"].toString()),
                    fontSize: 14,
                  ),
                ),
              ),
              onTap: () {
                openLanguagePicker(context);
              },
            ),
          ],
        ),

        // Currency Section
        SettingsGroupCard(
          title: "Currency",
          icon: navBarIconsData["accountDetails"]!.iconData,
          children: [
            SettingsContainerOpenPage(
              openPage: const ExchangeRates(),
              title: "exchange-rates".tr(),
              icon: appStateSettings["outlinedIcons"]
                  ? Icons.currency_exchange_outlined
                  : Icons.currency_exchange_rounded,
            ),
            const PrimaryCurrencySetting(),
          ],
        ),

        // Calendar Format Section
        SettingsGroupCard(
          title: "Calendar Format",
          icon: Icons.calendar_month_rounded,
          children: const [
            Time24HourFormatSetting(),
            FirstDayOfWeekSetting(updateHomePage: true),
          ],
        ),

        // Number Format Section
        SettingsGroupCard(
          title: "Number Format",
          icon: Icons.pin_outlined,
          children: const [
            NumberFormattingSetting(),
            PercentagePrecisionSetting(),
          ],
        ),
      ],
    );
  }
}

class NotificationsSettingsSubPage extends StatelessWidget {
  const NotificationsSettingsSubPage({super.key});

  @override
  Widget build(BuildContext context) {
    return PageFramework(
      title: "Notifications",
      dragDownToDismiss: true,
      listWidgets: [
        SettingsGroupCard(
          title: "Reminders",
          icon: Icons.notifications_active_outlined,
          children: const [
            DailyNotificationsSettings(),
          ],
        ),
      ],
    );
  }
}

class ImportExportSettingsSubPage extends StatelessWidget {
  const ImportExportSettingsSubPage({super.key});

  @override
  Widget build(BuildContext context) {
    return PageFramework(
      title: "Import & Export",
      dragDownToDismiss: true,
      listWidgets: [
        // Spreadsheets Section
        SettingsGroupCard(
          title: "Spreadsheets",
          icon: Icons.table_chart_outlined,
          children: const [
            ExportCSV(),
            ImportCSV(),
          ],
        ),

        // Backups Section
        SettingsGroupCard(
          title: "Backups",
          icon: Icons.backup_outlined,
          children: [
            const ExportDB(),
            const ImportDB(),
            GoogleAccountLoginButton(
              isOutlinedButton: false,
              forceButtonName: "google-drive".tr(),
            ),
          ],
        ),
      ],
    );
  }
}

class EditDataOverviewPage extends StatelessWidget {
  const EditDataOverviewPage({super.key});

  @override
  Widget build(BuildContext context) {
    return PageFramework(
      title: "Edit, Delete, and Reorder Data",
      dragDownToDismiss: true,
      listWidgets: [
        SettingsGroupCard(
          title: "Manage Data",
          icon: Icons.edit_note_rounded,
          children: [
            SettingsContainerOpenPage(
              openPage: const EditWalletsPage(),
              title: navBarIconsData["accountDetails"]!.label.tr(),
              icon: navBarIconsData["accountDetails"]!.iconData,
            ),
            SettingsContainerOpenPage(
              openPage: const EditBudgetPage(),
              title: navBarIconsData["budgetDetails"]!.label.tr(),
              icon: navBarIconsData["budgetDetails"]!.iconData,
            ),
            SettingsContainerOpenPage(
              openPage: const EditCategoriesPage(),
              title: navBarIconsData["categoriesDetails"]!.label.tr(),
              icon: navBarIconsData["categoriesDetails"]!.iconData,
            ),
            SettingsContainerOpenPage(
              openPage: const EditAssociatedTitlesPage(),
              title: navBarIconsData["titlesDetails"]!.label.tr(),
              icon: navBarIconsData["titlesDetails"]!.iconData,
            ),
            SettingsContainerOpenPage(
              openPage: const ObjectivesListPage(backButton: true),
              title: navBarIconsData["goals"]!.label.tr(),
              icon: navBarIconsData["goals"]!.iconData,
            ),
            SettingsContainerOpenPage(
              openPage: const CreditDebtTransactions(isCredit: null),
              title: navBarIconsData["loans"]!.label.tr(),
              icon: navBarIconsData["loans"]!.iconData,
            ),
          ],
        ),
      ],
    );
  }
}

class ThemeSettingsDropdown extends StatefulWidget {
  const ThemeSettingsDropdown({super.key});

  @override
  State<ThemeSettingsDropdown> createState() => _ThemeSettingsDropdownState();
}

class _ThemeSettingsDropdownState extends State<ThemeSettingsDropdown> {
  @override
  Widget build(BuildContext context) {
    return SettingsContainerDropdown(
      key: ValueKey(appStateSettings["materialYou"].toString()),
      title: "theme-mode".tr(),
      icon: Theme.of(context).brightness == Brightness.light
          ? appStateSettings["outlinedIcons"]
              ? Icons.lightbulb_outlined
              : Icons.lightbulb_rounded
          : appStateSettings["outlinedIcons"]
              ? Icons.dark_mode_outlined
              : Icons.dark_mode_rounded,
      initial: appStateSettings["theme"].toString() == "black" &&
              appStateSettings["materialYou"] == false
          ? "dark"
          : appStateSettings["theme"].toString(),
      items: [
        "system",
        "light",
        "dark",
        if (appStateSettings["materialYou"] == true) "black"
      ],
      faintValues: [
        if (appStateSettings["materialYou"] == true &&
            appStateSettings["theme"].toString() == "system")
          appStateSettings["forceFullDarkBackground"] == true ? "dark" : "black"
      ],
      onChanged: (value) async {
        if (value == "black") {
          await updateSettings("forceFullDarkBackground", true,
              updateGlobalState: false);
        } else if (value == "dark") {
          await updateSettings("forceFullDarkBackground", false,
              updateGlobalState: false);
        }
        setState(() {});
        await updateSettings("theme", value, updateGlobalState: true);
        updateWidgetColorsAndText(context);
      },
      getLabel: (item) {
        return item.tr();
      },
    );
  }
}

class MoreOptionsPagePreferences extends StatelessWidget {
  const MoreOptionsPagePreferences({super.key});

  @override
  Widget build(BuildContext context) {
    return PageFramework(
      title: "more".tr(),
      dragDownToDismiss: true,
      horizontalPaddingConstrained: true,
      listWidgets: [
        SettingsGroupCard(
          title: "style".tr(),
          icon: appStateSettings["outlinedIcons"]
              ? Icons.palette_outlined
              : Icons.palette_rounded,
          children: const [
            HeaderHeightSetting(),
            OutlinedIconsSetting(),
            FontPickerSetting(),
            AppAnimationSetting(),
            CountingNumberAnimationSetting(),
            IncreaseTextContrastSetting(),
          ],
        ),
        SettingsGroupCard(
          title: "transactions".tr(),
          icon: navBarIconsData["transactions"]!.iconData,
          children: const [
            TransactionsSettings(),
          ],
        ),
        SettingsGroupCard(
          title: "accounts".tr(),
          icon: navBarIconsData["accountDetails"]!.iconData,
          children: const [
            WalletsSettings(),
            PrimaryCurrencySetting(),
          ],
        ),
        SettingsGroupCard(
          title: "budgets".tr(),
          icon: navBarIconsData["budgetDetails"]!.iconData,
          children: const [
            BudgetSettings(),
          ],
        ),
        SettingsGroupCard(
          title: "goals".tr(),
          icon: navBarIconsData["goals"]!.iconData,
          children: const [
            ObjectiveSettings(),
          ],
        ),
        SettingsGroupCard(
          title: "titles".tr(),
          icon: navBarIconsData["titlesDetails"]!.iconData,
          children: const [
            TitlesSettings(),
          ],
        ),
        SettingsGroupCard(
          title: "widgets".tr(),
          icon: appStateSettings["outlinedIcons"]
              ? Icons.widgets_outlined
              : Icons.widgets_rounded,
          children: const [
            WidgetSettings(),
          ],
        ),
        SettingsGroupCard(
          title: "formatting".tr(),
          icon: appStateSettings["outlinedIcons"]
              ? Icons.format_list_numbered_outlined
              : Icons.format_list_numbered_rounded,
          children: const [
            NumberFormattingSetting(),
            PercentagePrecisionSetting(),
            Time24HourFormatSetting(),
            FirstDayOfWeekSetting(updateHomePage: true),
            NumberPadFormatSetting(),
          ],
        ),
      ],
    );
  }
}

class WidgetSettings extends StatelessWidget {
  const WidgetSettings({super.key});

  @override
  Widget build(BuildContext context) {
    if (getPlatform(ignoreEmulation: true) != PlatformOS.isAndroid) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SettingsContainer(
          title: "net-worth-total-widget".tr(),
          description: "select-accounts-and-time-period".tr(),
          onTap: () async {
            await openNetWorthSettings(context);
            // We need to resfresh the widget rendering since it exists on the homepage!
            homePageStateKey.currentState?.refreshState();
          },
          icon: appStateSettings["outlinedIcons"]
              ? Icons.area_chart_outlined
              : Icons.area_chart_rounded,
        ),
        SettingsContainerDropdown(
          title: "widget-theme".tr(),
          icon: appStateSettings["outlinedIcons"]
              ? Icons.contrast_outlined
              : Icons.contrast_rounded,
          initial: appStateSettings["widgetTheme"].toString(),
          items: const ["app", "light", "dark"],
          onChanged: (value) async {
            if (value == "app") value = "system";
            await updateSettings("widgetTheme", value,
                updateGlobalState: false);
            updateWidgetColorsAndText(context);
          },
          getLabel: (item) {
            return item.tr();
          },
        ),
        SettingsContainer(
          title: "widget-background-opacity".tr(),
          icon: appStateSettings["outlinedIcons"]
              ? Icons.blur_on_outlined
              : Icons.blur_on_rounded,
          descriptionWidget: Container(
            height: 28,
            padding: const EdgeInsetsDirectional.only(end: 10),
            child: SliderTheme(
              data: SliderThemeData(
                trackShape: CustomTrackShape(),
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 9),
              ),
              child: SliderSelector(
                min: 0,
                max: 1,
                initialValue:
                    (appStateSettings["widgetOpacity"] ?? 1).toDouble(),
                onChange: (value) {},
                divisions: 20,
                onFinished: (value) {
                  updateSettings("widgetOpacity", value,
                      updateGlobalState: false);
                  updateWidgetColorsAndText(context);
                },
                displayFilter: (double number) {
                  return convertToPercent(number * 100, numberDecimals: 0);
                },
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class CustomTrackShape extends RoundedRectSliderTrackShape {
  @override
  Rect getPreferredRect({
    required RenderBox parentBox,
    Offset offset = Offset.zero,
    required SliderThemeData sliderTheme,
    bool isEnabled = false,
    bool isDiscrete = false,
  }) {
    final trackHeight = sliderTheme.trackHeight;
    final trackLeft = offset.dx;
    final trackTop =
        offset.dy + (parentBox.size.height - (trackHeight ?? 0)) / 2;
    final trackWidth = parentBox.size.width;
    return Rect.fromLTWH(trackLeft, trackTop, trackWidth, (trackHeight ?? 0));
  }
}

class BiometricsSettingToggle extends StatefulWidget {
  const BiometricsSettingToggle({super.key});

  @override
  State<BiometricsSettingToggle> createState() =>
      _BiometricsSettingToggleState();
}

class _BiometricsSettingToggleState extends State<BiometricsSettingToggle> {
  bool isLocked = appStateSettings["requireAuth"];
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        authAvailable || isLocked
            ? SettingsContainerSwitch(
                title: "biometric-lock".tr(),
                description: "biometric-lock-description".tr(),
                onSwitched: (value) async {
                  AuthResult authResult =
                      await checkBiometrics(checkAlways: true);
                  if (authResult == AuthResult.error) {
                    openPopup(
                      context,
                      icon: appStateSettings["outlinedIcons"]
                          ? Icons.warning_outlined
                          : Icons.warning_rounded,
                      title: getPlatform() == PlatformOS.isIOS
                          ? "biometrics-disabled".tr()
                          : "biometrics-error".tr(),
                      description: getPlatform() == PlatformOS.isIOS
                          ? "biometrics-disabled-description".tr()
                          : "biometrics-error-description".tr(),
                      onCancelLabel:
                          getPlatform() == PlatformOS.isIOS ? "ok".tr() : null,
                      onCancel: () {
                        popRoute(context);
                      },
                      onSubmitLabel: getPlatform() == PlatformOS.isIOS
                          ? "open-settings".tr()
                          : "ok".tr(),
                      onSubmit: () {
                        updateSettings("requireAuth", false,
                            updateGlobalState: false);
                        setState(() {
                          isLocked = false;
                        });
                        popRoute(context);
                        // On iOS the notification app settings page also has
                        // the permission for biometrics
                        if (getPlatform() == PlatformOS.isIOS) {
                          AppSettings.openAppSettings(
                              type: AppSettingsType.notification);
                        }
                      },
                    );
                  } else if (authResult == AuthResult.authenticated) {
                    updateSettings("requireAuth", value,
                        updateGlobalState: false);
                    setState(() {
                      isLocked = value;
                    });
                  }
                  return authResult == AuthResult.authenticated;
                },
                initialValue: isLocked,
                icon: isLocked
                    ? appStateSettings["outlinedIcons"]
                        ? Icons.lock_outlined
                        : Icons.lock_rounded
                    : appStateSettings["outlinedIcons"]
                        ? Icons.lock_open_outlined
                        : Icons.lock_open_rounded,
              )
            : const SizedBox.shrink(),
      ],
    );
  }
}

class HeaderHeightSetting extends StatelessWidget {
  const HeaderHeightSetting({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedExpanded(
      // Indicates if it is enabled by default per device height
      expand: MediaQuery.sizeOf(context).height > MIN_HEIGHT_FOR_HEADER &&
          getPlatform() != PlatformOS.isIOS,
      child: SettingsContainerDropdown(
        title: "header-height".tr(),
        icon: appStateSettings["outlinedIcons"]
            ? Icons.subtitles_outlined
            : Icons.subtitles_rounded,
        initial: appStateSettings["forceSmallHeader"].toString(),
        items: const ["true", "false"],
        onChanged: (value) async {
          bool boolValue = false;
          if (value == "true") {
            boolValue = true;
          } else if (value == "false") {
            boolValue = false;
          }
          await updateSettings(
            "forceSmallHeader",
            boolValue,
            updateGlobalState: false,
            setStateAllPageFrameworks: true,
            pagesNeedingRefresh: [0],
          );
        },
        getLabel: (item) {
          if (item == "true") return "short".tr();
          if (item == "false") return "tall".tr();
        },
      ),
    );
  }
}

// Changing this setting needs to update the UI, that's not something that happens when setting global state
class OutlinedIconsSetting extends StatelessWidget {
  const OutlinedIconsSetting({super.key});

  @override
  Widget build(BuildContext context) {
    return SettingsContainerDropdown(
      items: const ["rounded", "outlined"],
      onChanged: (value) async {
        if (value == "rounded") {
          await updateSettings("outlinedIcons", false,
              updateGlobalState: false);
        } else {
          await updateSettings(
            "outlinedIcons",
            true,
            updateGlobalState: false,
          );
        }
        navBarIconsData = getNavBarIconsData();
        RestartApp.restartApp(context);
      },
      getLabel: (value) {
        return value.tr();
      },
      initial:
          appStateSettings["outlinedIcons"] == true ? "outlined" : "rounded",
      title: "icon-style".tr(),
      icon: appStateSettings["outlinedIcons"]
          ? Icons.star_outline
          : Icons.star_rounded,
    );
  }
}

class CountingNumberAnimationSetting extends StatelessWidget {
  const CountingNumberAnimationSetting({super.key});

  @override
  Widget build(BuildContext context) {
    return SettingsContainerDropdown(
      title: "number-animation".tr(),
      icon: appStateSettings["outlinedIcons"]
          ? Icons.pin_outlined
          : Icons.pin_rounded,
      initial: appStateSettings["numberCountUpAnimation"] == true
          ? "count-up"
          : "disabled",
      items: const ["count-up", "disabled"],
      onChanged: (value) async {
        await updateSettings(
          "numberCountUpAnimation",
          value == "count-up" ? true : false,
          updateGlobalState: false,
        );
      },
      getLabel: (item) {
        return item.tr();
      },
    );
  }
}

class AppAnimationSetting extends StatelessWidget {
  const AppAnimationSetting({super.key});

  @override
  Widget build(BuildContext context) {
    return SettingsContainerDropdown(
      title: "app-animations".tr(),
      description: "app-animations-description".tr(),
      icon: appStateSettings["outlinedIcons"]
          ? Icons.animation_outlined
          : Icons.animation_rounded,
      initial: appStateSettings["appAnimations"] == AppAnimations.all.index
          ? "all"
          : appStateSettings["appAnimations"] == AppAnimations.minimal.index
              ? "minimal"
              : appStateSettings["appAnimations"] ==
                      AppAnimations.disabled.index
                  ? "disabled"
                  : "all",
      items: const ["all", "minimal"], // "disabled" is not yet supported
      onChanged: (value) async {
        await updateSettings(
          "appAnimations",
          value == "all"
              ? AppAnimations.all.index
              : value == "minimal"
                  ? AppAnimations.minimal.index
                  : value == "disabled"
                      ? AppAnimations.disabled.index
                      : "all",
          updateGlobalState: false,
          setStateAllPageFrameworks: true,
        );
        appStateKey.currentState?.refreshAppState();
      },
      getLabel: (item) {
        return item.tr();
      },
    );
  }
}

class IncreaseTextContrastSetting extends StatelessWidget {
  const IncreaseTextContrastSetting({super.key});

  @override
  Widget build(BuildContext context) {
    return SettingsContainerSwitch(
      title: "increase-text-contrast".tr(),
      description: "increase-text-contrast-description".tr(),
      onSwitched: (value) async {
        await updateSettings("increaseTextContrast", value,
            updateGlobalState: true);
      },
      initialValue: appStateSettings["increaseTextContrast"],
      icon: appStateSettings["outlinedIcons"]
          ? Icons.exposure_outlined
          : Icons.exposure_rounded,
      descriptionColor: appStateSettings["increaseTextContrast"]
          ? getColor(context, "black").withValues(alpha: 0.84)
          : Theme.of(context).colorScheme.secondary.withValues(alpha: 0.45),
    );
  }
}

class FontPickerSetting extends StatelessWidget {
  const FontPickerSetting({super.key});

  @override
  Widget build(BuildContext context) {
    return SettingsContainer(
      title: "font".tr().capitalizeFirst,
      icon: appStateSettings["outlinedIcons"]
          ? Icons.font_download_outlined
          : Icons.font_download_rounded,
      afterWidget: Tappable(
        color: Theme.of(context).colorScheme.secondaryContainer,
        borderRadius: 10,
        child: Padding(
          padding: const EdgeInsetsDirectional.symmetric(
              horizontal: 16, vertical: 10),
          child: Builder(builder: (context) {
            String displayFontName =
                fontNameDisplayFilter(appStateSettings["font"].toString());
            return TextFont(
              text: displayFontName,
              fontSize: 14,
            );
          }),
        ),
      ),
      onTap: () {
        openFontPicker(context);
      },
    );
  }
}

void openFontPicker(BuildContext context) {
  openBottomSheet(
    context,
    PopupFramework(
      title: "font".tr(),
      child: RadioItems(
        itemsAreFonts: true,
        items: const [
          // These values match that of pubspec font family
          "Avenir",
          "DMSans",
          "Metropolis",
          // SF Pro removed - users on iOS can just select Platform font
          // Inter is the font family fallback
          "RobotoCondensed",
          "Inconsolata",
          "(Platform)",
        ],
        initial: appStateSettings["font"].toString(),
        displayFilter: fontNameDisplayFilter,
        onChanged: (value) async {
          updateSettings("font", value, updateGlobalState: true);
          await Future.delayed(const Duration(milliseconds: 50));
          popRoute(context);
        },
      ),
    ),
  );
}

String fontNameDisplayFilter(String value) {
  if (value == "Avenir") {
    return "default".tr().capitalizeFirst;
  } else if (value == "(Platform)") {
    return "platform".tr().capitalizeFirst;
  } else if (value == "DMSans") {
    return "DM Sans";
  } else if (value == "RobotoCondensed") {
    return "Roboto Condensed";
  } else if (value == "Inconsolata") {
    return "Inconsolata Monospace";
  }
  return value.toString();
}

class NumberFormattingSetting extends StatelessWidget {
  const NumberFormattingSetting({super.key});

  @override
  Widget build(BuildContext context) {
    return SettingsContainer(
      title: "number-format".tr(),
      icon: appStateSettings["outlinedIcons"]
          ? Icons.one_x_mobiledata_outlined
          : Icons.one_x_mobiledata_rounded,
      afterWidget: IgnorePointer(
        child: Tappable(
          color: Theme.of(context).colorScheme.secondaryContainer,
          borderRadius: 10,
          child: Padding(
            padding: const EdgeInsetsDirectional.symmetric(
                horizontal: 16, vertical: 10),
            child: TextFont(
              text: convertToMoney(
                Provider.of<AllWallets>(context, listen: true),
                1234.56,
              ),
              fontSize: 14,
            ),
          ),
        ),
      ),
      onTap: () async {
        String originalSetting =
            appStateSettings["customNumberFormat"].toString() +
                appStateSettings["numberFormatDelimiter"].toString() +
                appStateSettings["numberFormatDecimal"].toString() +
                appStateSettings["numberFormatCurrencyFirst"].toString();
        await openBottomSheet(
          context,
          fullSnap: true,
          const SetNumberFormatPopup(),
        );
        String newSetting = appStateSettings["customNumberFormat"].toString() +
            appStateSettings["numberFormatDelimiter"].toString() +
            appStateSettings["numberFormatDecimal"].toString() +
            appStateSettings["numberFormatCurrencyFirst"].toString();
        await updateSettings(
          "customNumberFormat",
          appStateSettings["customNumberFormat"],
          updateGlobalState: true,
          forceGlobalStateUpdate: originalSetting != newSetting,
        );
      },
    );
  }
}

class Time24HourFormatSetting extends StatelessWidget {
  const Time24HourFormatSetting({super.key});

  @override
  Widget build(BuildContext context) {
    return SettingsContainerDropdown(
      title: "clock-format".tr(),
      icon: appStateSettings["outlinedIcons"]
          ? Icons.history_toggle_off_outlined
          : Icons.history_toggle_off_rounded,
      initial: appStateSettings["use24HourFormat"].toString(),
      items: const ["system", "12-hour", "24-hour"],
      onChanged: (value) async {
        await updateSettings("use24HourFormat", value, updateGlobalState: true);
      },
      getLabel: (item) {
        return item.tr();
      },
    );
  }
}

class SetNumberFormatPopup extends StatefulWidget {
  const SetNumberFormatPopup({super.key});

  @override
  State<SetNumberFormatPopup> createState() => _SetNumberFormatPopupState();
}

class _SetNumberFormatPopupState extends State<SetNumberFormatPopup> {
  bool customNumberFormat = appStateSettings["customNumberFormat"] == true;

  @override
  Widget build(BuildContext context) {
    AllWallets allWallets = Provider.of<AllWallets>(context);
    return PopupFramework(
      title: "number-format".tr(),
      child: Column(
        children: [
          SettingsContainerSwitch(
            title: "short-number-format".tr(),
            onSwitched: (value) {
              updateSettings(
                "shortNumberFormat",
                value ? "compact" : null,
                updateGlobalState: true,
              );
            },
            initialValue: appStateSettings["shortNumberFormat"] == "compact",
            enableBorderRadius: true,
            icon: appStateSettings["outlinedIcons"]
                ? Icons.one_k_outlined
                : Icons.one_k_rounded,
          ),
          const HorizontalBreak(),
          const SizedBox(height: 10),
          AnimatedOpacity(
            duration: const Duration(milliseconds: 500),
            opacity: customNumberFormat == false ? 1 : 0.5,
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButtonStacked(
                    filled: customNumberFormat == false,
                    alignStart: true,
                    alignBeside: true,
                    padding: const EdgeInsetsDirectional.symmetric(
                        horizontal: 20, vertical: 20),
                    text: "default".tr(),
                    afterWidget: Padding(
                      padding:
                          const EdgeInsetsDirectional.symmetric(vertical: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          TextFont(
                            textAlign: TextAlign.center,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            text: convertToMoney(
                              allWallets,
                              -1234.56,
                              forceNonCustomNumberFormat: true,
                              addCurrencyName: true,
                            ),
                          ),
                        ],
                      ),
                    ),
                    iconData: appStateSettings["outlinedIcons"]
                        ? Icons.check_circle_outlined
                        : Icons.check_circle_rounded,
                    onTap: () {
                      updateSettings("customNumberFormat", false,
                          updateGlobalState: false);
                      setState(() {
                        customNumberFormat = false;
                      });
                    },
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 13),
          AnimatedOpacity(
            duration: const Duration(milliseconds: 500),
            opacity: customNumberFormat == true ? 1 : 0.5,
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButtonStacked(
                    filled: customNumberFormat == true,
                    alignStart: true,
                    alignBeside: true,
                    padding: const EdgeInsetsDirectional.symmetric(
                        horizontal: 20, vertical: 20),
                    text: "custom".tr(),
                    afterWidget: CustomNumberFormatPopup(onChangeAnyOption: () {
                      updateSettings("customNumberFormat", true,
                          updateGlobalState: false);
                      setState(() {
                        customNumberFormat = true;
                      });
                    }),
                    iconData: appStateSettings["outlinedIcons"]
                        ? Icons.tune_outlined
                        : Icons.tune_rounded,
                    onTap: () {
                      updateSettings("customNumberFormat", true,
                          updateGlobalState: false);
                      setState(() {
                        customNumberFormat = true;
                      });
                    },
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 5),
          Tappable(
            borderRadius: 10,
            color: Colors.transparent,
            onTap: () {
              popRoute(context);
              pushRoute(context, const EditWalletsPage());
            },
            child: Padding(
              padding: const EdgeInsetsDirectional.only(
                  start: 8, end: 8, top: 5, bottom: 5),
              child: TextFont(
                text: "decimal-precision-edit-account-info".tr(),
                fontSize: 14,
                maxLines: 10,
                textColor: getColor(context, "textLight"),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class CustomNumberFormatPopup extends StatefulWidget {
  const CustomNumberFormatPopup({super.key, this.onChangeAnyOption});
  final VoidCallback? onChangeAnyOption;

  @override
  State<CustomNumberFormatPopup> createState() =>
      _CustomNumberFormatPopupState();
}

class _CustomNumberFormatPopupState extends State<CustomNumberFormatPopup> {
  String customDelimiter = appStateSettings["numberFormatDelimiter"];
  String customDecimal = appStateSettings["numberFormatDecimal"];
  bool numberFormatCurrencyFirst =
      appStateSettings["numberFormatCurrencyFirst"];
  @override
  Widget build(BuildContext context) {
    AllWallets allWallets = Provider.of<AllWallets>(context);
    String formattedNumber = convertToMoney(
      allWallets,
      -1234.56,
      forceCustomNumberFormat: true,
      addCurrencyName: true,
      customSymbol: getCurrencyString(allWallets) == ""
          ? "⬚"
          : getCurrencyString(allWallets),
    );
    return Column(
      children: [
        const SizedBox(height: 20),
        AnimatedSizeSwitcher(
          child: TextFont(
            key: ValueKey(formattedNumber),
            textAlign: TextAlign.center,
            fontSize: 28,
            fontWeight: FontWeight.bold,
            text: formattedNumber,
          ),
        ),
        const SizedBox(height: 30),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: SettingsContainer(
                isOutlined: true,
                isOutlinedColumn: true,
                title: "delimiter".tr(),
                icon: appStateSettings["outlinedIcons"]
                    ? Symbols.decimal_decrease_sharp
                    : Symbols.decimal_decrease_rounded,
                onTap: () {
                  if (widget.onChangeAnyOption != null) {
                    widget.onChangeAnyOption!();
                  }
                  openBottomSheet(
                    context,
                    popupWithKeyboard: true,
                    PopupFramework(
                      title: "set-delimiter".tr(),
                      child: SelectText(
                        maxLength: 5,
                        buttonLabel: "set-delimiter".tr(),
                        popContext: false,
                        setSelectedText: (_) {},
                        placeholder: "delimiter-symbol".tr(),
                        icon: appStateSettings["outlinedIcons"]
                            ? Symbols.decimal_decrease_sharp
                            : Symbols.decimal_decrease_rounded,
                        selectedText: customDelimiter,
                        nextWithInput: (text) async {
                          setState(() {
                            customDelimiter = text;
                          });
                          updateSettings("numberFormatDelimiter", text,
                              updateGlobalState: false);
                          popRoute(context);
                        },
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: SettingsContainer(
                isOutlined: true,
                isOutlinedColumn: true,
                title: "${"symbol".tr()}\n${numberFormatCurrencyFirst
                        ? "before".tr().capitalizeFirst
                        : "after".tr().capitalizeFirst}",
                icon: appStateSettings["outlinedIcons"]
                    ? Icons.monetization_on_outlined
                    : Icons.monetization_on_rounded,
                onTap: () {
                  if (widget.onChangeAnyOption != null) {
                    widget.onChangeAnyOption!();
                  }
                  setState(() {
                    numberFormatCurrencyFirst = !numberFormatCurrencyFirst;
                  });
                  updateSettings(
                      "numberFormatCurrencyFirst", numberFormatCurrencyFirst,
                      updateGlobalState: false);
                },
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: SettingsContainer(
                isOutlined: true,
                isOutlinedColumn: true,
                title: "decimal".tr(),
                icon: appStateSettings["outlinedIcons"]
                    ? Symbols.decimal_increase_sharp
                    : Symbols.decimal_increase_rounded,
                onTap: () {
                  if (widget.onChangeAnyOption != null) {
                    widget.onChangeAnyOption!();
                  }
                  openBottomSheet(
                    context,
                    popupWithKeyboard: true,
                    PopupFramework(
                      title: "set-decimal".tr(),
                      child: SelectText(
                        maxLength: 5,
                        buttonLabel: "set-decimal".tr(),
                        popContext: false,
                        setSelectedText: (_) {},
                        placeholder: "decimal-symbol".tr(),
                        icon: appStateSettings["outlinedIcons"]
                            ? Symbols.decimal_increase_sharp
                            : Symbols.decimal_increase_rounded,
                        selectedText: customDecimal,
                        nextWithInput: (text) async {
                          setState(() {
                            customDecimal = text;
                          });
                          updateSettings("numberFormatDecimal", text,
                              updateGlobalState: false);
                          popRoute(context);
                        },
                      ),
                    ),
                  );
                },
              ),
            )
          ],
        ),
      ],
    );
  }
}

class NumberPadFormatSetting extends StatelessWidget {
  const NumberPadFormatSetting({super.key});

  @override
  Widget build(BuildContext context) {
    return SettingsContainer(
      title: "number-pad-format".tr(),
      onTap: () {
        openBottomSheet(
          context,
          const NumberPadFormatSettingPopup(),
        );
      },
      icon: appStateSettings["outlinedIcons"]
          ? Icons.dialpad_sharp
          : Icons.dialpad_rounded,
    );
  }
}

class NumberPadFormatSettingPopup extends StatefulWidget {
  const NumberPadFormatSettingPopup({super.key});

  @override
  State<NumberPadFormatSettingPopup> createState() =>
      _NumberPadFormatSettingPopupState();
}

class _NumberPadFormatSettingPopupState
    extends State<NumberPadFormatSettingPopup> {
  @override
  Widget build(BuildContext context) {
    return PopupFramework(
      title: "number-pad-format".tr(),
      child: Column(
        children: [
          ExtraZerosButtonSetting(
            enableBorderRadius: true,
            onChange: () {
              setState(() {});
            },
          ),
          const NumberPadHapticFeedbackSetting(
            enableBorderRadius: true,
          ),
          const HorizontalBreak(),
          const SizedBox(height: 10),
          const NumberPadFormatPicker(),
        ],
      ),
    );
  }
}

class NumberPadFormatPicker extends StatefulWidget {
  const NumberPadFormatPicker({super.key});

  @override
  State<NumberPadFormatPicker> createState() => _NumberPadFormatPickerState();
}

class _NumberPadFormatPickerState extends State<NumberPadFormatPicker> {
  NumberPadFormat selectedNumberPadFormat = getNumberPadFormat();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 500),
                opacity: selectedNumberPadFormat == NumberPadFormat.format123
                    ? 1
                    : 0.5,
                child: OutlinedButtonStacked(
                  filled: selectedNumberPadFormat == NumberPadFormat.format123,
                  alignStart: true,
                  alignBeside: true,
                  text: null,
                  afterWidget: IgnorePointer(
                    child: NumberPadAmount(
                      extraWidgetAboveNumbers: null,
                      addToAmount: (_) {},
                      enableDecimal: true,
                      removeToAmount: () {},
                      removeAll: () {},
                      canChange: () => true,
                      enableCalculator: true,
                      padding: EdgeInsetsDirectional.zero,
                      setState: () {},
                      format: NumberPadFormat.format123,
                    ),
                  ),
                  padding: const EdgeInsetsDirectional.only(
                      start: 20, end: 15, top: 10, bottom: 15),
                  iconData: null,
                  onTap: () {
                    setState(() {
                      selectedNumberPadFormat = NumberPadFormat.format123;
                    });
                    updateSettings(
                        "numberPadFormat", NumberPadFormat.format123.index,
                        updateGlobalState: false);
                  },
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 500),
                opacity: selectedNumberPadFormat == NumberPadFormat.format789
                    ? 1
                    : 0.5,
                child: OutlinedButtonStacked(
                  filled: selectedNumberPadFormat == NumberPadFormat.format789,
                  alignStart: true,
                  alignBeside: true,
                  text: null,
                  afterWidget: IgnorePointer(
                    child: NumberPadAmount(
                      extraWidgetAboveNumbers: null,
                      addToAmount: (_) {},
                      enableDecimal: true,
                      removeToAmount: () {},
                      removeAll: () {},
                      canChange: () => true,
                      enableCalculator: true,
                      padding: EdgeInsetsDirectional.zero,
                      setState: () {},
                      format: NumberPadFormat.format789,
                    ),
                  ),
                  padding: const EdgeInsetsDirectional.only(
                      start: 20, end: 15, top: 10, bottom: 15),
                  iconData: null,
                  onTap: () {
                    setState(() {
                      selectedNumberPadFormat = NumberPadFormat.format789;
                    });
                    updateSettings(
                        "numberPadFormat", NumberPadFormat.format789.index,
                        updateGlobalState: false);
                  },
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class ExtraZerosButtonSetting extends StatelessWidget {
  const ExtraZerosButtonSetting(
      {this.onChange, this.enableBorderRadius = false, super.key});
  final bool enableBorderRadius;
  final VoidCallback? onChange;
  @override
  Widget build(BuildContext context) {
    return SettingsContainerDropdown(
      enableBorderRadius: enableBorderRadius,
      title: "extra-zeros-button".tr(),
      icon: appStateSettings["outlinedIcons"]
          ? Symbols.counter_0_sharp
          : Symbols.counter_0_rounded,
      initial: appStateSettings["extraZerosButton"].toString(),
      items: const ["", "00", "000"],
      onChanged: (value) async {
        await updateSettings(
          "extraZerosButton",
          value == "" ? null : value,
          updateGlobalState: false,
        );
        if (onChange != null) onChange!();
      },
      getLabel: (item) {
        if (item == "") return "none".tr().capitalizeFirst;
        return item;
      },
    );
  }
}

class NumberPadHapticFeedbackSetting extends StatelessWidget {
  const NumberPadHapticFeedbackSetting(
      {this.enableBorderRadius = false, super.key});
  final bool enableBorderRadius;
  @override
  Widget build(BuildContext context) {
    return SettingsContainerSwitch(
      enableBorderRadius: enableBorderRadius,
      title: "haptic-feedback".tr(),
      icon: appStateSettings["outlinedIcons"]
          ? Icons.vibration_outlined
          : Symbols.vibration_rounded,
      initialValue: appStateSettings["numberPadHapticFeedback"] == true,
      onSwitched: (value) async {
        if (value == true) HapticFeedback.heavyImpact();
        await updateSettings(
          "numberPadHapticFeedback",
          value,
          updateGlobalState: false,
        );
      },
    );
  }
}

class PercentagePrecisionSetting extends StatelessWidget {
  const PercentagePrecisionSetting({super.key});
  @override
  Widget build(BuildContext context) {
    return SettingsContainerDropdown(
      title: "percentage-precision".tr(),
      icon: appStateSettings["outlinedIcons"]
          ? Icons.percent_outlined
          : Icons.percent_rounded,
      initial: appStateSettings["percentagePrecision"] == 2
          ? "2-decimals"
          : appStateSettings["percentagePrecision"] == 1
              ? "1-decimal"
              : "0-decimals",
      items: const ["0-decimals", "1-decimal", "2-decimals"],
      onChanged: (value) async {
        updateSettings(
          "percentagePrecision",
          value == "2-decimals"
              ? 2
              : value == "1-decimal"
                  ? 1
                  : 0,
          updateGlobalState: true,
        );
      },
      getLabel: (item) {
        return item.tr();
      },
    );
  }
}

void savingHapticFeedback() {
  if (appStateSettings["savingHapticFeedback"] == true) {
    HapticFeedback.lightImpact();
  }
}

class FirstDayOfWeekSetting extends StatelessWidget {
  const FirstDayOfWeekSetting({required this.updateHomePage, super.key});
  final bool updateHomePage;
  @override
  Widget build(BuildContext context) {
    return SettingsContainerDropdown(
      title: "first-weekday".tr(),
      icon: appStateSettings["outlinedIcons"]
          ? Icons.calendar_month_outlined
          : Icons.calendar_month_rounded,
      initial: appStateSettings["firstDayOfWeek"].toString(),
      items: const ["-1", "0", "1"],
      onChanged: (value) async {
        int intValue = int.tryParse(value) ?? -1;
        await updateSettings(
          "firstDayOfWeek",
          intValue,
          updateGlobalState: false,
          pagesNeedingRefresh: updateHomePage ? [0] : [],
        );
      },
      getLabel: (item) {
        List<String> weekDayNames = getWeekdayNames();
        if (item == "-1") return "default".tr();
        if (item == "0") return weekDayNames[0];
        if (item == "1") return weekDayNames[1];
      },
    );
  }
}

List<String> getWeekdayNames() {
  List<String> localizedWeekdayNames = [];
  final String? locale = navigatorKey.currentContext?.locale.toString();

  // Use a fixed date that is not affected by daylight saving time.
  // December 31st, 2023, is a Sunday
  final DateTime baseDate = DateTime.utc(2023, 12, 31, 12, 0, 0);

  for (int i = 0; i < 7; i++) {
    final DateTime date = baseDate.add(Duration(days: i));
    final String weekdayName = DateFormat.EEEE(locale).format(date);
    localizedWeekdayNames.add(weekdayName);
  }

  return localizedWeekdayNames;
}

class ShowSubcategoryIconSetting extends StatelessWidget {
  const ShowSubcategoryIconSetting({super.key});
  @override
  Widget build(BuildContext context) {
    return SettingsContainerSwitch(
      title: "Show Subcategory Icons",
      description: "Display subcategory icon instead of main category icon on transaction rows",
      icon: appStateSettings["outlinedIcons"]
          ? Icons.category_outlined
          : Icons.category_rounded,
      initialValue: appStateSettings["showSubcategoryIcon"] == true,
      onSwitched: (value) async {
        await updateSettings(
          "showSubcategoryIcon",
          value,
          updateGlobalState: true,
          pagesNeedingRefresh: [0, 1, 2],
        );
      },
    );
  }
}

class AnimatedBudgetContainersSetting extends StatelessWidget {
  const AnimatedBudgetContainersSetting({super.key});
  @override
  Widget build(BuildContext context) {
    return SettingsContainerSwitch(
      title: "Animated Budget Containers",
      description: "Enable smooth animations for budget cards (disable to increase scrolling performance)",
      icon: appStateSettings["outlinedIcons"]
          ? Icons.animation_outlined
          : Icons.animation_rounded,
      initialValue: appStateSettings["animatedBudgetContainers"] == true,
      onSwitched: (value) async {
        await updateSettings(
          "animatedBudgetContainers",
          value,
          updateGlobalState: true,
          pagesNeedingRefresh: [0, 2],
        );
      },
    );
  }
}
