import 'dart:math';
import 'package:budget/colors.dart';
import 'package:budget/database/tables.dart' hide AppSettings;
import 'package:reorderable_grid_view/reorderable_grid_view.dart';
import 'package:budget/pages/aboutPage.dart';
import 'package:budget/pages/addTransactionPage.dart';
import 'package:budget/pages/billSplitter.dart';
import 'package:budget/pages/budgetsListPage.dart';
import 'package:budget/pages/calendarPage.dart';
import 'package:budget/pages/creditDebtTransactionsPage.dart';
import 'package:budget/pages/editHomePage.dart';
import 'package:budget/pages/editObjectivesPage.dart';
import 'package:budget/pages/homePage/homePageNetWorth.dart';
import 'package:budget/pages/objectivesListPage.dart';
import 'package:budget/pages/premiumPage.dart';
import 'package:budget/pages/transactionsListPage.dart';
import 'package:budget/pages/transactionsSearchPage.dart';
import 'package:budget/struct/currencyFunctions.dart';
import 'package:budget/struct/defaultPreferences.dart';
import 'package:budget/struct/languageMap.dart';
import 'package:budget/struct/navBarIconsData.dart';
import 'package:budget/widgets/animatedExpanded.dart';
import 'package:budget/widgets/bottomNavBar.dart';
import 'package:budget/widgets/exportDB.dart';
import 'package:budget/widgets/exportPDF.dart';
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
import 'package:budget/pages/offlineIntelligencePage.dart';
import 'package:budget/pages/errorLogsPage.dart';
import 'package:budget/pages/faqPage.dart';

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
import 'package:budget/widgets/selectCategoryImage.dart';
import 'package:budget/widgets/selectColor.dart';
import 'package:budget/widgets/settingsContainers.dart';
import 'package:budget/pages/walletDetailsPage.dart';
import 'package:budget/struct/initializeBiometrics.dart';
import 'package:budget/widgets/sliderSelector.dart';
import 'package:budget/widgets/tappable.dart';
import 'package:budget/widgets/textInput.dart';
import 'package:budget/widgets/textWidgets.dart';
import 'package:budget/widgets/util/checkWidgetLaunch.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:budget/main.dart';
import 'package:flutter/services.dart' hide TextInput;
import 'package:material_symbols_icons/material_symbols_icons.dart';
import 'package:provider/provider.dart';
import 'package:notification_listener_service/notification_listener_service.dart';
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
  bool _isEditMode = false;

  void refreshState() {
    setState(() {});
  }

  void scrollToTop() {
    pageState.currentState?.scrollToTop();
  }

  void _toggleEditMode() {
    HapticFeedback.heavyImpact();
    setState(() {
      _isEditMode = !_isEditMode;
      isExploreEditingNotifier.value = _isEditMode;
    });
  }

  @override
  Widget build(BuildContext context) {
    return OrientationBuilder(builder: (context, _) {
      return PageFramework(
        key: pageState,
        title: _isEditMode ? "Customize Explore" : "Explore",
        backButton: false,
        horizontalPaddingConstrained: true,
        overlay: _isEditMode
            ? Align(
                alignment: Alignment.bottomCenter,
                child: SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: _ExploreEditToolbar(
                      onReset: () async {
                        HapticFeedback.mediumImpact();
                        await updateSettings("morePageCardOrder", <String>[], updateGlobalState: true);
                        await updateSettings("hiddenMorePageItems", <String>[], updateGlobalState: true);
                        settingsPageStateKey.currentState?.refreshState();
                        setState(() {});
                      },
                      onDone: () => _toggleEditMode(),
                    ),
                  ),
                ),
              )
            : null,
        actions: [
          IconButton(
            onPressed: _toggleEditMode,
            icon: Icon(
              _isEditMode
                  ? (appStateSettings["outlinedIcons"]
                      ? Icons.check_circle_outline
                      : Icons.check_circle_rounded)
                  : (appStateSettings["outlinedIcons"]
                      ? Icons.edit_outlined
                      : Icons.edit_rounded),
            ),
            tooltip: _isEditMode ? "Done" : "Edit",
          ),
        ],
        slivers: [
          SliverToBoxAdapter(
            child: MorePages(
              isEditMode: _isEditMode,
              onEditModeChanged: (value) => setState(() {
                _isEditMode = value;
                isExploreEditingNotifier.value = value;
              }),
            ),
          ),
        ],
      );
    });
  }
}


// ─── _ExploreCard data model ───────────────────────────────────────────────

/// Data model for each card shown in the Explore screen grid.
class _ExploreCard {
  const _ExploreCard({
    required this.key,
    required this.title,
    required this.icon,
    required this.builder,
  });
  final String key;
  final String title;
  final IconData icon;
  final Widget Function(BuildContext context) builder;

  bool matchesSearch(String query) {
    if (query.trim().isEmpty) return true;
    return title.toLowerCase().contains(query.trim().toLowerCase());
  }
}

// ─── Canonical ordered card list (default order) ────────────────────────────

// ─── Canonical ordered card list (default order) ────────────────────────────

const List<String> _kDefaultCardOrder = [
  "premium", "about", "betaFeedback", "faq", "googleAccount",
  "calendar", "activityLog", "subscriptions", "scheduled",
  "goals", "loans", "accounts", "budgets",
  "intelligence", "offlineIntelligence",
  "billSplitter", "transactions", "search",
];

// ─── _ExploreEditToolbar widget ─────────────────────────────────────────────

class _ExploreEditToolbar extends StatelessWidget {
  const _ExploreEditToolbar({
    required this.onReset,
    required this.onDone,
  });

  final VoidCallback onReset;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    final hidden = List<String>.from(appStateSettings["hiddenMorePageItems"] ?? []);
    final totalCount = _kDefaultCardOrder.length;
    final visibleCount = totalCount - hidden.where((k) => _kDefaultCardOrder.contains(k)).length;

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 500),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.18),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(
              Icons.dashboard_customize_rounded,
              size: 20,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 8),
            TextFont(
              text: "$visibleCount/$totalCount Visible",
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
            const Spacer(),
            IconButton(
              tooltip: "Reset Defaults",
              icon: const Icon(Icons.refresh_rounded),
              onPressed: onReset,
            ),
            IconButton(
              tooltip: "Done",
              icon: Icon(
                Icons.check_circle_rounded,
                color: Theme.of(context).colorScheme.primary,
                size: 28,
              ),
              onPressed: onDone,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── MorePages widget ────────────────────────────────────────────────────────

class MorePages extends StatefulWidget {
  const MorePages({
    super.key,
    this.searchValue = "",
    this.isEditMode = false,
    this.onEditModeChanged,
  });
  final String searchValue;
  final bool isEditMode;
  final ValueChanged<bool>? onEditModeChanged;

  @override
  State<MorePages> createState() => _MorePagesState();
}

class _MorePagesState extends State<MorePages> {
  // ── Card catalogue ────────────────────────────────────────────────────────
  Map<String, _ExploreCard> _buildCardCatalogue(BuildContext context) {
    return {
      "premium": _ExploreCard(
        key: "premium",
        title: "Xpenzi Premium",
        icon: appStateSettings["outlinedIcons"]
            ? Icons.star_outline_rounded
            : Icons.star_rounded,
        builder: (_) => SettingsContainerOpenPage(
          openPage: const PremiumPage(popRouteWithPurchase: false),
          title: "Xpenzi Premium",
          icon: appStateSettings["outlinedIcons"]
              ? Icons.star_outline_rounded
              : Icons.star_rounded,
          isOutlined: true,
        ),
      ),
      "about": _ExploreCard(
        key: "about",
        title: "about-app".tr(namedArgs: {"app": globalAppName}),
        icon: navBarIconsData["about"]!.iconData,
        builder: (_) => SettingsContainerOpenPage(
          openPage: const AboutPage(),
          title: "about-app".tr(namedArgs: {"app": globalAppName}),
          icon: navBarIconsData["about"]!.iconData,
          isOutlined: true,
        ),
      ),
      "betaFeedback": _ExploreCard(
        key: "betaFeedback",
        title: "Beta Feedback",
        icon: appStateSettings["outlinedIcons"] ? Icons.rate_review_outlined : Icons.rate_review_rounded,
        builder: (_) => SettingsContainer(
          onTap: () => openBottomSheet(context, const RatingPopup(), fullSnap: true),
          title: "Beta Feedback",
          icon: appStateSettings["outlinedIcons"] ? Icons.rate_review_outlined : Icons.rate_review_rounded,
          isOutlined: true,
        ),
      ),
      "faq": _ExploreCard(
        key: "faq",
        title: "Guide / FAQ",
        icon: appStateSettings["outlinedIcons"] ? Icons.help_outline : Icons.help_rounded,
        builder: (_) => SettingsContainerOpenPage(
          openPage: const FAQPage(),
          title: "Guide / FAQ",
          icon: appStateSettings["outlinedIcons"] ? Icons.help_outline : Icons.help_rounded,
          isOutlined: true,
        ),
      ),
      "googleAccount": _ExploreCard(
        key: "googleAccount",
        title: "Google Account",
        icon: appStateSettings["outlinedIcons"] ? Icons.account_circle_outlined : Icons.account_circle_rounded,
        builder: (_) => GoogleAccountLoginButton(
          key: settingsGoogleAccountLoginButtonKey,
        ),
      ),
      "calendar": _ExploreCard(
        key: "calendar",
        title: "Calendar",
        icon: appStateSettings["outlinedIcons"] ? Icons.calendar_month_outlined : Icons.calendar_month_rounded,
        builder: (_) => SettingsContainerOpenPage(
          openPage: const CalendarPage(),
          title: "Calendar",
          icon: appStateSettings["outlinedIcons"] ? Icons.calendar_month_outlined : Icons.calendar_month_rounded,
          isOutlined: true,
        ),
      ),
      "activityLog": _ExploreCard(
        key: "activityLog",
        title: "Activity Log",
        icon: appStateSettings["outlinedIcons"] ? Icons.receipt_long_outlined : Icons.receipt_long_rounded,
        builder: (_) => SettingsContainerOpenPage(
          openPage: const ActivityPage(),
          title: "Activity Log",
          icon: appStateSettings["outlinedIcons"] ? Icons.receipt_long_outlined : Icons.receipt_long_rounded,
          isOutlined: true,
        ),
      ),
      "subscriptions": _ExploreCard(
        key: "subscriptions",
        title: navBarIconsData["subscriptions"]!.label.tr(),
        icon: navBarIconsData["subscriptions"]!.iconData,
        builder: (_) => SettingsContainerOpenPage(
          openPage: const RecurringHubPage(initialIndex: 0),
          title: navBarIconsData["subscriptions"]!.label.tr(),
          icon: navBarIconsData["subscriptions"]!.iconData,
          isOutlined: true,
        ),
      ),
      "scheduled": _ExploreCard(
        key: "scheduled",
        title: navBarIconsData["scheduled"]!.label.tr(),
        icon: navBarIconsData["scheduled"]!.iconData,
        builder: (_) => SettingsContainerOpenPage(
          openPage: const RecurringHubPage(initialIndex: 1),
          title: navBarIconsData["scheduled"]!.label.tr(),
          icon: navBarIconsData["scheduled"]!.iconData,
          isOutlined: true,
        ),
      ),
      "goals": _ExploreCard(
        key: "goals",
        title: navBarIconsData["goals"]!.label,
        icon: navBarIconsData["goals"]!.iconData,
        builder: (_) => SettingsContainerOpenPage(
          openPage: const ObjectivesListPage(backButton: true),
          title: navBarIconsData["goals"]!.label,
          icon: navBarIconsData["goals"]!.iconData,
          isOutlined: true,
        ),
      ),
      "loans": _ExploreCard(
        key: "loans",
        title: navBarIconsData["loans"]!.label,
        icon: navBarIconsData["loans"]!.iconData,
        builder: (_) => SettingsContainerOpenPage(
          openPage: const CreditDebtTransactions(isCredit: null),
          title: navBarIconsData["loans"]!.label,
          icon: navBarIconsData["loans"]!.iconData,
          isOutlined: true,
        ),
      ),
      "accounts": _ExploreCard(
        key: "accounts",
        title: "Accounts",
        icon: navBarIconsData["accountDetails"]!.iconData,
        builder: (_) => SettingsContainerOpenPage(
          openPage: const EditWalletsPage(),
          title: "Accounts",
          icon: navBarIconsData["accountDetails"]!.iconData,
          isOutlined: true,
        ),
      ),
      "budgets": _ExploreCard(
        key: "budgets",
        title: "Budgets",
        icon: navBarIconsData["budgetDetails"]!.iconData,
        builder: (_) => SettingsContainerOpenPage(
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
      "billSplitter": _ExploreCard(
        key: "billSplitter",
        title: "Bill Splitter",
        icon: appStateSettings["outlinedIcons"] ? Icons.summarize_outlined : Icons.summarize_rounded,
        builder: (_) => SettingsContainerOpenPage(
          openPage: const BillSplitter(),
          title: "Bill Splitter",
          icon: appStateSettings["outlinedIcons"] ? Icons.summarize_outlined : Icons.summarize_rounded,
          isOutlined: true,
        ),
      ),
      "transactions": _ExploreCard(
        key: "transactions",
        title: "transactions".tr(),
        icon: navBarIconsData["transactions"]!.iconData,
        builder: (_) => SettingsContainerOpenPage(
          openPage: const TransactionsListPage(),
          title: "transactions".tr(),
          icon: navBarIconsData["transactions"]!.iconData,
          isOutlined: true,
        ),
      ),
      "intelligence": _ExploreCard(
        key: "intelligence",
        title: "Xpenzi Intelligence",
        icon: appStateSettings["outlinedIcons"]
            ? Icons.auto_awesome_outlined
            : Icons.auto_awesome_rounded,
        builder: (_) => SettingsContainerOpenPage(
          openPage: const AiSettingsPage(),
          title: "Xpenzi Intelligence",
          icon: appStateSettings["outlinedIcons"]
              ? Icons.auto_awesome_outlined
              : Icons.auto_awesome_rounded,
          isOutlined: true,
        ),
      ),
      "offlineIntelligence": _ExploreCard(
        key: "offlineIntelligence",
        title: "Auto-Detect SMS",
        icon: appStateSettings["outlinedIcons"]
            ? Icons.sms_outlined
            : Icons.sms_rounded,
        builder: (_) => SettingsContainerOpenPage(
          openPage: const OfflineIntelligencePage(),
          title: "Auto-Detect SMS",
          icon: appStateSettings["outlinedIcons"]
              ? Icons.sms_outlined
              : Icons.sms_rounded,
          isOutlined: true,
        ),
      ),
      "search": _ExploreCard(
        key: "search",
        title: "search".tr(),
        icon: appStateSettings["outlinedIcons"] ? Icons.search_outlined : Icons.search_rounded,
        builder: (_) => SettingsContainerOpenPage(
          openPage: const TransactionsSearchPage(),
          title: "search".tr(),
          icon: appStateSettings["outlinedIcons"] ? Icons.search_outlined : Icons.search_rounded,
          isOutlined: true,
        ),
      ),
    };
  }

  /// Returns the ordered list of keys from preferences, padded with defaults.
  List<String> _resolveOrder() {
    final saved = List<String>.from(appStateSettings["morePageCardOrder"] ?? []);
    for (final key in _kDefaultCardOrder) {
      if (!saved.contains(key)) saved.add(key);
    }
    saved.removeWhere((k) => !_kDefaultCardOrder.contains(k));
    return saved;
  }

  Future<void> _saveOrder(List<String> order) async {
    await updateSettings("morePageCardOrder", order, updateGlobalState: true);
    settingsPageStateKey.currentState?.refreshState();
  }

  Future<void> _toggleVisibility(String key, List<String> hidden) async {
    HapticFeedback.lightImpact();
    final newHidden = List<String>.from(hidden);
    if (newHidden.contains(key)) {
      newHidden.remove(key);
    } else {
      newHidden.add(key);
    }
    await updateSettings("hiddenMorePageItems", newHidden, updateGlobalState: true);
    settingsPageStateKey.currentState?.refreshState();
  }

  @override
  Widget build(BuildContext context) {
    final catalogue = _buildCardCatalogue(context);
    final orderedKeys = _resolveOrder();
    final hidden = List<String>.from(appStateSettings["hiddenMorePageItems"] ?? []);
    final isSearching = widget.searchValue.trim().isNotEmpty;
    final visibleCount = orderedKeys.length - hidden.length;

    return Padding(
      padding: const EdgeInsetsDirectional.symmetric(horizontal: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ──────────────────────────────────────────────────────────────
          // EDIT MODE: 2-column reorderable grid with + and - badges
          // ──────────────────────────────────────────────────────────────
          if (widget.isEditMode) ...[
            Padding(
              padding: const EdgeInsetsDirectional.only(start: 8, bottom: 8, top: 4),
              child: Text(
                "Drag cards to reorder · Tap + or - to show/hide",
                style: TextStyle(
                  fontFamily: appStateSettings["font"],
                  fontFamilyFallback: const ["Inter"],
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                ),
              ),
            ),
            ReorderableGridView.count(
              key: ValueKey("reorder_grid_${orderedKeys.join('_')}"),
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: 2.3,
              crossAxisSpacing: 6,
              mainAxisSpacing: 6,
              onReorder: (oldIndex, newIndex) async {
                HapticFeedback.mediumImpact();
                final newOrder = List<String>.from(orderedKeys);
                final item = newOrder.removeAt(oldIndex);
                newOrder.insert(newIndex, item);
                await _saveOrder(newOrder);
                setState(() {});
                return true;
              },
              children: [
                for (String key in orderedKeys)
                  if (catalogue.containsKey(key))
                    _GridCardWrapper(
                      key: ValueKey(key),
                      card: catalogue[key]!,
                      isEditMode: true,
                      isVisible: !hidden.contains(key),
                      onToggleVisibility: () => setState(() => _toggleVisibility(key, hidden)),
                    ),
              ],
            ),
            const SizedBox(height: 80),
          ] else ...[
            // ────────────────────────────────────────────────────────────
            // NORMAL / SEARCH MODE: 2-column card grid (Strict Sizing)
            // ────────────────────────────────────────────────────────────
            Builder(builder: (context) {
              final isPremiumVisible = !hidden.contains("premium") &&
                  catalogue.containsKey("premium") &&
                  catalogue["premium"]!.matchesSearch(widget.searchValue);

              final gridCards = orderedKeys
                  .where((k) => k != "premium")
                  .where((k) => catalogue.containsKey(k))
                  .where((k) => !hidden.contains(k))
                  .map((k) => catalogue[k]!)
                  .where((c) => c.matchesSearch(widget.searchValue))
                  .toList();

              if (!isPremiumVisible && gridCards.isEmpty && isSearching) {
                return const SizedBox.shrink();
              }

              final List<Widget> rows = [];

              // Top Full-Width Highlight Card: Xpenzi Pro with authentic Premium background theme
              if (isPremiumVisible) {
                rows.add(
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: const PremiumBanner(),
                  ),
                );
              }

              if (!isSearching) {
                rows.add(
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
                );
                rows.add(const SizedBox(height: 6));
                rows.add(
                  SettingsContainerOpenPage(
                    openPage: const WalletDetailsPage(wallet: null),
                    title: navBarIconsData["allSpending"]!.labelLong.tr(),
                    description: "Your spending statistics all in one place",
                    icon: navBarIconsData["allSpending"]!.iconData,
                    isOutlined: true,
                    isWideOutlined: true,
                  ),
                );
                rows.add(const SizedBox(height: 8));
              }

              for (int i = 0; i < gridCards.length; i += 2) {
                final left = gridCards[i];
                final right = i + 1 < gridCards.length ? gridCards[i + 1] : null;

                rows.add(
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      children: [
                        Expanded(
                          child: SizedBox(
                            height: 64,
                            child: left.builder(context),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: right != null
                              ? SizedBox(
                                  height: 64,
                                  child: right.builder(context),
                                )
                              : const SizedBox.shrink(),
                        ),
                      ],
                    ),
                  ),
                );
              }

              if (!isSearching) {
                rows.add(const SizedBox(height: 6));
                rows.add(
                  SettingsContainer(
                    onTap: () {
                      openBottomSheet(
                        context,
                        const EditDataOverviewPage(),
                      );
                    },
                    title: "Edit, Delete, and Reorder Data",
                    description: "For accounts, categories, titles, budgets, goals, loans",
                    icon: appStateSettings["outlinedIcons"]
                        ? Icons.edit_note_outlined
                        : Icons.edit_note_rounded,
                    isOutlined: true,
                    isWideOutlined: true,
                  ),
                );
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: rows,
              );
            }),
          ],
        ],
      ),
    );
  }
}

// ─── Grid card wrapper widget with Wiggle Animation ─────────────────────────

class _GridCardWrapper extends StatefulWidget {
  const _GridCardWrapper({
    super.key,
    required this.card,
    required this.isEditMode,
    required this.isVisible,
    required this.onToggleVisibility,
  });

  final _ExploreCard card;
  final bool isEditMode;
  final bool isVisible;
  final VoidCallback onToggleVisibility;

  @override
  State<_GridCardWrapper> createState() => _GridCardWrapperState();
}

class _GridCardWrapperState extends State<_GridCardWrapper> with SingleTickerProviderStateMixin {
  late AnimationController _wiggleController;

  @override
  void initState() {
    super.initState();
    _wiggleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 140),
    );
    if (widget.isEditMode) {
      _wiggleController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(covariant _GridCardWrapper oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isEditMode && !_wiggleController.isAnimating) {
      _wiggleController.repeat(reverse: true);
    } else if (!widget.isEditMode && _wiggleController.isAnimating) {
      _wiggleController.stop();
      _wiggleController.reset();
    }
  }

  @override
  void dispose() {
    _wiggleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _wiggleController,
      builder: (context, child) {
        final angle = widget.isEditMode ? (sin(_wiggleController.value * pi * 2) * 0.016) : 0.0;
        final offsetY = widget.isEditMode ? (cos(_wiggleController.value * pi * 2) * 0.8) : 0.0;
        return Transform.translate(
          offset: Offset(0, offsetY),
          child: Transform.rotate(
            angle: angle,
            child: child,
          ),
        );
      },
      child: SizedBox(
        height: 64,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Opacity(
              opacity: widget.isVisible ? 1.0 : 0.4,
              child: AbsorbPointer(
                absorbing: widget.isEditMode,
                child: widget.card.builder(context),
              ),
            ),
            if (widget.isEditMode)
              PositionedDirectional(
                top: 4,
                end: 4,
                child: GestureDetector(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    widget.onToggleVisibility();
                  },
                  child: Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      color: widget.isVisible
                          ? Theme.of(context).colorScheme.error
                          : Theme.of(context).colorScheme.primary,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Icon(
                      widget.isVisible ? Icons.remove_rounded : Icons.add_rounded,
                      size: 16,
                      color: widget.isVisible
                          ? Theme.of(context).colorScheme.onError
                          : Theme.of(context).colorScheme.onPrimary,
                    ),
                  ),
                ),
              ),
          ],
        ),
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
              updateGlobalState: true);
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
  String searchValue = "";

  void refreshState() {
    print("refresh settings framework");
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return PageFramework(
      title: "settings".tr(),
      dragDownToDismiss: true,
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsetsDirectional.only(bottom: 8.0, start: 15, end: 15),
            child: TextInput(
              labelText: "Find settings, preferences & features...",
              icon: appStateSettings["outlinedIcons"]
                  ? Icons.search_outlined
                  : Icons.search_rounded,
              onChanged: (value) {
                setState(() {
                  searchValue = value.toLowerCase();
                });
              },
              autoFocus: false,
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: SettingsPageContent(searchValue: searchValue),
        ),
      ],
    );
  }
}

class SettingsPageContent extends StatelessWidget {
  const SettingsPageContent({super.key, this.searchValue = ""});
  final String searchValue;

  bool _fuzzyMatch(String target, String token) {
    if (target.contains(token) || token.contains(target)) return true;
    if (token.length >= 4 && target.length >= 4) {
      if (target.startsWith(token.substring(0, 3))) return true;
    }
    return false;
  }

  bool _match(String title, String description, [List<String> keywords = const []]) {
    if (searchValue.trim().isEmpty) return true;
    String rawQuery = searchValue.trim().toLowerCase();
    List<String> queryTokens =
        rawQuery.split(RegExp(r'\s+')).where((t) => t.isNotEmpty).toList();
    if (queryTokens.isEmpty) return true;

    List<String> pool = [
      title.toLowerCase(),
      description.toLowerCase(),
      ...keywords.map((k) => k.toLowerCase()),
    ];

    Set<String> expandedQueryTokens = Set.from(queryTokens);
    for (String token in queryTokens) {
      if (["password", "passcode", "auth", "pin", "finger", "face", "security", "protect", "lock", "login"].contains(token)) {
        expandedQueryTokens.addAll(["biometric", "biometrics", "pin", "lock", "security"]);
      }
      if (["color", "colour", "dark", "light", "appearance", "skin", "ui", "look", "night", "day", "mode"].contains(token)) {
        expandedQueryTokens.addAll(["theme", "style", "color", "accent", "outlined"]);
      }
      if (["money", "dollar", "rupee", "euro", "forex", "cash", "account", "wallet", "symbol"].contains(token)) {
        expandedQueryTokens.addAll(["currency", "formatting", "exchange"]);
      }
      if (["words", "speech", "translate", "i18n", "dictionary", "dialect", "talk"].contains(token)) {
        expandedQueryTokens.addAll(["language", "locale", "translation"]);
      }
      if (["export", "download", "save", "sync", "cloud", "drive", "excel", "file", "dump"].contains(token)) {
        expandedQueryTokens.addAll(["backup", "import", "csv", "pdf"]);
      }
      if (["notice", "notify", "alarm", "schedule", "alert", "ping", "bell", "remind"].contains(token)) {
        expandedQueryTokens.addAll(["notification", "reminder", "daily"]);
      }
      if (["reset", "clear", "revert", "factory", "default", "restore"].contains(token)) {
        expandedQueryTokens.addAll(["reset home", "default layout"]);
      }
      if (["dock", "bar", "navigation", "nav", "bottom", "float", "label"].contains(token)) {
        expandedQueryTokens.addAll(["floating", "dock", "navbar"]);
      }
      if (["vibrate", "touch", "haptic", "press", "pad", "number", "numpad"].contains(token)) {
        expandedQueryTokens.addAll(["haptic", "vibration", "feedback"]);
      }
      if (["user", "name", "profile", "nick", "who", "avatar", "me"].contains(token)) {
        expandedQueryTokens.addAll(["username", "profile", "name", "greeting"]);
      }
      if (["auto", "automated", "bot", "gmail", "scan", "parser", "email", "mail"].contains(token)) {
        expandedQueryTokens.addAll(["automation", "mail", "ai"]);
      }
      if (["split", "bill", "divide", "share", "group", "check", "tab"].contains(token)) {
        expandedQueryTokens.addAll(["bill", "splitter"]);
      }
      if (["beta", "test", "experiment", "trial", "secret", "lab"].contains(token)) {
        expandedQueryTokens.addAll(["experimental", "beta"]);
      }
    }

    for (String qToken in expandedQueryTokens) {
      for (String item in pool) {
        if (item.contains(qToken) || _fuzzyMatch(item, qToken)) {
          return true;
        }
      }
    }

    return false;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AnimatedExpanded(
            expand: _match("General Settings", "Biometric lock, haptic feedback, edit data", [
              "general", "preferences", "biometric", "biometrics", "fingerprint", "face id", "lock", "passcode", "pin", "security", "haptic", "feedback", "vibration", "edit home", "widgets", "layout", "floating", "dock", "navbar", "navigation bar", "labels", "reset home", "default layout"
            ]),
            child: Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: SettingsContainerOpenPage(
                openPage: const GeneralSettingsSubPage(),
                title: "General Settings",
                description: "Biometric lock, haptic feedback, edit data",
                icon: appStateSettings["outlinedIcons"]
                    ? Icons.tune_outlined
                    : Icons.tune_rounded,
                isOutlined: true,
                isWideOutlined: true,
              ),
            ),
          ),
          AnimatedExpanded(
            expand: _match("Theme & Style", "Theme color, icon style, animations, font", [
              "theme", "style", "appearance", "dark mode", "light mode", "color", "accent", "outlined", "icons", "font", "typography", "animation", "animations", "count up", "black background", "palette"
            ]),
            child: Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: SettingsContainerOpenPage(
                openPage: const ThemeStyleSettingsSubPage(),
                title: "Theme & Style",
                description: "Theme color, icon style, animations, font",
                icon: appStateSettings["outlinedIcons"]
                    ? Icons.palette_outlined
                    : Icons.palette_rounded,
                isOutlined: true,
                isWideOutlined: true,
              ),
            ),
          ),
          AnimatedExpanded(
            expand: _match("Transactions", "New transaction, scheduled transactions", [
              "transaction", "transactions", "auto pay", "automatic", "subscriptions", "recurring", "repetitive", "upcoming", "compact", "title", "note", "layout"
            ]),
            child: Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: SettingsContainerOpenPage(
                openPage: const TransactionsSettingsSubPage(),
                title: "Transactions",
                description: "New transaction, scheduled transactions",
                icon: navBarIconsData["transactions"]!.iconData,
                isOutlined: true,
                isWideOutlined: true,
              ),
            ),
          ),
          AnimatedExpanded(
            expand: _match("Localization & Formatting", "Language, currency, formatting", [
              "localization", "formatting", "language", "locale", "translation", "currency", "currencies", "exchange rate", "24-hour", "time format", "format", "decimals"
            ]),
            child: Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: SettingsContainerOpenPage(
                openPage: const LocalizationSettingsSubPage(),
                title: "Localization & Formatting",
                description: "Language, currency, formatting",
                icon: appStateSettings["outlinedIcons"]
                    ? Icons.language_outlined
                    : Icons.language_rounded,
                isOutlined: true,
                isWideOutlined: true,
              ),
            ),
          ),
          AnimatedExpanded(
            expand: _match("Notifications", "Daily & upcoming transaction reminders", [
              "notification", "notifications", "reminder", "reminders", "daily", "upcoming", "alert"
            ]),
            child: Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: SettingsContainerOpenPage(
                openPage: const NotificationsPage(),
                title: "Notifications",
                description: "Daily & upcoming transaction reminders",
                icon: appStateSettings["outlinedIcons"]
                    ? Icons.notifications_outlined
                    : Icons.notifications_rounded,
                isOutlined: true,
                isWideOutlined: true,
              ),
            ),
          ),
          AnimatedExpanded(
            expand: _match("Import & Export Data", "Import CSV, backup data", [
              "import", "export", "csv", "pdf", "backup", "restore", "google drive", "data", "file"
            ]),
            child: Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: SettingsContainerOpenPage(
                openPage: const ImportExportSettingsSubPage(),
                title: "Import & Export Data",
                description: "Import CSV, backup data",
                icon: appStateSettings["outlinedIcons"]
                    ? Icons.sd_storage_outlined
                    : Icons.sd_storage_rounded,
                isOutlined: true,
                isWideOutlined: true,
              ),
            ),
          ),
          AnimatedExpanded(
            expand: _match("about-app".tr(namedArgs: {"app": globalAppName}), "App version, changelog, licensing info", [
              "about", "version", "changelog", "license", "licensing", "app info"
            ]),
            child: Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: SettingsContainerOpenPage(
                openPage: const AboutPage(),
                title: "about-app".tr(namedArgs: {"app": globalAppName}),
                description: "App version, changelog, licensing info",
                icon: appStateSettings["outlinedIcons"]
                    ? Icons.info_outline
                    : Icons.info_rounded,
                isOutlined: true,
                isWideOutlined: true,
              ),
            ),
          ),

          AnimatedExpanded(
            expand: searchValue.trim().isEmpty || 
                    _match("Intelligent & Automation", "", ["ai", "automation", "mail", "email", "gemini", "read emails", "parse", "offline", "sms", "notification"]) || 
                    _match("Offline Intelligence", "", ["offline", "sms", "notification", "scan", "parser", "bank alerts"]) || 
                    _match("Advanced Automation", "", ["mail", "email", "automation", "read emails", "parse"]) || 
                    _match("Xpenzi Intelligence", "", ["ai", "intelligence", "gemini", "smart", "assistant"]),
            child: SettingsGroupCard(
              title: "Intelligent & Automation",
              icon: appStateSettings["outlinedIcons"]
                  ? Icons.auto_awesome_outlined
                  : Icons.auto_awesome_rounded,
              children: [
                SettingsContainerOpenPage(
                  openPage: const OfflineIntelligencePage(),
                  title: "Auto-Detect Bank SMS & Alerts",
                  description: "100% Private on-device bank SMS & payment notification parser",
                  icon: appStateSettings["outlinedIcons"]
                      ? Icons.sms_outlined
                      : Icons.sms_rounded,
                ),
                const Divider(height: 1),
                SettingsContainerOpenPage(
                  openPage: const AiSettingsPage(),
                  title: "Xpenzi Intelligence",
                  description: "Google Gemini AI model, category suggestions, and custom prompt rules",
                  icon: appStateSettings["outlinedIcons"]
                      ? Icons.auto_awesome_outlined
                      : Icons.auto_awesome_rounded,
                ),
                const Divider(height: 1),
                SettingsContainerOpenPage(
                  openPage: const AutoTransactionsPageEmail(),
                  title: "Advanced Automation",
                  description: "Connect mailbox to automatically track bank transaction receipts",
                  icon: appStateSettings["outlinedIcons"]
                      ? Icons.mark_email_read_outlined
                      : Icons.mark_email_read_rounded,
                ),
              ],
            ),
          ),

          AnimatedExpanded(
            expand: searchValue.trim().isEmpty || 
                    _match("Permissions", "", ["permission", "permissions", "security", "device", "access"]) || 
                    _match("Device Permissions", "", ["permission", "permissions", "security", "device", "access"]),
            child: Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: SettingsContainerOpenPage(
                openPage: const PermissionsSettingsSubPage(),
                title: "Device Permissions",
                description: "Storage, notification access, biometrics & security",
                icon: appStateSettings["outlinedIcons"]
                    ? Icons.security_outlined
                    : Icons.security_rounded,
                isOutlined: true,
                isWideOutlined: true,
              ),
            ),
          ),

          AnimatedExpanded(
            expand: searchValue.trim().isEmpty || 
                    _match("Tools & Extras", "", ["bill", "splitter", "display", "preferences", "visual", "layout"]) || 
                    _match("Bill Splitter", "", ["bill", "splitter", "split", "divide bill", "group bill"]) || 
                    _match("Display Preferences", "", ["display", "preferences", "visual", "layout", "cards", "icons", "animations"]),
            child: Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: SettingsContainerOpenPage(
                openPage: const ToolsAndExtrasSubPage(),
                title: "Tools & Extras",
                description: "Bill splitter, display & visual preferences",
                icon: appStateSettings["outlinedIcons"]
                    ? Icons.extension_outlined
                    : Icons.extension_rounded,
                isOutlined: true,
                isWideOutlined: true,
              ),
            ),
          ),
        ],
      ),
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
            SettingsContainer(
              title: "username".tr(),
              description: appStateSettings["username"] == null ||
                      appStateSettings["username"] == ""
                  ? "Set display name for greetings"
                  : appStateSettings["username"].toString(),
              icon: appStateSettings["outlinedIcons"]
                  ? Icons.person_outlined
                  : Icons.person_rounded,
              onTap: () async {
                await enterNameBottomSheet(context);
              },
            ),
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
                await resetHomePageLayoutSettings();
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
                                RestartApp.restartApp(context);
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
                    title: "Dynamic Color (Material You)",
                    description: "Match app colors to your device's wallpaper",
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
            const OutlinedIconsSetting(),
            SettingsContainerOpenPage(
              openPage: const CategoryIconPackGalleryPage(),
              title: "Category Icon Pack & Gallery",
              description: "Browse 450+ category icons & packs",
              icon: appStateSettings["outlinedIcons"]
                  ? Icons.category_outlined
                  : Icons.category_rounded,
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
            SettingsContainerSwitch(
              title: "Pin Account Filters",
              description: "Show quick account filter chips on transactions list under month selector",
              initialValue: appStateSettings["pinAccountFilters"] ?? false,
              icon: appStateSettings["outlinedIcons"]
                  ? Icons.account_balance_wallet_outlined
                  : Icons.account_balance_wallet_rounded,
              onSwitched: (value) {
                updateSettings("pinAccountFilters", value, updateGlobalState: true);
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
              openPage: const RecurringHubPage(initialIndex: 0),
              title: navBarIconsData["subscriptions"]!.label.tr(),
              icon: navBarIconsData["subscriptions"]!.iconData,
            ),
            SettingsContainerOpenPage(
              openPage: const RecurringHubPage(initialIndex: 1),
              title: navBarIconsData["scheduled"]!.label.tr(),
              icon: navBarIconsData["scheduled"]!.iconData,
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
            ExportPDF(),
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
    return PopupFramework(
      title: "Edit, Delete, and Reorder Data",
      child: Column(
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
      initial: appStateSettings["theme"].toString(),
      items: const [
        "system",
        "light",
        "dark",
        "black",
      ],
      faintValues: [
        if (appStateSettings["theme"].toString() == "system")
          appStateSettings["forceFullDarkBackground"] == true ? "black" : "dark"
      ],
      onChanged: (value) async {
        final bool isBlack = value == "black";
        appStateSettings["forceFullDarkBackground"] = isBlack;
        appStateSettings["theme"] = value;
        setState(() {});
        updateSettings("forceFullDarkBackground", isBlack,
            updateGlobalState: false);
        await updateSettings("theme", value,
            updateGlobalState: true, forceGlobalStateUpdate: true);
        updateWidgetColorsAndText(context);
        RestartApp.restartApp(context);
      },
      getLabel: (item) {
        return item.tr();
      },
    );
  }
}

class ToolsAndExtrasSubPage extends StatelessWidget {
  const ToolsAndExtrasSubPage({super.key});

  @override
  Widget build(BuildContext context) {
    return PageFramework(
      title: "Tools & Extras",
      dragDownToDismiss: true,
      listWidgets: [
        SettingsGroupCard(
          title: "Tools",
          icon: appStateSettings["outlinedIcons"]
              ? Icons.construction_outlined
              : Icons.construction_rounded,
          children: [
            SettingsContainerOpenPage(
              openPage: const BillSplitter(),
              title: "Bill Splitter",
              description: "Easily split expenses, calculate tip, and share breakdown",
              icon: appStateSettings["outlinedIcons"]
                  ? Icons.summarize_outlined
                  : Icons.summarize_rounded,
            ),
            SettingsContainerOpenPage(
              openPage: const ErrorLogsPage(),
              title: "Diagnostic & Error Logs",
              description: "Inspect runtime logs, sign-in errors & copy reports",
              icon: appStateSettings["outlinedIcons"]
                  ? Icons.bug_report_outlined
                  : Icons.bug_report_rounded,
            ),
          ],
        ),
        SettingsGroupCard(
          title: "Display Preferences",
          icon: appStateSettings["outlinedIcons"]
              ? Icons.tune_outlined
              : Icons.tune_rounded,
          children: [
            SettingsContainerOpenPage(
              openPage: const ExperimentalFeaturesSubPage(),
              title: "Visual & Layout Preferences",
              description: "Cards detail, animations, badge icons & layout",
              icon: appStateSettings["outlinedIcons"]
                  ? Icons.view_quilt_outlined
                  : Icons.view_quilt_rounded,
            ),
          ],
        ),
      ],
    );
  }
}

class ExperimentalFeaturesSubPage extends StatelessWidget {
  const ExperimentalFeaturesSubPage({super.key});

  @override
  Widget build(BuildContext context) {
    return PageFramework(
      title: "Display Preferences",
      dragDownToDismiss: true,
      listWidgets: [
        SettingsGroupCard(
          title: "Visual & Layout Options",
          icon: appStateSettings["outlinedIcons"]
              ? Icons.tune_outlined
              : Icons.tune_rounded,
          children: [
            SettingsContainerSwitch(
              title: "Detailed Transaction Cards",
              description: "Show multi-line layout with extra details in list views",
              onSwitched: (value) {
                updateSettings("nonCompactTransactions", value, updateGlobalState: true);
              },
              initialValue: appStateSettings["nonCompactTransactions"] ?? false,
              icon: appStateSettings["outlinedIcons"]
                  ? Icons.table_rows_outlined
                  : Icons.table_rows_rounded,
            ),
            SettingsContainerSwitch(
              title: "Fade Transaction Overflows",
              description: "Fade long title text instead of standard truncation dots",
              onSwitched: (value) {
                updateSettings("fadeTransactionNameOverflows", value, updateGlobalState: true);
              },
              initialValue: appStateSettings["fadeTransactionNameOverflows"] ?? false,
              icon: appStateSettings["outlinedIcons"]
                  ? Icons.gradient_outlined
                  : Icons.gradient_rounded,
            ),
            SettingsContainerSwitch(
              title: "Circular Progress Offset",
              description: "Align circular progress rotation with pie chart sections",
              onSwitched: (value) {
                updateSettings("circularProgressRotation", value, updateGlobalState: true);
              },
              initialValue: appStateSettings["circularProgressRotation"] ?? false,
              icon: appStateSettings["outlinedIcons"]
                  ? Icons.pie_chart_outline
                  : Icons.pie_chart_rounded,
            ),
            SettingsContainerSwitch(
              title: "Subcategory Icons",
              description: "Display subcategory icons inside transaction lists",
              onSwitched: (value) {
                updateSettings("showSubcategoryIcon", value, updateGlobalState: true);
              },
              initialValue: appStateSettings["showSubcategoryIcon"] ?? false,
              icon: appStateSettings["outlinedIcons"]
                  ? Icons.category_outlined
                  : Icons.category_rounded,
            ),
            SettingsContainerSwitch(
              title: "Animated Budget Cards",
              description: "Enable smooth animations on budget progress bars",
              onSwitched: (value) {
                updateSettings("animatedBudgetContainers", value, updateGlobalState: true);
              },
              initialValue: appStateSettings["animatedBudgetContainers"] ?? true,
              icon: appStateSettings["outlinedIcons"]
                  ? Icons.animation_outlined
                  : Icons.animation_rounded,
            ),
            SettingsContainerSwitch(
              title: "FAQ & Help Shortcuts",
              description: "Display quick help links in options menus",
              onSwitched: (value) {
                updateSettings("showFAQAndHelpLink", value, updateGlobalState: true);
              },
              initialValue: appStateSettings["showFAQAndHelpLink"] ?? true,
              icon: appStateSettings["outlinedIcons"]
                  ? Icons.help_outline
                  : Icons.help_rounded,
            ),
          ],
        ),
      ],
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
    return SettingsContainerOpenPage(
      openPage: const HapticFeedbackSettingsSubPage(),
      title: "haptic-feedback".tr(),
      description: "Customize touch vibrations per action & triggers",
      icon: appStateSettings["outlinedIcons"]
          ? Icons.vibration_outlined
          : Symbols.vibration_rounded,
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

class HapticFeedbackSettingsSubPage extends StatelessWidget {
  const HapticFeedbackSettingsSubPage({super.key});

  @override
  Widget build(BuildContext context) {
    return PageFramework(
      title: "haptic-feedback".tr(),
      dragDownToDismiss: true,
      listWidgets: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: SettingsContainerOutlined(
            icon: appStateSettings["outlinedIcons"]
                ? Icons.info_outline
                : Icons.info_rounded,
            title: "Haptic Feedback & Trigger Conditions",
            description:
                "Vibration effects occur dynamically during key app actions. Ensure Touch Haptics are enabled in your device's System Settings for vibrations to function.",
          ),
        ),
        SettingsGroupCard(
          title: "Customizable Actions",
          icon: appStateSettings["outlinedIcons"]
              ? Icons.vibration_outlined
              : Symbols.vibration_rounded,
          children: [
            SettingsContainerSwitch(
              title: "Number Pad & Keypad",
              description:
                  "Vibrates when typing digits or backspace on the amount keypad",
              icon: appStateSettings["outlinedIcons"]
                  ? Icons.pin_outlined
                  : Icons.pin_rounded,
              initialValue: appStateSettings["numberPadHapticFeedback"] == true,
              onSwitched: (value) async {
                if (value == true) HapticFeedback.heavyImpact();
                await updateSettings("numberPadHapticFeedback", value,
                    updateGlobalState: false);
              },
            ),
            SettingsContainerSwitch(
              title: "Saving Transactions & Data",
              description:
                  "Vibrates upon successfully saving or adding entries",
              icon: appStateSettings["outlinedIcons"]
                  ? Icons.save_outlined
                  : Icons.save_rounded,
              initialValue: appStateSettings["savingHapticFeedback"] == true,
              onSwitched: (value) async {
                if (value == true) HapticFeedback.lightImpact();
                await updateSettings("savingHapticFeedback", value,
                    updateGlobalState: false);
              },
            ),
            SettingsContainerSwitch(
              title: "Tab & Dock Navigation",
              description:
                  "Vibrates when switching bottom navigation tabs or dock items",
              icon: appStateSettings["outlinedIcons"]
                  ? Icons.tab_outlined
                  : Icons.tab_rounded,
              initialValue:
                  appStateSettings["tabNavigationHapticFeedback"] == true,
              onSwitched: (value) async {
                if (value == true) HapticFeedback.mediumImpact();
                await updateSettings("tabNavigationHapticFeedback", value,
                    updateGlobalState: false);
              },
            ),
            SettingsContainerSwitch(
              title: "Popups & Drag Dismissal",
              description:
                  "Vibrates when pulling down or closing bottom sheets and popups",
              icon: appStateSettings["outlinedIcons"]
                  ? Icons.swipe_down_outlined
                  : Icons.swipe_down_rounded,
              initialValue:
                  appStateSettings["closeNavigationHapticFeedback"] == true,
              onSwitched: (value) async {
                if (value == true) HapticFeedback.selectionClick();
                await updateSettings("closeNavigationHapticFeedback", value,
                    updateGlobalState: false);
              },
            ),
            SettingsContainerSwitch(
              title: "Buttons & Selection Taps",
              description:
                  "Vibrates when pressing buttons or selecting items",
              icon: appStateSettings["outlinedIcons"]
                  ? Icons.touch_app_outlined
                  : Icons.touch_app_rounded,
              initialValue: appStateSettings["buttonPressHapticFeedback"] == true,
              onSwitched: (value) async {
                if (value == true) HapticFeedback.selectionClick();
                await updateSettings("buttonPressHapticFeedback", value,
                    updateGlobalState: false);
              },
            ),
            SettingsContainerSwitch(
              title: "Delete & Destructive Actions",
              description:
                  "Vibrates when deleting entries, categories, or accounts",
              icon: appStateSettings["outlinedIcons"]
                  ? Icons.delete_outline
                  : Icons.delete_rounded,
              initialValue: appStateSettings["deleteActionHapticFeedback"] == true,
              onSwitched: (value) async {
                if (value == true) HapticFeedback.heavyImpact();
                await updateSettings("deleteActionHapticFeedback", value,
                    updateGlobalState: false);
              },
            ),
          ],
        ),
      ],
    );
  }
}

void savingHapticFeedback() {
  if (appStateSettings["savingHapticFeedback"] == true) {
    HapticFeedback.lightImpact();
  }
}

void deleteHapticFeedback() {
  if (appStateSettings["deleteActionHapticFeedback"] == true) {
    HapticFeedback.heavyImpact();
  }
}

void buttonPressHapticFeedback() {
  if (appStateSettings["buttonPressHapticFeedback"] == true) {
    HapticFeedback.selectionClick();
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

class PermissionsSettingsSubPage extends StatelessWidget {
  const PermissionsSettingsSubPage({super.key});

  @override
  Widget build(BuildContext context) {
    return PageFramework(
      title: "Permissions",
      dragDownToDismiss: true,
      listWidgets: [
        SettingsGroupCard(
          title: "Device Permissions",
          icon: appStateSettings["outlinedIcons"]
              ? Icons.security_outlined
              : Icons.security_rounded,
          children: [
            SettingsContainer(
              title: "Notifications",
              description: "Enable or disable notifications for this app",
              icon: appStateSettings["outlinedIcons"]
                  ? Icons.notifications_outlined
                  : Icons.notifications_rounded,
              onTap: () {
                AppSettings.openAppSettings(type: AppSettingsType.notification);
              },
            ),
            SettingsContainer(
              title: "Read App Notifications",
              description: "Manage permission to auto-detect transaction SMS/alerts",
              icon: appStateSettings["outlinedIcons"]
                  ? Icons.mark_email_read_outlined
                  : Icons.mark_email_read_rounded,
              onTap: () async {
                bool status = await NotificationListenerService.isPermissionGranted();
                if (status) {
                  openSnackbar(
                    SnackbarMessage(
                      title: "Permission Already Granted",
                      description: "You can revoke or manage this in Android Device & App Notification settings.",
                      icon: Icons.check_circle_rounded,
                    )
                  );
                  NotificationListenerService.requestPermission();
                } else {
                  promptNotificationPermissionPopup(context);
                }
              },
            ),
            SettingsContainer(
              title: "Battery Optimization",
              description: "Allow unrestricted background running for notification capture",
              icon: appStateSettings["outlinedIcons"]
                  ? Icons.battery_saver_outlined
                  : Icons.battery_saver_rounded,
              onTap: () {
                AppSettings.openAppSettings(type: AppSettingsType.batteryOptimization);
              },
            ),
            SettingsContainer(
              title: "Open App Settings",
              description: "Open system settings to manage all permissions",
              icon: appStateSettings["outlinedIcons"]
                  ? Icons.settings_applications_outlined
                  : Icons.settings_applications_rounded,
              onTap: () {
                AppSettings.openAppSettings();
              },
            ),
          ],
        ),
      ],
    );
  }
}
