import 'package:budget/colors.dart';
import 'package:budget/functions.dart';
import 'package:budget/pages/aiPromptPage.dart';
import 'package:budget/struct/ai/aiManager.dart';
import 'package:budget/struct/ai/aiProvider.dart';
import 'package:budget/struct/settings.dart';
import 'package:budget/widgets/framework/pageFramework.dart';
import 'package:budget/widgets/framework/popupFramework.dart';
import 'package:budget/widgets/globalSnackbar.dart';
import 'package:budget/widgets/openBottomSheet.dart';
import 'package:budget/widgets/openPopup.dart';
import 'package:budget/widgets/openSnackbar.dart';
import 'package:budget/widgets/settingsContainers.dart';
import 'package:budget/widgets/tappable.dart';
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

  void _openProviderPicker() {
    openBottomSheet(
      context,
      PopupFramework(
        title: "Select AI Provider",
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ...AiProviderType.values.map((type) {
              bool isSelected = _selectedProviderType == type;

              String subtitle = "";
              IconData iconData = Icons.auto_awesome_rounded;
              switch (type) {
                case AiProviderType.gemini:
                  subtitle = "Free API key tier • Fast • Recommended";
                  iconData = Icons.auto_awesome_rounded;
                  break;
                case AiProviderType.openAi:
                  subtitle = "GPT-4o & GPT-4o-mini models";
                  iconData = Icons.chat_bubble_outline_rounded;
                  break;
                case AiProviderType.claude:
                  subtitle = "Claude 3.5 Sonnet & Claude 3.5 Haiku";
                  iconData = Icons.psychology_rounded;
                  break;
                case AiProviderType.custom:
                  subtitle = "OpenRouter, local Ollama, or OpenAI-compatible endpoint";
                  iconData = Icons.dns_rounded;
                  break;
              }

              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                child: Tappable(
                  borderRadius: 14,
                  color: isSelected
                      ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.12)
                      : Colors.transparent,
                  onTap: () {
                    HapticFeedback.lightImpact();
                    popRoute(context);
                    if (_selectedProviderType != type) {
                      _onProviderChanged(type);
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isSelected
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context).colorScheme.outline.withValues(alpha: 0.12),
                        width: isSelected ? 1.8 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.2)
                                : Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            iconData,
                            size: 19,
                            color: isSelected
                                ? Theme.of(context).colorScheme.primary
                                : getColor(context, "textLight"),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  TextFont(
                                    text: type.displayName,
                                    fontSize: 14.5,
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                                    textColor: isSelected
                                        ? Theme.of(context).colorScheme.primary
                                        : null,
                                  ),
                                  if (type == AiProviderType.gemini) ...[
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: Colors.green.withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: const TextFont(
                                        text: "Free Tier",
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        textColor: Colors.green,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 3),
                              TextFont(
                                text: subtitle,
                                fontSize: 11.5,
                                textColor: getColor(context, "textLight"),
                                maxLines: 1,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
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

              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                child: Tappable(
                  borderRadius: 14,
                  color: isSelected
                      ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.12)
                      : Colors.transparent,
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
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isSelected
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context).colorScheme.outline.withValues(alpha: 0.12),
                        width: isSelected ? 1.8 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  TextFont(
                                    text: option.label,
                                    fontSize: 14,
                                    fontWeight: isSelected
                                        ? FontWeight.bold
                                        : FontWeight.w600,
                                    textColor: isSelected
                                        ? Theme.of(context).colorScheme.primary
                                        : null,
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
                                        textColor: Theme.of(context)
                                            .colorScheme
                                            .primary,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 3),
                              TextFont(
                                text: option.description,
                                fontSize: 12,
                                textColor: getColor(context, "textLight"),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              child: ListTile(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
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
          // Provider Selection Dropdown Card
          SettingsGroupCard(
            title: "Select AI Provider",
            icon: Icons.hub_rounded,
            children: [
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                child: Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: Theme.of(context)
                            .colorScheme
                            .primary
                            .withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        _selectedProviderType == AiProviderType.gemini
                            ? Icons.auto_awesome_rounded
                            : _selectedProviderType == AiProviderType.openAi
                                ? Icons.chat_bubble_outline_rounded
                                : _selectedProviderType == AiProviderType.claude
                                    ? Icons.psychology_rounded
                                    : Icons.dns_rounded,
                        size: 20,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              TextFont(
                                text: _selectedProviderType.displayName,
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                              ),
                              if (_selectedProviderType == AiProviderType.gemini) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.green.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const TextFont(
                                    text: "Free Tier",
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    textColor: Colors.green,
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 3),
                          TextFont(
                            text: _selectedProviderType == AiProviderType.gemini
                                ? "Free tier available • Fast • Recommended"
                                : _selectedProviderType == AiProviderType.openAi
                                    ? "OpenAI GPT-4o & GPT-4o-mini"
                                    : _selectedProviderType == AiProviderType.claude
                                        ? "Anthropic Claude 3.5 Sonnet & Haiku"
                                        : "OpenRouter, local Ollama, or custom endpoint",
                            fontSize: 11.5,
                            textColor: getColor(context, "textLight"),
                            maxLines: 1,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Tappable(
                      borderRadius: 16,
                      color: Theme.of(context)
                          .colorScheme
                          .surfaceContainerHighest
                          .withValues(alpha: 0.7),
                      onTap: _openProviderPicker,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 7),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Theme.of(context)
                                .colorScheme
                                .outline
                                .withValues(alpha: 0.2),
                            width: 1.2,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            TextFont(
                              text: "Change",
                              fontSize: 12.5,
                              fontWeight: FontWeight.bold,
                              textColor: Theme.of(context).colorScheme.primary,
                            ),
                            const SizedBox(width: 4),
                            Icon(
                              Icons.keyboard_arrow_down_rounded,
                              size: 16,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ],
                        ),
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
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
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
                        visualDensity: VisualDensity.compact,
                        constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                        padding: EdgeInsets.zero,
                        icon: const Icon(Icons.clear_rounded, size: 18),
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
                      visualDensity: VisualDensity.compact,
                      constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                      padding: EdgeInsets.zero,
                      icon: Icon(
                        _obscureApiKey
                            ? Icons.visibility_rounded
                            : Icons.visibility_off_rounded,
                        size: 18,
                      ),
                      tooltip: _obscureApiKey ? "Show Key" : "Hide Key",
                      onPressed: () {
                        setState(() => _obscureApiKey = !_obscureApiKey);
                      },
                    ),
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                      padding: EdgeInsets.zero,
                      icon: const Icon(Icons.paste_rounded, size: 18),
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
                    const SizedBox(width: 6),
                    Tappable(
                      borderRadius: 10,
                      color: Theme.of(context).colorScheme.primaryContainer,
                      onTap: () {
                        if (!_isTesting) _testConnection();
                      },
                      child: Container(
                        height: 34,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        alignment: Alignment.center,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Icon(
                              _isTesting
                                  ? Icons.hourglass_top_rounded
                                  : Icons.network_check_rounded,
                              size: 16,
                              color: Theme.of(context).colorScheme.onPrimaryContainer,
                            ),
                            const SizedBox(width: 6),
                            TextFont(
                              text: _isTesting ? "Testing..." : "Test",
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                              textColor: Theme.of(context).colorScheme.onPrimaryContainer,
                            ),
                          ],
                        ),
                      ),
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
