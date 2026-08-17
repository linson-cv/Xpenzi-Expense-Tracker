import 'package:budget/colors.dart';
import 'package:budget/database/tables.dart';
import 'package:budget/functions.dart';
import 'package:budget/pages/addTransactionPage.dart';
import 'package:budget/pages/homePage/homePageWalletSwitcher.dart';
import 'package:budget/struct/currencyFunctions.dart';
import 'package:budget/struct/databaseGlobal.dart';
import 'package:budget/struct/settings.dart';
import 'package:budget/widgets/navigationFramework.dart';
import 'package:budget/widgets/tappable.dart';
import 'package:budget/widgets/util/keepAliveClientMixin.dart';
import 'package:budget/widgets/openBottomSheet.dart';
import 'package:budget/widgets/walletEntry.dart';
import 'package:budget/widgets/transactionEntry/incomeAmountArrow.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:budget/pages/addButton.dart';
import 'package:budget/widgets/textWidgets.dart';
class HomePageWalletList extends StatelessWidget {
  const HomePageWalletList({super.key});

  @override
  Widget build(BuildContext context) {
    const double borderRadius = 15;
    return KeepAliveClientMixin(
      child: Padding(
        padding:
            const EdgeInsetsDirectional.only(bottom: 13, start: 13, end: 13),
        child: Container(
          decoration: BoxDecoration(
            boxShadow: boxShadowCheck(boxShadowGeneral(context)),
            borderRadius: BorderRadiusDirectional.circular(borderRadius),
          ),
          child: ClipRRect(
            borderRadius: BorderRadiusDirectional.circular(borderRadius),
            child: Tappable(
              color: getColor(context, "lightDarkAccentHeavyLight"),
              borderRadius: borderRadius,
              onLongPress: () async {
                await openBottomSheet(
                  context,
                  const EditHomePagePinnedWalletsPopup(
                    homePageWidgetDisplay: HomePageWidgetDisplay.WalletList,
                    showCyclePicker: true,
                  ),
                  useCustomController: true,
                );
                homePageStateKey.currentState?.refreshState();
              },
              child: Column(
                children: [
                  StreamBuilder<List<WalletWithDetails>>(
                    stream: database.watchAllWalletsWithDetails(
                        homePageWidgetDisplay:
                            HomePageWidgetDisplay.WalletList),
                    builder: (context, snapshot) {
                      if (snapshot.hasData) {
                        List<WalletWithDetails> wallets = snapshot.data!;
                        if (wallets.isEmpty) {
                          return Column(
                            mainAxisSize: MainAxisSize.max,
                            children: [
                              Row(
                                mainAxisSize: MainAxisSize.max,
                                children: [
                                  Expanded(
                                    child: AddButton(
                                      onTap: () async {
                                        await openBottomSheet(
                                          context,
                                          const EditHomePagePinnedWalletsPopup(
                                            homePageWidgetDisplay:
                                                HomePageWidgetDisplay.WalletList,
                                          ),
                                          useCustomController: true,
                                        );
                                        homePageStateKey.currentState
                                            ?.refreshState();
                                      },
                                      height: null,
                                      labelUnder: "account".tr(),
                                      icon: Icons.format_list_bulleted_add,
                                      padding: const EdgeInsetsDirectional.symmetric(
                                          vertical: 10),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          );
                        }

                        String groupStyle = appStateSettings["walletsListGroupStyle"] ??
                            (appStateSettings["walletsListGroupByColor"] == true
                                ? "Color"
                                : "None");
                        List<Widget> children = [];
                        children.add(const SizedBox(height: 4));

                        if (groupStyle == "Account Type") {
                          List<String> accountTypeOrder = [
                            "Bank Account",
                            "Credit Card",
                            "Meal Card",
                            "Cash",
                            "Savings",
                          ];
                          Map<String, List<WalletWithDetails>> grouped = {};
                          for (var w in wallets) {
                            String type = getWalletAccountType(w.wallet);
                            grouped.putIfAbsent(type, () => []).add(w);
                          }
                          // Sort group keys by defined logical order
                          List<String> sortedTypes = grouped.keys.toList()
                            ..sort((a, b) {
                              int indexA = accountTypeOrder.indexOf(a);
                              int indexB = accountTypeOrder.indexOf(b);
                              if (indexA == -1) indexA = 999;
                              if (indexB == -1) indexB = 999;
                              return indexA.compareTo(indexB);
                            });

                          for (String type in sortedTypes) {
                            List<WalletWithDetails> groupWallets =
                                grouped[type]!;
                            double groupTotal = 0;
                            for (var w in groupWallets) {
                              groupTotal += (w.totalSpent ?? 0.0) *
                                  amountRatioToPrimaryCurrency(
                                      Provider.of<AllWallets>(context),
                                      w.wallet.currency);
                            }

                            IconData typeIcon;
                            switch (type) {
                              case "Credit Card":
                                typeIcon = Icons.credit_card_rounded;
                                break;
                              case "Meal Card":
                                typeIcon = Icons.restaurant_rounded;
                                break;
                              case "Cash":
                                typeIcon = Icons.payments_rounded;
                                break;
                              case "Savings":
                                typeIcon = Icons.savings_rounded;
                                break;
                              case "Bank Account":
                              default:
                                typeIcon = Icons.account_balance_rounded;
                                break;
                            }

                            children.add(
                              Container(
                                margin: const EdgeInsets.symmetric(
                                    horizontal: 4, vertical: 6),
                                decoration: BoxDecoration(
                                  color: getColor(
                                      context, "lightDarkAccentHeavyLight"),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Padding(
                                      padding:
                                          const EdgeInsetsDirectional.only(
                                        start: 16,
                                        end: 16,
                                        top: 10,
                                        bottom: 4,
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(
                                            typeIcon,
                                            size: 18,
                                            color: Theme.of(context)
                                                .colorScheme
                                                .primary,
                                          ),
                                          const SizedBox(width: 8),
                                          TextFont(
                                            text: type,
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                            textColor: Theme.of(context)
                                                .colorScheme
                                                .primary,
                                          ),
                                          const Spacer(),
                                          TextFont(
                                            text:
                                                "${groupWallets.length} ${groupWallets.length == 1 ? "account".tr() : "accounts".tr()}",
                                            fontSize: 12,
                                            textColor: getColor(
                                                    context, "textLight")
                                                .withValues(alpha: 0.8),
                                          ),
                                        ],
                                      ),
                                    ),
                                    for (var w in groupWallets)
                                      WalletEntryRow(
                                        selected: Provider.of<SelectedWalletPk>(
                                                    context)
                                                .selectedWalletPk ==
                                            w.wallet.walletPk,
                                        walletWithDetails: w,
                                        closedColor: Colors.transparent,
                                      ),
                                    if (groupWallets.length > 1) ...[
                                      const SizedBox(height: 2),
                                      Container(
                                        height: 1,
                                        margin: const EdgeInsets.symmetric(
                                            horizontal: 16),
                                        color: getColor(context, "dividerColor")
                                            .withValues(alpha: 0.3),
                                      ),
                                      Padding(
                                        padding:
                                            const EdgeInsetsDirectional.only(
                                          start: 48,
                                          end: 18,
                                          top: 10,
                                          bottom: 10,
                                        ),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            TextFont(
                                              text: "total".tr(),
                                              fontSize: 15,
                                              fontWeight: FontWeight.bold,
                                            ),
                                            Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                if (appStateSettings[
                                                            "accountColorfulAmountsWithArrows"] ==
                                                        true &&
                                                    groupTotal != 0)
                                                  Padding(
                                                    padding:
                                                        const EdgeInsetsDirectional
                                                            .only(end: 4),
                                                    child: IncomeOutcomeArrow(
                                                      isIncome: groupTotal > 0,
                                                      iconSize: 24,
                                                      width: 14,
                                                      height: 10,
                                                    ),
                                                  ),
                                                TextFont(
                                                  text: convertToMoney(
                                                    Provider.of<AllWallets>(
                                                        context),
                                                    appStateSettings[
                                                                "accountColorfulAmountsWithArrows"] ==
                                                            true
                                                        ? groupTotal.abs()
                                                        : groupTotal,
                                                  ),
                                                  fontSize: 15,
                                                  fontWeight: FontWeight.bold,
                                                  textColor: appStateSettings[
                                                              "accountColorfulAmountsWithArrows"] ==
                                                          true
                                                      ? (groupTotal == 0
                                                          ? getColor(
                                                              context, "black")
                                                          : (groupTotal > 0
                                                              ? getColor(
                                                                  context,
                                                                  "incomeAmount")
                                                              : getColor(
                                                                  context,
                                                                  "expenseAmount")))
                                                      : getColor(
                                                          context, "black"),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ] else ...[
                                      const SizedBox(height: 4),
                                    ],
                                  ],
                                ),
                              ),
                            );
                          }
                        } else if (groupStyle == "Color") {
                          Map<String, List<WalletWithDetails>> grouped = {};
                          for (var w in wallets) {
                            String color = w.wallet.colour ?? "";
                            grouped.putIfAbsent(color, () => []).add(w);
                          }
                          grouped.forEach((color, groupWallets) {
                            double groupTotal = 0;
                            for (var w in groupWallets) {
                              groupTotal += (w.totalSpent ?? 0.0) *
                                  amountRatioToPrimaryCurrency(
                                      Provider.of<AllWallets>(context),
                                      w.wallet.currency);
                            }
                            Color groupColor = HexColor(color,
                                defaultColor:
                                    Theme.of(context).colorScheme.primary);
                            children.add(
                              Container(
                                margin: const EdgeInsets.symmetric(
                                    horizontal: 4, vertical: 6),
                                decoration: BoxDecoration(
                                  color: getColor(
                                      context, "lightDarkAccentHeavyLight"),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: groupColor.withValues(alpha: 0.4),
                                    width: 1.5,
                                  ),
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const SizedBox(height: 4),
                                    for (var w in groupWallets)
                                      WalletEntryRow(
                                        selected: Provider.of<SelectedWalletPk>(
                                                    context)
                                                .selectedWalletPk ==
                                            w.wallet.walletPk,
                                        walletWithDetails: w,
                                        closedColor: Colors.transparent,
                                      ),
                                    if (groupWallets.length > 1) ...[
                                      const SizedBox(height: 4),
                                      Container(
                                        height: 1,
                                        margin: const EdgeInsets.symmetric(
                                            horizontal: 16),
                                        color:
                                            groupColor.withValues(alpha: 0.3),
                                      ),
                                      Padding(
                                        padding:
                                            const EdgeInsetsDirectional.only(
                                          start: 48,
                                          end: 18,
                                          top: 12,
                                          bottom: 12,
                                        ),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            TextFont(
                                              text: "total".tr(),
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                            ),
                                            Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                if (appStateSettings[
                                                            "accountColorfulAmountsWithArrows"] ==
                                                        true &&
                                                    groupTotal != 0)
                                                  Padding(
                                                    padding:
                                                        const EdgeInsetsDirectional.only(
                                                            end: 4),
                                                    child: IncomeOutcomeArrow(
                                                      isIncome: groupTotal > 0,
                                                      iconSize: 24,
                                                      width: 14,
                                                      height: 10,
                                                    ),
                                                  ),
                                                TextFont(
                                                  text: convertToMoney(
                                                    Provider.of<AllWallets>(
                                                        context),
                                                    appStateSettings[
                                                                "accountColorfulAmountsWithArrows"] ==
                                                            true
                                                        ? groupTotal.abs()
                                                        : groupTotal,
                                                  ),
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                  textColor: appStateSettings[
                                                              "accountColorfulAmountsWithArrows"] ==
                                                          true
                                                      ? (groupTotal == 0
                                                          ? getColor(
                                                              context, "black")
                                                          : (groupTotal > 0
                                                              ? getColor(
                                                                  context,
                                                                  "incomeAmount")
                                                              : getColor(
                                                                  context,
                                                                  "expenseAmount")))
                                                      : getColor(
                                                          context, "black"),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ] else ...[
                                      const SizedBox(height: 4),
                                    ],
                                  ],
                                ),
                              ),
                            );
                          });
                        } else {
                          for (var w in wallets) {
                            children.add(WalletEntryRow(
                              selected: Provider.of<SelectedWalletPk>(context).selectedWalletPk == w.wallet.walletPk,
                              walletWithDetails: w,
                            ));
                          }
                        }
                        children.add(const SizedBox(height: 4));

                        return Column(
                          mainAxisSize: MainAxisSize.max,
                          children: children,
                        );
                      }
                      return Container();
                    },
                  ),
                  if (appStateSettings["walletsListCurrencyBreakdown"] ==
                          true &&
                      Provider.of<AllWallets>(context)
                              .allContainSameCurrency() ==
                          false &&
                      Provider.of<AllWallets>(context)
                              .containsMultipleAccountsWithSameCurrency() ==
                          true)
                    HorizontalBreakAbove(
                      padding: EdgeInsetsDirectional.zero,
                      child: StreamBuilder<List<WalletWithDetails>>(
                        stream: database.watchAllWalletsWithDetails(
                            mergeLikeCurrencies: true),
                        builder: (context, snapshot) {
                          double totalAmountSpent = (snapshot.data ?? []).fold(
                              0.0, (double acc, WalletWithDetails wallet) {
                            return acc +
                                (wallet.totalSpent ?? 0.0) *
                                    amountRatioToPrimaryCurrency(
                                        Provider.of<AllWallets>(context),
                                        wallet.wallet.currency);
                          });

                          if (snapshot.hasData) {
                            return Column(
                              mainAxisSize: MainAxisSize.max,
                              children: [
                                if (snapshot.hasData &&
                                    snapshot.data!.isNotEmpty)
                                  const SizedBox(height: 8),
                                for (WalletWithDetails walletDetails
                                    in snapshot.data!)
                                  WalletEntryRow(
                                    selected: Provider.of<AllWallets>(context)
                                            .indexedByPk[appStateSettings[
                                                "selectedWalletPk"]]
                                            ?.currency ==
                                        walletDetails.wallet.currency,
                                    walletWithDetails: walletDetails,
                                    isCurrencyRow: true,
                                    percent: (totalAmountSpent == 0
                                                ? 0
                                                : ((walletDetails.totalSpent ??
                                                            0) *
                                                        amountRatioToPrimaryCurrency(
                                                            Provider.of<
                                                                    AllWallets>(
                                                                context),
                                                            walletDetails.wallet
                                                                .currency)) /
                                                    totalAmountSpent)
                                            .abs() *
                                        100
                                    // * ((walletDetails.totalSpent ?? 0) < 0
                                    //     ? -1
                                    //     : 1)
                                    ,
                                  ),
                                if (snapshot.hasData &&
                                    snapshot.data!.isNotEmpty)
                                  const SizedBox(height: 8),
                              ],
                            );
                          }
                          return Container();
                        },
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
