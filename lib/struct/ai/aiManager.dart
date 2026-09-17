import 'dart:typed_data';
import 'package:budget/database/tables.dart';
import 'package:budget/struct/ai/aiProvider.dart';
import 'package:budget/struct/ai/claudeProvider.dart';
import 'package:budget/struct/ai/customProvider.dart';
import 'package:budget/struct/ai/geminiProvider.dart';
import 'package:budget/struct/ai/openAiProvider.dart';
import 'package:budget/struct/databaseGlobal.dart';
import 'package:budget/struct/settings.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class AiManager {
  static final AiManager _instance = AiManager._internal();
  factory AiManager() => _instance;
  AiManager._internal();

  final Map<AiProviderType, BaseAiProvider> _providers = {
    AiProviderType.gemini: GeminiAiProvider(),
    AiProviderType.openAi: OpenAiProvider(),
    AiProviderType.claude: ClaudeProvider(),
    AiProviderType.custom: CustomAiProvider(),
  };

  BaseAiProvider getProvider(AiProviderType type) {
    return _providers[type] ?? _providers[AiProviderType.gemini]!;
  }

  AiProviderType get activeProviderType {
    String? stored = appStateSettings["activeAiProvider"]?.toString();
    return getProviderTypeFromId(stored);
  }

  BaseAiProvider get activeProvider => getProvider(activeProviderType);

  bool get isAiEnabled => appStateSettings["geminiEnabled"] ?? true;

  String getActiveApiKey() {
    String keySetting = activeProviderType.keySettingName;
    return (appStateSettings[keySetting] ?? "").toString().trim();
  }

  String getActiveModel() {
    String modelSetting = activeProviderType.modelSettingName;
    String? stored = appStateSettings[modelSetting]?.toString().trim();
    if (stored == null || stored.isEmpty || stored.toLowerCase() == "default") {
      return activeProviderType.defaultModel;
    }
    return stored;
  }

  bool isConfigured() {
    if (!isAiEnabled) return false;
    if (activeProviderType == AiProviderType.custom) {
      return (appStateSettings["customAiEndpoint"] ?? "").toString().trim().isNotEmpty;
    }
    return getActiveApiKey().isNotEmpty;
  }

  Future<AiConnectionTestResult> testActiveConnection({
    AiProviderType? providerOverride,
    String? apiKeyOverride,
    String? modelOverride,
    String? customEndpointOverride,
  }) async {
    AiProviderType type = providerOverride ?? activeProviderType;
    BaseAiProvider provider = getProvider(type);

    String key = apiKeyOverride ??
        (appStateSettings[type.keySettingName] ?? "").toString().trim();
    String model = modelOverride ??
        (appStateSettings[type.modelSettingName] ?? "").toString().trim();
    String? endpoint = customEndpointOverride ??
        appStateSettings["customAiEndpoint"]?.toString().trim();

    return await provider.testConnection(
      apiKey: key,
      model: model,
      customEndpoint: endpoint,
    );
  }

  Future<Map<String, String?>?> recommendCategory(
      String title, BuildContext context) async {
    if (!isConfigured()) return null;

    Map<String, List<String>> categoriesWithSubcategories =
        await _buildCategoryTree();

    return await activeProvider.recommendCategory(
      title: title,
      categoriesWithSubcategories: categoriesWithSubcategories,
      apiKey: getActiveApiKey(),
      model: getActiveModel(),
      customEndpoint: appStateSettings["customAiEndpoint"]?.toString(),
    );
  }

  Future<List<ParsedAiTransaction>?> parseTransactionText(
      String text, BuildContext context) async {
    if (!isConfigured()) return null;

    Map<String, List<String>> categoriesWithSubcategories =
        await _buildCategoryTree();
    List<String> wallets = _buildWalletsList(context);

    return await activeProvider.parseTransactionText(
      text: text,
      categoriesWithSubcategories: categoriesWithSubcategories,
      walletNames: wallets,
      extraRules: appStateSettings["aiExtraRules"]?.toString(),
      referenceTime: DateTime.now(),
      apiKey: getActiveApiKey(),
      model: getActiveModel(),
      customEndpoint: appStateSettings["customAiEndpoint"]?.toString(),
    );
  }

  Future<List<ParsedAiTransaction>?> parseReceipt(
      Uint8List imageBytes, BuildContext context) async {
    if (!isConfigured()) return null;

    Map<String, List<String>> categoriesWithSubcategories =
        await _buildCategoryTree();
    List<String> wallets = _buildWalletsList(context);

    return await activeProvider.parseReceiptImage(
      imageBytes: imageBytes,
      categoriesWithSubcategories: categoriesWithSubcategories,
      walletNames: wallets,
      apiKey: getActiveApiKey(),
      model: getActiveModel(),
      customEndpoint: appStateSettings["customAiEndpoint"]?.toString(),
    );
  }

  Future<Map<String, List<String>>> _buildCategoryTree() async {
    Map<String, List<String>> result = {};
    if (appStateSettings["aiShareCategoryNames"] == false) return result;

    try {
      var allCats = await database.getAllCategories();
      for (var c in allCats) {
        if (c.mainCategoryPk == null) result[c.name] = [];
      }
      for (var c in allCats) {
        if (c.mainCategoryPk != null) {
          for (var main in allCats) {
            if (main.categoryPk == c.mainCategoryPk) {
              result[main.name]?.add(c.name);
              break;
            }
          }
        }
      }
    } catch (_) {}
    return result;
  }

  List<String> _buildWalletsList(BuildContext context) {
    if (appStateSettings["aiShareAccountNames"] == false) return [];
    try {
      return Provider.of<AllWallets>(context, listen: false)
          .list
          .map((w) => w.name)
          .toList();
    } catch (_) {
      return [];
    }
  }
}

final aiManager = AiManager();
