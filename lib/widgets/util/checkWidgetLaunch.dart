import 'dart:async';
import 'package:budget/colors.dart';
import 'package:budget/database/tables.dart';
import 'package:budget/functions.dart';
import 'package:budget/pages/addTransactionPage.dart';
import 'package:budget/pages/transactionFilters.dart';
import 'package:budget/pages/walletDetailsPage.dart';
import 'package:budget/struct/databaseGlobal.dart';
import 'package:budget/struct/settings.dart';
import 'package:budget/widgets/openBottomSheet.dart';
import 'package:budget/widgets/openPopup.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:home_widget/home_widget.dart';
import 'package:provider/provider.dart';
import 'package:budget/pages/addWalletPage.dart';
import "package:budget/struct/throttler.dart";

class AndroidOnly extends StatelessWidget {
  const AndroidOnly({required this.child, super.key});
  final Widget child;
  @override
  Widget build(BuildContext context) {
    if (getPlatform(ignoreEmulation: true) != PlatformOS.isAndroid) {
      return const SizedBox.shrink();
    }
    return child;
  }
}

class CheckWidgetLaunch extends StatefulWidget {
  const CheckWidgetLaunch({super.key});

  @override
  State<CheckWidgetLaunch> createState() => _CheckWidgetLaunchState();
}

Throttler widgetActionThrottler =
    Throttler(duration: const Duration(milliseconds: 350));

bool _initialWidgetLaunchChecked = false;
Uri? _lastProcessedWidgetUri;

class _CheckWidgetLaunchState extends State<CheckWidgetLaunch> {
  StreamSubscription<Uri?>? _widgetSubscription;

  @override
  void initState() {
    super.initState();
    try {
      HomeWidget.setAppGroupId('WIDGET_GROUP_ID');
      if (!_initialWidgetLaunchChecked) {
        _initialWidgetLaunchChecked = true;
        Future.delayed(const Duration(milliseconds: 100), () {
          _checkForWidgetLaunch();
        });
      }
      _widgetSubscription = HomeWidget.widgetClicked.listen(_launchedFromWidget);
    } catch (e) {
      debugPrint("Error initializing HomeWidget: $e");
    }
  }

  @override
  void dispose() {
    _widgetSubscription?.cancel();
    super.dispose();
  }

  void _checkForWidgetLaunch() {
    try {
      HomeWidget.initiallyLaunchedFromHomeWidget().then((uri) {
        if (uri != null) {
          _launchedFromWidget(uri);
        }
      }).catchError((e) {
        debugPrint("Error checking initiallyLaunchedFromHomeWidget: $e");
      });
    } catch (e) {
      debugPrint("Error in _checkForWidgetLaunch: $e");
    }
  }

  void _launchedFromWidget(Uri? uri) async {
    if (uri == null) return;
    String widgetPayload = uri.toString();
    if (widgetPayload.isEmpty) return;

    // Prevent duplicate triggers when returning from recent apps
    if (_lastProcessedWidgetUri == uri && !widgetActionThrottler.canProceed()) return;
    _lastProcessedWidgetUri = uri;
    if (!widgetActionThrottler.canProceed()) return;

    try {
      if (widgetPayload == "addTransactionWidget") {
        Future.delayed(const Duration(milliseconds: 50), () {
          if (!mounted) return;
          pushRoute(
            context,
            const AddTransactionPage(
              routesToPopAfterDelete: RoutesToPopAfterDelete.None,
            ),
          );
        });
      } else if (widgetPayload == "transferTransactionWidget") {
        if (!mounted) return;
        final allWalletsProvider = Provider.of<AllWallets>(context, listen: false);
        if (allWalletsProvider.indexedByPk[appStateSettings["selectedWalletPk"]] == null) {
          popAllRoutes(context);
        }

        openBottomSheet(
          context,
          fullSnap: true,
          TransferBalancePopup(
            allowEditWallet: true,
            wallet: allWalletsProvider.indexedByPk[appStateSettings["selectedWalletPk"]],
            showAllEditDetails: true,
          ),
        );
      } else if (widgetPayload == "netWorthLaunchWidget") {
        if (!mounted) return;
        pushRoute(
          context,
          const WalletDetailsPage(
            wallet: null,
          ),
        );
      }
    } catch (e) {
      debugPrint("Error handling widget launch payload: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
}

class RenderHomePageWidgets extends StatefulWidget {
  const RenderHomePageWidgets({super.key});

  @override
  State<RenderHomePageWidgets> createState() => RenderHomePageWidgetsState();
}

Future updateWidgetColorsAndText(BuildContext context) async {
  if (getPlatform(ignoreEmulation: true) != PlatformOS.isAndroid) return;
  await Future.delayed(const Duration(milliseconds: 500), () async {
    double widgetBackgroundOpacity =
        (double.tryParse((appStateSettings["widgetOpacity"] ?? 1).toString()) ??
                1)
            .clamp(0, 1);
    ThemeData widgetTheme = appStateSettings["widgetTheme"] == "light"
        ? getLightTheme()
        : appStateSettings["widgetTheme"] == "dark"
            ? getDarkTheme()
            : Theme.of(context);

    await HomeWidget.saveWidgetData<String>('netWorthTitle', "net-worth".tr());
    await HomeWidget.saveWidgetData<String>(
      'widgetColorBackground',
      colorToHex(widgetTheme.colorScheme.secondaryContainer),
    );
    await HomeWidget.saveWidgetData<String>(
      'widgetAlpha',
      widgetTheme.colorScheme.secondaryContainer
          .withValues(alpha: widgetBackgroundOpacity)
          .alpha
          .toString(),
    );
    await HomeWidget.saveWidgetData<String>(
      'widgetColorPrimary',
      colorToHex(widgetTheme.colorScheme.primary),
    );
    await HomeWidget.saveWidgetData<String>(
      'widgetColorText',
      colorToHex(widgetTheme.colorScheme.onSecondaryContainer),
    );
    await HomeWidget.updateWidget(
      name: 'NetWorthWidgetProvider',
    );
    await HomeWidget.updateWidget(
      name: 'NetWorthPlusWidgetProvider',
    );
    await HomeWidget.updateWidget(
      name: 'PlusWidgetProvider',
    );
    await HomeWidget.updateWidget(
      name: 'TransferWidgetProvider',
    );
  });

  return;
}

class RenderHomePageWidgetsState extends State<RenderHomePageWidgets> {
  @override
  void initState() {
    super.initState();
    Future.delayed(Duration.zero, () async {
      updateWidgetColorsAndText(context);
    });
  }

  void refreshState() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<TransactionWallet>>(
      stream: database.getAllPinnedWallets(HomePageWidgetDisplay.NetWorth).$1,
      builder: (context, snapshot) {
        List<String>? walletPks =
            (snapshot.data ?? []).map((item) => item.walletPk).toList();
        if (walletPks.isEmpty ||
            appStateSettings["netWorthAllWallets"] == true) {
          walletPks = null;
        }
        return Container(
          child: StreamBuilder<TotalWithCount?>(
            stream: database.watchTotalWithCountOfWallet(
              isIncome: null,
              allWallets: Provider.of<AllWallets>(context),
              followCustomPeriodCycle: true,
              cycleSettingsExtension: "NetWorth",
              searchFilters: SearchFilters(walletPks: walletPks ?? []),
            ),
            builder: (context, snapshot) {
              Future.delayed(Duration.zero, () async {
                int totalCount = snapshot.data?.count ?? 0;
                String netWorthTransactionsNumber = "$totalCount ${totalCount == 1
                        ? "transaction".tr().toLowerCase()
                        : "transactions".tr().toLowerCase()}";
                double totalSpent = snapshot.data?.total ?? 0;
                String netWorthAmount = convertToMoney(
                  Provider.of<AllWallets>(context, listen: false),
                  totalSpent,
                );
                await HomeWidget.saveWidgetData<String>(
                  'netWorthAmount',
                  netWorthAmount,
                );
                await HomeWidget.saveWidgetData<String>(
                  'netWorthTransactionsNumber',
                  netWorthTransactionsNumber,
                );
                await HomeWidget.updateWidget(
                  name: 'NetWorthWidgetProvider',
                );
                await HomeWidget.updateWidget(
                  name: 'NetWorthPlusWidgetProvider',
                );
              });

              return const SizedBox.shrink();
            },
          ),
        );
      },
    );
  }
}
