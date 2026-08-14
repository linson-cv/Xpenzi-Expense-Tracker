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

  // 1. Promotional and Marketing Message Filter
  // Ignore shopping spam, discount alerts, coupon codes, and marketing pushes
  RegExp promotionalKeywords = RegExp(
    r'\b(off\b|discount|deal|offer|sale\b|cashback up to|win|won|gift|coupon|promo|voucher|exclusive|free\b|save up to|flat ₹|flat rs|use code|code:|ends soon|hurry|order now|explore)\b',
    caseSensitive: false,
  );
  if (promotionalKeywords.hasMatch(text)) {
    // Only proceed if it is definitively an actual completed payment transaction alert
    bool isDefinitiveTransaction = text.toLowerCase().contains("debited") ||
        text.toLowerCase().contains("credited") ||
        text.toLowerCase().contains("paid to") ||
        text.toLowerCase().contains("spent on") ||
        text.toLowerCase().contains("sent to");
    if (!isDefinitiveTransaction) return null;
  }

  // Strict Transaction Verification: Must contain at least one real transaction keyword
  RegExp transactionVerification = RegExp(
    r'\b(debited|credited|paid|spent|sent|received|transferred|withdrawn|deposited|refunded|a/c|vpa|txn|ref no|upi ref)\b',
    caseSensitive: false,
  );
  if (!transactionVerification.hasMatch(text)) {
    return null;
  }

  // 2. Amount Extraction
  double? amount;
  // Supports global currencies: $, €, £, ¥, ₹, ₩, ₺, ₱, ฿, ₫, ₴, R$, CHF, CAD, AUD, USD, EUR, GBP, INR, etc.
  RegExp amountRegex = RegExp(
    r'(?:[\$\€\£\¥\₹\₩\₺\₱\฿\₫\₴]|usd|eur|gbp|inr|cad|aud|chf|jpy|cny|rs\.?|debited\s+by|debited\s+for|debit\s+of|debit\s+by|debit\s+for|debit|credited\s+with|credited\s+by|credited\s+for|credit\s+of|credit\s+by|credit\s+for|credit|paid|spent|amount)\s*:?\s*([0-9]+(?:,[0-9]{3})*(?:\.[0-9]{1,2})?)',
    caseSensitive: false,
  );

  var amountMatch = amountRegex.firstMatch(text);
  if (amountMatch != null && amountMatch.group(1) != null) {
    String cleanAmountStr = amountMatch.group(1)!.replaceAll(',', '');
    amount = double.tryParse(cleanAmountStr);
  }

  // Fallback amount regex for any standalone currency symbol or code
  if (amount == null) {
    RegExp fallbackAmountRegex = RegExp(r'(?:[\$\€\£\¥\₹\₩\₺\₱\฿\₫\₴]|usd|eur|gbp|inr|cad|aud|chf|jpy|rs\.?)\s*([0-9]+(?:\.[0-9]{1,2})?)', caseSensitive: false);
    var fallbackMatch = fallbackAmountRegex.firstMatch(text);
    if (fallbackMatch != null && fallbackMatch.group(1) != null) {
      amount = double.tryParse(fallbackMatch.group(1)!);
    }
  }

  // Fallback for "debit/credit/debited/credited by/of <amount>" or direct number following debit/credit
  if (amount == null) {
    RegExp debitCreditRegex = RegExp(r'(?:debited|credited|debit|credit)\s+(?:by|of|for)?\s*:?\s*([0-9]+(?:\.[0-9]{1,2})?)', caseSensitive: false);
    var match = debitCreditRegex.firstMatch(text);
    if (match != null && match.group(1) != null) {
      amount = double.tryParse(match.group(1)!);
    }
  }

  if (amount == null || amount <= 0) return null;

  // 3. Transaction Type (Income vs Expense)
  bool isIncome = false;
  // If scheduled/mandate reminder without actual debit, ignore or treat as expense if debit
  RegExp incomeKeywords = RegExp(
    r'\b(credited|received|added to your|deposited|refund|cashback|salary)\b',
    caseSensitive: false,
  );
  if (incomeKeywords.hasMatch(text)) {
    isIncome = true;
  }

  // 4. Merchant / Payee Title Extraction
  String title = "Transaction";

  // Check for specialized bank SMS patterns
  // Pattern A: "by <MERCHANT>, INFO: ..." or "by <MERCHANT>"
  RegExp byMerchantRegex = RegExp(r'\bby\s+([A-Za-z0-9\s&\.\-\@]+?)(?=,\s*INFO|\s+INFO|//|\.|$)', caseSensitive: false);
  // Pattern B: "trf to <PAYEE> Refno" or "transfer to <PAYEE>"
  RegExp trfToRegex = RegExp(r'\b(?:trf to|transfer to|transferred to)\s+([A-Za-z0-9\s&\.\-\@]+?)(?=\s+(?:Refno|Ref|on|via|using|If not)|\.|$)', caseSensitive: false);
  // Pattern C: "AutoPay for <MERCHANT> SIP" or "AutoPay for <MERCHANT>"
  RegExp autoPayRegex = RegExp(r'\b(?:AutoPay for|mandate for|autopay to)\s+([A-Za-z0-9\s&\.\-\@]+?)(?=\s+(?:debit|credit|scheduled|is scheduled)|\.|$)', caseSensitive: false);
  // Pattern D: Standard "at/to/vpa/for/towards <PAYEE>"
  RegExp payeeRegex = RegExp(
    r'(?:at|to|vpa|info|for|towards)\s+([A-Za-z0-9\s&\.\-\@]+?)(?=\s+(?:on|ref|using|via|a/c|card|bal|avbl|date|val)|\.|$)',
    caseSensitive: false,
  );

  var match = trfToRegex.firstMatch(text) ??
      byMerchantRegex.firstMatch(text) ??
      autoPayRegex.firstMatch(text) ??
      payeeRegex.firstMatch(text);

  if (match != null && match.group(1) != null) {
    String extractedTitle = match.group(1)!.trim();
    // Clean trailing punctuation or noise
    extractedTitle = extractedTitle.replaceAll(RegExp(r'[\/\,\.]+$'), '').trim();
    if (extractedTitle.length > 2 && extractedTitle.length < 50) {
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

      // First check if any wallet name is explicitly mentioned in the text
      for (var w in wallets) {
        if (textLower.contains(w.name.toLowerCase())) {
          matchedWallet = w;
          break;
        }
      }

      // If no exact wallet name matched, distinguish between Credit Card and Regular Bank
      if (matchedWallet == null && wallets.isNotEmpty) {
        bool isCreditCard = textLower.contains("credit card") ||
            (textLower.contains("card") && (textLower.contains("debited") || textLower.contains("spent"))) ||
            textLower.contains("spent on card") ||
            textLower.contains("card ending");

        if (isCreditCard) {
          // Find a credit card wallet if available
          matchedWallet = wallets.where((w) {
            String name = w.name.toLowerCase();
            return name.contains("credit") || name.contains("card");
          }).firstOrNull;
        } else if (textLower.contains("debited") ||
            textLower.contains("credited") ||
            textLower.contains("a/c") ||
            textLower.contains("account") ||
            textLower.contains("bank") ||
            textLower.contains("upi")) {
          // Other credited or debited messages are for regular bank accounts
          matchedWallet = wallets.where((w) {
            String name = w.name.toLowerCase();
            return !name.contains("credit") && (name.contains("bank") || name.contains("saving") || name.contains("current") || name.contains("primary") || name.contains("account"));
          }).firstOrNull ?? wallets.where((w) {
            String name = w.name.toLowerCase();
            return !name.contains("credit") && !name.contains("card");
          }).firstOrNull;
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
