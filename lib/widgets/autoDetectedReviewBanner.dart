import 'package:budget/colors.dart';
import 'package:budget/database/tables.dart';
import 'package:budget/functions.dart';
import 'package:budget/pages/addTransactionPage.dart';
import 'package:budget/struct/autoTransactionTracker.dart';
import 'package:budget/struct/databaseGlobal.dart';
import 'package:budget/struct/settings.dart';
import 'package:budget/widgets/button.dart';
import 'package:budget/widgets/openPopup.dart';
import 'package:budget/widgets/tappable.dart';
import 'package:budget/widgets/textWidgets.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

class AutoDetectedReviewBanner extends StatelessWidget {
  const AutoDetectedReviewBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: pendingReviewTransactionsNotifier,
      builder: (context, count, _) {
        if (count <= 0) return const SizedBox.shrink();

        final pendingList = getPendingReviewTransactions();
        if (pendingList.isEmpty) return const SizedBox.shrink();

        final firstItem = pendingList.first;
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final bool isAmoled = appStateSettings["forceFullDarkBackground"] == true && isDark;

        AllWallets? allWallets;
        try {
          allWallets = Provider.of<AllWallets>(context, listen: false);
        } catch (_) {}

        String formattedAmount = allWallets != null
            ? convertToMoney(allWallets, firstItem.amount.abs())
            : firstItem.amount.abs().toStringAsFixed(2);

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: Container(
            decoration: BoxDecoration(
              color: isAmoled
                  ? const Color(0xFF0F0F0F)
                  : dynamicPastel(
                      context,
                      Theme.of(context).colorScheme.primaryContainer,
                      amount: 0.2,
                    ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.35),
                width: 1.2,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          firstItem.isIncome
                              ? Icons.arrow_downward_rounded
                              : Icons.auto_awesome_rounded,
                          size: 18,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                TextFont(
                                  text: count > 1
                                      ? "Auto-Detected ($count pending)"
                                      : "Auto-Detected SMS",
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  textColor: Theme.of(context).colorScheme.primary,
                                ),
                                const Spacer(),
                                TextFont(
                                  text: DateFormat('HH:mm').format(firstItem.timestamp.toLocal()),
                                  fontSize: 11,
                                  textColor: getColor(context, "textLight"),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            TextFont(
                              text: "${firstItem.title} · $formattedAmount",
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              maxLines: 1,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: Button(
                          label: "Review & Add",
                          icon: Icons.check_rounded,
                          fontSize: 13,
                          padding: const EdgeInsetsDirectional.symmetric(vertical: 10, horizontal: 12),
                          onTap: () async {
                            HapticFeedback.selectionClick();
                            dismissPendingReviewTransaction(0);

                            // Find matched category if any
                            TransactionCategory? category;
                            try {
                              TransactionAssociatedTitleWithCategory? foundTitle =
                                  (await database.getSimilarAssociatedTitles(
                                          title: firstItem.title, limit: 1))
                                      .firstOrNull;
                              category = foundTitle?.category;
                            } catch (_) {}

                            pushRoute(
                              context,
                              AddTransactionPage(
                                routesToPopAfterDelete: RoutesToPopAfterDelete.None,
                                selectedAmount: firstItem.amount,
                                selectedTitle: firstItem.title,
                                selectedCategory: category,
                                startInitialAddTransactionSequence: false,
                                selectedDate: firstItem.timestamp,
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Tappable(
                        color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.5),
                        borderRadius: 14,
                        onTap: () {
                          HapticFeedback.lightImpact();
                          dismissPendingReviewTransaction(0);
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          child: TextFont(
                            text: "Dismiss",
                            fontSize: 13,
                            textColor: getColor(context, "textLight"),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
