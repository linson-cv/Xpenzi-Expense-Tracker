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

  AutoAddedTransactionInfo({
    required this.title,
    required this.amount,
    this.isIncome = false,
    required this.timestamp,
    this.transactionPk,
  });

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'amount': amount,
      'isIncome': isIncome,
      'timestamp': timestamp.toIso8601String(),
      'transactionPk': transactionPk,
    };
  }

  factory AutoAddedTransactionInfo.fromMap(Map<String, dynamic> map) {
    return AutoAddedTransactionInfo(
      title: map['title'] ?? '',
      amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
      isIncome: map['isIncome'] ?? false,
      timestamp: DateTime.tryParse(map['timestamp'] ?? '') ?? DateTime.now(),
      transactionPk: map['transactionPk']?.toString(),
    );
  }
}

final List<AutoAddedTransactionInfo> _pendingReviewTransactions = [];
final ValueNotifier<int> pendingReviewTransactionsNotifier = ValueNotifier<int>(0);

List<AutoAddedTransactionInfo> getPendingReviewTransactions() {
  return List.unmodifiable(_pendingReviewTransactions);
}

void _savePendingToPrefs() {
  try {
    List<String> list = _pendingReviewTransactions.map((e) => jsonEncode(e.toMap())).toList();
    sharedPreferences.setStringList("pending_review_transactions_json", list);
  } catch (e) {
    print("Error saving pending transactions to prefs: $e");
  }
}

void syncPendingReviewTransactionsFromPrefs() {
  try {
    List<String>? saved = sharedPreferences.getStringList("pending_review_transactions_json");
    if (saved != null && saved.isNotEmpty) {
      _pendingReviewTransactions.clear();
      for (var str in saved) {
        try {
          var map = jsonDecode(str);
          _pendingReviewTransactions.add(AutoAddedTransactionInfo.fromMap(map));
        } catch (_) {}
      }
      pendingReviewTransactionsNotifier.value = _pendingReviewTransactions.length;
    }
  } catch (e) {
    print("Error syncing pending review transactions: $e");
  }
}

void registerAutoDetectedTransactionForReview(
  String title,
  double amount, {
  bool isIncome = false,
  String? transactionPk,
}) {
  _pendingReviewTransactions.add(
    AutoAddedTransactionInfo(
      title: title,
      amount: amount,
      isIncome: isIncome,
      timestamp: DateTime.now(),
      transactionPk: transactionPk,
    ),
  );
  pendingReviewTransactionsNotifier.value = _pendingReviewTransactions.length;
  _savePendingToPrefs();
}

void dismissPendingReviewTransaction(int index) {
  if (index >= 0 && index < _pendingReviewTransactions.length) {
    _pendingReviewTransactions.removeAt(index);
    pendingReviewTransactionsNotifier.value = _pendingReviewTransactions.length;
    _savePendingToPrefs();
  }
}

void clearAllPendingReviewTransactions() {
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
}) {
  _recentAutoAddedTransactions.add(
    AutoAddedTransactionInfo(
      title: title,
      amount: amount,
      isIncome: isIncome,
      timestamp: DateTime.now(),
      transactionPk: transactionPk,
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
