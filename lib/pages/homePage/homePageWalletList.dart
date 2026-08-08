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

                        bool groupByColor = appStateSettings["walletsListGroupByColor"] == true;
                        List<Widget> children = [];
                        children.add(const SizedBox(height: 8));

                        if (groupByColor) {
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
                            children.add(
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 12,
                                      height: 12,
                                      decoration: BoxDecoration(
                                        color: HexColor(color, defaultColor: Theme.of(context).colorScheme.primary),
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: TextFont(
                                        text: "", // could be a color name if we had one, but we leave empty or say Group
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    TextFont(
                                      text: convertToMoney(Provider.of<AllWallets>(context), groupTotal),
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      textColor: getColor(context, "black"),
                                    ),
                                  ],
                                ),
                              ),
                            );
                            for (var w in groupWallets) {
                              children.add(WalletEntryRow(
                                selected: Provider.of<SelectedWalletPk>(context).selectedWalletPk == w.wallet.walletPk,
                                walletWithDetails: w,
                              ));
                            }
                          });
                        } else {
                          for (var w in wallets) {
                            children.add(WalletEntryRow(
                              selected: Provider.of<SelectedWalletPk>(context).selectedWalletPk == w.wallet.walletPk,
                              walletWithDetails: w,
                            ));
                          }
                        }
                        children.add(const SizedBox(height: 8));

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
