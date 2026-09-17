import 'dart:typed_data';
import 'package:budget/struct/ai/aiManager.dart';
import 'package:budget/struct/ai/aiProvider.dart';
import 'package:flutter/material.dart';

export 'package:budget/struct/ai/aiProvider.dart';
export 'package:budget/struct/ai/aiManager.dart';

typedef GeminiParsedTransaction = ParsedAiTransaction;

/// Backward-compatible testAiConnection delegating to active provider
Future<AiConnectionTestResult> testAiConnection({
  String? apiKeyOverride,
  String? modelOverride,
}) async {
  return await aiManager.testActiveConnection(
    apiKeyOverride: apiKeyOverride,
    modelOverride: modelOverride,
  );
}

/// Backward-compatible single transaction parser
Future<GeminiParsedTransaction?> parseTransactionWithGemini(
    String input, BuildContext context) async {
  List<ParsedAiTransaction>? list =
      await aiManager.parseTransactionText(input, context);
  if (list != null && list.isNotEmpty) {
    return list.first;
  }
  return null;
}

/// Backward-compatible multi-transaction parser
Future<List<GeminiParsedTransaction>?> parseTransactionsWithGemini(
    String input, BuildContext context) async {
  return await aiManager.parseTransactionText(input, context);
}

/// Backward-compatible category recommendation
Future<Map<String, String?>?> recommendCategoryFromTitle(
    String title, BuildContext context) async {
  return await aiManager.recommendCategory(title, context);
}

/// Backward-compatible receipt scanner
Future<List<GeminiParsedTransaction>?> parseReceiptWithGemini(
    Uint8List imageBytes, BuildContext context) async {
  return await aiManager.parseReceipt(imageBytes, context);
}
