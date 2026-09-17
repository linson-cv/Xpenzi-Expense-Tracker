import 'package:budget/colors.dart';
import 'package:budget/functions.dart';
import 'package:budget/pages/aiPromptPage.dart';
import 'package:budget/struct/ai/aiManager.dart';
import 'package:budget/struct/ai/aiProvider.dart';
import 'package:budget/struct/settings.dart';
import 'package:budget/widgets/button.dart';
import 'package:budget/widgets/framework/pageFramework.dart';
import 'package:budget/widgets/framework/popupFramework.dart';
import 'package:budget/widgets/globalSnackbar.dart';
import 'package:budget/widgets/openBottomSheet.dart';
import 'package:budget/widgets/openPopup.dart';
import 'package:budget/widgets/openSnackbar.dart';
import 'package:budget/widgets/settingsContainers.dart';
import 'package:budget/widgets/textInput.dart';
import 'package:budget/widgets/textWidgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' hide TextInput;

class AiSettingsPage extends StatefulWidget {
  const AiSettingsPage({super.key});

  @override
  State<AiSettingsPage> createState() => _AiSettingsPageState();
}

class _AiSettingsPageState extends State<AiSettingsPage> {
  late AiProviderType _selectedProviderType;
  late TextEditingController _apiKeyController;
  late TextEditingController _customEndpointController;
  late TextEditingController _extraRulesController;

  bool _obscureApiKey = true;
  bool _isTesting = false;
  bool? _testSuccess;
  String? _testMessage;

  @override
  void initState() {
    super.initState();
    _selectedProviderType = aiManager.activeProviderType;
    _apiKeyController = TextEditingController(
        text: appStateSettings[_selectedProviderType.keySettingName] ?? "");
    _customEndpointController = TextEditingController(
        text: appStateSettings["customAiEndpoint"] ?? "https://openrouter.ai/api/v1");
    _extraRulesController =
        TextEditingController(text: appStateSettings["aiExtraRules"] ?? "");

    if (_apiKeyController.text.trim().isNotEmpty) {
      _testSuccess = true;
    }
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    _customEndpointController.dispose();
    _extraRulesController.dispose();
    super.dispose();
  }

  void _onProviderChanged(AiProviderType newType) {
    if (_selectedProviderType == newType) return;
    HapticFeedback.lightImpact();
    setState(() {
      _selectedProviderType = newType;
      updateSettings("activeAiProvider", newType.id, updateGlobalState: true);
      _apiKeyController.text =
          appStateSettings[newType.keySettingName]?.toString() ?? "";
      _testSuccess = _apiKeyController.text.trim().isNotEmpty ? true : null;
      _testMessage = null;
    });
  }

  Future<void> _testConnection() async {
    String key = _apiKeyController.text.trim();
    if (key.isEmpty && _selectedProviderType != AiProviderType.custom) {
      HapticFeedback.heavyImpact();
      openSnackbar(
        SnackbarMessage(
          title: "Please enter an API Key first",
          icon: Icons.error_outline_rounded,
        ),
      );
      return;
    }

    setState(() => _isTesting = true);

    var result = await aiManager.testActiveConnection(
      providerOverride: _selectedProviderType,
      apiKeyOverride: key,
      customEndpointOverride: _customEndpointController.text.trim(),
    );

    if (!mounted) return;

    setState(() {
      _isTesting = false;
      _testSuccess = result.success;
      _testMessage = result.message;
    });

    if (result.success) {
      HapticFeedback.lightImpact();
      openSnackbar(
        SnackbarMessage(
          title: "Connection Successful!",
          description: result.message,
          icon: Icons.check_circle_outline_rounded,
        ),
      );
    } else {
      HapticFeedback.heavyImpact();
      openSnackbar(
        SnackbarMessage(
          title: "Connection Failed",
          description: result.message,
          icon: Icons.error_outline_rounded,
        ),
      );
    }
  }

  void _openModelPicker() {
    BaseAiProvider provider = aiManager.getProvider(_selectedProviderType);
    String currentModelKey =
        (appStateSettings[_selectedProviderType.modelSettingName] ??
                _selectedProviderType.defaultModel)
            .toString();

    openBottomSheet(
      context,
      PopupFramework(
        title: "Select ${_selectedProviderType.displayName} Model",
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ...provider.availableModels.map((option) {
              bool isSelected =
                  currentModelKey.toLowerCase() == option.key.toLowerCase() ||
                      (option.isDefault &&
                          (currentModelKey.isEmpty ||
                              currentModelKey.toLowerCase() == "default"));

              return ListTile(
                title: Row(
                  children: [
                    TextFont(
                      text: option.label,
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                    if (option.isDefault) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Theme.of(context)
                              .colorScheme
                              .primary
                              .withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: TextFont(
                          text: "Default",
                          fontSize: 10,
                          textColor: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ],
                  ],
                ),
                subtitle: TextFont(
                  text: option.description,
                  fontSize: 12,
                  textColor: getColor(context, "textLight"),
                ),
                trailing: isSelected
                    ? Icon(Icons.check_circle_rounded,
                        color: Theme.of(context).colorScheme.primary)
                    : null,
                onTap: () {
                  HapticFeedback.lightImpact();
                  updateSettings(
                    _selectedProviderType.modelSettingName,
                    option.key,
                    updateGlobalState: true,
                  );
                  popRoute(context);
                  setState(() {});
                },
              );
            }),
            ListTile(
              title: const TextFont(text: "Custom Model Name..."),
              subtitle: TextFont(
                text: "Specify any custom model identifier for this provider",
                fontSize: 12,
                textColor: getColor(context, "textLight"),
              ),
              leading: const Icon(Icons.edit_note_rounded),
              onTap: () {
                popRoute(context);
                _openCustomModelDialog();
              },
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  void _openCustomModelDialog() {
    TextEditingController customController = TextEditingController(
      text: appStateSettings[_selectedProviderType.modelSettingName] ?? "",
    );

    openPopup(
      context,
      title: "Custom Model Identifier",
      description: "Enter the model ID (e.g. gpt-4o, claude-3-5-sonnet):",
      onSubmitLabel: "Save",
      onSubmit: () {
        String entered = customController.text.trim();
        updateSettings(_selectedProviderType.modelSettingName, entered,
            updateGlobalState: true);
        HapticFeedback.lightImpact();
        popRoute(context);
        setState(() {});
      },
      onCancelLabel: "Cancel",
      onCancel: () => popRoute(context),
      descriptionWidget: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: TextInput(
          labelText: "Model Identifier",
          controller: customController,
          icon: Icons.memory_rounded,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    bool isAiEnabled = appStateSettings["geminiEnabled"] ?? true;
    bool hasKey = _apiKeyController.text.trim().isNotEmpty ||
        _selectedProviderType == AiProviderType.custom;

    return PageFramework(
      title: "AI & Intelligence",
      actions: [
        IconButton(
          icon: const Icon(Icons.help_outline_rounded),
          tooltip: "Provider Setup Guide",
          onPressed: () {
            openUrl(_selectedProviderType.getKeyUrl);
          },
        ),
      ],
      listWidgets: [
        // Master Enable Toggle
        SettingsGroupCard(
          title: "AI Engine",
          icon: Icons.auto_awesome_rounded,
          children: [
            SettingsContainerSwitch(
              title: "Enable AI Features",
              description:
                  "Powers auto-categorization, bank notification fallback, and receipt scanning",
              icon: Icons.power_settings_new_rounded,
              initialValue: isAiEnabled,
              onSwitched: (val) {
                updateSettings("geminiEnabled", val, updateGlobalState: true);
                setState(() {});
              },
            ),
          ],
        ),

        if (isAiEnabled) ...[
          // Provider Selection Segment
          SettingsGroupCard(
            title: "Select AI Provider",
            icon: Icons.hub_rounded,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextFont(
                      text:
                          "Choose your preferred AI service. Your API token is kept strictly local on your device.",
                      fontSize: 12.5,
                      textColor: getColor(context, "textLight"),
                    ),
                    const SizedBox(height: 12),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: AiProviderType.values.map((type) {
                          bool isSelected = _selectedProviderType == type;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ChoiceChip(
                              label: TextFont(
                                text: type.displayName,
                                fontSize: 12.5,
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                              selected: isSelected,
                              selectedColor: Theme.of(context)
                                  .colorScheme
                                  .primary
                                  .withValues(alpha: 0.2),
                              avatar: Icon(
                                type == AiProviderType.gemini
                                    ? Icons.auto_awesome_rounded
                                    : type == AiProviderType.openAi
                                        ? Icons.chat_bubble_outline_rounded
                                        : type == AiProviderType.claude
                                            ? Icons.psychology_rounded
                                            : Icons.dns_rounded,
                                size: 16,
                                color: isSelected
                                    ? Theme.of(context).colorScheme.primary
                                    : getColor(context, "textLight"),
                              ),
                              onSelected: (_) => _onProviderChanged(type),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Active Provider Configuration
          SettingsGroupCard(
            title: "${_selectedProviderType.displayName} Configuration",
            icon: Icons.key_rounded,
            children: [
              // Success or Setup Notice
              if (hasKey && (_testSuccess ?? false))
                Container(
                  margin:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.green.withValues(alpha: 0.45),
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle_rounded,
                          color: Colors.green, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextFont(
                          text:
                              "${_selectedProviderType.displayName} is active and ready for automatic tasks.",
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          textColor: Theme.of(context).brightness == Brightness.dark
                              ? Colors.greenAccent
                              : Colors.green.shade800,
                        ),
                      ),
                    ],
                  ),
                ),

              // Inline Connection Error Notice
              if (_testSuccess == false && _testMessage != null)
                Container(
                  margin:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.red.withValues(alpha: 0.45),
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.error_outline_rounded,
                          color: Colors.red, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            TextFont(
                              text: "Connection Failed",
                              fontSize: 12.5,
                              fontWeight: FontWeight.bold,
                              textColor: Colors.red,
                            ),
                            const SizedBox(height: 3),
                            TextFont(
                              text: _testMessage!,
                              fontSize: 11.5,
                              textColor: getColor(context, "textLight"),
                              maxLines: 4,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

              if (!hasKey)
                Container(
                  margin:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.orange.withValues(alpha: 0.45),
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline_rounded,
                          color: Colors.orange, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextFont(
                          text:
                              "Enter your ${_selectedProviderType.displayName} API key below to activate AI features.",
                          fontSize: 12.5,
                          textColor: getColor(context, "textLight"),
                        ),
                      ),
                    ],
                  ),
                ),

              // Custom Base URL (only for Custom / OpenRouter)
              if (_selectedProviderType == AiProviderType.custom)
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  child: TextInput(
                    labelText: "API Base URL",
                    controller: _customEndpointController,
                    icon: Icons.link_rounded,
                    onChanged: (text) {
                      updateSettings("customAiEndpoint", text.trim(),
                          updateGlobalState: true);
                    },
                  ),
                ),

              // API Key Field
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                child: TextInput(
                  labelText: "${_selectedProviderType.displayName} API Key",
                  controller: _apiKeyController,
                  icon: Icons.vpn_key_rounded,
                  obscureText: _obscureApiKey,
                  onChanged: (text) {
                    updateSettings(
                      _selectedProviderType.keySettingName,
                      text.trim(),
                      updateGlobalState: true,
                    );
                    setState(() {
                      _testSuccess = null;
                      _testMessage = null;
                    });
                  },
                ),
              ),

              // Key Actions: Get Key, Paste, Show/Hide, Test
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                child: Row(
                  children: [
                    InkWell(
                      borderRadius: BorderRadius.circular(8),
                      onTap: () => openUrl(_selectedProviderType.getKeyUrl),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 6),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.open_in_new_rounded, size: 14),
                            const SizedBox(width: 6),
                            const TextFont(
                              text: "Get API Key",
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const Spacer(),
                    if (_apiKeyController.text.isNotEmpty)
                      IconButton(
                        icon: const Icon(Icons.clear_rounded, size: 19),
                        tooltip: "Clear Key",
                        onPressed: () {
                          HapticFeedback.lightImpact();
                          _apiKeyController.clear();
                          updateSettings(
                            _selectedProviderType.keySettingName,
                            "",
                            updateGlobalState: true,
                          );
                          setState(() {
                            _testSuccess = null;
                            _testMessage = null;
                          });
                        },
                      ),
                    IconButton(
                      icon: Icon(
                        _obscureApiKey
                            ? Icons.visibility_rounded
                            : Icons.visibility_off_rounded,
                        size: 19,
                      ),
                      tooltip: _obscureApiKey ? "Show Key" : "Hide Key",
                      onPressed: () {
                        setState(() => _obscureApiKey = !_obscureApiKey);
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.paste_rounded, size: 19),
                      tooltip: "Paste Key",
                      onPressed: () async {
                        ClipboardData? data =
                            await Clipboard.getData(Clipboard.kTextPlain);
                        if (data != null && data.text != null) {
                          String pasted = data.text!.trim();
                          _apiKeyController.text = pasted;
                          updateSettings(
                            _selectedProviderType.keySettingName,
                            pasted,
                            updateGlobalState: true,
                          );
                          HapticFeedback.lightImpact();
                          setState(() {
                            _testSuccess = null;
                            _testMessage = null;
                          });
                          openSnackbar(
                            SnackbarMessage(
                              title: "Pasted API key",
                              icon: Icons.check_circle_outline_rounded,
                            ),
                          );
                        }
                      },
                    ),
                    const SizedBox(width: 4),
                    Button(
                      label: _isTesting ? "Testing..." : "Test",
                      icon: _isTesting ? Icons.hourglass_top_rounded : Icons.network_check_rounded,
                      disabled: _isTesting,
                      fontSize: 12,
                      padding: const EdgeInsetsDirectional.symmetric(
                          horizontal: 12, vertical: 6),
                      onTap: () {
                        if (!_isTesting) _testConnection();
                      },
                    ),
                  ],
                ),
              ),

              const Divider(height: 16),

              // Model Selector Row
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                child: Row(
                  children: [
                    const Icon(Icons.memory_rounded, size: 22),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const TextFont(
                          text: "Active Model",
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                        TextFont(
                          text: appStateSettings[
                                  _selectedProviderType.modelSettingName] ??
                              _selectedProviderType.defaultModel,
                          fontSize: 11,
                          textColor: getColor(context, "textLight"),
                        ),
                      ],
                    ),
                    const Spacer(),
                    InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: _openModelPicker,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: getColor(context, "canvasContainer"),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: getColor(context, "dividerColor"),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            TextFont(
                              text: (appStateSettings[_selectedProviderType
                                          .modelSettingName] ??
                                      _selectedProviderType.defaultModel)
                                  .toString(),
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                            ),
                            const SizedBox(width: 4),
                            const Icon(Icons.keyboard_arrow_down_rounded,
                                size: 18),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 4),
            ],
          ),

          // Pragmatic Automation & Background Features
          SettingsGroupCard(
            title: "Automation & Background Intelligence",
            icon: Icons.tune_rounded,
            children: [
              SettingsContainerSwitch(
                title: "Smart Category Suggestion",
                description:
                    "Automatically predict categories when entering merchant titles",
                icon: Icons.category_rounded,
                initialValue: appStateSettings["aiRecommendCategory"] ?? true,
                onSwitched: (val) {
                  updateSettings("aiRecommendCategory", val,
                      updateGlobalState: true);
                },
              ),
              const Divider(height: 1),
              SettingsContainerSwitch(
                title: "Bank Notification & SMS Fallback",
                description:
                    "Use AI to extract transaction amounts from unformatted bank alerts",
                icon: Icons.mark_email_read_rounded,
                initialValue: appStateSettings["aiNotificationFallback"] ?? true,
                onSwitched: (val) {
                  updateSettings("aiNotificationFallback", val,
                      updateGlobalState: true);
                },
              ),
              Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextInput(
                      labelText: "Custom Instructions / Rules",
                      controller: _extraRulesController,
                      icon: Icons.rule_rounded,
                      onChanged: (text) {
                        updateSettings("aiExtraRules", text,
                            updateGlobalState: true);
                      },
                    ),
                    const SizedBox(height: 6),
                    TextFont(
                      text:
                          "Optional guidelines for the AI (e.g., 'Treat all Uber expenses as Transport', 'Default to Credit Card').",
                      fontSize: 12,
                      textColor: getColor(context, "textLight"),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Shared Information & Transparency
          SettingsGroupCard(
            title: "Privacy & Transparency",
            icon: Icons.privacy_tip_rounded,
            children: [
              SettingsContainerSwitch(
                title: "Share Account Names",
                description: "Allows AI to match bank & card names",
                icon: Icons.account_balance_wallet_rounded,
                initialValue: appStateSettings["aiShareAccountNames"] ?? true,
                onSwitched: (val) {
                  updateSettings("aiShareAccountNames", val,
                      updateGlobalState: true);
                },
              ),
              const Divider(height: 1),
              SettingsContainerSwitch(
                title: "Share Category Names",
                description: "Allows AI to pick from your custom categories",
                icon: Icons.folder_rounded,
                initialValue: appStateSettings["aiShareCategoryNames"] ?? true,
                onSwitched: (val) {
                  updateSettings("aiShareCategoryNames", val,
                      updateGlobalState: true);
                },
              ),
              SettingsContainerOpenPage(
                title: "View AI Prompt & Transparency",
                description: "Inspect live prompts and schema definitions",
                icon: Icons.code_rounded,
                openPage: const AiPromptPage(),
              ),
            ],
          ),
        ],
        const SizedBox(height: 40),
      ],
    );
  }
}
