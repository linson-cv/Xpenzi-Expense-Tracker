import 'package:budget/colors.dart';
import 'package:budget/functions.dart';
import 'package:budget/pages/addTransactionPage.dart';
import 'package:budget/pages/aiSettingsPage.dart';
import 'package:budget/pages/transactionsSearchPage.dart';
import 'package:budget/struct/ai/aiManager.dart';
import 'package:budget/struct/ai/askAiQueryEngine.dart';
import 'package:budget/struct/settings.dart';
import 'package:budget/widgets/button.dart';
import 'package:budget/widgets/framework/popupFramework.dart';
import 'package:budget/widgets/openBottomSheet.dart';
import 'package:budget/widgets/openPopup.dart';
import 'package:budget/widgets/tappable.dart';
import 'package:budget/widgets/textInput.dart';
import 'package:budget/widgets/textWidgets.dart';
import 'package:budget/widgets/transactionEntry/transactionEntry.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' hide TextInput;

/// Opens the draggable Ask AI bottom sheet dialog.
void openAskAiBottomSheet(BuildContext context) {
  openBottomSheet(
    context,
    fullSnap: true,
    popupWithKeyboard: true,
    const AskAiBottomSheet(),
  );
}

class AskAiBottomSheet extends StatefulWidget {
  const AskAiBottomSheet({super.key});

  @override
  State<AskAiBottomSheet> createState() => _AskAiBottomSheetState();
}

class _AskAiBottomSheetState extends State<AskAiBottomSheet> {
  final TextEditingController _queryController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  bool _isLoading = false;
  String? _errorMessage;
  AiQueryResult? _currentResult;
  String? _lastExecutedQuery;

  static const List<String> _quickSuggestions = [
    "How much did I spend last month?",
    "What was my biggest expense this week?",
    "How much did I spend on groceries?",
    "Total income this month",
    "How much did I spend yesterday?",
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 250), () {
        if (mounted && _focusNode.canRequestFocus) {
          _focusNode.requestFocus();
        }
      });
    });
  }

  @override
  void dispose() {
    _queryController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _submitQuery(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty || _isLoading) return;

    if (!aiManager.isConfigured()) {
      setState(() {
        _errorMessage =
            "AI is not configured. Please add an API key in AI Settings.";
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _lastExecutedQuery = trimmed;
    });

    try {
      final result = await AskAiQueryEngine().executeQuery(
        query: trimmed,
        context: context,
      );

      if (mounted) {
        setState(() {
          _currentResult = result;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = "Failed to process query: $e";
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isConfigured = aiManager.isConfigured();

    return PopupFramework(
      title: "Ask AI",
      subtitle: "Natural language financial search",
      icon: IconButton(
        tooltip: "AI Settings",
        icon: Icon(
          appStateSettings["outlinedIcons"]
              ? Icons.settings_outlined
              : Icons.settings_rounded,
        ),
        onPressed: () {
          popRoute(context);
          pushRoute(context, const AiSettingsPage());
        },
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildInputRow(theme),
          const SizedBox(height: 12),
          if (!isConfigured) _buildUnconfiguredBanner(theme),
          if (_currentResult == null && !_isLoading) _buildSuggestions(theme),
          if (_isLoading) _buildLoadingState(),
          if (_errorMessage != null) _buildErrorCard(theme),
          if (_currentResult != null && !_isLoading) ...[
            _buildResultCard(theme),
            _buildTransactionsPreview(),
          ],
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildInputRow(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: TextInput(
              controller: _queryController,
              focusNode: _focusNode,
              autoFocus: true,
              labelText: "Ask anything about your spending...",
              icon: Icons.auto_awesome_rounded,
              padding: EdgeInsetsDirectional.zero,
              onSubmitted: (val) => _submitQuery(val),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed:
                _isLoading ? null : () => _submitQuery(_queryController.text),
            icon: _isLoading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2.5),
                  )
                : Icon(
                    Icons.arrow_upward_rounded,
                    color: theme.colorScheme.primary,
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildUnconfiguredBanner(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: theme.colorScheme.errorContainer.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Icon(Icons.vpn_key_rounded, color: theme.colorScheme.error),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextFont(
                    text: "AI Provider Not Configured",
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    textColor: theme.colorScheme.onErrorContainer,
                  ),
                  const SizedBox(height: 2),
                  TextFont(
                    text:
                        "Add an API key in AI Settings to enable instant natural language querying.",
                    fontSize: 12,
                    textColor: theme.colorScheme.onErrorContainer
                        .withValues(alpha: 0.8),
                    maxLines: 2,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Button(
              label: "Setup",
              fontSize: 12,
              padding: const EdgeInsetsDirectional.symmetric(
                  horizontal: 12, vertical: 6),
              onTap: () {
                popRoute(context);
                pushRoute(context, const AiSettingsPage());
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuggestions(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: TextFont(
            text: "Suggestions",
            fontSize: 12,
            textColor: getColor(context, "textLight"),
            fontWeight: FontWeight.w600,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _quickSuggestions.map((suggestion) {
              return Tappable(
                color: theme.colorScheme.surfaceContainerHighest
                    .withValues(alpha: 0.6),
                borderRadius: 14,
                onTap: () {
                  HapticFeedback.lightImpact();
                  _queryController.text = suggestion;
                  _submitQuery(suggestion);
                },
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.auto_awesome_rounded,
                        size: 14,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 6),
                      TextFont(
                        text: suggestion,
                        fontSize: 12.5,
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingState() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 36),
      child: Center(
        child: Column(
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 14),
            TextFont(
              text: "Analyzing spending data...",
              fontSize: 13,
              textColor: getColor(context, "textLight"),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorCard(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: theme.colorScheme.errorContainer.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(Icons.info_outline_rounded,
                color: theme.colorScheme.error, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: TextFont(
                text: _errorMessage!,
                fontSize: 13,
                textColor: theme.colorScheme.error,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultCard(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.colorScheme.primaryContainer.withValues(alpha: 0.45),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: theme.colorScheme.primary.withValues(alpha: 0.25),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.psychology_rounded,
                  size: 20,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextFont(
                    text: _lastExecutedQuery ?? "Answer",
                    fontSize: 12,
                    textColor: getColor(context, "textLight"),
                    maxLines: 1,
                  ),
                ),
                Tappable(
                  color: Colors.transparent,
                  borderRadius: 8,
                  onTap: () {
                    popRoute(context);
                    pushRoute(
                      context,
                      TransactionsSearchPage(
                        initialFilters: _currentResult!.searchFilters,
                        initialSearchQuery:
                            _currentResult!.searchFilters.searchQuery,
                      ),
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Row(
                      children: [
                        TextFont(
                          text: "View all",
                          fontSize: 12,
                          textColor: theme.colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                        const SizedBox(width: 2),
                        Icon(
                          Icons.chevron_right_rounded,
                          size: 16,
                          color: theme.colorScheme.primary,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            TextFont(
              text: _currentResult!.answer,
              fontSize: 15,
              fontWeight: FontWeight.w600,
              maxLines: 5,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionsPreview() {
    if (_currentResult!.transactions.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextFont(
                text: "Transactions (${_currentResult!.transactions.length})",
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
              TextFont(
                text:
                    "Showing top ${_currentResult!.transactions.length > 5 ? 5 : _currentResult!.transactions.length}",
                fontSize: 11,
                textColor: getColor(context, "textLight"),
              ),
            ],
          ),
        ),
        ..._currentResult!.transactions.take(5).map((tx) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 3),
            child: TransactionEntry(
              openPage: AddTransactionPage(
                transaction: tx.transaction,
                routesToPopAfterDelete: RoutesToPopAfterDelete.One,
              ),
              transaction: tx.transaction,
              category: tx.category,
              subCategory: tx.subCategory,
              budget: tx.budget,
              objective: tx.objective,
              allowSelect: false,
            ),
          );
        }),
      ],
    );
  }
}
