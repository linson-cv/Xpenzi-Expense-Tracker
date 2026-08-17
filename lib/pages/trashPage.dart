import 'package:budget/colors.dart';
import 'package:budget/database/tables.dart' hide AppSettings;
import 'package:budget/pages/activityPage.dart';
import 'package:budget/pages/addTransactionPage.dart';
import 'package:budget/struct/databaseGlobal.dart';
import 'package:budget/struct/settings.dart';
import 'package:budget/widgets/dateDivider.dart';
import 'package:budget/widgets/framework/pageFramework.dart';
import 'package:budget/widgets/globalSnackbar.dart';
import 'package:budget/widgets/openBottomSheet.dart';
import 'package:budget/widgets/openPopup.dart';
import 'package:budget/widgets/openSnackbar.dart';
import 'package:budget/widgets/tappable.dart';
import 'package:budget/widgets/textWidgets.dart';
import 'package:budget/widgets/transactionEntry/transactionEntry.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:budget/functions.dart';

class TrashPage extends StatefulWidget {
  const TrashPage({super.key});

  @override
  State<TrashPage> createState() => _TrashPageState();
}

class _TrashPageState extends State<TrashPage> {
  GlobalKey<PageFrameworkState> pageState = GlobalKey();
  String pageId = "TrashPage";

  Future<void> _emptyTrash(List<TransactionActivityLog> items) async {
    openPopup(
      context,
      title: "Empty Trash?",
      description: "Permanently delete all ${items.length} items from trash? This action cannot be undone.",
      icon: Icons.delete_forever_rounded,
      onCancelLabel: "cancel".tr(),
      onCancel: () => popRoute(context),
      onSubmitLabel: "delete".tr(),
      onSubmit: () async {
        for (var item in items) {
          if (item.deleteLog != null) {
            await database.deleteDeleteLog(item.deleteLog!.deleteLogPk);
            recentlyDeletedTransactions
                .removeWhere((entry) => entry.key == item.deleteLog!.entryPk);
          }
        }
        await saveRecentlyDeletedTransactions();
        popRoute(context);
        openSnackbar(
          SnackbarMessage(
            title: "Trash Emptied",
            description: "All deleted transactions were permanently removed.",
            icon: Icons.delete_sweep_rounded,
          ),
        );
      },
    );
  }

  Future<void> _restoreAll(List<TransactionActivityLog> items) async {
    openPopup(
      context,
      title: "Restore All?",
      description: "Restore all ${items.length} transactions back to your accounts?",
      icon: Icons.restore_page_rounded,
      onCancelLabel: "cancel".tr(),
      onCancel: () => popRoute(context),
      onSubmitLabel: "Restore All",
      onSubmit: () async {
        int restoredCount = 0;
        for (var item in items) {
          if (item.transaction != null && item.deleteLog != null) {
            if (await database.getCategoryInstanceOrNull(item.transaction!.categoryFk) != null) {
              await database.createOrUpdateTransaction(item.transaction!);
              await database.deleteDeleteLog(item.deleteLog!.deleteLogPk);
              restoredCount++;
            }
          }
        }
        popRoute(context);
        openSnackbar(
          SnackbarMessage(
            title: "Transactions Restored",
            description: "Successfully restored $restoredCount transactions.",
            icon: Icons.restore_rounded,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return PageFramework(
      key: pageState,
      dragDownToDismiss: true,
      title: "Trash (30 Days)",
      listID: pageId,
      slivers: [
        StreamBuilder<List<TransactionActivityLog>>(
          stream: database.watchAllTransactionDeleteActivityLog(limit: 500),
          builder: (context, snapshot) {
            if (snapshot.hasData == false) {
              return const SliverToBoxAdapter(child: SizedBox.shrink());
            }

            final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
            List<TransactionActivityLog> trashItems = (snapshot.data ?? [])
                .where((item) => item.dateTime.isAfter(thirtyDaysAgo))
                .toList()
              ..sort((a, b) => b.dateTime.compareTo(a.dateTime));

            if (trashItems.isEmpty) {
              return SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.only(top: 40),
                  child: Column(
                    children: [
                      Icon(
                        appStateSettings["outlinedIcons"]
                            ? Icons.delete_outline_rounded
                            : Icons.delete_rounded,
                        size: 64,
                        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.4),
                      ),
                      const SizedBox(height: 12),
                      const TextFont(
                        text: "Trash is Empty",
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                      const SizedBox(height: 6),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32),
                        child: TextFont(
                          text: "Transactions deleted within the last 30 days appear here and can be restored.",
                          fontSize: 14,
                          textAlign: TextAlign.center,
                          textColor: getColor(context, "textLight"),
                          maxLines: 3,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            return SliverMainAxisGroup(
              slivers: [
                // Info header with Restore All / Empty Trash actions
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsetsDirectional.symmetric(
                      horizontal: getHorizontalPaddingConstrained(context) + 14,
                      vertical: 8,
                    ),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.auto_delete_outlined,
                            size: 22,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                TextFont(
                                  text: "${trashItems.length} Deleted Items",
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                                TextFont(
                                  text: "Items are kept for 30 days before removal.",
                                  fontSize: 12,
                                  textColor: getColor(context, "textLight"),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            tooltip: "Restore All",
                            icon: const Icon(Icons.restore_rounded, size: 22),
                            onPressed: () => _restoreAll(trashItems),
                          ),
                          IconButton(
                            tooltip: "Empty Trash",
                            icon: Icon(
                              Icons.delete_sweep_rounded,
                              size: 22,
                              color: Theme.of(context).colorScheme.error,
                            ),
                            onPressed: () => _emptyTrash(trashItems),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    childCount: trashItems.length,
                    (BuildContext context, int index) {
                      TransactionActivityLog item = trashItems[index];
                      Transaction? transaction = item.transaction;

                      int daysLeft = 30 - DateTime.now().difference(item.dateTime).inDays;
                      if (daysLeft < 0) daysLeft = 0;

                      Widget trashEntry = transaction != null
                          ? Tappable(
                              color: Colors.transparent,
                              onTap: () {
                                if (item.deleteLog != null && item.transaction != null) {
                                  restoreTransaction(
                                    context,
                                    item.deleteLog!,
                                    item.transaction!,
                                  );
                                }
                              },
                              child: TransactionEntry(
                                openPage: AddTransactionPage(
                                  transaction: transaction,
                                  routesToPopAfterDelete: RoutesToPopAfterDelete.One,
                                ),
                                transaction: transaction,
                                listID: pageId,
                              ),
                            )
                          : Padding(
                              padding: EdgeInsetsDirectional.symmetric(
                                horizontal: getHorizontalPaddingConstrained(context) + 16,
                                vertical: 5,
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 10),
                                      decoration: BoxDecoration(
                                        color: Theme.of(context).colorScheme.secondaryContainer.withValues(alpha: 0.2),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: TextFont(
                                        text: "transaction-no-longer-available".tr(),
                                        textColor: getColor(context, "textLight"),
                                        fontSize: 14,
                                        maxLines: 2,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );

                      return Column(
                        key: ValueKey((item.transaction?.transactionPk ?? "") +
                            (item.deleteLog?.deleteLogPk ?? "")),
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          DateDivider(
                            date: transaction?.dateCreated ?? item.dateTime,
                            maxLines: 2,
                            afterDate: " • Deleted ${getTimeAgo(item.dateTime)} ($daysLeft days left)",
                          ),
                          trashEntry,
                        ],
                      );
                    },
                  ),
                ),
                const SliverToBoxAdapter(
                  child: SizedBox(height: 75),
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}
