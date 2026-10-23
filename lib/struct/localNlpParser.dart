import 'package:budget/database/tables.dart';
import 'package:budget/struct/databaseGlobal.dart';
import 'package:budget/struct/settings.dart';
import 'package:budget/widgets/walletEntry.dart';
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

final RegExp _completedDebitConfirmationRegex = RegExp(
  r'\b(has been debited|was debited|debited by|debited for|debited from|debited with|successfully debited|payment successful|paid successfully|sent successfully|transferred successfully|txn successful|spent on card|withdrawn from)\b',
  caseSensitive: false,
);

final RegExp _reminderKeywordsRegex = RegExp(
  r'\b(reminder|bill reminder|payment reminder|due on|is due|due date|due by|pay before|pay now|to avoid late fee|avoid late payment|to avoid disconnection|to avoid service interruption|upcoming debit|will be debited|is scheduled to be debited|scheduled to be debited|is scheduled on|scheduled on|scheduled for|standing instruction|ensure sufficient balance|maintain sufficient balance|maintain balance|keep sufficient balance|outstanding amount|total amount due|min amount due|minimum amount due|total due|min due|minimum due|bill generated|e-bill generated|bill for rs|invoice generated)\b',
  caseSensitive: false,
);

/// Helper to detect payment reminders, bill generation alerts, due-date notices,
/// and scheduled pre-debit notifications before any actual money has been transferred.
bool isPaymentReminderOrPendingNotice(String text) {
  String lower = text.toLowerCase();

  // If text contains reminder/pre-debit keywords:
  if (_reminderKeywordsRegex.hasMatch(lower)) {
    // If it also contains an explicit completed debit confirmation, verify it isn't negated by "will be"
    if (_completedDebitConfirmationRegex.hasMatch(lower)) {
      // If it says "will be debited", "scheduled to be debited", or "is due", it's still future/reminder
      if (lower.contains("will be") ||
          lower.contains("scheduled to") ||
          lower.contains("is due") ||
          lower.contains("due on")) {
        return true;
      }
      // Otherwise confirmed completed transaction
      return false;
    }
    return true;
  }

  return false;
}

final RegExp _unconditionalPromoKeywordsRegex = RegExp(
  r'\b(welcome rewards|welcome offer|apply now|get flex|rewards with flex|eligible for|pre-approved|instant loan|personal loan|apply for credit|claim reward|claim your|claim now|earn\s+[\$\₹\£\€]?\s*[0-9]+|earn\s+.*welcome|congratulations|unlock rewards|exclusive offer|limited period offer|flat\s*₹|flat\s*rs|use code|use promo|save flat|discount of|cashback up to|win up to|save up to|zero fee credit card|zero-fee|zero fee|scratch card|hurry\b|ends soon|order now|shop now|spin and win|refer and earn)\b',
  caseSensitive: false,
);

final RegExp _fakeCreditMarketingRegex = RegExp(
  r'\b(loan.*credited|limit increased|credit limit of|approved for loan|sanctioned loan|recharge now to get|avail loan)\b',
  caseSensitive: false,
);

final RegExp _loyaltyOrPointsRegex = RegExp(
  r'\b(loyalty\s+account|myg\s+loyalty|loyalty\s+points?|reward\s+points?|points?\s+credited|points?\s+debited|points?\s+redeemed|pts\s+credited|pts\s+redeemed|supercoins?|neucoins?|payback\s+points?|airmiles|miles\s+credited)\b',
  caseSensitive: false,
);

final RegExp _completedTransferConfirmationRegex = RegExp(
  r'\b(has been debited|was debited|debited by|debited for|debited from|debited with|debited\b|successfully debited|payment successful|paid successfully|sent successfully|transferred successfully|txn successful|spent on card|withdrawn from|deposited in|deposited to|credited to your|credited with|salary credited)\b',
  caseSensitive: false,
);

/// Helper to detect promotional, marketing, rewards, loans, and coupon messages
/// that are NOT actual completed financial transactions.
bool isPromotionalOrMarketingNotification(String text) {
  String lower = text.toLowerCase();

  // 0. Loyalty points / reward points account messages (e.g., "your myG Loyalty account 86065537...")
  if (_loyaltyOrPointsRegex.hasMatch(lower)) {
    return true;
  }

  // 1. Unconditional promotional & spam indicators:
  // These calls-to-action or marketing terms are NEVER part of legitimate bank debit/credit transactional alerts
  if (_unconditionalPromoKeywordsRegex.hasMatch(lower)) {
    return true;
  }

  // 2. Loan offers / limit increment marketing disguised with "credited"
  if (_fakeCreditMarketingRegex.hasMatch(lower)) {
    return true;
  }

  // 3. Strict phrases that prove real money transfer has occurred
  if (_completedTransferConfirmationRegex.hasMatch(lower)) {
    return false;
  }

  return false;
}

/// Checks if a package belongs to a non-financial chat, social media, entertainment,
/// or system app that should be ignored unless explicitly whitelisted by the user.
bool isNonFinancialPackageByDefault(String? packageName,
    {String? allowedPackagesString}) {
  if (packageName == null || packageName.trim().isEmpty) return false;
  final String pkg = packageName.trim().toLowerCase();

  // Always ignore Xpenzi's own notifications
  if (pkg == "com.navlin.xpenzi" || pkg.contains("xpenzi")) {
    return true;
  }

  // Default blocked chat, social, media, and system packages
  const List<String> blockedByDefaultKeywords = [
    "com.whatsapp",
    "whatsapp",
    "org.telegram",
    "telegram",
    "com.instagram",
    "instagram",
    "com.facebook.orca",
    "com.facebook.katana",
    "com.facebook.lite",
    "com.snapchat",
    "com.discord",
    "org.thoughtcrime.securesms",
    "com.slack",
    "com.microsoft.teams",
    "com.twitter",
    "com.zhiliaoapp.musically",
    "com.reddit",
    "com.linkedin",
    "com.pinterest",
    "com.google.android.youtube",
    "com.spotify",
    "com.netflix",
    "in.startv.hotstar",
    "com.amazon.avod",
    "com.android.systemui",
    "com.android.vending",
    "com.android.providers.downloads",
    "com.sec.android.app.music",
    "com.samsung.android.incallui",
    "com.google.android.dialer",
    "com.google.android.deskclock",
    "com.sec.android.app.clockpackage",
    "com.google.android.calendar",
    "com.samsung.android.calendar",
    "com.google.android.gm",
    "com.microsoft.office.outlook",
  ];

  bool matchesBlocked = blockedByDefaultKeywords.any((b) => pkg.contains(b));
  if (!matchesBlocked) return false;

  // If user explicitly added this package keyword in allowedPackagesString, allow it through to NLP checks
  if (allowedPackagesString != null &&
      allowedPackagesString.trim().isNotEmpty) {
    final List<String> allowedList = allowedPackagesString
        .split(",")
        .map((e) => e.trim().toLowerCase())
        .where((e) => e.isNotEmpty)
        .toList();
    if (allowedList
        .any((allowed) => pkg.contains(allowed) || allowed.contains(pkg))) {
      return false;
    }
  }

  return true;
}

final RegExp _chatMediaIndicatorsRegex = RegExp(
  r'(\b(?:sent|received)\s+(?:a\s+|an\s+|\d+\s+)?(?:photo|photos|image|images|picture|pictures|video|videos|voice\s*message|voice\s*note|audio|sticker|stickers|gif|gifs|document|documents|file|files|contact|location|reaction|poll|link|message|messages)\b|\b(?:missed\s+(?:voice|video|group)?\s*call|incoming\s+(?:voice|video)?\s*call|ongoing\s+call|calling\.\.\.|ringing\.\.\.|\d+\s+new\s+messages?|\d+\s+unread\s+messages?|messages?\s+from\s+\d+\s+chats?|typing\.\.\.|recording\s+audio|reacted\s+to|replied\s+to\s+your|deleted\s+this\s+message)\b|[📷🎥🎤🎧📄📍👾])',
  caseSensitive: false,
);

final RegExp _strictBankConfirmationRegex = RegExp(
  r'\b(has been debited|was debited|debited by|debited for|debited from|credited to your|credited with|upi\s*ref|ref\s*no|utr\b)\b',
  caseSensitive: false,
);

/// Detects personal chat messages, media attachments (e.g. WhatsApp "Sent 2 photos"),
/// group chat prefixes, and call/message summary alerts that are never financial transactions.
bool isChatOrMediaNotification(String text) {
  final String lower = text.toLowerCase();

  // 1. Media attachment & chat action notices (e.g., "📷 Sent 2 photos", "Sent a video", "Missed voice call")
  if (_chatMediaIndicatorsRegex.hasMatch(text)) {
    return true;
  }

  // 2. WhatsApp group chat sender prefix "~ SenderName" without any bank/UPI confirmation
  if (text.contains("~ ") || text.contains("~")) {
    if (!_strictBankConfirmationRegex.hasMatch(lower)) {
      return true;
    }
  }

  return false;
}

/// Strict currency symbols and word-bounded ISO currency codes.
/// Word boundaries (\b) prevent substrings inside words (e.g., "SAR" in "SARJAPURA" or "rs" in "hours"/"others")
/// from ever matching as currencies.
const String _strictCurrencySymbols =
    r'[\$\€\£\¥\₹\₩\₺\₱\฿\₫\₴\₦\₵\₸\₲\֏\؋\৳\៛\₭\₮\₨\₽\₾]';
const String _strictCurrencyCodes =
    r'\b(?:usd|eur|gbp|inr|cad|aud|chf|jpy|cny|rs\.?(?=\s|[0-9])|brl|mxn|sgd|hkd|nzd|sek|nok|dkk|pln|aed|sar|zar|myr|idr|php|thb|vnd|ngn|kes|egp|ils|clp|czk|huf|ron|bgn|kwd|bhd|omr|qar)\b';
const String globalCurrencies =
    '(?:$_strictCurrencySymbols|$_strictCurrencyCodes)';

final RegExp _currencyWithAmountRegex = RegExp(
  '(?:$globalCurrencies\\s*[0-9]+|[0-9]+(?:[.,][0-9]{1,2})?\\s*$globalCurrencies)',
  caseSensitive: false,
);

final RegExp _strictFinancialKeywordsRegex = RegExp(
  r'\b(debited|credited|withdrawn|deposited|refunded|autopay|mandate|a/c|acct|vpa|upi\s*ref|ref\s*no|utr|imps|neft|rtgs|nach|pos\b|atm\b|card\s+ending|spent\s+on|spent\s+at|paid\s+to|sent\s+to|received\s+from|pagado|abonado|prelevement|virement|abgebucht|gutgeschrieben|addebitato|accreditato)\b',
  caseSensitive: false,
);

final RegExp _bankAccountContextRegex = RegExp(
  r'\b(a/c|acct|account|card\s+ending|upi|vpa|imps|neft|rtgs|utr|ref\s*no)\b',
  caseSensitive: false,
);

final RegExp _explicitDebitCreditRegex = RegExp(
  r'\b(debited|credited|withdrawn)\b',
  caseSensitive: false,
);

/// Verifies whether a notification message contains genuine financial transaction context.
bool hasConfirmedFinancialTransactionContext(String text) {
  if (isChatOrMediaNotification(text)) return false;
  if (isPaymentReminderOrPendingNotice(text)) return false;
  if (isPromotionalOrMarketingNotification(text)) return false;

  // Must have either an explicit currency symbol/code with a number OR an explicit bank/UPI ledger phrase
  if (!_strictFinancialKeywordsRegex.hasMatch(text)) {
    return false;
  }

  // If no explicit currency symbol/code is attached to a number, require both an account/UPI identifier AND debited/credited
  if (!_currencyWithAmountRegex.hasMatch(text)) {
    final bool hasBankAccountContext = _bankAccountContextRegex.hasMatch(text);
    final bool hasExplicitDebitCredit =
        _explicitDebitCreditRegex.hasMatch(text);
    if (!hasBankAccountContext || !hasExplicitDebitCredit) {
      return false;
    }
  }

  return true;
}

Future<LocalNlpParsedTransaction?> parseTransactionFromNotificationText(
    String input, BuildContext? context) async {
  if (input.trim().isEmpty) return null;

  // Extract package name, notification title, and notification content if structured
  String? packageName;
  String? notifTitle;
  String? notifContent;

  if (input.contains("Package name:") ||
      input.contains("Notification Content:")) {
    final pkgMatch = RegExp(r'Package name:\s*([^\n\r]+)', caseSensitive: false)
        .firstMatch(input);
    if (pkgMatch != null) packageName = pkgMatch.group(1)?.trim();

    final titleMatch =
        RegExp(r'Notification Title:\s*([^\n\r]+)', caseSensitive: false)
            .firstMatch(input);
    if (titleMatch != null) notifTitle = titleMatch.group(1)?.trim();

    final contentMatch =
        RegExp(r'Notification Content:\s*([\s\S]+)$', caseSensitive: false)
            .firstMatch(input);
    if (contentMatch != null) notifContent = contentMatch.group(1)?.trim();
  }

  // 0. Block default non-financial packages (WhatsApp, social media, music players, etc.)
  if (packageName != null && isNonFinancialPackageByDefault(packageName)) {
    print(
        "[LocalNLP] Ignored notification from non-financial package: $packageName");
    return null;
  }

  // Build clean text from notification body/title ONLY (never include "Package name:" or metadata headers)
  // If notification content is present, only include notification title when the title itself contains
  // financial keywords (like GPay "Paid ₹500 to..."), so sender/group names with numbers (like "TEXS MALL-3 SARJAPURA")
  // are never parsed as transaction amounts!
  String rawBody;
  if (notifContent != null && notifContent.isNotEmpty) {
    final bool titleHasFinancialData = notifTitle != null &&
        RegExp('(?:$globalCurrencies|\\b(?:debited|credited|paid|spent|received|refunded)\\b)',
                caseSensitive: false)
            .hasMatch(notifTitle);
    rawBody =
        titleHasFinancialData ? "${notifTitle!} $notifContent" : notifContent;
  } else {
    rawBody = input;
  }

  String text = rawBody.replaceAll("\n", " ").trim();
  if (text.isEmpty) return null;

  // 0b. Filter out chat messages and media notifications (e.g. "📷 Sent 2 photos")
  if (isChatOrMediaNotification(input) || isChatOrMediaNotification(text)) {
    print(
        "[LocalNLP] Ignored message: Detected personal chat or media notification.");
    return null;
  }

  // 1. Payment Reminder & Scheduled Pre-Debit Filter
  // Prevents bill reminders, due-date notices, and scheduled autopay warnings from being recorded as expenses
  if (isPaymentReminderOrPendingNotice(text)) {
    print(
        "[LocalNLP] Ignored message: Detected payment reminder or scheduled bill notice without actual debit.");
    return null;
  }

  // 1b. Promotional, Marketing, and Rewards Filter
  // Prevents promotional reward banners (e.g., GPay "Earn ₹1,000 welcome rewards with Flex") from being recorded
  if (isPromotionalOrMarketingNotification(text)) {
    print(
        "[LocalNLP] Ignored message: Detected promotional or marketing rewards offer.");
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
        text.toLowerCase().contains("spent on");
    if (!isDefinitiveTransaction) return null;
  }

  // Strict Financial Transaction Context Verification
  if (!hasConfirmedFinancialTransactionContext(text)) {
    return null;
  }

  // 2. Amount Extraction
  double? amount;

  // Pattern A: Explicit currency symbol/code or strict debit/credit verb followed by amount
  RegExp amountRegex = RegExp(
    '(?:$globalCurrencies|\\b(?:debited|credited)\\s+(?:by|for|of|with))\\s*:?\\s*([0-9]{1,3}(?:[.,][0-9]{3})*(?:[.,][0-9]{1,2})|[0-9]+(?:[.,][0-9]{1,2})?)',
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

  // Fallback B: Number followed by strict currency symbol/code (e.g. "50.00 USD spent", "120 € debited")
  if (amount == null) {
    RegExp numberBeforeCurrencyRegex = RegExp(
      '([0-9]{1,3}(?:[.,][0-9]{3})*(?:[.,][0-9]{1,2})|[0-9]+(?:[.,][0-9]{1,2})?)\\s*$globalCurrencies',
      caseSensitive: false,
    );
    var match = numberBeforeCurrencyRegex.firstMatch(text);
    if (match != null && match.group(1) != null) {
      amount = parseAmountString(match.group(1)!);
    }
  }

  // Fallback C: Direct debited/credited followed by number when bank account context is verified
  if (amount == null) {
    RegExp debitCreditRegex = RegExp(
      r'\b(?:debited|credited)\s+(?:by|of|for|with)?\s*:?\s*([0-9]+(?:[.,][0-9]{1,2})?)',
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
  bool hasDebit = RegExp(
          r'\b(debited|debit|withdrawn|spent|paid|charged|purchase|sent)\b',
          caseSensitive: false)
      .hasMatch(lowerText);
  bool hasCredit = RegExp(
          r'\b(credited|credit|deposited|refund|refunded|cashback|salary|received)\b',
          caseSensitive: false)
      .hasMatch(lowerText);

  bool isIncome = false;
  String? extractedPayeeFromDualPattern;

  if (hasDebit && hasCredit) {
    // Both are present! Determine which action applies to the user's account vs the counterparty.
    int userAcctIndex = lowerText
        .indexOf(RegExp(r'\b(your a/c|acct|a/c|account|card ending|card)\b'));
    int debitIndex =
        lowerText.indexOf(RegExp(r'\b(debited|debit|spent|paid)\b'));
    int creditIndex =
        lowerText.indexOf(RegExp(r'\b(credited|credit|deposited|received)\b'));

    // Check specific structural syntax:
    // Case 1: "debited for ... ; <PAYEE> credited" or "debited ... credited to <PAYEE>" -> User is debited!
    RegExp userDebitedOtherCredited = RegExp(
      r'(?:debited|paid|spent).+?(?:;\s*([A-Za-z0-9\s&\.\-\@]+?)\s+credited|credited to\s+([A-Za-z0-9\s&\.\-\@]+?))',
      caseSensitive: false,
    );
    var dualMatch = userDebitedOtherCredited.firstMatch(text);
    if (dualMatch != null) {
      isIncome = false; // Expense
      extractedPayeeFromDualPattern =
          (dualMatch.group(1) ?? dualMatch.group(2))?.trim();
    } else {
      // Case 2: "credited with ... debited from <PAYER>" -> User is credited!
      RegExp userCreditedOtherDebited = RegExp(
        r'(?:credited|deposited|received).+?(?:debited from\s+([A-Za-z0-9\s&\.\-\@]+?)|from\s+([A-Za-z0-9\s&\.\-\@]+?))',
        caseSensitive: false,
      );
      var dualCreditMatch = userCreditedOtherDebited.firstMatch(text);
      if (dualCreditMatch != null) {
        isIncome = true; // Income
        extractedPayeeFromDualPattern =
            (dualCreditMatch.group(1) ?? dualCreditMatch.group(2))?.trim();
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

  if (extractedPayeeFromDualPattern != null &&
      extractedPayeeFromDualPattern.isNotEmpty) {
    title = extractedPayeeFromDualPattern;
  } else {
    // Check for specialized bank SMS patterns
    // Pattern 0: Bank debit where recipient is credited: "; <RECIPIENT> credited" (e.g. ICICI UPI alert)
    RegExp recipientCreditedRegex = RegExp(
      r';\s*([A-Za-z0-9\s&\.\-\@]+?)\s+credited\b',
      caseSensitive: false,
    );
    // Pattern A: "by <MERCHANT>, INFO: ..." or "by <MERCHANT>"
    RegExp byMerchantRegex = RegExp(
        r'\bby\s+([A-Za-z0-9\s&\.\-\@]+?)(?=,\s*INFO|\s+INFO|//|\.|$)',
        caseSensitive: false);
    // Pattern B: "trf to <PAYEE> Refno" or "transfer to <PAYEE>"
    RegExp trfToRegex = RegExp(
        r'\b(?:trf to|transfer to|transferred to)\s+([A-Za-z0-9\s&\.\-\@]+?)(?=\s+(?:Refno|Ref|on|via|using|If not)|\.|$)',
        caseSensitive: false);
    // Pattern C: "AutoPay for <MERCHANT> SIP" or "AutoPay for <MERCHANT>"
    RegExp autoPayRegex = RegExp(
        r'\b(?:AutoPay for|mandate for|autopay to)\s+([A-Za-z0-9\s&\.\-\@]+?)(?=\s+(?:debit|credit|scheduled|is scheduled)|\.|$)',
        caseSensitive: false);
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
      "your a/c",
      "your account",
      "account",
      "a/c",
      "bank",
      "card",
      "credit card",
      "debit card",
      "vpa",
      "upi",
      "pay",
      "payment",
      "user",
      "transfer",
      "info"
    ];
    if (noiseWords.contains(title.toLowerCase())) {
      title = "Transaction";
    }
  } else {
    title = "Transaction";
  }

  // Fallback title from package or notification sender if default
  if (title == "Transaction") {
    RegExp altTitleRegex =
        RegExp(r'notification title:\s*([^\n\r]+)', caseSensitive: false);
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
      final String? defaultWalletPk =
          appStateSettings["selectedWalletPk"]?.toString();
      final TransactionWallet? userDefaultWallet = defaultWalletPk != null
          ? wallets.where((w) => w.walletPk == defaultWalletPk).firstOrNull
          : null;

      // 1. Check if any wallet name is explicitly mentioned in the text
      for (var w in wallets) {
        if (w.name.trim().isNotEmpty &&
            textLower.contains(w.name.trim().toLowerCase())) {
          matchedWallet = w;
          break;
        }
      }

      // 2. If no full wallet name matched, check significant brand/bank keywords in wallet names
      // (e.g., wallet named "HDFC Savings" or "ICICI Coral" when SMS says "HDFC Bank" or "ICICI Bank")
      bool isMealCard = textLower.contains("pluxee") ||
          textLower.contains("sodexo") ||
          textLower.contains("meal card") ||
          textLower.contains("food wallet") ||
          textLower.contains("zaggle");
      bool isCreditCard = !isMealCard &&
          (textLower.contains("credit card") ||
              (textLower.contains("card") &&
                  !textLower.contains("debit card") &&
                  (textLower.contains("debited") ||
                      textLower.contains("spent"))) ||
              textLower.contains("spent on card") ||
              textLower.contains("card ending"));

      if (matchedWallet == null) {
        const Set<String> genericWords = {
          "bank",
          "account",
          "card",
          "credit",
          "debit",
          "savings",
          "saving",
          "current",
          "salary",
          "wallet",
          "cash",
          "primary",
          "main",
          "personal",
          "my",
          "the",
          "and",
        };
        for (var w in wallets) {
          final tokens = w.name
              .toLowerCase()
              .split(RegExp(r'[^a-z0-9]+'))
              .where((t) => t.length >= 3 && !genericWords.contains(t));
          if (tokens.any((token) =>
              RegExp(r'\b' + RegExp.escape(token) + r'\b')
                  .hasMatch(textLower))) {
            // If user has both a Credit Card and Bank Account from the same bank (e.g. HDFC),
            // match the one whose Account Type aligns with the notification
            final String wType = getWalletAccountType(w);
            if (isCreditCard && wType != "Credit Card") continue;
            if (!isCreditCard && !isMealCard && wType == "Credit Card") continue;
            matchedWallet = w;
            break;
          }
        }
      }

      // 3. If still no match, match by detected Account Type, preferring user's default account
      if (matchedWallet == null) {
        if (isMealCard) {
          matchedWallet = (userDefaultWallet != null &&
                      getWalletAccountType(userDefaultWallet) == "Meal Card")
                  ? userDefaultWallet
                  : wallets
                      .where((w) => getWalletAccountType(w) == "Meal Card")
                      .firstOrNull;
        } else if (isCreditCard) {
          matchedWallet = (userDefaultWallet != null &&
                      getWalletAccountType(userDefaultWallet) == "Credit Card")
                  ? userDefaultWallet
                  : wallets
                      .where((w) => getWalletAccountType(w) == "Credit Card")
                      .firstOrNull;
        }
      }

      // 4. Fallback: always default to the user's chosen default account (selectedWalletPk)
      matchedWallet ??= userDefaultWallet ?? wallets.firstOrNull;
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
