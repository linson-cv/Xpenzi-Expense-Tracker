import 'package:budget/colors.dart';
import 'package:budget/functions.dart';
import 'package:budget/struct/settings.dart';
import 'package:budget/widgets/button.dart';
import 'package:budget/widgets/framework/pageFramework.dart';
import 'package:budget/widgets/openPopup.dart';
import 'package:budget/widgets/settingsContainers.dart';
import 'package:budget/widgets/textInput.dart';
import 'package:budget/widgets/textWidgets.dart';
import 'package:flutter/material.dart';

class AiSettingsPage extends StatefulWidget {
  const AiSettingsPage({super.key});

  @override
  State<AiSettingsPage> createState() => _AiSettingsPageState();
}

class _AiSettingsPageState extends State<AiSettingsPage> {
  late TextEditingController _apiKeyController;
  late TextEditingController _extraRulesController;

  @override
  void initState() {
    super.initState();
    _apiKeyController =
        TextEditingController(text: appStateSettings["geminiApiKey"] ?? "");
    _extraRulesController =
        TextEditingController(text: appStateSettings["aiExtraRules"] ?? "");
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    _extraRulesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    bool isApiKeyMissing =
        (appStateSettings["geminiApiKey"] ?? "").trim().isEmpty;
    return PageFramework(
      title: "Xpenzi Intelligence",
      actions: [
        IconButton(
          icon: const Icon(Icons.help_outline_rounded),
          tooltip: "Help",
          onPressed: () {
            openUrl("https://aistudio.google.com/app/apikey");
          },
        ),
      ],
      listWidgets: [
        // Header Overview Card
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: SettingsGroupCard(
            title: "Xpenzi Intelligence Overview",
            icon: Icons.auto_awesome_rounded,
            children: [
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextFont(
                      text:
                          "Xpenzi Intelligence uses Google Gemini AI to parse transaction details, suggest categories, and process incoming notifications. AI can make mistakes. This is an optional feature.",
                      fontSize: 13,
                      textColor: getColor(context, "textLight"),
                    ),
                    const SizedBox(height: 12),
                    Button(
                      label: "View Setup Guide",
                      icon: Icons.open_in_new_rounded,
                      onTap: () {
                        openUrl("https://aistudio.google.com/app/apikey");
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Gemini Model Provider Container
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: SettingsGroupCard(
            title: "Google Gemini Model",
            icon: Icons.psychology_rounded,
            children: [
              SettingsContainerSwitch(
                title: "Google Gemini Provider",
                description: "Online AI parsing model",
                icon: Icons.auto_awesome_rounded,
                initialValue: appStateSettings["geminiEnabled"] ?? true,
                onSwitched: (val) {
                  updateSettings("geminiEnabled", val, updateGlobalState: true);
                  setState(() {});
                },
              ),

              // Missing API Key Alert Box
              if (isApiKeyMissing)
                Container(
                  margin: const EdgeInsets.all(12),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: Colors.red.withValues(alpha: 0.5),
                      width: 1.5,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.warning_amber_rounded,
                              color: Colors.red.shade400, size: 22),
                          const SizedBox(width: 8),
                          const TextFont(
                            text: "Missing API Key",
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            textColor: Colors.red,
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      TextFont(
                        text:
                            "A Google Gemini API key is required to enable intelligent parsing. Enter it below or tap 'Get API Key'.",
                        fontSize: 13,
                        textColor: getColor(context, "textLight"),
                      ),
                    ],
                  ),
                ),

              // API Key Text Field
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: TextInput(
                  labelText: "Gemini API Key",
                  controller: _apiKeyController,
                  icon: Icons.key_rounded,
                  onChanged: (text) {
                    updateSettings("geminiApiKey", text.trim(),
                        updateGlobalState: true);
                    setState(() {});
                  },
                ),
              ),

              // Get API Key Link
              SettingsContainer(
                title: "Get API Key",
                description: "Generate a free Gemini API key on Google AI Studio",
                icon: Icons.vpn_key_rounded,
                onTap: () {
                  openUrl("https://aistudio.google.com/app/apikey");
                },
              ),

              // Model Selection
              SettingsContainerDropdown(
                title: "AI Model",
                icon: Icons.memory_rounded,
                initial: appStateSettings["geminiModel"] ?? "gemini-1.5-flash",
                items: const [
                  "gemini-1.5-flash",
                  "gemini-1.5-pro",
                  "gemini-2.0-flash",
                ],
                onChanged: (val) {
                  updateSettings("geminiModel", val, updateGlobalState: true);
                },
              ),
            ],
          ),
        ),

        // Intelligence Settings Section
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: SettingsGroupCard(
            title: "Intelligence Settings",
            icon: Icons.tune_rounded,
            children: [
              SettingsContainerSwitch(
                title: "Edit Before Adding",
                description: "When creating a transaction with a prompt",
                icon: Icons.edit_note_rounded,
                initialValue: appStateSettings["aiEditBeforeAdding"] ?? true,
                onSwitched: (val) {
                  updateSettings("aiEditBeforeAdding", val,
                      updateGlobalState: true);
                },
              ),
              const Divider(height: 1),
              SettingsContainerSwitch(
                title: "Recommend Category",
                description: "Based on a new transaction's title",
                icon: Icons.category_rounded,
                initialValue: appStateSettings["aiRecommendCategory"] ?? true,
                onSwitched: (val) {
                  updateSettings("aiRecommendCategory", val,
                      updateGlobalState: true);
                },
              ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextInput(
                      labelText: "Extra Rules",
                      controller: _extraRulesController,
                      icon: Icons.rule_rounded,
                      onChanged: (text) {
                        updateSettings("aiExtraRules", text,
                            updateGlobalState: true);
                      },
                    ),
                    const SizedBox(height: 4),
                    TextFont(
                      text:
                          "Specify extra rules that the AI will consider before an output is generated.",
                      fontSize: 12,
                      textColor: getColor(context, "textLight"),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Shared Information Section
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: SettingsGroupCard(
            title: "Shared Information",
            icon: Icons.privacy_tip_rounded,
            children: [
              Padding(
                padding: const EdgeInsets.all(12),
                child: TextFont(
                  text:
                      "To make accurate predictions, selected details are included with your prompt. You can customize shared information below.",
                  fontSize: 13,
                  textColor: getColor(context, "textLight"),
                ),
              ),
              SettingsContainerSwitch(
                title: "Account Names",
                description: "ICICI, Credit Card, Cash...",
                icon: Icons.account_balance_wallet_rounded,
                initialValue: appStateSettings["aiShareAccountNames"] ?? true,
                onSwitched: (val) {
                  updateSettings("aiShareAccountNames", val,
                      updateGlobalState: true);
                },
              ),
              const Divider(height: 1),
              SettingsContainerSwitch(
                title: "Category Names",
                description: "Food, Bills, Shopping...",
                icon: Icons.category_rounded,
                initialValue: appStateSettings["aiShareCategoryNames"] ?? true,
                onSwitched: (val) {
                  updateSettings("aiShareCategoryNames", val,
                      updateGlobalState: true);
                },
              ),
              const Divider(height: 1),
              SettingsContainerSwitch(
                title: "Loan Names",
                description: "Lent / Borrowed Contacts...",
                icon: Icons.handshake_rounded,
                initialValue: appStateSettings["aiShareLoanNames"] ?? false,
                onSwitched: (val) {
                  updateSettings("aiShareLoanNames", val,
                      updateGlobalState: true);
                },
              ),
              SettingsContainer(
                title: "AI Prompt Details",
                description: "View structure of prompt sent to Gemini",
                icon: Icons.chat_bubble_outline_rounded,
                onTap: () {
                  openPopup(
                    context,
                    title: "AI Prompt Details",
                    description:
                        "Structure of system prompt sent to Gemini:\n\n"
                        "1. Extractor System Rules\n"
                        "2. User Category list (if enabled)\n"
                        "3. Account Names (if enabled)\n"
                        "4. Extra Rules\n"
                        "5. User Input Text",
                    onSubmit: () => popRoute(context),
                    onSubmitLabel: "Close",
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}
