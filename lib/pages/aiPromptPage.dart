import 'package:budget/colors.dart';
import 'package:budget/database/tables.dart';
import 'package:budget/struct/databaseGlobal.dart';
import 'package:budget/struct/geminiAi.dart';
import 'package:budget/struct/settings.dart';
import 'package:budget/widgets/framework/pageFramework.dart';
import 'package:budget/widgets/globalSnackbar.dart';
import 'package:budget/widgets/openSnackbar.dart';
import 'package:budget/widgets/textWidgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

class AiPromptPage extends StatefulWidget {
  const AiPromptPage({super.key});

  @override
  State<AiPromptPage> createState() => _AiPromptPageState();
}

class _AiPromptPageState extends State<AiPromptPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Map<String, List<String>> _categoriesMap = {};
  List<String> _walletsList = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadLiveContext();
  }

  Future<void> _loadLiveContext() async {
    try {
      var allCats = await database.getAllCategories();
      Map<String, List<String>> catsWithSubs = {};
      for (var c in allCats) {
        if (c.mainCategoryPk == null) {
          catsWithSubs[c.name] = [];
        }
      }
      for (var c in allCats) {
        if (c.mainCategoryPk != null) {
          for (var main in allCats) {
            if (main.categoryPk == c.mainCategoryPk) {
              catsWithSubs[main.name]?.add(c.name);
              break;
            }
          }
        }
      }
      var allWallets =
          Provider.of<AllWallets>(context, listen: false).list;
      setState(() {
        _categoriesMap = catsWithSubs;
        _walletsList = allWallets.map((w) => w.name).toList();
      });
    } catch (_) {}
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _copyToClipboard(String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    openSnackbar(
      SnackbarMessage(
        title: "Copied $label to clipboard",
        icon: Icons.copy_rounded,
      ),
    );
  }

  Widget _buildCodeBlock(String title, String content) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: getColor(context, "canvasContainer"),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: getColor(context, "dividerColor"),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.08),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(13)),
            ),
            child: Row(
              children: [
                Icon(Icons.terminal_rounded,
                    size: 16, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                TextFont(
                  text: title,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  textColor: Theme.of(context).colorScheme.primary,
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.copy_rounded, size: 16),
                  tooltip: "Copy",
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: () => _copyToClipboard(content, title),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: SelectableText(
              content,
              style: const TextStyle(
                fontFamily: "monospace",
                fontSize: 11.5,
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    String transactionPrompt = buildTransactionPrompt(
      input: "{USER_INPUT}",
      categoriesWithSubcategories: _categoriesMap,
      walletNames: _walletsList,
      extraRules: appStateSettings["aiExtraRules"] ?? "",
    );

    String categoryPrompt = buildCategoryRecommendationPrompt(
      title: "{TRANSACTION_TITLE}",
      categoriesWithSubcategories: _categoriesMap,
    );

    String receiptPrompt = buildReceiptPrompt(
      categoriesWithSubcategories: _categoriesMap,
      walletNames: _walletsList,
    );

    const String transactionSchema = '''{
  "type": "object",
  "properties": {
    "out": {
      "type": "array",
      "items": {
        "type": "object",
        "properties": {
          "title": {"type": "string"},
          "amount": {"type": "number"},
          "income": {"type": "boolean"},
          "category": {"type": ["string", "null"]},
          "subcategory": {"type": ["string", "null"]},
          "wallet": {"type": ["string", "null"]},
          "date": {"type": ["string", "null"]},
          "note": {"type": "string"}
        },
        "required": ["title", "amount", "income"]
      }
    }
  },
  "required": ["out"]
}''';

    const String categorySchema = '''{
  "type": "object",
  "properties": {
    "category": {"type": ["string", "null"]},
    "subcategory": {"type": ["string", "null"]}
  },
  "required": ["category"]
}''';

    const String receiptSchema = '''{
  "type": "object",
  "properties": {
    "out": {
      "type": "array",
      "items": {
        "type": "object",
        "properties": {
          "title": {"type": "string"},
          "amount": {"type": "number"},
          "income": {"type": "boolean"},
          "category": {"type": ["string", "null"]},
          "subcategory": {"type": ["string", "null"]},
          "wallet": {"type": ["string", "null"]},
          "date": {"type": ["string", "null"]},
          "note": {"type": "string"}
        },
        "required": ["title", "amount"]
      }
    }
  },
  "required": ["out"]
}''';

    return PageFramework(
      title: "AI Prompt",
      listWidgets: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFont(
                text: "AI Prompt & Transparency",
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
              const SizedBox(height: 4),
              TextFont(
                text:
                    "See what information is sent to your AI provider (${aiManager.activeProvider.providerType.displayName}) and the exact structured prompt templates when using AI features in Xpenzi.",
                fontSize: 13,
                textColor: getColor(context, "textLight"),
              ),
            ],
          ),
        ),

        // Tabs Header
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: getColor(context, "canvasContainer"),
            borderRadius: BorderRadius.circular(14),
          ),
          child: TabBar(
            controller: _tabController,
            indicatorSize: TabBarIndicatorSize.tab,
            indicator: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
              borderRadius: BorderRadius.circular(14),
            ),
            labelColor: Theme.of(context).colorScheme.onPrimary,
            unselectedLabelColor: getColor(context, "textLight"),
            tabs: const [
              Tab(text: "Text Input"),
              Tab(text: "Category"),
              Tab(text: "Receipts"),
            ],
          ),
        ),

        // Tab Contents
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: AnimatedBuilder(
            animation: _tabController,
            builder: (context, _) {
              int index = _tabController.index;
              String providerName = aiManager.activeProvider.providerType.displayName;
              if (index == 0) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.edit_note_rounded, size: 20),
                        const SizedBox(width: 8),
                        const TextFont(
                          text: "create-transaction-from-input",
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    TextFont(
                      text:
                          "Information sent to $providerName when you type or paste a natural language transaction prompt.",
                      fontSize: 12,
                      textColor: getColor(context, "textLight"),
                    ),
                    const SizedBox(height: 8),
                    _buildCodeBlock("System Instruction & Prompt", transactionPrompt),
                    _buildCodeBlock("JSON Output Schema (Enforced via API)", transactionSchema),
                  ],
                );
              } else if (index == 1) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.category_rounded, size: 20),
                        const SizedBox(width: 8),
                        const TextFont(
                          text: "generate-category-from-title",
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    TextFont(
                      text:
                          "Information sent to $providerName to automatically recommend a category and subcategory based on a transaction title.",
                      fontSize: 12,
                      textColor: getColor(context, "textLight"),
                    ),
                    const SizedBox(height: 8),
                    _buildCodeBlock("System Instruction & Prompt", categoryPrompt),
                    _buildCodeBlock("JSON Output Schema (Enforced via API)", categorySchema),
                  ],
                );
              } else {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.receipt_long_rounded, size: 20),
                        const SizedBox(width: 8),
                        const TextFont(
                          text: "generate-transaction-from-image",
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    TextFont(
                      text:
                          "Information sent to $providerName vision model when scanning a receipt or invoice photo.",
                      fontSize: 12,
                      textColor: getColor(context, "textLight"),
                    ),
                    const SizedBox(height: 8),
                    _buildCodeBlock("System Instruction & Prompt", receiptPrompt),
                    _buildCodeBlock("JSON Output Schema (Enforced via API)", receiptSchema),
                  ],
                );
              }
            },
          ),
        ),
        const SizedBox(height: 40),
      ],
    );
  }
}
