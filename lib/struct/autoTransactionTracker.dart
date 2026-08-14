import 'package:budget/main.dart';
import 'package:budget/widgets/globalSnackbar.dart';
import 'package:budget/widgets/openSnackbar.dart';
import 'package:flutter/material.dart';

class AutoAddedTransactionInfo {
  final String title;
  final double amount;
  final bool isIncome;
  final DateTime timestamp;

  AutoAddedTransactionInfo({
    required this.title,
    required this.amount,
    this.isIncome = false,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'amount': amount,
      'isIncome': isIncome,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory AutoAddedTransactionInfo.fromMap(Map<String, dynamic> map) {
    return AutoAddedTransactionInfo(
      title: map['title'] ?? '',
      amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
      isIncome: map['isIncome'] ?? false,
      timestamp: DateTime.tryParse(map['timestamp'] ?? '') ?? DateTime.now(),
    );
  }
}

final List<AutoAddedTransactionInfo> _pendingReviewTransactions = [];
final ValueNotifier<int> pendingReviewTransactionsNotifier = ValueNotifier<int>(0);

List<AutoAddedTransactionInfo> getPendingReviewTransactions() {
  return List.unmodifiable(_pendingReviewTransactions);
}

void registerAutoDetectedTransactionForReview(String title, double amount, {bool isIncome = false}) {
  _pendingReviewTransactions.add(
    AutoAddedTransactionInfo(
      title: title,
      amount: amount,
      isIncome: isIncome,
      timestamp: DateTime.now(),
    ),
  );
  pendingReviewTransactionsNotifier.value = _pendingReviewTransactions.length;
}

void dismissPendingReviewTransaction(int index) {
  if (index >= 0 && index < _pendingReviewTransactions.length) {
    _pendingReviewTransactions.removeAt(index);
    pendingReviewTransactionsNotifier.value = _pendingReviewTransactions.length;
  }
}

void clearAllPendingReviewTransactions() {
  _pendingReviewTransactions.clear();
  pendingReviewTransactionsNotifier.value = 0;
}

final List<AutoAddedTransactionInfo> _recentAutoAddedTransactions = [];

void registerAutoAddedTransaction(String title, double amount) {
  _recentAutoAddedTransactions.add(
    AutoAddedTransactionInfo(
      title: title,
      amount: amount,
      timestamp: DateTime.now(),
    ),
  );
}

void checkAndShowAutoAddedTransactionsSummary() {
  if (_recentAutoAddedTransactions.isEmpty) return;

  final count = _recentAutoAddedTransactions.length;
  final latestTitles = _recentAutoAddedTransactions
      .take(2)
      .map((e) => e.title)
      .join(", ");
  final hasMore = count > 2;

  final String description = hasMore
      ? "$latestTitles and ${count - 2} more · Tap to view"
      : "$latestTitles · Tap to view";

  _recentAutoAddedTransactions.clear();

  Future.delayed(const Duration(milliseconds: 600), () {
    openSnackbar(
      SnackbarMessage(
        title: "$count Auto-Recorded Transaction${count > 1 ? 's' : ''}",
        description: description,
        icon: Icons.auto_awesome_rounded,
        timeout: const Duration(seconds: 5),
        onTap: () {
          pageNavigationFrameworkKey.currentState?.changePage(1);
        },
      ),
    );
  });
}
