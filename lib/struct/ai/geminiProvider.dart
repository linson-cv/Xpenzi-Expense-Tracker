import 'dart:convert';
import 'package:budget/struct/ai/aiProvider.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class GeminiAiProvider extends BaseAiProvider {
  @override
  AiProviderType get providerType => AiProviderType.gemini;

  @override
  List<AiModelOption> get availableModels => const [
        AiModelOption(
          key: "gemini-1.5-flash",
          label: "Gemini 1.5 Flash",
          description: "Recommended: Generous free quota, ultra fast and lightweight.",
          isDefault: true,
        ),
        AiModelOption(
          key: "gemini-2.0-flash",
          label: "Gemini 2.0 Flash",
          description: "Next-generation model with enhanced speed and accuracy.",
        ),
        AiModelOption(
          key: "gemini-1.5-pro",
          label: "Gemini 1.5 Pro",
          description: "Maximum reasoning capability for complex text and prompts.",
        ),
        AiModelOption(
          key: "gemini-1.5-flash-8b",
          label: "Gemini 1.5 Flash-8B",
          description: "Ultra-high throughput, lowest latency.",
        ),
      ];

  String _resolveModel(String? model) {
    if (model == null ||
        model.trim().isEmpty ||
        model.trim().toLowerCase() == "default") {
      return "gemini-1.5-flash";
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
        message: "Please enter a Google Gemini API key.",
      );
    }

    if (key.startsWith("sk-") && !key.startsWith("sk-ant-")) {
      return const AiConnectionTestResult(
        success: false,
        message:
            "This appears to be an OpenAI key ('sk-...'). Please select the OpenAI provider tab or enter a Gemini key.",
        statusCode: 400,
      );
    }

    bool keyValid = false;
    try {
      var listResp = await http.get(
        Uri.parse(
            "https://generativelanguage.googleapis.com/v1beta/models?key=$key"),
      ).timeout(const Duration(seconds: 10));

      if (listResp.statusCode == 200) {
        keyValid = true;
      } else if (listResp.statusCode == 400 || listResp.statusCode == 403) {
        String msg = "Invalid API Key or unauthorized.";
        try {
          var err = jsonDecode(listResp.body);
          if (err["error"]?["message"] != null) {
            msg = err["error"]["message"];
          }
        } catch (_) {}
        return AiConnectionTestResult(
          success: false,
          message: msg,
          statusCode: listResp.statusCode,
        );
      }
    } catch (e) {
      debugPrint("Gemini list models notice: $e");
    }

    String targetModel = _resolveModel(model);
    try {
      var resp = await http.post(
        Uri.parse(
            "https://generativelanguage.googleapis.com/v1beta/models/$targetModel:generateContent?key=$key"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "contents": [
            {
              "parts": [
                {"text": "Ping"}
              ]
            }
          ]
        }),
      ).timeout(const Duration(seconds: 12));

      if (resp.statusCode == 200) {
        return AiConnectionTestResult(
          success: true,
          message: "Connected successfully with $targetModel!",
          statusCode: 200,
        );
      } else if (keyValid) {
        return const AiConnectionTestResult(
          success: true,
          message: "API Key verified successfully with Google AI Studio!",
          statusCode: 200,
        );
      } else {
        String msg = "HTTP ${resp.statusCode}: ${resp.reasonPhrase}";
        try {
          var err = jsonDecode(resp.body);
          if (err["error"]?["message"] != null) msg = err["error"]["message"];
        } catch (_) {}
        return AiConnectionTestResult(
          success: false,
          message: msg,
          statusCode: resp.statusCode,
        );
      }
    } catch (e) {
      if (keyValid) {
        return const AiConnectionTestResult(
          success: true,
          message: "API Key verified with Google Gemini!",
          statusCode: 200,
        );
      }
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

    String prompt = """
Classify the transaction title "$title" into the best category and subcategory from this catalog:
$catJson

Rules:
1. Choose ONLY from the catalog.
2. If no subcategory fits, set subcategory to null.
3. If no category fits, set category to null.

Return ONLY raw JSON:
{"category": "name or null", "subcategory": "name or null"}
""";

    try {
      var resp = await http.post(
        Uri.parse(
            "https://generativelanguage.googleapis.com/v1beta/models/$targetModel:generateContent?key=$key"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "contents": [
            {
              "parts": [
                {"text": prompt}
              ]
            }
          ],
          "generationConfig": {
            "response_mime_type": "application/json",
            "temperature": 0.0,
          }
        }),
      ).timeout(const Duration(seconds: 8));

      if (resp.statusCode == 200) {
        var data = jsonDecode(resp.body);
        String? text =
            data["candidates"]?[0]?["content"]?["parts"]?[0]?["text"];
        if (text != null) {
          var json = jsonDecode(_cleanJson(text));
          return {
            "category": json["category"] as String?,
            "subcategory": json["subcategory"] as String?,
          };
        }
      }
    } catch (e) {
      debugPrint("Gemini recommendCategory error: $e");
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
    String catJson = jsonEncode(categoriesWithSubcategories);
    String walletJson = jsonEncode(walletNames);

    String prompt = """
You are a financial transaction extractor.
Current Timestamp: "${ref.toIso8601String()}"
Available Categories: $catJson
Available Accounts: $walletJson
${extraRules != null && extraRules.isNotEmpty ? "User Rules: $extraRules" : ""}

Extract details from this text: "$text"

Rules:
1. amount: strictly positive float. If none, set 0.0.
2. income: true for income/salary/credit/refund, false for expense/purchase/debit.
3. category & subcategory: match from available categories or null.
4. wallet: match from available accounts or null.
5. date: ISO-8601 (YYYY-MM-DDTHH:mm:ss) relative to current timestamp, or null.
6. note: extra details or empty string.

Return ONLY raw JSON:
{"out": [{"title": "Vendor", "amount": 0.0, "income": false, "category": null, "subcategory": null, "wallet": null, "date": null, "note": ""}]}
""";

    try {
      var resp = await http.post(
        Uri.parse(
            "https://generativelanguage.googleapis.com/v1beta/models/$targetModel:generateContent?key=$key"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "contents": [
            {
              "parts": [
                {"text": prompt}
              ]
            }
          ],
          "generationConfig": {
            "response_mime_type": "application/json",
            "temperature": 0.1,
          }
        }),
      ).timeout(const Duration(seconds: 14));

      if (resp.statusCode == 200) {
        var data = jsonDecode(resp.body);
        String? content =
            data["candidates"]?[0]?["content"]?["parts"]?[0]?["text"];
        if (content != null) {
          return _parseOutArray(content);
        }
      }
    } catch (e) {
      debugPrint("Gemini parseTransactionText error: $e");
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
    String prompt = """
Analyze this receipt image and extract:
1. Store or merchant name as "title".
2. Grand total paid as positive "amount".
3. Date printed as "date" (YYYY-MM-DD or null).
4. Matched "category" and "subcategory" from ${jsonEncode(categoriesWithSubcategories)}.
5. Matched "wallet" from ${jsonEncode(walletNames)} or null.
6. Purchased line items as "note".

Return ONLY raw JSON:
{"out": [{"title": "Store", "amount": 0.0, "income": false, "category": null, "subcategory": null, "wallet": null, "date": null, "note": ""}]}
""";

    try {
      String base64Image = base64Encode(imageBytes);
      var resp = await http.post(
        Uri.parse(
            "https://generativelanguage.googleapis.com/v1beta/models/$targetModel:generateContent?key=$key"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "contents": [
            {
              "parts": [
                {"text": prompt},
                {
                  "inline_data": {
                    "mime_type": "image/jpeg",
                    "data": base64Image,
                  }
                }
              ]
            }
          ],
          "generationConfig": {
            "response_mime_type": "application/json",
            "temperature": 0.1,
          }
        }),
      ).timeout(const Duration(seconds: 20));

      if (resp.statusCode == 200) {
        var data = jsonDecode(resp.body);
        String? content =
            data["candidates"]?[0]?["content"]?["parts"]?[0]?["text"];
        if (content != null) {
          return _parseOutArray(content);
        }
      }
    } catch (e) {
      debugPrint("Gemini parseReceiptImage error: $e");
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
      debugPrint("Error parsing out array: $e");
      return [];
    }
  }
}
