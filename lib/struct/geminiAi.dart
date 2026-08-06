import 'dart:convert';
import 'package:budget/database/tables.dart';
import 'package:budget/struct/databaseGlobal.dart';
import 'package:budget/struct/settings.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

class GeminiParsedTransaction {
  final String? title;
  final double? amount;
  final bool income;
  final String? categoryName;
  final String? walletName;

  GeminiParsedTransaction({
    this.title,
    this.amount,
    this.income = false,
    this.categoryName,
    this.walletName,
  });
}

Future<GeminiParsedTransaction?> parseTransactionWithGemini(
    String input, BuildContext context) async {
  String apiKey = appStateSettings["geminiApiKey"] ?? "";
  if (apiKey.trim().isEmpty) return null;

  String model = appStateSettings["geminiModel"] ?? "gemini-1.5-flash";

  // Build context information based on privacy settings
  List<String> categories = [];
  if (appStateSettings["aiShareCategoryNames"] == true) {
    try {
      var allCats = await database.getAllCategories();
      categories = allCats.map((c) => c.name).toList();
    } catch (_) {}
  }

  List<String> wallets = [];
  if (appStateSettings["aiShareAccountNames"] == true) {
    try {
      var allWallets = Provider.of<AllWallets>(context, listen: false).list;
      wallets = allWallets.map((w) => w.name).toList();
    } catch (_) {}
  }

  String extraRules = appStateSettings["aiExtraRules"] ?? "";

  String prompt = """
You are a financial transaction extractor. Analyze the input text and extract transaction details into JSON format.

Available Categories: ${categories.join(", ")}
Available Accounts: ${wallets.join(", ")}
${extraRules.isNotEmpty ? "User Extra Rules: $extraRules" : ""}

Input Text: "$input"

Return ONLY valid raw JSON without markdown code fences or quotes around the JSON block matching this exact structure:
{
  "title": "Merchant/Payee or short summary",
  "amount": numeric_amount_or_null,
  "income": true_or_false,
  "category": "matched_category_name_or_null",
  "wallet": "matched_account_name_or_null"
}
""";

  try {
    Uri url = Uri.parse(
        "https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent?key=$apiKey");

    var response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "contents": [
          {
            "parts": [
              {"text": prompt}
            ]
          }
        ]
      }),
    );

    if (response.statusCode == 200) {
      var data = jsonDecode(response.body);
      String? text =
          data["candidates"]?[0]?["content"]?["parts"]?[0]?["text"];
      if (text == null) return null;

      // Clean markdown code blocks if present
      text = text.replaceAll("```json", "").replaceAll("```", "").trim();
      var jsonResult = jsonDecode(text);

      return GeminiParsedTransaction(
        title: jsonResult["title"] as String?,
        amount: (jsonResult["amount"] as num?)?.toDouble(),
        income: jsonResult["income"] == true,
        categoryName: jsonResult["category"] as String?,
        walletName: jsonResult["wallet"] as String?,
      );
    }
  } catch (e) {
    debugPrint("Gemini AI Parsing Error: $e");
  }
  return null;
}
