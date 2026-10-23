import 'package:budget/database/tables.dart';
import 'package:budget/functions.dart';
import 'package:budget/pages/addWalletPage.dart';
import 'package:budget/pages/addTransactionPage.dart';
import 'package:budget/pages/homePage/homePageWalletSwitcher.dart';
import 'package:budget/pages/transactionFilters.dart';
import 'package:budget/struct/settings.dart';
import 'package:budget/widgets/animatedExpanded.dart';
import 'package:budget/widgets/fadeIn.dart';
import 'package:budget/widgets/navigationFramework.dart';
import 'package:budget/widgets/openBottomSheet.dart';
import 'package:budget/widgets/openContainerNavigation.dart';
import 'package:budget/widgets/openPopup.dart';
import 'package:budget/widgets/tappable.dart';
import 'package:budget/widgets/textWidgets.dart';
import 'package:budget/widgets/transactionEntry/incomeAmountArrow.dart';
import 'package:budget/widgets/watchAllWallets.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:budget/pages/walletDetailsPage.dart';
import 'package:budget/colors.dart';
import 'package:provider/provider.dart';
import 'package:budget/widgets/countNumber.dart';

class WalletEntry extends StatelessWidget {
  const WalletEntry(
      {super.key, required this.walletWithDetails, required this.selected});
  final WalletWithDetails walletWithDetails;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsetsDirectional.only(start: 6, end: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadiusDirectional.circular(15),
        boxShadow: boxShadowCheck(boxShadowGeneral(context)),
      ),
      child: OpenContainerNavigation(
        borderRadius: 15,
        openPage: WatchedWalletDetailsPage(
            walletPk: walletWithDetails.wallet.walletPk),
        button: (openContainer) {
          return Tappable(
            color: getColor(context, "lightDarkAccentHeavyLight"),
            borderRadius: 14,
            child: AnimatedContainer(
              decoration: BoxDecoration(
                borderRadius: BorderRadiusDirectional.circular(15),
                border: Border.all(
                  width: 2,
                  color: selected
                      ? HexColor(walletWithDetails.wallet.colour,
                              defaultColor:
                                  Theme.of(context).colorScheme.primary)
                          .withValues(alpha: 0.7)
                      : Colors.transparent,
                ),
              ),
              duration: const Duration(milliseconds: 450),
              child: Padding(
                padding: const EdgeInsetsDirectional.symmetric(
                    horizontal: 18, vertical: 13),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    PositionedDirectional(
                      end: -11,
                      top: -5,
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadiusDirectional.circular(100),
                          color: HexColor(walletWithDetails.wallet.colour,
                                  defaultColor:
                                  Theme.of(context).colorScheme.primary)
                              .withValues(alpha: 0.7),
                        ),
                        width: 20,
                        height: 20,
                      ),
                    ),
                    Container(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Flexible(
                                child: Padding(
                                  padding: const EdgeInsetsDirectional.only(end: 10),
                                  child: TextFont(
                                    text: walletWithDetails.wallet.name,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              if (getWalletAccountType(walletWithDetails.wallet) == "Credit Card")
                                Padding(
                                  padding: const EdgeInsetsDirectional.only(end: 14),
                                  child: Tappable(
                                    color: Theme.of(context).colorScheme.primaryContainer,
                                    borderRadius: 8,
                                    onTap: () {
                                      pushRoute(
                                        context,
                                        AddTransactionPage(
                                          transferBalancePopup: true,
                                          routesToPopAfterDelete: RoutesToPopAfterDelete.All,
                                        ),
                                      );
                                    },
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.credit_card_rounded,
                                            size: 13,
                                            color: Theme.of(context).colorScheme.onPrimaryContainer,
                                          ),
                                          const SizedBox(width: 4),
                                          TextFont(
                                            text: "Pay Bill",
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                            textColor: Theme.of(context).colorScheme.onPrimaryContainer,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          AmountAccount(
                            walletWithDetails: walletWithDetails,
                            textAlign: TextAlign.start,
                            fontSize: 17,
                          ),
                          TextFont(
                            textAlign: TextAlign.start,
                            text: "${walletWithDetails.numberTransactions} ${walletWithDetails.numberTransactions == 1
                                    ? "transaction".tr().toLowerCase()
                                    : "transactions".tr().toLowerCase()}",
                            fontSize: 14,
                            textColor:
                                getColor(context, "black").withValues(alpha: 0.65),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            onTap: () async {
              if (selected) {
                openContainer();
              } else {
                setPrimaryWallet(walletWithDetails.wallet.walletPk,
                    allWallets:
                        Provider.of<AllWallets>(context, listen: false));
              }
            },
            onLongPress: () {
              pushRoute(
                context,
                AddWalletPage(
                  wallet: walletWithDetails.wallet,
                  routesToPopAfterDelete: RoutesToPopAfterDelete.All,
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class WalletEntryRow extends StatelessWidget {
  const WalletEntryRow({
    super.key,
    required this.walletWithDetails,
    required this.selected,
    this.isCurrencyRow = false,
    this.percent,
    this.closedColor,
    this.showAccountIcon = true,
  });
  final WalletWithDetails walletWithDetails;
  final bool selected;
  final bool isCurrencyRow;
  final double? percent;
  final Color? closedColor;
  final bool showAccountIcon;

  @override
  Widget build(BuildContext context) {
    return OpenContainerNavigation(
      borderRadius: 0,
      openPage: isCurrencyRow
          ? WalletDetailsPage(
              wallet: null,
              initialSearchFilters: SearchFilters(
                walletPks: Provider.of<AllWallets>(context)
                    .list
                    .where((wallet) =>
                        wallet.currency == walletWithDetails.wallet.currency)
                    .map((e) => e.walletPk)
                    .toList(),
              ),
            )
          : WatchedWalletDetailsPage(
              walletPk: walletWithDetails.wallet.walletPk),
      closedColor: closedColor ?? getColor(context, "lightDarkAccentHeavyLight"),
      button: (openContainer) {
        return Tappable(
          color: Colors.transparent,
          borderRadius: 0,
          child: Padding(
            padding: const EdgeInsetsDirectional.symmetric(
                horizontal: 18, vertical: 8),
            child: Container(
              child: Row(
                mainAxisSize: MainAxisSize.max,
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        ScaledAnimatedSwitcher(
                          keyToWatch: selected.toString(),
                          child: selected
                              ? Container(
                                  decoration: BoxDecoration(
                                    borderRadius:
                                        BorderRadiusDirectional.circular(100),
                                    color: HexColor(
                                      walletWithDetails.wallet.colour,
                                      defaultColor:
                                          Theme.of(context).colorScheme.primary,
                                    ).withValues(alpha: 0.7),
                                  ),
                                  width: 20,
                                  height: 20,
                                )
                              : Transform.scale(
                                  scale: 0.9,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      borderRadius:
                                          BorderRadiusDirectional.circular(100),
                                      border: Border.all(
                                        width: 2,
                                        color: HexColor(
                                          walletWithDetails.wallet.colour,
                                          defaultColor: Theme.of(context)
                                              .colorScheme
                                              .primary,
                                        ).withValues(alpha: 0.7),
                                      ),
                                    ),
                                    width: 20,
                                    height: 20,
                                  ),
                                ),
                        ),
                        Flexible(
                          child: Padding(
                                  padding: const EdgeInsetsDirectional.only(
                              end: 17,
                              start: 10,
                            ),
                            child: TextFont(
                              textAlign: TextAlign.start,
                              text: "",
                              maxLines: 1,
                              richTextSpan: [
                                if (!isCurrencyRow && showAccountIcon)
                                  WidgetSpan(
                                    alignment: PlaceholderAlignment.middle,
                                    child: Padding(
                                      padding: const EdgeInsetsDirectional.only(end: 5),
                                      child: Icon(
                                        getWalletAccountIconData(walletWithDetails.wallet),
                                        size: 18,
                                        color: getColor(context, "black"),
                                      ),
                                    ),
                                  ),
                                TextSpan(
                                  text: isCurrencyRow
                                      ? (walletWithDetails.wallet.currency ??
                                              "")
                                          .toString()
                                          .allCaps
                                      : walletWithDetails.wallet.name,
                                  style: TextStyle(
                                    fontSize: 18,
                                    color: getColor(context, "black"),
                                    fontFamily: appStateSettings["font"],
                                    fontFamilyFallback: const ['Inter'],
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                if (percent != null)
                                  TextSpan(
                                    text: "  (${convertToPercent(percent ?? 0,
                                            useLessThanZero: true)})",
                                    style: TextStyle(
                                      fontSize: 15,
                                      color: getColor(context, "textLight"),
                                      fontFamily: appStateSettings["font"],
                                      fontFamilyFallback: const ['Inter'],
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  AmountAccount(
                    walletWithDetails: walletWithDetails,
                    textAlign: TextAlign.end,
                    fontSize: 18,
                  )
                ],
              ),
            ),
          ),
          onTap: () async {
            if (selected || isCurrencyRow) {
              openContainer();
            } else {
              setPrimaryWallet(walletWithDetails.wallet.walletPk,
                  allWallets: Provider.of<AllWallets>(context, listen: false));
            }
          },
          onLongPress: () async {
            if (isCurrencyRow) {
              await openBottomSheet(
                context,
                const EditHomePagePinnedWalletsPopup(
                  homePageWidgetDisplay: HomePageWidgetDisplay.WalletList,
                  showCyclePicker: true,
                ),
                useCustomController: true,
              );
              homePageStateKey.currentState?.refreshState();
            } else {
              pushRoute(
                context,
                AddWalletPage(
                  wallet: walletWithDetails.wallet,
                  routesToPopAfterDelete: RoutesToPopAfterDelete.All,
                ),
              );
            }
          },
        );
      },
    );
  }
}

class AmountAccount extends StatelessWidget {
  const AmountAccount({
    required this.walletWithDetails,
    required this.textAlign,
    required this.fontSize,
    super.key,
  });

  final WalletWithDetails walletWithDetails;
  final TextAlign textAlign;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    double? roundedWalletWithTotal = (double.tryParse(
        absoluteZero(walletWithDetails.totalSpent ?? 0)
            .toStringAsFixed(walletWithDetails.wallet.decimals)));
    Color textColor =
        appStateSettings["accountColorfulAmountsWithArrows"] == true
            ? roundedWalletWithTotal == 0
                ? getColor(context, "black")
                : (walletWithDetails.totalSpent ?? 0) > 0
                    ? getColor(context, "incomeAmount")
                    : getColor(context, "expenseAmount")
            : getColor(context, "black");
    double finalTotal =
        appStateSettings["accountColorfulAmountsWithArrows"] == true
            ? (walletWithDetails.totalSpent ?? 0).abs()
            : (absoluteZero(walletWithDetails.totalSpent ?? 0));
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (appStateSettings["accountColorfulAmountsWithArrows"] == true)
          AnimatedSizeSwitcher(
            child: roundedWalletWithTotal == 0
                ? Container(
                    key: const ValueKey(1),
                  )
                : IncomeOutcomeArrow(
                    key: const ValueKey(2),
                    isIncome: (walletWithDetails.totalSpent ?? 0) > 0,
                    iconSize: 24,
                    width: 14,
                    height: 10,
                  ),
          ),
        CountNumber(
          lazyFirstRender: false,
          count: finalTotal,
          duration: const Duration(milliseconds: 1000),
          decimals: walletWithDetails.wallet.decimals,
          initialCount: 0,
          textBuilder: (number) {
            return TextFont(
              textAlign: textAlign,
              text: convertToMoney(
                Provider.of<AllWallets>(context),
                number,
                finalNumber: finalTotal,
                currencyKey: walletWithDetails.wallet.currency,
                decimals: walletWithDetails.wallet.decimals,
                addCurrencyName:
                    Provider.of<AllWallets>(context).allContainSameCurrency() ==
                        false,
              ),
              textColor: textColor,
              fontSize: fontSize,
              fontWeight: FontWeight.bold,
            );
          },
        ),
      ],
    );
  }
}

// set selectedWallet, update selectedWallet
Future<bool> setPrimaryWallet(String walletPk, {AllWallets? allWallets}) async {
  if (allWallets != null &&
      allWallets.indexedByPk[appStateSettings["selectedWalletPk"]]?.currency !=
          null &&
      allWallets.indexedByPk[walletPk]?.currency != null &&
      allWallets.indexedByPk[appStateSettings["selectedWalletPk"]]?.currency ==
          allWallets.indexedByPk[walletPk]?.currency &&
      allWallets.indexedByPk[appStateSettings["selectedWalletPk"]]?.decimals !=
          null &&
      allWallets.indexedByPk[walletPk]?.decimals != null &&
      allWallets.indexedByPk[appStateSettings["selectedWalletPk"]]?.decimals ==
          allWallets.indexedByPk[walletPk]?.decimals) {
    // The currency has not changed, we do not need to refresh the global state!
    await updateSettings("selectedWalletPk", walletPk,
        updateGlobalState: false);
  } else {
    // The currency has changed, or we do not have access to allWallets, so we need to refresh the global state
    await updateSettings("selectedWalletPk", walletPk, updateGlobalState: true);
  }
  selectedWalletPkController.add(SelectedWalletPk(selectedWalletPk: walletPk));
  return true;
}

String inferAccountTypeFromName(String name, {String defaultType = "Bank Account"}) {
  final String nameLower = name.trim().toLowerCase();
  if (nameLower.isEmpty) return defaultType;

  // 1. Meal / Food Cards (check before generic "card" or "wallet")
  if (RegExp(r'\b(pluxee|sodexo|meal|zaggle|edenred|pantry)\b').hasMatch(nameLower) ||
      nameLower.contains("food card") ||
      nameLower.contains("meal card") ||
      nameLower.contains("food wallet") ||
      nameLower.contains("ticket restaurant")) {
    return "Meal Card";
  }

  // 2. Credit Cards & BNPL Cards (exclude explicit "debit card")
  final bool isExplicitDebitCard = nameLower.contains("debit card") || nameLower.contains("atm card");
  if (!isExplicitDebitCard &&
      (RegExp(r'\b(credit|cc|amex|diners|regalia|millennia|infinia|magnus|atlas|aurum|simplyclick|simplysave|onecard|slice|lazypay|simpl)\b')
              .hasMatch(nameLower) ||
          nameLower.contains("credit card") ||
          nameLower.contains("american express") ||
          nameLower.contains("amazon pay icici") ||
          nameLower.contains("icici amazon") ||
          nameLower.contains("flipkart axis") ||
          nameLower.contains("uni card") ||
          nameLower.contains("sbi card") ||
          nameLower.contains("card"))) {
    return "Credit Card";
  }

  // 3. Cash & Digital Wallets
  if (RegExp(r'\b(cash|petty|coins|mobikwik|freecharge)\b').hasMatch(nameLower) ||
      nameLower.contains("pocket money") ||
      nameLower.contains("cash in hand") ||
      nameLower.contains("paytm wallet") ||
      nameLower.contains("phonepe wallet") ||
      nameLower.contains("amazon pay balance") ||
      (nameLower.contains("wallet") && !nameLower.contains("bank"))) {
    return "Cash";
  }

  // 4. Savings, Deposits & Vaults
  if (RegExp(r'\b(savings?|sav|fd|rd|ppf|epf|vault|piggy|stash|treasury|emergency)\b').hasMatch(nameLower) ||
      nameLower.contains("fixed deposit") ||
      nameLower.contains("recurring deposit") ||
      nameLower.contains("emergency fund") ||
      nameLower.contains("liquid fund")) {
    return "Savings";
  }

  // 5. Bank Accounts
  if (RegExp(r'\b(bank|debit|checking|current|salary|upi|a/c|acct|hdfc|icici|sbi|axis|kotak|canara|federal|indus|indusind|yes|pnb|bob|idfc|rbl|au|bandhan|union|indian|boi|citi|citibank|hsbc|sc|chase|bofa|barclays|revolut|wise|monzo|n26|jupiter|fi|niyo)\b')
          .hasMatch(nameLower) ||
      nameLower.contains("standard chartered") ||
      nameLower.contains("wells fargo") ||
      nameLower.contains("bank of")) {
    return "Bank Account";
  }

  return defaultType;
}

String getWalletAccountType(TransactionWallet wallet) {
  const validTypes = ["Bank Account", "Credit Card", "Meal Card", "Cash", "Savings"];
  if (wallet.currencyFormat != null &&
      validTypes.contains(wallet.currencyFormat) &&
      wallet.currencyFormat != "Bank Account") {
    return wallet.currencyFormat!;
  }
  if (wallet.iconName != null &&
      validTypes.contains(wallet.iconName) &&
      wallet.iconName != "Bank Account") {
    return wallet.iconName!;
  }
  return inferAccountTypeFromName(
    wallet.name,
    defaultType: (wallet.currencyFormat != null && validTypes.contains(wallet.currencyFormat))
        ? wallet.currencyFormat!
        : "Bank Account",
  );
}

IconData getWalletAccountIconData(TransactionWallet wallet) {
  String accountType = getWalletAccountType(wallet);
  switch (accountType) {
    case "Credit Card":
      return Icons.credit_card_rounded;
    case "Meal Card":
      return Icons.restaurant_rounded;
    case "Cash":
      return Icons.payments_rounded;
    case "Savings":
      return Icons.savings_rounded;
    case "Bank Account":
      return Icons.account_balance_rounded;
    default:
      return Icons.account_balance_wallet_rounded;
  }
}
