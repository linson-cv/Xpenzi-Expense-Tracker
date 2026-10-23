import 'package:budget/colors.dart';
import 'package:budget/database/tables.dart';
import 'package:budget/functions.dart';
import 'package:budget/pages/addTransactionPage.dart';
import 'package:budget/struct/autoTransactionTracker.dart';
import 'package:budget/struct/databaseGlobal.dart';
import 'package:budget/struct/settings.dart';
import 'package:budget/widgets/button.dart';
import 'package:budget/widgets/globalSnackbar.dart';
import 'package:budget/widgets/openPopup.dart';
import 'package:budget/widgets/openSnackbar.dart';
import 'package:budget/widgets/tappable.dart';
import 'package:budget/widgets/textWidgets.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

class AutoDetectedReviewBanner extends StatefulWidget {
  const AutoDetectedReviewBanner({super.key});

  @override
  State<AutoDetectedReviewBanner> createState() => _AutoDetectedReviewBannerState();
}

class _AutoDetectedReviewBannerState extends State<AutoDetectedReviewBanner> {
  @override
  void initState() {
    super.initState();
    syncPendingReviewTransactionsFromPrefs();
  }

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
          child: Dismissible(
            key: ValueKey(
              "${firstItem.uniqueKey}_$count",
            ),
            direction: DismissDirection.horizontal,
            onDismissed: (_) {
              HapticFeedback.lightImpact();
              dismissPendingReviewTransaction(0);
              openSnackbar(
                SnackbarMessage(
                  title: "Saved Without Review",
                  description: "${firstItem.title} ($formattedAmount) kept in transactions",
                  icon: Icons.check_circle_outline_rounded,
                  timeout: const Duration(seconds: 3),
                ),
              );
            },
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
                                  Flexible(
                                    child: TextFont(
                                      text: firstItem.transactionPk != null
                                          ? (count > 1
                                              ? "Auto-Recorded ($count to review)"
                                              : "Auto-Recorded (Review)")
                                          : (count > 1
                                              ? "Auto-Detected ($count pending)"
                                              : "Auto-Detected SMS"),
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      textColor: Theme.of(context).colorScheme.primary,
                                      maxLines: 1,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  if (count > 1) ...[
                                    Tappable(
                                      color: Colors.transparent,
                                      borderRadius: 8,
                                      onTap: () {
                                        HapticFeedback.lightImpact();
                                        clearAllPendingReviewTransactions();
                                        openSnackbar(
                                          SnackbarMessage(
                                            title: "Saved All Without Review",
                                            description: "$count auto-recorded transactions kept",
                                            icon: Icons.done_all_rounded,
                                            timeout: const Duration(seconds: 3),
                                          ),
                                        );
                                      },
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        child: TextFont(
                                          text: "Keep all",
                                          fontSize: 11.5,
                                          fontWeight: FontWeight.w600,
                                          textColor: Theme.of(context).colorScheme.primary,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                  ],
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
                            label: firstItem.transactionPk != null
                                ? "Review"
                                : "Review & Add",
                            icon: Icons.edit_note_rounded,
                            fontSize: 13,
                            padding: const EdgeInsetsDirectional.symmetric(vertical: 10, horizontal: 10),
                            onTap: () async {
                              HapticFeedback.selectionClick();
                              dismissPendingReviewTransaction(0);

                              if (firstItem.transactionPk != null) {
                                try {
                                  Transaction tx = await database.getTransactionFromPk(firstItem.transactionPk!);
                                  pushRoute(
                                    context,
                                    AddTransactionPage(
                                      transaction: tx,
                                      routesToPopAfterDelete: RoutesToPopAfterDelete.None,
                                    ),
                                  );
                                  return;
                                } catch (e) {
                                  print("Error opening auto-recorded transaction: $e");
                                }
                              }

                              // Fallback / pending addition flow:
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
                                  selectedNotes: firstItem.note,
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
                          color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.6),
                          borderRadius: 14,
                          onTap: () {
                            HapticFeedback.lightImpact();
                            dismissPendingReviewTransaction(0);
                            openSnackbar(
                              SnackbarMessage(
                                title: "Saved Without Review",
                                description: "${firstItem.title} ($formattedAmount) kept in transactions",
                                icon: Icons.check_circle_outline_rounded,
                                timeout: const Duration(seconds: 3),
                              ),
                            );
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.check_rounded,
                                  size: 16,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                                const SizedBox(width: 4),
                                TextFont(
                                  text: "Keep",
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  textColor: getColor(context, "black"),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Tappable(
                          color: Theme.of(context).colorScheme.errorContainer.withValues(alpha: 0.45),
                          borderRadius: 14,
                          onTap: () async {
                            HapticFeedback.mediumImpact();
                            await deletePendingReviewTransaction(0);
                            openSnackbar(
                              SnackbarMessage(
                                title: "Transaction Deleted",
                                description: "Removed ${firstItem.title} ($formattedAmount)",
                                icon: Icons.delete_outline_rounded,
                                timeout: const Duration(seconds: 3),
                              ),
                            );
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                            child: Icon(
                              Icons.delete_outline_rounded,
                              size: 18,
                              color: Theme.of(context).colorScheme.error,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
