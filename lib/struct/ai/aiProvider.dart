import 'dart:convert';
import 'dart:typed_data';

enum AiProviderType {
  gemini,
  openAi,
  claude,
  custom,
}

extension AiProviderTypeExtension on AiProviderType {
  String get id {
    switch (this) {
      case AiProviderType.gemini:
        return "gemini";
      case AiProviderType.openAi:
        return "openai";
      case AiProviderType.claude:
        return "claude";
      case AiProviderType.custom:
        return "custom";
    }
  }

  String get displayName {
    switch (this) {
      case AiProviderType.gemini:
        return "Google Gemini";
      case AiProviderType.openAi:
        return "OpenAI (ChatGPT)";
      case AiProviderType.claude:
        return "Anthropic Claude";
      case AiProviderType.custom:
        return "Custom / OpenRouter";
    }
  }

  String get keySettingName {
    switch (this) {
      case AiProviderType.gemini:
        return "geminiApiKey";
      case AiProviderType.openAi:
        return "openAiApiKey";
      case AiProviderType.claude:
        return "claudeApiKey";
      case AiProviderType.custom:
        return "customAiApiKey";
    }
  }

  String get modelSettingName {
    switch (this) {
      case AiProviderType.gemini:
        return "geminiModel";
      case AiProviderType.openAi:
        return "openAiModel";
      case AiProviderType.claude:
        return "claudeModel";
      case AiProviderType.custom:
        return "customAiModel";
    }
  }

  String get defaultModel {
    switch (this) {
      case AiProviderType.gemini:
        return "gemini-1.5-flash";
      case AiProviderType.openAi:
        return "gpt-4o-mini";
      case AiProviderType.claude:
        return "claude-3-5-haiku-latest";
      case AiProviderType.custom:
        return "deepseek/deepseek-chat";
    }
  }

  String get getKeyUrl {
    switch (this) {
      case AiProviderType.gemini:
        return "https://aistudio.google.com/app/apikey";
      case AiProviderType.openAi:
        return "https://platform.openai.com/api-keys";
      case AiProviderType.claude:
        return "https://console.anthropic.com/settings/keys";
      case AiProviderType.custom:
        return "https://openrouter.ai/keys";
    }
  }
}

AiProviderType getProviderTypeFromId(String? id) {
  switch (id?.toLowerCase()) {
    case "openai":
      return AiProviderType.openAi;
    case "claude":
      return AiProviderType.claude;
    case "custom":
      return AiProviderType.custom;
    case "gemini":
    default:
      return AiProviderType.gemini;
  }
}

class AiModelOption {
  final String key;
  final String label;
  final String description;
  final bool isDefault;

  const AiModelOption({
    required this.key,
    required this.label,
    required this.description,
    this.isDefault = false,
  });
}

class ParsedAiTransaction {
  final String? title;
  final double? amount;
  final bool income;
  final String? categoryName;
  final String? subCategoryName;
  final String? walletName;
  final DateTime? dateTime;
  final String? note;

  ParsedAiTransaction({
    this.title,
    this.amount,
    this.income = false,
    this.categoryName,
    this.subCategoryName,
    this.walletName,
    this.dateTime,
    this.note,
  });
}

class AiConnectionTestResult {
  final bool success;
  final String message;
  final int? statusCode;

  const AiConnectionTestResult({
    required this.success,
    required this.message,
    this.statusCode,
  });
}

abstract class BaseAiProvider {
  AiProviderType get providerType;
  List<AiModelOption> get availableModels;

  Future<AiConnectionTestResult> testConnection({
    String? apiKey,
    String? model,
    String? customEndpoint,
  });

  Future<Map<String, String?>?> recommendCategory({
    required String title,
    required Map<String, List<String>> categoriesWithSubcategories,
    String? apiKey,
    String? model,
    String? customEndpoint,
  });

  Future<List<ParsedAiTransaction>?> parseTransactionText({
    required String text,
    required Map<String, List<String>> categoriesWithSubcategories,
    required List<String> walletNames,
    String? extraRules,
    DateTime? referenceTime,
    String? apiKey,
    String? model,
    String? customEndpoint,
  });

  Future<List<ParsedAiTransaction>?> parseReceiptImage({
    required Uint8List imageBytes,
    required Map<String, List<String>> categoriesWithSubcategories,
    required List<String> walletNames,
    String? apiKey,
    String? model,
    String? customEndpoint,
  });
}

// --------------------------------------------------------------------------
// PROMPT BUILDERS
// --------------------------------------------------------------------------

String buildTransactionPrompt({
  required String input,
  required Map<String, List<String>> categoriesWithSubcategories,
  required List<String> walletNames,
  String? extraRules,
  DateTime? referenceTime,
}) {
  DateTime now = referenceTime ?? DateTime.now();
  String refTimeStr = now.toIso8601String();
  String categoryTreeJson = jsonEncode(categoriesWithSubcategories);
  String walletsJson = jsonEncode(walletNames);

  return '''
You are a financial transaction parsing engine. Extract all financial transactions mentioned in the user's input into structured JSON.

### Reference Context:
- Current Timestamp: "$refTimeStr"
- Available Categories & Subcategories:
$categoryTreeJson
- Available Accounts/Wallets:
$walletsJson
${extraRules != null && extraRules.trim().isNotEmpty ? "- User Custom Rules:\n${extraRules.trim()}" : ""}

### Extraction Rules:
1. Title: Clean merchant, payee, or short transaction title with proper capitalization (e.g. "Subway", "Uber", "Electricity Bill").
2. Amount: Positive numeric decimal amount (e.g. 450.0). If not specified, set to 0.0.
3. Income / Expense: 
   - Set income: true for salary, income, received money, refunds, cashback, investments returned.
   - Set income: false for purchases, bills, debits, transfers out, dining, transport, and all regular expenses.
4. Category & Subcategory:
   - Match against the available categories and subcategories provided above.
   - Prefer an exact subcategory if one applies.
   - If no category matches, set to null.
5. Account / Wallet:
   - Match against the provided available accounts.
   - If not mentioned or unclear, set to null.
6. Date & Time:
   - Calculate relative dates relative to reference timestamp "$refTimeStr" and format as ISO-8601 (YYYY-MM-DDTHH:mm:ss).
   - If no date is mentioned, set to null.
7. Note:
   - Include specific item details or comments not covered in the title.
   - If redundant with title, set to empty string "".

### Input to Parse:
"$input"

### Response Format:
Return ONLY valid JSON matching this schema:
{
  "out": [
    {
      "title": "Merchant name",
      "amount": 12.34,
      "income": false,
      "category": "Category or null",
      "subcategory": "Subcategory or null",
      "wallet": "Wallet or null",
      "date": "YYYY-MM-DDTHH:mm:ss or null",
      "note": "Extra note or empty string"
    }
  ]
}
''';
}

String buildCategoryRecommendationPrompt({
  required String title,
  required Map<String, List<String>> categoriesWithSubcategories,
}) {
  String categoryTreeJson = jsonEncode(categoriesWithSubcategories);

  return '''
You are a financial category classifier. Given a merchant/title, classify it into the best category and subcategory from:
$categoryTreeJson

### Transaction Title:
"$title"

### Rules:
1. Choose ONLY from the available category tree.
2. Select the most specific category and subcategory.
3. If no specific subcategory fits, set subcategory to null.
4. If no category fits at all, set category to null.

### Response Format:
Return ONLY valid JSON matching this schema:
{
  "category": "Matched category name or null",
  "subcategory": "Matched subcategory name or null"
}
''';
}

String buildReceiptPrompt({
  required Map<String, List<String>> categoriesWithSubcategories,
  required List<String> walletNames,
}) {
  String categoryTreeJson = jsonEncode(categoriesWithSubcategories);
  String walletsJson = jsonEncode(walletNames);

  return '''
Analyze the receipt/invoice image and extract:
1. Merchant/Store name as "title".
2. Grand total paid as positive "amount".
3. Date printed as "date" (YYYY-MM-DD or null).
4. Matched "category" and "subcategory" from: $categoryTreeJson
5. Matched "wallet" from: $walletsJson or null.
6. Line items as "note".

### Response Format:
Return ONLY valid JSON matching this schema:
{
  "out": [
    {
      "title": "Store name",
      "amount": 0.0,
      "income": false,
      "category": "Category or null",
      "subcategory": "Subcategory or null",
      "wallet": "Wallet or null",
      "date": "YYYY-MM-DD or null",
      "note": "Items list"
    }
  ]
}
''';
}
