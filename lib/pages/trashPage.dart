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
import 'package:budget/widgets/selectedTransactionsAppBar.dart';
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
      description:
          "Permanently delete all ${items.length} items from trash? This action cannot be undone.",
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
      description:
          "Restore all ${items.length} transactions back to your accounts?",
      icon: Icons.restore_page_rounded,
      onCancelLabel: "cancel".tr(),
      onCancel: () => popRoute(context),
      onSubmitLabel: "Restore All",
      onSubmit: () async {
        int restoredCount = 0;
        for (var item in items) {
          if (item.transaction != null && item.deleteLog != null) {
            if (await database
                    .getCategoryInstanceOrNull(item.transaction!.categoryFk) !=
                null) {
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

  Future<void> _restoreSelected(
      List<String> selectedPks, List<TransactionActivityLog> allItems) async {
    openPopup(
      context,
      title: "Restore Selected?",
      description:
          "Restore ${selectedPks.length} selected ${selectedPks.length == 1 ? "transaction" : "transactions"} back to your accounts?",
      icon: Icons.restore_rounded,
      onCancelLabel: "cancel".tr(),
      onCancel: () => popRoute(context),
      onSubmitLabel: "Restore",
      onSubmit: () async {
        int restoredCount = 0;
        for (var item in allItems) {
          if (item.transaction != null &&
              item.deleteLog != null &&
              selectedPks.contains(item.transaction!.transactionPk)) {
            if (await database
                    .getCategoryInstanceOrNull(item.transaction!.categoryFk) !=
                null) {
              await database.createOrUpdateTransaction(item.transaction!);
              await database.deleteDeleteLog(item.deleteLog!.deleteLogPk);
              restoredCount++;
            }
          }
        }
        globalSelectedID.value[pageId] = [];
        globalSelectedID.notifyListeners();
        popRoute(context);
        openSnackbar(
          SnackbarMessage(
            title: "Transactions Restored",
            description:
                "Successfully restored $restoredCount ${restoredCount == 1 ? "transaction" : "transactions"}.",
            icon: Icons.restore_rounded,
          ),
        );
      },
    );
  }

  Future<void> _deleteSelectedPermanently(
      List<String> selectedPks, List<TransactionActivityLog> allItems) async {
    openPopup(
      context,
      title: "Delete Permanently?",
      description:
          "Permanently remove ${selectedPks.length} selected ${selectedPks.length == 1 ? "transaction" : "transactions"}? This cannot be undone.",
      icon: Icons.delete_forever_rounded,
      onCancelLabel: "cancel".tr(),
      onCancel: () => popRoute(context),
      onSubmitLabel: "delete".tr(),
      onSubmit: () async {
        for (var item in allItems) {
          if (item.deleteLog != null &&
              item.transaction != null &&
              selectedPks.contains(item.transaction!.transactionPk)) {
            await database.deleteDeleteLog(item.deleteLog!.deleteLogPk);
            recentlyDeletedTransactions
                .removeWhere((entry) => entry.key == item.deleteLog!.entryPk);
          }
        }
        await saveRecentlyDeletedTransactions();
        globalSelectedID.value[pageId] = [];
        globalSelectedID.notifyListeners();
        popRoute(context);
        openSnackbar(
          SnackbarMessage(
            title: "Deleted Permanently",
            description: "Selected transactions were permanently removed.",
            icon: Icons.delete_sweep_rounded,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<TransactionActivityLog>>(
      stream: database.watchAllTransactionDeleteActivityLog(limit: 500),
      builder: (context, snapshot) {
        final thirtyDaysAgo =
            DateTime.now().subtract(const Duration(days: 30));
        List<TransactionActivityLog> trashItems = (snapshot.data ?? [])
            .where((item) => item.dateTime.isAfter(thirtyDaysAgo))
            .toList()
          ..sort((a, b) => b.dateTime.compareTo(a.dateTime));

        return PageFramework(
          key: pageState,
          dragDownToDismiss: true,
          title: "Trash (30 Days)",
          listID: pageId,
          selectedTransactionsAppBar: ValueListenableBuilder(
            valueListenable: globalSelectedID,
            builder: (context, _, __) {
              List<String> selectedPks = globalSelectedID.value[pageId] ?? [];
              return SelectedTransactionsAppBar(
                pageID: pageId,
                customAction: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      tooltip: "Restore Selected",
                      icon: const Icon(Icons.restore_rounded),
                      onPressed: () =>
                          _restoreSelected(selectedPks, trashItems),
                    ),
                    IconButton(
                      tooltip: "Delete Permanently",
                      icon: Icon(
                        Icons.delete_forever_rounded,
                        color: Theme.of(context).colorScheme.error,
                      ),
                      onPressed: () =>
                          _deleteSelectedPermanently(selectedPks, trashItems),
                    ),
                  ],
                ),
              );
            },
          ),
          slivers: [
            if (snapshot.hasData == false)
              const SliverToBoxAdapter(child: SizedBox.shrink())
            else if (trashItems.isEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.only(top: 40),
                  child: Column(
                    children: [
                      Icon(
                        appStateSettings["outlinedIcons"]
                            ? Icons.delete_outline_rounded
                            : Icons.delete_rounded,
                        size: 64,
                        color: Theme.of(context)
                            .colorScheme
                            .primary
                            .withValues(alpha: 0.4),
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
                          text:
                              "Transactions deleted within the last 30 days appear here and can be restored.",
                          fontSize: 14,
                          textAlign: TextAlign.center,
                          textColor: getColor(context, "textLight"),
                          maxLines: 3,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              SliverMainAxisGroup(
                slivers: [
                  // Info header with Restore All / Empty Trash actions
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsetsDirectional.symmetric(
                        horizontal:
                            getHorizontalPaddingConstrained(context) + 14,
                        vertical: 8,
                      ),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Theme.of(context)
                              .colorScheme
                              .surfaceContainerHighest
                              .withValues(alpha: 0.5),
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
                                    text:
                                        "Items are kept for 30 days before removal.",
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

                        int daysLeft = 30 -
                            DateTime.now().difference(item.dateTime).inDays;
                        if (daysLeft < 0) daysLeft = 0;

                        Widget trashEntry = transaction != null
                            ? TransactionEntry(
                                openPage: AddTransactionPage(
                                  transaction: transaction,
                                  routesToPopAfterDelete:
                                      RoutesToPopAfterDelete.One,
                                ),
                                transaction: transaction,
                                listID: pageId,
                                allowSelect: true,
                              )
                            : Padding(
                                padding: EdgeInsetsDirectional.symmetric(
                                  horizontal:
                                      getHorizontalPaddingConstrained(context) +
                                          16,
                                  vertical: 5,
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 8.0, horizontal: 10),
                                        decoration: BoxDecoration(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .secondaryContainer
                                              .withValues(alpha: 0.2),
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                        child: TextFont(
                                          text:
                                              "transaction-no-longer-available"
                                                  .tr(),
                                          textColor:
                                              getColor(context, "textLight"),
                                          fontSize: 14,
                                          maxLines: 2,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );

                        return Column(
                          key: ValueKey(
                              (item.transaction?.transactionPk ?? "") +
                                  (item.deleteLog?.deleteLogPk ?? "")),
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            DateDivider(
                              date: transaction?.dateCreated ?? item.dateTime,
                              maxLines: 2,
                              afterDate:
                                  " • Deleted ${getTimeAgo(item.dateTime)} ($daysLeft days left)",
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
              ),
          ],
        );
      },
    );
  }
}
