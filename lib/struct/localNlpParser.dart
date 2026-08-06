import 'package:budget/database/tables.dart';
import 'package:budget/struct/databaseGlobal.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class LocalNlpParsedTransaction {
  final String title;
  final double amount;
  final bool income;
  final TransactionCategory? category;
  final TransactionWallet? wallet;

  LocalNlpParsedTransaction({
    required this.title,
    required this.amount,
    required this.income,
    this.category,
    this.wallet,
  });
}

Future<LocalNlpParsedTransaction?> parseTransactionFromNotificationText(
    String input, BuildContext? context) async {
  if (input.trim().isEmpty) return null;
  String text = input.replaceAll("\n", " ");

  // 1. Amount Extraction
  double? amount;
  RegExp amountRegex = RegExp(
    r'(?:rs\.?|inr|₹|debited by|credited with|paid|spent|amount)\s*:?\s*([0-9]+(?:,[0-9]{3})*(?:\.[0-9]{1,2})?)',
    caseSensitive: false,
  );

  var amountMatch = amountRegex.firstMatch(text);
  if (amountMatch != null && amountMatch.group(1) != null) {
    String cleanAmountStr = amountMatch.group(1)!.replaceAll(',', '');
    amount = double.tryParse(cleanAmountStr);
  }

  // Fallback amount regex for any standalone currency formatted number
  if (amount == null) {
    RegExp fallbackAmountRegex = RegExp(r'₹\s*([0-9]+(?:\.[0-9]{1,2})?)');
    var fallbackMatch = fallbackAmountRegex.firstMatch(text);
    if (fallbackMatch != null && fallbackMatch.group(1) != null) {
      amount = double.tryParse(fallbackMatch.group(1)!);
    }
  }

  if (amount == null || amount <= 0) return null;

  // 2. Transaction Type (Income vs Expense)
  bool isIncome = false;
  RegExp incomeKeywords = RegExp(
    r'\b(credited|received|added|deposited|refund|cashback|salary)\b',
    caseSensitive: false,
  );
  if (incomeKeywords.hasMatch(text)) {
    isIncome = true;
  }

  // 3. Merchant / Payee Title Extraction
  String title = "Transaction";
  RegExp payeeRegex = RegExp(
    r'(?:at|to|vpa|info|for|towards)\s+([A-Za-z0-9\s&\.\-\@]+?)(?=\s+(?:on|ref|using|via|a/c|card|bal|avbl|date|val)|\.|$)',
    caseSensitive: false,
  );
  var payeeMatch = payeeRegex.firstMatch(text);
  if (payeeMatch != null && payeeMatch.group(1) != null) {
    String extractedTitle = payeeMatch.group(1)!.trim();
    if (extractedTitle.length > 2 && extractedTitle.length < 35) {
      title = extractedTitle;
    }
  }

  // Fallback title from package or notification sender if default
  if (title == "Transaction") {
    RegExp altTitleRegex = RegExp(r'notification title:\s*([^\n\r]+)', caseSensitive: false);
    var altMatch = altTitleRegex.firstMatch(input);
    if (altMatch != null && altMatch.group(1) != null) {
      title = altMatch.group(1)!.trim();
    }
  }

  // 4. Category Matching
  TransactionCategory? matchedCategory;
  try {
    List<TransactionCategory> allCategories = await database.getAllCategories();
    String titleLower = title.toLowerCase();

    for (var cat in allCategories) {
      String catLower = cat.name.toLowerCase();
      if (titleLower.contains(catLower) || catLower.contains(titleLower)) {
        matchedCategory = cat;
        break;
      }
    }

    // Match keywords like swiggy/zomato -> Food, uber/ola -> Transport
    if (matchedCategory == null) {
      if (titleLower.contains("swiggy") ||
          titleLower.contains("zomato") ||
          titleLower.contains("starbucks") ||
          titleLower.contains("restaurant") ||
          titleLower.contains("diner")) {
        matchedCategory = allCategories
            .where((c) => c.name.toLowerCase().contains("food"))
            .firstOrNull;
      } else if (titleLower.contains("uber") ||
          titleLower.contains("ola") ||
          titleLower.contains("rapido") ||
          titleLower.contains("fuel") ||
          titleLower.contains("petrol")) {
        matchedCategory = allCategories
            .where((c) =>
                c.name.toLowerCase().contains("transport") ||
                c.name.toLowerCase().contains("travel"))
            .firstOrNull;
      } else if (titleLower.contains("amazon") ||
          titleLower.contains("flipkart") ||
          titleLower.contains("myntra")) {
        matchedCategory = allCategories
            .where((c) => c.name.toLowerCase().contains("shopping"))
            .firstOrNull;
      }
    }
  } catch (_) {}

  // 5. Account / Wallet Matching
  TransactionWallet? matchedWallet;
  if (context != null) {
    try {
      List<TransactionWallet> wallets =
          Provider.of<AllWallets>(context, listen: false).list;
      String textLower = text.toLowerCase();
      for (var w in wallets) {
        if (textLower.contains(w.name.toLowerCase())) {
          matchedWallet = w;
          break;
        }
      }
    } catch (_) {}
  }

  return LocalNlpParsedTransaction(
    title: title,
    amount: amount,
    income: isIncome,
    category: matchedCategory,
    wallet: matchedWallet,
  );
}
