import 'dart:convert';
import 'package:budget/struct/ai/aiProvider.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class CustomAiProvider extends BaseAiProvider {
  @override
  AiProviderType get providerType => AiProviderType.custom;

  @override
  List<AiModelOption> get availableModels => const [
        AiModelOption(
          key: "deepseek/deepseek-chat",
          label: "DeepSeek V3",
          description: "Via OpenRouter: high performance and extremely economical.",
          isDefault: true,
        ),
        AiModelOption(
          key: "meta-llama/llama-3.3-70b-instruct",
          label: "Llama 3.3 70B",
          description: "Via OpenRouter: state-of-the-art open-weights model.",
        ),
        AiModelOption(
          key: "mistralai/mistral-small-24b-instruct-2501",
          label: "Mistral Small",
          description: "Via OpenRouter: fast, cost-effective reasoning.",
        ),
      ];

  String _resolveBaseUrl(String? customEndpoint) {
    if (customEndpoint == null || customEndpoint.trim().isEmpty) {
      return "https://openrouter.ai/api/v1";
    }
    String endpoint = customEndpoint.trim();
    if (endpoint.endsWith("/")) {
      endpoint = endpoint.substring(0, endpoint.length - 1);
    }
    return endpoint;
  }

  String _resolveModel(String? model) {
    if (model == null ||
        model.trim().isEmpty ||
        model.trim().toLowerCase() == "default") {
      return "deepseek/deepseek-chat";
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
    String baseUrl = _resolveBaseUrl(customEndpoint);
    String targetModel = _resolveModel(model);

    try {
      var resp = await http.post(
        Uri.parse("$baseUrl/chat/completions"),
        headers: {
          "Content-Type": "application/json",
          if (key.isNotEmpty) "Authorization": "Bearer $key",
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
          message: "Connected successfully to $baseUrl with $targetModel!",
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
    String baseUrl = _resolveBaseUrl(customEndpoint);
    String key = (apiKey ?? "").trim();
    String targetModel = _resolveModel(model);

    String systemPrompt = """
Classify the transaction title "$title" into the best category and subcategory from:
${jsonEncode(categoriesWithSubcategories)}

Return ONLY raw JSON with format:
{"category": "Category or null", "subcategory": "Subcategory or null"}
""";

    try {
      var resp = await http.post(
        Uri.parse("$baseUrl/chat/completions"),
        headers: {
          "Content-Type": "application/json",
          if (key.isNotEmpty) "Authorization": "Bearer $key",
        },
        body: jsonEncode({
          "model": targetModel,
          "messages": [
            {"role": "system", "content": systemPrompt},
            {"role": "user", "content": title}
          ],
          "temperature": 0.0,
        }),
      ).timeout(const Duration(seconds: 10));

      if (resp.statusCode == 200) {
        var data = jsonDecode(resp.body);
        String? content = data["choices"]?[0]?["message"]?["content"];
        if (content != null) {
          var json = jsonDecode(_cleanJson(content));
          return {
            "category": json["category"] as String?,
            "subcategory": json["subcategory"] as String?,
          };
        }
      }
    } catch (e) {
      debugPrint("Custom recommendCategory error: $e");
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
    String baseUrl = _resolveBaseUrl(customEndpoint);
    String key = (apiKey ?? "").trim();
    String targetModel = _resolveModel(model);
    DateTime ref = referenceTime ?? DateTime.now();

    String systemPrompt = """
You are a financial transaction extractor.
Current Timestamp: "${ref.toIso8601String()}"
Available Categories: ${jsonEncode(categoriesWithSubcategories)}
Available Accounts: ${jsonEncode(walletNames)}
${extraRules != null && extraRules.isNotEmpty ? "User Rules: $extraRules" : ""}

Rules:
1. amount: positive float.
2. income: true for credit/income/refund, false for expense/purchase/debit.
3. category & subcategory: match from available list or null.
4. wallet: match from available accounts or null.
5. date: ISO-8601 (YYYY-MM-DDTHH:mm:ss) relative to current timestamp, or null.
6. note: extra details or empty string.

Return ONLY raw JSON with format:
{"out": [{"title": "Vendor", "amount": 0.0, "income": false, "category": null, "subcategory": null, "wallet": null, "date": null, "note": ""}]}
""";

    try {
      var resp = await http.post(
        Uri.parse("$baseUrl/chat/completions"),
        headers: {
          "Content-Type": "application/json",
          if (key.isNotEmpty) "Authorization": "Bearer $key",
        },
        body: jsonEncode({
          "model": targetModel,
          "messages": [
            {"role": "system", "content": systemPrompt},
            {"role": "user", "content": text}
          ],
          "temperature": 0.1,
        }),
      ).timeout(const Duration(seconds: 16));

      if (resp.statusCode == 200) {
        var data = jsonDecode(resp.body);
        String? content = data["choices"]?[0]?["message"]?["content"];
        if (content != null) {
          return _parseOutArray(content);
        }
      }
    } catch (e) {
      debugPrint("Custom parseTransactionText error: $e");
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
    String baseUrl = _resolveBaseUrl(customEndpoint);
    String key = (apiKey ?? "").trim();
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
        Uri.parse("$baseUrl/chat/completions"),
        headers: {
          "Content-Type": "application/json",
          if (key.isNotEmpty) "Authorization": "Bearer $key",
        },
        body: jsonEncode({
          "model": targetModel,
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
        }),
      ).timeout(const Duration(seconds: 24));

      if (resp.statusCode == 200) {
        var data = jsonDecode(resp.body);
        String? content = data["choices"]?[0]?["message"]?["content"];
        if (content != null) {
          return _parseOutArray(content);
        }
      }
    } catch (e) {
      debugPrint("Custom parseReceiptImage error: $e");
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
      debugPrint("Error parsing Custom out array: $e");
      return [];
    }
  }
}
