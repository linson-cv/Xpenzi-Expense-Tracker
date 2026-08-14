import 'package:budget/main.dart';
import 'package:budget/widgets/globalSnackbar.dart';
import 'package:budget/widgets/openSnackbar.dart';
import 'package:flutter/material.dart';

class AutoAddedTransactionInfo {
  final String title;
  final double amount;
  final DateTime timestamp;

  AutoAddedTransactionInfo({
    required this.title,
    required this.amount,
    required this.timestamp,
  });
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
