import 'dart:convert';
import 'package:budget/functions.dart';
import 'package:budget/main.dart';
import 'package:budget/pages/addTransactionPage.dart';
import 'package:budget/struct/databaseGlobal.dart';
import 'package:budget/widgets/globalSnackbar.dart';
import 'package:budget/widgets/navigationFramework.dart';
import 'package:budget/widgets/openPopup.dart';
import 'package:budget/widgets/openSnackbar.dart';
import 'package:flutter/material.dart';

class AutoAddedTransactionInfo {
  final String title;
  final double amount;
  final bool isIncome;
  final DateTime timestamp;
  final String? transactionPk;
  final String? note;

  AutoAddedTransactionInfo({
    required this.title,
    required this.amount,
    this.isIncome = false,
    required this.timestamp,
    this.transactionPk,
    this.note,
  });

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'amount': amount,
      'isIncome': isIncome,
      'timestamp': timestamp.toIso8601String(),
      'transactionPk': transactionPk,
      'note': note,
    };
  }

  String get uniqueKey =>
      transactionPk != null && transactionPk!.isNotEmpty
          ? "pk_$transactionPk"
          : "${title.trim().toLowerCase()}_${amount.abs().toStringAsFixed(2)}_${timestamp.millisecondsSinceEpoch}";

  factory AutoAddedTransactionInfo.fromMap(Map<String, dynamic> map) {
    return AutoAddedTransactionInfo(
      title: map['title'] ?? '',
      amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
      isIncome: map['isIncome'] ?? false,
      timestamp: DateTime.tryParse(map['timestamp'] ?? '') ?? DateTime.now(),
      transactionPk: map['transactionPk']?.toString(),
      note: map['note']?.toString(),
    );
  }
}

final List<AutoAddedTransactionInfo> _pendingReviewTransactions = [];
final Set<String> _dismissedReviewKeys = {};
final ValueNotifier<int> pendingReviewTransactionsNotifier = ValueNotifier<int>(0);

List<AutoAddedTransactionInfo> getPendingReviewTransactions() {
  return List.unmodifiable(_pendingReviewTransactions);
}

void _recordDismissedKey(String key) {
  _dismissedReviewKeys.add(key);
  try {
    List<String> savedDismissed =
        sharedPreferences.getStringList("dismissed_review_transaction_keys") ?? [];
    if (!savedDismissed.contains(key)) {
      savedDismissed.add(key);
      if (savedDismissed.length > 100) {
        savedDismissed = savedDismissed.sublist(savedDismissed.length - 100);
      }
      sharedPreferences.setStringList(
          "dismissed_review_transaction_keys", savedDismissed);
    }
  } catch (_) {}
}

void _savePendingToPrefs() {
  try {
    List<String> list = _pendingReviewTransactions.map((e) => jsonEncode(e.toMap())).toList();
    sharedPreferences.setStringList("pending_review_transactions_json", list);
  } catch (e) {
    print("Error saving pending transactions to prefs: $e");
  }
}

Future<void> syncPendingReviewTransactionsFromPrefs() async {
  try {
    await sharedPreferences.reload();
    final List<String> savedDismissed =
        sharedPreferences.getStringList("dismissed_review_transaction_keys") ?? [];
    _dismissedReviewKeys.addAll(savedDismissed);

    List<String>? saved = sharedPreferences.getStringList("pending_review_transactions_json");
    _pendingReviewTransactions.clear();
    if (saved != null && saved.isNotEmpty) {
      bool prunedAny = false;
      for (var str in saved) {
        try {
          var map = jsonDecode(str);
          final info = AutoAddedTransactionInfo.fromMap(map);
          if (_dismissedReviewKeys.contains(info.uniqueKey)) {
            prunedAny = true;
            continue;
          }
          _pendingReviewTransactions.add(info);
        } catch (_) {}
      }
      // Show newest auto-recorded items first
      _pendingReviewTransactions.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      if (prunedAny) {
        _savePendingToPrefs();
      }
    }
    pendingReviewTransactionsNotifier.value = _pendingReviewTransactions.length;
  } catch (e) {
    print("Error syncing pending review transactions: $e");
  }
}

void registerAutoDetectedTransactionForReview(
  String title,
  double amount, {
  bool isIncome = false,
  String? transactionPk,
  String? note,
}) {
  final now = DateTime.now();
  final double absAmount = amount.abs();
  final String normTitle = title.trim().toLowerCase();

  // Deduplication check against currently pending review queue
  final bool isDuplicate = _pendingReviewTransactions.any((pending) {
    if (pending.amount.abs() != absAmount) return false;
    final pendingNorm = pending.title.trim().toLowerCase();
    final bool sameOrSimilarTitle = pendingNorm == normTitle ||
        pendingNorm.contains(normTitle) ||
        normTitle.contains(pendingNorm);
    final bool withinTimeWindow = now.difference(pending.timestamp).inMinutes.abs() <= 10;
    return sameOrSimilarTitle && withinTimeWindow;
  });

  if (isDuplicate) {
    print("[AutoTransactionTracker] Ignored duplicate review item for $title ($amount)");
    return;
  }

  final newItem = AutoAddedTransactionInfo(
    title: title,
    amount: amount,
    isIncome: isIncome,
    timestamp: now,
    transactionPk: transactionPk,
    note: note,
  );
  if (_dismissedReviewKeys.contains(newItem.uniqueKey)) return;

  // Insert at index 0 so newest item appears first
  _pendingReviewTransactions.insert(0, newItem);
  pendingReviewTransactionsNotifier.value = _pendingReviewTransactions.length;
  _savePendingToPrefs();
}

void dismissPendingReviewTransaction(int index) {
  if (index >= 0 && index < _pendingReviewTransactions.length) {
    final removed = _pendingReviewTransactions.removeAt(index);
    _recordDismissedKey(removed.uniqueKey);
    pendingReviewTransactionsNotifier.value = _pendingReviewTransactions.length;
    _savePendingToPrefs();
  }
}

Future<void> deletePendingReviewTransaction(int index) async {
  if (index >= 0 && index < _pendingReviewTransactions.length) {
    final removed = _pendingReviewTransactions.removeAt(index);
    _recordDismissedKey(removed.uniqueKey);
    pendingReviewTransactionsNotifier.value = _pendingReviewTransactions.length;
    _savePendingToPrefs();

    if (removed.transactionPk != null && removed.transactionPk!.isNotEmpty) {
      try {
        await database.deleteTransaction(removed.transactionPk!);
      } catch (e) {
        print("Error deleting dismissed auto transaction: $e");
      }
    }
  }
}

void clearAllPendingReviewTransactions() {
  for (final item in _pendingReviewTransactions) {
    _recordDismissedKey(item.uniqueKey);
  }
  _pendingReviewTransactions.clear();
  pendingReviewTransactionsNotifier.value = 0;
  _savePendingToPrefs();
}

final List<AutoAddedTransactionInfo> _recentAutoAddedTransactions = [];

void registerAutoAddedTransaction(
  String title,
  double amount, {
  bool isIncome = false,
  String? transactionPk,
  String? note,
}) {
  _recentAutoAddedTransactions.add(
    AutoAddedTransactionInfo(
      title: title,
      amount: amount,
      isIncome: isIncome,
      timestamp: DateTime.now(),
      transactionPk: transactionPk,
      note: note,
    ),
  );
}

Future<void> checkAndShowAutoAddedTransactionsSummary() async {
  // 1. Also sync pending reviews so the Home Page banner updates immediately
  syncPendingReviewTransactionsFromPrefs();

  // 2. Load any background-recorded transactions from shared preferences
  List<AutoAddedTransactionInfo> allRecent = List.from(_recentAutoAddedTransactions);
  try {
    List<String>? bgList = sharedPreferences.getStringList("recent_auto_added_transactions");
    if (bgList != null && bgList.isNotEmpty) {
      for (var str in bgList) {
        try {
          var map = jsonDecode(str);
          allRecent.add(AutoAddedTransactionInfo.fromMap(map));
        } catch (_) {}
      }
      await sharedPreferences.remove("recent_auto_added_transactions");
    }
  } catch (_) {}

  _recentAutoAddedTransactions.clear();

  if (allRecent.isEmpty) return;

  final count = allRecent.length;
  final latestTitles = allRecent
      .take(2)
      .map((e) => e.title)
      .join(", ");
  final hasMore = count > 2;

  final String description = hasMore
      ? "$latestTitles and ${count - 2} more · Tap to review"
      : "$latestTitles · Tap to review";

  Future.delayed(const Duration(milliseconds: 600), () {
    openSnackbar(
      SnackbarMessage(
        title: "$count Auto-Recorded Transaction${count > 1 ? 's' : ''}",
        description: description,
        icon: Icons.auto_awesome_rounded,
        timeout: const Duration(seconds: 6),
        onTap: () {
          if (count == 1 && allRecent.first.transactionPk != null) {
            BuildContext? ctx = navigatorKey.currentContext;
            if (ctx != null) {
              database.getTransactionFromPk(allRecent.first.transactionPk!).then((tx) {
                pushRoute(
                  ctx,
                  AddTransactionPage(
                    transaction: tx,
                    routesToPopAfterDelete: RoutesToPopAfterDelete.None,
                  ),
                );
              }).catchError((_) {
                pageNavigationFrameworkKey.currentState?.changePage(1);
              });
              return;
            }
          }
          pageNavigationFrameworkKey.currentState?.changePage(1);
        },
      ),
    );
  });
}
