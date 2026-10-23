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

/// Helper to detect payment reminders, bill generation alerts, due-date notices,
/// and scheduled pre-debit notifications before any actual money has been transferred.
bool isPaymentReminderOrPendingNotice(String text) {
  String lower = text.toLowerCase();

  // Explicit confirmation phrases that verify money has ALREADY been debited or transferred.
  // If present, it is a completed payment, NOT just a reminder.
  final RegExp completedDebitConfirmation = RegExp(
    r'\b(has been debited|was debited|debited by|debited for|debited from|debited with|successfully debited|payment successful|paid successfully|sent successfully|transferred successfully|txn successful|spent on card|withdrawn from)\b',
    caseSensitive: false,
  );

  // Future-tense or non-debited alert indicators that signify reminders or pending dues.
  final RegExp reminderKeywords = RegExp(
    r'\b(reminder|bill reminder|payment reminder|due on|is due|due date|due by|pay before|pay now|to avoid late fee|avoid late payment|to avoid disconnection|to avoid service interruption|upcoming debit|will be debited|is scheduled to be debited|scheduled to be debited|is scheduled on|scheduled on|scheduled for|standing instruction|ensure sufficient balance|maintain sufficient balance|maintain balance|keep sufficient balance|outstanding amount|total amount due|min amount due|minimum amount due|total due|min due|minimum due|bill generated|e-bill generated|bill for rs|invoice generated)\b',
    caseSensitive: false,
  );

  // If text contains reminder/pre-debit keywords:
  if (reminderKeywords.hasMatch(lower)) {
    // If it also contains an explicit completed debit confirmation, verify it isn't negated by "will be"
    if (completedDebitConfirmation.hasMatch(lower)) {
      // If it says "will be debited", "scheduled to be debited", or "is due", it's still future/reminder
      if (lower.contains("will be") || lower.contains("scheduled to") || lower.contains("is due") || lower.contains("due on")) {
        return true;
      }
      // Otherwise confirmed completed transaction
      return false;
    }
    return true;
  }

  return false;
}

/// Helper to detect promotional, marketing, rewards, loans, and coupon messages
/// that are NOT actual completed financial transactions.
bool isPromotionalOrMarketingNotification(String text) {
  String lower = text.toLowerCase();

  // 1. Unconditional promotional & spam indicators:
  // These calls-to-action or marketing terms are NEVER part of legitimate bank debit/credit transactional alerts
  final RegExp unconditionalPromoKeywords = RegExp(
    r'\b(welcome rewards|welcome offer|apply now|get flex|rewards with flex|eligible for|pre-approved|instant loan|personal loan|apply for credit|claim reward|claim your|claim now|earn\s+[\$\₹\£\€]?\s*[0-9]+|earn\s+.*welcome|congratulations|unlock rewards|exclusive offer|limited period offer|flat\s*₹|flat\s*rs|use code|use promo|save flat|discount of|cashback up to|win up to|save up to|zero fee credit card|zero-fee|zero fee|scratch card|hurry\b|ends soon|order now|shop now|spin and win|refer and earn)\b',
    caseSensitive: false,
  );

  if (unconditionalPromoKeywords.hasMatch(lower)) {
    return true;
  }

  // 2. Loan offers / limit increment marketing disguised with "credited"
  final RegExp fakeCreditMarketing = RegExp(
    r'\b(loan.*credited|limit increased|credit limit of|approved for loan|sanctioned loan|recharge now to get|avail loan)\b',
    caseSensitive: false,
  );
  if (fakeCreditMarketing.hasMatch(lower)) {
    return true;
  }

  // 3. Strict phrases that prove real money transfer has occurred
  final RegExp completedDebitConfirmation = RegExp(
    r'\b(has been debited|was debited|debited by|debited for|debited from|debited with|debited\b|successfully debited|payment successful|paid successfully|sent successfully|transferred successfully|txn successful|spent on card|withdrawn from|deposited in|deposited to|credited to your|credited with|salary credited)\b',
    caseSensitive: false,
  );

  if (completedDebitConfirmation.hasMatch(lower)) {
    return false;
  }

  return false;
}

Future<LocalNlpParsedTransaction?> parseTransactionFromNotificationText(
    String input, BuildContext? context) async {
  if (input.trim().isEmpty) return null;
  String text = input.replaceAll("\n", " ");

  // 1. Payment Reminder & Scheduled Pre-Debit Filter
  // Prevents bill reminders, due-date notices, and scheduled autopay warnings from being recorded as expenses
  if (isPaymentReminderOrPendingNotice(text)) {
    print("[LocalNLP] Ignored message: Detected payment reminder or scheduled bill notice without actual debit.");
    return null;
  }

  // 1b. Promotional, Marketing, and Rewards Filter
  // Prevents promotional reward banners (e.g., GPay "Earn ₹1,000 welcome rewards with Flex") from being recorded
  if (isPromotionalOrMarketingNotification(text)) {
    print("[LocalNLP] Ignored message: Detected promotional or marketing rewards offer.");
    return null;
  }

  // 2. Additional Promotional and Marketing Message Filter
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
    r'\b(debited|credited|debit|credit|paid|spent|sent|received|transferred|withdrawn|deposited|refunded|a/c|acct|vpa|txn|ref\s*no|upi\s*ref|imps|neft|rtgs|nach|pos\b|atm\b|autopay|mandate|purchase|charged|pagado|abonado|gasto|compra|pago|retirada|charge\b|prelevement|virement|paiement|retrait|abgebucht|gutgeschrieben|zahlung|ausgabe|bonifico|addebitato|accreditato|spesa|pagamento)\b',
    caseSensitive: false,
  );
  if (!transactionVerification.hasMatch(text)) {
    return null;
  }

  // 2. Amount Extraction
  // Comprehensive currency matching across North America, Europe, UK, Asia, LatAm, Africa, Middle East, Oceania:
  // Symbols: $, €, £, ¥, ₹, ₩, ₺, ₱, ฿, ₫, ₴, ₦, ₵, ₸, ₲, ֏, ؋, ৳, ៛, ₭, ₮, ₨, ₢, ₡, ₰, ₳, ₶, ₷, ₻, ₼, ₽, ₾
  // Codes: USD, EUR, GBP, CAD, AUD, JPY, CNY, INR, CHF, BRL, MXN, SGD, HKD, NZD, SEK, NOK, DKK, PLN, TRY, AED, SAR, ZAR, MYR, IDR, PHP, THB, VND, NGN, KES, EGP, etc.
  double? amount;

  const String globalCurrencies =
      r'(?:[\$\€\£\¥\₹\₩\₺\₱\฿\₫\₴\₦\₵\₸\₲\֏\؋\৳\៛\₭\₮\₨\₽\₾]|usd|eur|gbp|inr|cad|aud|chf|jpy|cny|rs\.?|brl|mxn|sgd|hkd|nzd|sek|nok|dkk|pln|try|aed|sar|zar|myr|idr|php|thb|vnd|ngn|kes|egp|ils|clp|cop|pen|czk|huf|ron|bgn|kwd|bhd|omr|qgt)';

  // Pattern A: Currency or transactional verb followed by amount (e.g. "$125.50", "EUR 45,99", "debited: 300.00")
  RegExp amountRegex = RegExp(
    '(?:$globalCurrencies|debited\\s+(?:by|for|of)?|debit\\s+(?:by|for|of)?|credited\\s+(?:by|for|of|with)?|credit\\s+(?:by|for|of)?|paid|spent|amount)\\s*:?\\s*([0-9]{1,3}(?:[.,][0-9]{3})*(?:[.,][0-9]{1,2})|[0-9]+(?:[.,][0-9]{1,2})?)',
    caseSensitive: false,
  );

  double? parseAmountString(String rawStr) {
    String s = rawStr.trim();
    // Handle European comma decimals (e.g. "1.250,50" -> 1250.50, or "45,99" -> 45.99)
    if (s.contains(",") && s.contains(".")) {
      if (s.lastIndexOf(",") > s.lastIndexOf(".")) {
        // Dot is thousand separator, comma is decimal (1.250,50)
        s = s.replaceAll('.', '').replaceAll(',', '.');
      } else {
        // Comma is thousand separator, dot is decimal (1,250.50)
        s = s.replaceAll(',', '');
      }
    } else if (s.contains(",")) {
      // Single comma: if followed by exactly 1 or 2 digits, likely decimal (e.g. "45,99")
      if (RegExp(r',\d{1,2}$').hasMatch(s)) {
        s = s.replaceAll(',', '.');
      } else {
        s = s.replaceAll(',', '');
      }
    }
    return double.tryParse(s);
  }

  var amountMatch = amountRegex.firstMatch(text);
  if (amountMatch != null && amountMatch.group(1) != null) {
    amount = parseAmountString(amountMatch.group(1)!);
  }

  // Fallback A: Standalone currency followed immediately by number
  if (amount == null) {
    RegExp fallbackAmountRegex = RegExp(
      '$globalCurrencies\\s*([0-9]{1,3}(?:[.,][0-9]{3})*(?:[.,][0-9]{1,2})|[0-9]+(?:[.,][0-9]{1,2})?)',
      caseSensitive: false,
    );
    var fallbackMatch = fallbackAmountRegex.firstMatch(text);
    if (fallbackMatch != null && fallbackMatch.group(1) != null) {
      amount = parseAmountString(fallbackMatch.group(1)!);
    }
  }

  // Fallback B: Number followed by currency or action keyword (e.g. "50.00 USD spent", "120 € debited")
  if (amount == null) {
    RegExp numberBeforeKeywordRegex = RegExp(
      '([0-9]{1,3}(?:[.,][0-9]{3})*(?:[.,][0-9]{1,2})|[0-9]+(?:[.,][0-9]{1,2})?)\\s*(?:$globalCurrencies|debited|credited|paid|spent)',
      caseSensitive: false,
    );
    var match = numberBeforeKeywordRegex.firstMatch(text);
    if (match != null && match.group(1) != null) {
      amount = parseAmountString(match.group(1)!);
    }
  }

  // Fallback C: Direct debit/credit followed by number anywhere
  if (amount == null) {
    RegExp debitCreditRegex = RegExp(
      r'(?:debited|credited|debit|credit)\s+(?:by|of|for)?\s*:?\s*([0-9]+(?:[.,][0-9]{1,2})?)',
      caseSensitive: false,
    );
    var match = debitCreditRegex.firstMatch(text);
    if (match != null && match.group(1) != null) {
      amount = parseAmountString(match.group(1)!);
    }
  }

  if (amount == null || amount <= 0) return null;

  // 3. Transaction Type (Income vs Expense Decision)
  // When BOTH "debited" and "credited" exist in the message:
  // Banks (ICICI, HDFC, SBI, Axis, etc.) frequently send messages like:
  // - "Acct XX322 debited for Rs 330.00 on 17-Sep-26; LOKESH S credited. UPI:..."
  // - "INR 500.00 debited from a/c ... towards ... credited to merchant"
  // Here the user's primary account was DEBITED (Expense), and the third-party payee was CREDITED.
  //
  // Conversely, reversed transactions or incoming transfers state:
  // - "Your a/c XX123 is credited with Rs 500 debited from Sender"
  // Here the user's primary account was CREDITED (Income).

  String lowerText = text.toLowerCase();
  bool hasDebit = RegExp(r'\b(debited|debit|withdrawn|spent|paid|charged|purchase|sent)\b', caseSensitive: false).hasMatch(lowerText);
  bool hasCredit = RegExp(r'\b(credited|credit|deposited|refund|refunded|cashback|salary|received)\b', caseSensitive: false).hasMatch(lowerText);

  bool isIncome = false;
  String? extractedPayeeFromDualPattern;

  if (hasDebit && hasCredit) {
    // Both are present! Determine which action applies to the user's account vs the counterparty.
    int userAcctIndex = lowerText.indexOf(RegExp(r'\b(your a/c|acct|a/c|account|card ending|card)\b'));
    int debitIndex = lowerText.indexOf(RegExp(r'\b(debited|debit|spent|paid)\b'));
    int creditIndex = lowerText.indexOf(RegExp(r'\b(credited|credit|deposited|received)\b'));

    // Check specific structural syntax:
    // Case 1: "debited for ... ; <PAYEE> credited" or "debited ... credited to <PAYEE>" -> User is debited!
    RegExp userDebitedOtherCredited = RegExp(
      r'(?:debited|paid|spent).+?(?:;\s*([A-Za-z0-9\s&\.\-\@]+?)\s+credited|credited to\s+([A-Za-z0-9\s&\.\-\@]+?))',
      caseSensitive: false,
    );
    var dualMatch = userDebitedOtherCredited.firstMatch(text);
    if (dualMatch != null) {
      isIncome = false; // Expense
      extractedPayeeFromDualPattern = (dualMatch.group(1) ?? dualMatch.group(2))?.trim();
    } else {
      // Case 2: "credited with ... debited from <PAYER>" -> User is credited!
      RegExp userCreditedOtherDebited = RegExp(
        r'(?:credited|deposited|received).+?(?:debited from\s+([A-Za-z0-9\s&\.\-\@]+?)|from\s+([A-Za-z0-9\s&\.\-\@]+?))',
        caseSensitive: false,
      );
      var dualCreditMatch = userCreditedOtherDebited.firstMatch(text);
      if (dualCreditMatch != null) {
        isIncome = true; // Income
        extractedPayeeFromDualPattern = (dualCreditMatch.group(1) ?? dualCreditMatch.group(2))?.trim();
      } else {
        // Fallback positioning: which action is associated with the user's account identifier?
        if (userAcctIndex != -1) {
          int distToDebit = (userAcctIndex - debitIndex).abs();
          int distToCredit = (userAcctIndex - creditIndex).abs();
          isIncome = distToCredit < distToDebit;
        } else {
          // If no account identifier, debit action takes precedence in standard payment receipts
          isIncome = false;
        }
      }
    }
  } else if (hasCredit) {
    // Only credit terms exist:
    // Validate that it's real credit to user's account
    bool explicitUserCredit = RegExp(
      r'\b(credited to your|credited to a/c|credited to acct|deposited in|refund|refunded|cashback|salary|received in your|received from|added to your)\b',
      caseSensitive: false,
    ).hasMatch(lowerText);

    if (explicitUserCredit || !hasDebit) {
      isIncome = true;
    }
  } else if (hasDebit) {
    // Only debit terms exist:
    isIncome = false;
  }

  // 4. Merchant / Payee Title Extraction
  String title = "Transaction";

  if (extractedPayeeFromDualPattern != null && extractedPayeeFromDualPattern.isNotEmpty) {
    title = extractedPayeeFromDualPattern;
  } else {
    // Check for specialized bank SMS patterns
    // Pattern 0: Bank debit where recipient is credited: "; <RECIPIENT> credited" (e.g. ICICI UPI alert)
    RegExp recipientCreditedRegex = RegExp(
      r';\s*([A-Za-z0-9\s&\.\-\@]+?)\s+credited\b',
      caseSensitive: false,
    );
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
    // Pattern E: Incoming transfer "from <SENDER>"
    RegExp fromSenderRegex = RegExp(
      r'\b(?:from)\s+([A-Za-z0-9\s&\.\-\@]+?)(?=\s+(?:on|ref|using|via|a/c|card|bal|avbl|date|val)|\.|$)',
      caseSensitive: false,
    );

    var match = recipientCreditedRegex.firstMatch(text) ??
        trfToRegex.firstMatch(text) ??
        byMerchantRegex.firstMatch(text) ??
        autoPayRegex.firstMatch(text) ??
        (isIncome ? fromSenderRegex.firstMatch(text) : null) ??
        payeeRegex.firstMatch(text);

    if (match != null && match.group(1) != null) {
      title = match.group(1)!.trim();
    }
  }

  // Clean trailing punctuation, UPI handle noise, or metadata words
  title = title.replaceAll(RegExp(r'[\/\,\.;]+$'), '').trim();
  // Strip UPI handle suffix if present (e.g. "lokesh.s@okhdfcbank" -> "lokesh.s" -> "Lokesh S")
  if (title.contains("@")) {
    int atIdx = title.indexOf("@");
    if (atIdx > 2) {
      title = title.substring(0, atIdx).trim();
    }
  }
  // Replace dots/underscores often used in handles with spaces
  title = title.replaceAll(RegExp(r'[\._]'), ' ').trim();

  if (title.length > 2 && title.length < 50) {
    final List<String> noiseWords = [
      "your a/c", "your account", "account", "a/c", "bank", "card",
      "credit card", "debit card", "vpa", "upi", "pay", "payment",
      "user", "transfer", "info"
    ];
    if (noiseWords.contains(title.toLowerCase())) {
      title = "Transaction";
    }
  } else {
    title = "Transaction";
  }

  // Fallback title from package or notification sender if default
  if (title == "Transaction") {
    RegExp altTitleRegex = RegExp(r'notification title:\s*([^\n\r]+)', caseSensitive: false);
    var altMatch = altTitleRegex.firstMatch(input);
    if (altMatch != null && altMatch.group(1) != null) {
      String cand = altMatch.group(1)!.trim();
      if (cand.isNotEmpty && cand.toLowerCase() != "transaction") {
        title = cand;
      }
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

    // Keyword heuristic matching for common merchants
    if (matchedCategory == null) {
      if (titleLower.contains("swiggy") ||
          titleLower.contains("zomato") ||
          titleLower.contains("starbucks") ||
          titleLower.contains("restaurant") ||
          titleLower.contains("diner") ||
          titleLower.contains("mcdonald") ||
          titleLower.contains("burger") ||
          titleLower.contains("pizza") ||
          titleLower.contains("cafe") ||
          titleLower.contains("coffee") ||
          titleLower.contains("kfc") ||
          titleLower.contains("subway") ||
          titleLower.contains("bistro") ||
          titleLower.contains("food")) {
        matchedCategory = allCategories
            .where((c) =>
                c.name.toLowerCase().contains("food") ||
                c.name.toLowerCase().contains("dining"))
            .firstOrNull;
      } else if (titleLower.contains("uber") ||
          titleLower.contains("ola") ||
          titleLower.contains("rapido") ||
          titleLower.contains("fuel") ||
          titleLower.contains("petrol") ||
          titleLower.contains("diesel") ||
          titleLower.contains("metro") ||
          titleLower.contains("irctc") ||
          titleLower.contains("railway") ||
          titleLower.contains("flight") ||
          titleLower.contains("transit")) {
        matchedCategory = allCategories
            .where((c) =>
                c.name.toLowerCase().contains("transport") ||
                c.name.toLowerCase().contains("travel"))
            .firstOrNull;
      } else if (titleLower.contains("amazon") ||
          titleLower.contains("flipkart") ||
          titleLower.contains("myntra") ||
          titleLower.contains("ajio") ||
          titleLower.contains("blinkit") ||
          titleLower.contains("zepto") ||
          titleLower.contains("instamart") ||
          titleLower.contains("grofer") ||
          titleLower.contains("bigbasket") ||
          titleLower.contains("mart") ||
          titleLower.contains("store") ||
          titleLower.contains("supermarket") ||
          titleLower.contains("grocery")) {
        matchedCategory = allCategories
            .where((c) =>
                c.name.toLowerCase().contains("grocer") ||
                c.name.toLowerCase().contains("shopping"))
            .firstOrNull;
      } else if (titleLower.contains("netflix") ||
          titleLower.contains("spotify") ||
          titleLower.contains("hotstar") ||
          titleLower.contains("prime") ||
          titleLower.contains("cinema") ||
          titleLower.contains("movie") ||
          titleLower.contains("pvr") ||
          titleLower.contains("inox")) {
        matchedCategory = allCategories
            .where((c) => c.name.toLowerCase().contains("entertainment"))
            .firstOrNull;
      } else if (titleLower.contains("hospital") ||
          titleLower.contains("pharmacy") ||
          titleLower.contains("apollo") ||
          titleLower.contains("chemist") ||
          titleLower.contains("medical") ||
          titleLower.contains("clinic")) {
        matchedCategory = allCategories
            .where((c) =>
                c.name.toLowerCase().contains("health") ||
                c.name.toLowerCase().contains("medical"))
            .firstOrNull;
      } else if (titleLower.contains("bill") ||
          titleLower.contains("electricity") ||
          titleLower.contains("water") ||
          titleLower.contains("broadband") ||
          titleLower.contains("wifi") ||
          titleLower.contains("airtel") ||
          titleLower.contains("jio") ||
          titleLower.contains("recharge")) {
        matchedCategory = allCategories
            .where((c) =>
                c.name.toLowerCase().contains("bill") ||
                c.name.toLowerCase().contains("utilities"))
            .firstOrNull;
      }
    }
  } catch (_) {}

  // 5. Account / Wallet Matching
  TransactionWallet? matchedWallet;
  List<TransactionWallet> wallets = [];
  if (context != null) {
    try {
      wallets = Provider.of<AllWallets>(context, listen: false).list;
    } catch (_) {}
  }
  if (wallets.isEmpty) {
    try {
      wallets = await database.getAllWallets();
    } catch (_) {}
  }

  if (wallets.isNotEmpty) {
    try {
      String textLower = text.toLowerCase();

      // First check if any wallet name is explicitly mentioned in the text
      for (var w in wallets) {
        if (textLower.contains(w.name.toLowerCase())) {
          matchedWallet = w;
          break;
        }
      }

      // If no exact wallet name matched, distinguish between Credit Card and Regular Bank
      if (matchedWallet == null) {
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
