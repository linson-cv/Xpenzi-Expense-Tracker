import 'dart:convert';
import 'package:budget/struct/ai/aiProvider.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class ClaudeProvider extends BaseAiProvider {
  @override
  AiProviderType get providerType => AiProviderType.claude;

  @override
  List<AiModelOption> get availableModels => const [
        AiModelOption(
          key: "claude-3-5-haiku-latest",
          label: "Claude 3.5 Haiku",
          description: "Recommended: Lightning-fast speed, low latency, and highly accurate.",
          isDefault: true,
        ),
        AiModelOption(
          key: "claude-3-5-sonnet-latest",
          label: "Claude 3.5 Sonnet",
          description: "State-of-the-art reasoning for receipts and complex financial data.",
        ),
      ];

  String _resolveModel(String? model) {
    if (model == null ||
        model.trim().isEmpty ||
        model.trim().toLowerCase() == "default") {
      return "claude-3-5-haiku-latest";
    }
    return model.trim();
  }

  @override
  Future<AiConnectionTestResult> testConnection({
    String? apiKey,
    String? model,
    String? customEndpoint,
  }) async {
    String key = (apiKey ?? "").trim();
    if (key.isEmpty) {
      return const AiConnectionTestResult(
        success: false,
        message: "Please enter an Anthropic Claude API key (starts with 'sk-ant-').",
      );
    }

    String targetModel = _resolveModel(model);
    try {
      var resp = await http.post(
        Uri.parse("https://api.anthropic.com/v1/messages"),
        headers: {
          "Content-Type": "application/json",
          "x-api-key": key,
          "anthropic-version": "2023-06-01",
        },
        body: jsonEncode({
          "model": targetModel,
          "max_tokens": 5,
          "messages": [
            {"role": "user", "content": "ping"}
          ],
        }),
      ).timeout(const Duration(seconds: 12));

      if (resp.statusCode == 200) {
        return AiConnectionTestResult(
          success: true,
          message: "Connected successfully to Claude with $targetModel!",
          statusCode: 200,
        );
      } else {
        String msg = "HTTP ${resp.statusCode}: ${resp.reasonPhrase}";
        try {
          var err = jsonDecode(resp.body);
          if (err["error"]?["message"] != null) {
            msg = err["error"]["message"];
          }
        } catch (_) {}
        return AiConnectionTestResult(
          success: false,
          message: msg,
          statusCode: resp.statusCode,
        );
      }
    } catch (e) {
      return AiConnectionTestResult(
        success: false,
        message: e.toString().replaceFirst("Exception: ", ""),
      );
    }
  }

  @override
  Future<Map<String, String?>?> recommendCategory({
    required String title,
    required Map<String, List<String>> categoriesWithSubcategories,
    String? apiKey,
    String? model,
    String? customEndpoint,
  }) async {
    String key = (apiKey ?? "").trim();
    if (key.isEmpty) return null;

    String targetModel = _resolveModel(model);
    String catJson = jsonEncode(categoriesWithSubcategories);

    String systemPrompt = """
You are a financial category classifier. Given a merchant/title, classify it into the best category and subcategory from this catalog:
$catJson

Return ONLY raw JSON with format:
{"category": "Category or null", "subcategory": "Subcategory or null"}
Do not include explanations or markdown fences.
""";

    try {
      var resp = await http.post(
        Uri.parse("https://api.anthropic.com/v1/messages"),
        headers: {
          "Content-Type": "application/json",
          "x-api-key": key,
          "anthropic-version": "2023-06-01",
        },
        body: jsonEncode({
          "model": targetModel,
          "max_tokens": 150,
          "system": systemPrompt,
          "messages": [
            {"role": "user", "content": title}
          ],
        }),
      ).timeout(const Duration(seconds: 8));

      if (resp.statusCode == 200) {
        var data = jsonDecode(resp.body);
        String? text = data["content"]?[0]?["text"];
        if (text != null) {
          var json = jsonDecode(_cleanJson(text));
          return {
            "category": json["category"] as String?,
            "subcategory": json["subcategory"] as String?,
          };
        }
      }
    } catch (e) {
      debugPrint("Claude recommendCategory error: $e");
    }
    return null;
  }

  @override
  Future<List<ParsedAiTransaction>?> parseTransactionText({
    required String text,
    required Map<String, List<String>> categoriesWithSubcategories,
    required List<String> walletNames,
    String? extraRules,
    DateTime? referenceTime,
    String? apiKey,
    String? model,
    String? customEndpoint,
  }) async {
    String key = (apiKey ?? "").trim();
    if (key.isEmpty) return null;

    String targetModel = _resolveModel(model);
    DateTime ref = referenceTime ?? DateTime.now();

    String systemPrompt = """
You are a financial transaction extractor.
Current Timestamp: "${ref.toIso8601String()}"
Available Categories: ${jsonEncode(categoriesWithSubcategories)}
Available Accounts: ${jsonEncode(walletNames)}
${extraRules != null && extraRules.isNotEmpty ? "User Rules: $extraRules" : ""}

Rules:
1. amount: positive float. If none, set 0.0.
2. income: true for income/salary/credit/refund, false for expense/debit.
3. category & subcategory: match from available list or null.
4. wallet: match from available accounts or null.
5. date: ISO-8601 (YYYY-MM-DDTHH:mm:ss) relative to current timestamp, or null.
6. note: extra details or empty string.

Return ONLY raw JSON with format:
{"out": [{"title": "Vendor", "amount": 0.0, "income": false, "category": null, "subcategory": null, "wallet": null, "date": null, "note": ""}]}
Do not include markdown fences or explanation.
""";

    try {
      var resp = await http.post(
        Uri.parse("https://api.anthropic.com/v1/messages"),
        headers: {
          "Content-Type": "application/json",
          "x-api-key": key,
          "anthropic-version": "2023-06-01",
        },
        body: jsonEncode({
          "model": targetModel,
          "max_tokens": 1000,
          "system": systemPrompt,
          "messages": [
            {"role": "user", "content": text}
          ],
        }),
      ).timeout(const Duration(seconds: 14));

      if (resp.statusCode == 200) {
        var data = jsonDecode(resp.body);
        String? textResponse = data["content"]?[0]?["text"];
        if (textResponse != null) {
          return _parseOutArray(textResponse);
        }
      }
    } catch (e) {
      debugPrint("Claude parseTransactionText error: $e");
    }
    return null;
  }

  @override
  Future<List<ParsedAiTransaction>?> parseReceiptImage({
    required Uint8List imageBytes,
    required Map<String, List<String>> categoriesWithSubcategories,
    required List<String> walletNames,
    String? apiKey,
    String? model,
    String? customEndpoint,
  }) async {
    String key = (apiKey ?? "").trim();
    if (key.isEmpty) return null;

    String targetModel = _resolveModel(model);
    String base64Image = base64Encode(imageBytes);

    String systemPrompt = """
Analyze the receipt image and extract:
1. Store name as "title".
2. Grand total paid as positive "amount".
3. Date as "date" (YYYY-MM-DD or null).
4. Matched "category" & "subcategory" from: ${jsonEncode(categoriesWithSubcategories)}.
5. Matched "wallet" from: ${jsonEncode(walletNames)}.
6. Line items as "note".

Return ONLY raw JSON:
{"out": [{"title": "Store", "amount": 0.0, "income": false, "category": null, "subcategory": null, "wallet": null, "date": null, "note": ""}]}
""";

    try {
      var resp = await http.post(
        Uri.parse("https://api.anthropic.com/v1/messages"),
        headers: {
          "Content-Type": "application/json",
          "x-api-key": key,
          "anthropic-version": "2023-06-01",
        },
        body: jsonEncode({
          "model": targetModel,
          "max_tokens": 1000,
          "system": systemPrompt,
          "messages": [
            {
              "role": "user",
              "content": [
                {
                  "type": "image",
                  "source": {
                    "type": "base64",
                    "media_type": "image/jpeg",
                    "data": base64Image,
                  }
                },
                {
                  "type": "text",
                  "text": "Extract all transaction details from this receipt."
                }
              ]
            }
          ],
        }),
      ).timeout(const Duration(seconds: 22));

      if (resp.statusCode == 200) {
        var data = jsonDecode(resp.body);
        String? textResponse = data["content"]?[0]?["text"];
        if (textResponse != null) {
          return _parseOutArray(textResponse);
        }
      }
    } catch (e) {
      debugPrint("Claude parseReceiptImage error: $e");
    }
    return null;
  }

  String _cleanJson(String text) {
    String clean = text
        .replaceAll("```json", "")
        .replaceAll("```JSON", "")
        .replaceAll("```", "")
        .trim();
    int start = clean.indexOf('{');
    int end = clean.lastIndexOf('}');
    if (start != -1 && end != -1 && end >= start) {
      clean = clean.substring(start, end + 1);
    }
    return clean;
  }

  List<ParsedAiTransaction> _parseOutArray(String rawJson) {
    try {
      var parsed = jsonDecode(_cleanJson(rawJson));
      List<dynamic> items = [];
      if (parsed is Map && parsed["out"] is List) {
        items = parsed["out"];
      } else if (parsed is List) {
        items = parsed;
      } else if (parsed is Map) {
        items = [parsed];
      }

      List<ParsedAiTransaction> results = [];
      for (var item in items) {
        if (item is! Map) continue;
        DateTime? dt;
        if (item["date"] != null && item["date"].toString().isNotEmpty) {
          try {
            dt = DateTime.parse(item["date"].toString());
          } catch (_) {}
        }
        results.add(ParsedAiTransaction(
          title: item["title"] as String?,
          amount: (item["amount"] as num?)?.toDouble().abs(),
          income: item["income"] == true,
          categoryName: item["category"] as String?,
          subCategoryName: item["subcategory"] as String?,
          walletName: item["wallet"] as String?,
          dateTime: dt,
          note: item["note"] as String?,
        ));
      }
      return results;
    } catch (e) {
      debugPrint("Error parsing Claude out array: $e");
      return [];
    }
  }
}
