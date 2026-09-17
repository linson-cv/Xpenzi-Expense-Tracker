import 'dart:convert';
import 'package:budget/struct/ai/aiProvider.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class OpenAiProvider extends BaseAiProvider {
  @override
  AiProviderType get providerType => AiProviderType.openAi;

  @override
  List<AiModelOption> get availableModels => const [
        AiModelOption(
          key: "gpt-4o-mini",
          label: "GPT-4o mini",
          description: "Recommended: Ultra fast, cost-effective, and highly intelligent.",
          isDefault: true,
        ),
        AiModelOption(
          key: "gpt-4o",
          label: "GPT-4o",
          description: "Flagship high-intelligence model for multimodal reasoning.",
        ),
        AiModelOption(
          key: "gpt-3.5-turbo",
          label: "GPT-3.5 Turbo",
          description: "Legacy lightweight model.",
        ),
      ];

  String _resolveModel(String? model) {
    if (model == null ||
        model.trim().isEmpty ||
        model.trim().toLowerCase() == "default") {
      return "gpt-4o-mini";
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
        message: "Please enter an OpenAI API key (starts with 'sk-').",
      );
    }

    if (key.startsWith("AIza") || key.startsWith("AQ.")) {
      return const AiConnectionTestResult(
        success: false,
        message:
            "This appears to be a Google Gemini key. Please select the Google Gemini provider tab.",
        statusCode: 400,
      );
    }

    String targetModel = _resolveModel(model);
    try {
      var resp = await http.post(
        Uri.parse("https://api.openai.com/v1/chat/completions"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $key",
        },
        body: jsonEncode({
          "model": targetModel,
          "messages": [
            {"role": "user", "content": "ping"}
          ],
          "max_tokens": 5,
        }),
      ).timeout(const Duration(seconds: 12));

      if (resp.statusCode == 200) {
        return AiConnectionTestResult(
          success: true,
          message: "Connected successfully to OpenAI with $targetModel!",
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

Return ONLY raw JSON with this format:
{"category": "Category or null", "subcategory": "Subcategory or null"}
""";

    try {
      var resp = await http.post(
        Uri.parse("https://api.openai.com/v1/chat/completions"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $key",
        },
        body: jsonEncode({
          "model": targetModel,
          "response_format": {"type": "json_object"},
          "messages": [
            {"role": "system", "content": systemPrompt},
            {"role": "user", "content": title}
          ],
          "temperature": 0.0,
        }),
      ).timeout(const Duration(seconds: 8));

      if (resp.statusCode == 200) {
        var data = jsonDecode(resp.body);
        String? content = data["choices"]?[0]?["message"]?["content"];
        if (content != null) {
          var json = jsonDecode(content);
          return {
            "category": json["category"] as String?,
            "subcategory": json["subcategory"] as String?,
          };
        }
      }
    } catch (e) {
      debugPrint("OpenAI recommendCategory error: $e");
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
""";

    try {
      var resp = await http.post(
        Uri.parse("https://api.openai.com/v1/chat/completions"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $key",
        },
        body: jsonEncode({
          "model": targetModel,
          "response_format": {"type": "json_object"},
          "messages": [
            {"role": "system", "content": systemPrompt},
            {"role": "user", "content": text}
          ],
          "temperature": 0.1,
        }),
      ).timeout(const Duration(seconds: 14));

      if (resp.statusCode == 200) {
        var data = jsonDecode(resp.body);
        String? content = data["choices"]?[0]?["message"]?["content"];
        if (content != null) {
          return _parseOutArray(content);
        }
      }
    } catch (e) {
      debugPrint("OpenAI parseTransactionText error: $e");
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
        Uri.parse("https://api.openai.com/v1/chat/completions"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $key",
        },
        body: jsonEncode({
          "model": targetModel,
          "response_format": {"type": "json_object"},
          "messages": [
            {"role": "system", "content": systemPrompt},
            {
              "role": "user",
              "content": [
                {
                  "type": "text",
                  "text": "Extract all transaction details from this receipt."
                },
                {
                  "type": "image_url",
                  "image_url": {
                    "url": "data:image/jpeg;base64,$base64Image"
                  }
                }
              ]
            }
          ],
          "max_tokens": 1000,
        }),
      ).timeout(const Duration(seconds: 22));

      if (resp.statusCode == 200) {
        var data = jsonDecode(resp.body);
        String? content = data["choices"]?[0]?["message"]?["content"];
        if (content != null) {
          return _parseOutArray(content);
        }
      }
    } catch (e) {
      debugPrint("OpenAI parseReceiptImage error: $e");
    }
    return null;
  }

  List<ParsedAiTransaction> _parseOutArray(String rawJson) {
    try {
      var parsed = jsonDecode(rawJson);
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
      debugPrint("Error parsing OpenAI out array: $e");
      return [];
    }
  }
}
