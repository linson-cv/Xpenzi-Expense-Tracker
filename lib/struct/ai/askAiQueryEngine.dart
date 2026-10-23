import 'dart:convert';
import 'package:budget/database/tables.dart';
import 'package:budget/functions.dart';
import 'package:budget/pages/transactionFilters.dart';
import 'package:budget/struct/ai/aiManager.dart';
import 'package:budget/struct/databaseGlobal.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// Structured filter parameters extracted from the user's natural language question.
class AiQueryParsedFilter {
  final String? intentDescription;
  final DateTime? startDate;
  final DateTime? endDate;
  final String? categoryName;
  final String? searchQuery;
  final bool? isIncome;

  const AiQueryParsedFilter({
    this.intentDescription,
    this.startDate,
    this.endDate,
    this.categoryName,
    this.searchQuery,
    this.isIncome,
  });

  factory AiQueryParsedFilter.fromMap(Map<String, dynamic> map) {
    DateTime? sDate;
    DateTime? eDate;
    if (map["startDate"] != null) {
      sDate = DateTime.tryParse(map["startDate"].toString());
    }
    if (map["endDate"] != null) {
      eDate = DateTime.tryParse(map["endDate"].toString());
    }

    return AiQueryParsedFilter(
      intentDescription: map["intent"]?.toString(),
      startDate: sDate,
      endDate: eDate,
      categoryName: map["category"]?.toString(),
      searchQuery: map["searchQuery"]?.toString(),
      isIncome: map["isIncome"] is bool ? map["isIncome"] as bool : null,
    );
  }
}

/// Comprehensive result of a natural-language query containing summarized totals,
/// conversational AI explanation, and direct transaction references.
class AiQueryResult {
  final String answer;
  final double totalAmount;
  final int transactionCount;
  final List<TransactionWithCategory> transactions;
  final SearchFilters searchFilters;
  final String? categoryName;
  final DateTimeRange? dateRange;

  const AiQueryResult({
    required this.answer,
    required this.totalAmount,
    required this.transactionCount,
    required this.transactions,
    required this.searchFilters,
    this.categoryName,
    this.dateRange,
  });
}

/// Hybrid on-device AI search engine:
/// 1. Uses the active LLM provider to extract dates, categories, and keywords.
/// 2. Performs strict on-device SQLite aggregations via Drift.
/// 3. Generates concise, accurate financial answers with direct drill-down links.
class AskAiQueryEngine {
  static final AskAiQueryEngine _instance = AskAiQueryEngine._internal();
  factory AskAiQueryEngine() => _instance;
  AskAiQueryEngine._internal();

  Future<AiQueryResult> executeQuery({
    required String query,
    required BuildContext context,
  }) async {
    final now = DateTime.now();

    // 1. Fetch live categories for semantic context
    final allCategories = await _loadAllCategories();
    final categoryNames = allCategories.map((c) => c.name).toSet().toList();

    // 2. Extract structured search intent via configured AI provider
    final parsedFilter = await _extractQueryIntent(
      query: query,
      now: now,
      categoryNames: categoryNames,
    );

    // 3. Resolve matched Category FK
    final matchedCategoryPk = _resolveCategoryPk(
      categoryName: parsedFilter.categoryName,
      allCategories: allCategories,
    );

    // 4. Construct SearchFilters for local database query
    final dateRange = _resolveDateRange(
      startDate: parsedFilter.startDate,
      endDate: parsedFilter.endDate,
      now: now,
    );

    final searchFilters = SearchFilters(
      dateTimeRange: dateRange,
      categoryPks: matchedCategoryPk != null ? [matchedCategoryPk] : [],
      searchQuery: parsedFilter.searchQuery,
      expenseIncome: parsedFilter.isIncome == true
          ? [ExpenseIncome.income]
          : parsedFilter.isIncome == false
              ? [ExpenseIncome.expense]
              : [],
    );

    // 5. Query Drift SQLite locally
    final matchingTransactions = await _fetchMatchingTransactions(searchFilters);

    // 6. Calculate exact local totals & format currency
    double totalAmount = 0.0;
    for (final item in matchingTransactions) {
      totalAmount += item.transaction.amount.abs();
    }

    AllWallets? allWallets;
    try {
      allWallets = Provider.of<AllWallets>(context, listen: false);
    } catch (_) {}

    final formattedTotal = allWallets != null
        ? convertToMoney(allWallets, totalAmount)
        : totalAmount.toStringAsFixed(2);

    // 7. Generate concise conversational answer
    final conversationalAnswer = await _generateConversationalAnswer(
      query: query,
      formattedTotal: formattedTotal,
      transactionCount: matchingTransactions.length,
      dateRange: dateRange,
      parsedFilter: parsedFilter,
    );

    return AiQueryResult(
      answer: conversationalAnswer,
      totalAmount: totalAmount,
      transactionCount: matchingTransactions.length,
      transactions: matchingTransactions,
      searchFilters: searchFilters,
      categoryName: parsedFilter.categoryName,
      dateRange: dateRange,
    );
  }

  Future<List<TransactionCategory>> _loadAllCategories() async {
    try {
      return await database.getAllCategories();
    } catch (_) {
      return [];
    }
  }

  Future<AiQueryParsedFilter> _extractQueryIntent({
    required String query,
    required DateTime now,
    required List<String> categoryNames,
  }) async {
    final systemPrompt = """
You are a financial query intent parser for the Xpenzi expense tracker.
Today's Date: "${now.toIso8601String()}" (Day: ${now.day}, Month: ${now.month}, Year: ${now.year})
Available User Categories: ${jsonEncode(categoryNames)}

Convert the user's natural language question into structured filter parameters:
1. "startDate": ISO-8601 string (e.g. start of last month, start of this week), or null for all-time.
2. "endDate": ISO-8601 string (e.g. end of last month, now), or null for all-time.
3. "category": Exact match from Available User Categories, or closest semantic match, or null.
4. "searchQuery": Vendor/title/merchant keyword (e.g. "Starbucks", "Uber", "Netflix"), or null.
5. "isIncome": true if asking about income/earnings/salary/deposits, false if spending/expenses/costs, or null for both.
6. "intent": Short 1-sentence description of what the user is looking for.

Return ONLY raw JSON in this exact format:
{
  "startDate": "YYYY-MM-DDTHH:mm:ss",
  "endDate": "YYYY-MM-DDTHH:mm:ss",
  "category": null,
  "searchQuery": null,
  "isIncome": false,
  "intent": "Total spending in last month"
}
""";

    try {
      final aiJsonString = await aiManager.generateAnswer(
        prompt: query,
        systemInstruction: systemPrompt,
      );

      if (aiJsonString != null && aiJsonString.isNotEmpty) {
        final cleaned = _cleanJsonString(aiJsonString);
        final map = jsonDecode(cleaned);
        if (map is Map<String, dynamic>) {
          return AiQueryParsedFilter.fromMap(map);
        } else if (map is Map) {
          return AiQueryParsedFilter.fromMap(Map<String, dynamic>.from(map));
        }
      }
    } catch (e) {
      debugPrint("Error parsing AI query intent: $e");
    }

    return const AiQueryParsedFilter();
  }

  String? _resolveCategoryPk({
    required String? categoryName,
    required List<TransactionCategory> allCategories,
  }) {
    if (categoryName == null) return null;
    final target = categoryName.trim().toLowerCase();
    final cat = allCategories.where((c) => c.name.toLowerCase() == target).firstOrNull ??
        allCategories.where((c) => c.name.toLowerCase().contains(target)).firstOrNull;
    return cat?.categoryPk;
  }

  DateTimeRange? _resolveDateRange({
    required DateTime? startDate,
    required DateTime? endDate,
    required DateTime now,
  }) {
    if (startDate == null && endDate == null) return null;
    final start = startDate ?? DateTime(now.year - 1, 1, 1);
    final end = endDate ?? now;
    return DateTimeRange(
      start: start.isBefore(end) ? start : end,
      end: end.isAfter(start) ? end : start,
    );
  }

  Future<List<TransactionWithCategory>> _fetchMatchingTransactions(
    SearchFilters searchFilters,
  ) async {
    try {
      return await database.getAllTransactionsWithCategoryWalletBudgetObjectiveSubCategory(
        (tbl) {
          return database.onlyShowIfFollowsSearchFilters(
            tbl,
            searchFilters,
            joinedWithSubcategoriesTable: null,
            joinedWithCategories: false,
            joinedWithBudgets: false,
            joinedWithObjectives: false,
            joinedWithObjectiveLoans: null,
          );
        },
      );
    } catch (e) {
      debugPrint("Error querying matching transactions: $e");
      return [];
    }
  }

  Future<String> _generateConversationalAnswer({
    required String query,
    required String formattedTotal,
    required int transactionCount,
    required DateTimeRange? dateRange,
    required AiQueryParsedFilter parsedFilter,
  }) async {
    try {
      final summaryPrompt = """
User Question: "$query"
Local Aggregated Results:
- Total Amount: $formattedTotal
- Total Matching Transactions: $transactionCount
- Time Range: ${dateRange != null ? "${dateRange.start.toIso8601String().split('T')[0]} to ${dateRange.end.toIso8601String().split('T')[0]}" : "All time"}
- Category: ${parsedFilter.categoryName ?? "All categories"}
- Search Keyword: ${parsedFilter.searchQuery ?? "None"}
- Polarity: ${parsedFilter.isIncome == true ? "Income" : "Expense"}

Provide a direct, friendly, and concise 1-2 sentence financial answer to the user based on these exact numbers. Always use the formatted total $formattedTotal.
""";

      final summaryResp = await aiManager.generateAnswer(
        prompt: summaryPrompt,
        systemInstruction: "You are Xpenzi Financial Assistant. Be concise, polite, and accurate.",
      );

      if (summaryResp != null && summaryResp.trim().isNotEmpty) {
        return summaryResp.trim();
      }
    } catch (_) {}

    if (transactionCount == 0) {
      return "No transactions found matching your question.";
    }

    return parsedFilter.isIncome == true
        ? "You earned a total of $formattedTotal across $transactionCount transactions."
        : "You spent a total of $formattedTotal across $transactionCount transactions.";
  }

  String _cleanJsonString(String raw) {
    String cleaned = raw.trim();
    if (cleaned.startsWith("```json")) {
      cleaned = cleaned.substring(7);
    } else if (cleaned.startsWith("```")) {
      cleaned = cleaned.substring(3);
    }
    if (cleaned.endsWith("```")) {
      cleaned = cleaned.substring(0, cleaned.length - 3);
    }
    return cleaned.trim();
  }
}
