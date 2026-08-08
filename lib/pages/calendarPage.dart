import 'package:budget/colors.dart';
import 'package:budget/database/tables.dart';
import 'package:budget/functions.dart';
import 'package:budget/pages/addTransactionPage.dart';
import 'package:budget/pages/transactionFilters.dart';
import 'package:budget/pages/transactionsSearchPage.dart';
import 'package:budget/struct/currencyFunctions.dart';
import 'package:budget/struct/databaseGlobal.dart';
import 'package:budget/struct/settings.dart';
import 'package:budget/widgets/framework/pageFramework.dart';
import 'package:budget/widgets/openPopup.dart';
import 'package:budget/widgets/tappable.dart';
import 'package:budget/widgets/textWidgets.dart';
import 'package:budget/widgets/monthSelector.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class CalendarPage extends StatefulWidget {
  const CalendarPage({super.key});

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  late DateTime _focusedMonth;
  DateTime? _selectedDay;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _focusedMonth = DateTime(now.year, now.month);
    _selectedDay = DateTime(now.year, now.month, now.day);
  }

  @override
  Widget build(BuildContext context) {
    final DateTime start =
        DateTime(_focusedMonth.year, _focusedMonth.month, 1);
    final DateTime end =
        DateTime(_focusedMonth.year, _focusedMonth.month + 1, 0);

    return PageFramework(
      title: "calendar".tr(),
      dragDownToDismiss: true,
      slivers: [
        SliverToBoxAdapter(
          child: StreamBuilder<List<Transaction>>(
            stream: database.getTransactionsInTimeRangeFromCategories(
              start,
              end,
              null,
              null,
              true,
              null,
              null,
              null,
            ),
            builder: (context, snapshot) {
              final allWallets = Provider.of<AllWallets>(context);
              final List<Transaction> transactions = snapshot.data ?? [];

              // Group and compute per-day totals
              final Map<int, List<Transaction>> txByDay = {};
              for (final tx in transactions) {
                txByDay.putIfAbsent(tx.dateCreated.day, () => []).add(tx);
              }

              final Map<int, _DayTotals> dailyTotals = {};
              for (final entry in txByDay.entries) {
                double income = 0;
                double expense = 0;
                for (final tx in entry.value) {
                  final ratio = amountRatioToPrimaryCurrencyGivenPk(
                      allWallets, tx.walletFk);
                  final converted = tx.amount.abs() * ratio;
                  if (tx.income) {
                    income += converted;
                  } else {
                    expense += converted;
                  }
                }
                dailyTotals[entry.key] =
                    _DayTotals(income: income, expense: expense);
              }

              // Monthly summary
              double monthIncome = 0;
              double monthExpense = 0;
              for (final t in dailyTotals.values) {
                monthIncome += t.income;
                monthExpense += t.expense;
              }

              return Column(
                children: [
                  MonthSelector(
                    setSelectedDateStart: (DateTime dateTime, int offset) {
                      setState(() {
                        _focusedMonth = DateTime(dateTime.year, dateTime.month);
                        _selectedDay = null;
                      });
                    },
                  ),
                  _MonthlySummary(
                    income: monthIncome,
                    expense: monthExpense,
                    allWallets: allWallets,
                  ),
                  const SizedBox(height: 10),
                  _CalendarGrid(
                    focusedMonth: _focusedMonth,
                    selectedDay: _selectedDay,
                    dailyTotals: dailyTotals,
                    onDaySelected: (day) {
                      setState(() {
                        _selectedDay =
                            (_selectedDay != null &&
                                    _selectedDay!.day == day.day &&
                                    _selectedDay!.month == day.month)
                                ? null
                                : day;
                      });
                    },
                  ),
                  if (_selectedDay != null)
                    _DayDetailPanel(
                      selectedDay: _selectedDay!,
                      transactions: txByDay[_selectedDay!.day] ?? [],
                      allWallets: allWallets,
                      dailyTotals: dailyTotals[_selectedDay!.day],
                    ),
                  const SizedBox(height: 80),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}

// ── Data Model ───────────────────────────────────────────────────────────────

class _DayTotals {
  final double income;
  final double expense;
  const _DayTotals({required this.income, required this.expense});
  double get net => income - expense;
}

// ── Monthly Summary ──────────────────────────────────────────────────────────

// ── Monthly Summary ──────────────────────────────────────────────────────────

class _MonthlySummary extends StatelessWidget {
  const _MonthlySummary({
    required this.income,
    required this.expense,
    required this.allWallets,
  });
  final double income;
  final double expense;
  final AllWallets allWallets;

  @override
  Widget build(BuildContext context) {
    final double net = income - expense;
    return Container(
      margin: const EdgeInsetsDirectional.symmetric(horizontal: 13, vertical: 4),
      padding: const EdgeInsetsDirectional.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.4),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Theme.of(context).colorScheme.outlineVariant.withOpacity(0.3),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          // Expense (Red arrow down)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.arrow_drop_down_rounded,
                color: Theme.of(context).colorScheme.error,
                size: 22,
              ),
              TextFont(
                text: convertToMoney(allWallets, expense),
                fontSize: 13,
                fontWeight: FontWeight.bold,
                textColor: Theme.of(context).colorScheme.error,
              ),
            ],
          ),
          // Income (Green arrow up)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.arrow_drop_up_rounded,
                color: Theme.of(context).colorScheme.primary,
                size: 22,
              ),
              TextFont(
                text: convertToMoney(allWallets, income),
                fontSize: 13,
                fontWeight: FontWeight.bold,
                textColor: Theme.of(context).colorScheme.primary,
              ),
            ],
          ),
          // Balance / Net (= amount)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const TextFont(
                text: "= ",
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
              TextFont(
                text: "${net < 0 ? '-' : ''}${convertToMoney(allWallets, net.abs())}",
                fontSize: 13,
                fontWeight: FontWeight.bold,
                textColor: net >= 0
                    ? Theme.of(context).colorScheme.onSurface
                    : Theme.of(context).colorScheme.error,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Calendar Grid ────────────────────────────────────────────────────────────

class _CalendarGrid extends StatelessWidget {
  const _CalendarGrid({
    required this.focusedMonth,
    required this.selectedDay,
    required this.dailyTotals,
    required this.onDaySelected,
  });
  final DateTime focusedMonth;
  final DateTime? selectedDay;
  final Map<int, _DayTotals> dailyTotals;
  final void Function(DateTime) onDaySelected;

  @override
  Widget build(BuildContext context) {
    final int daysInMonth =
        DateTime(focusedMonth.year, focusedMonth.month + 1, 0).day;

    final int firstDayOfWeek = appStateSettings["firstDayOfWeek"] == -1
        ? MaterialLocalizations.of(context).firstDayOfWeekIndex
        : (int.tryParse(appStateSettings["firstDayOfWeek"].toString()) ?? 0);

    final DateTime firstOfMonth =
        DateTime(focusedMonth.year, focusedMonth.month, 1);
    final int firstWeekdayIndex = firstOfMonth.weekday % 7; // 0 for Sun, 1 for Mon...
    final int startWeekday = (firstWeekdayIndex - firstDayOfWeek + 7) % 7;
    final DateTime today = DateTime.now();

    List<String> weekLabels = [];
    for (int i = 0; i < 7; i++) {
      int dayIndex = (firstDayOfWeek + i) % 7;
      DateTime dateForDayName = DateTime(2023, 1, 1 + dayIndex); // 2023-01-01 was a Sunday
      String name = DateFormat.E(context.locale.toLanguageTag()).format(dateForDayName);
      weekLabels.add(name);
    }

    return Padding(
      padding: const EdgeInsetsDirectional.symmetric(horizontal: 13),
      child: Column(
        children: [
          // Day-of-week headers
          Row(
            children: weekLabels
                .map(
                  (l) => Expanded(
                    child: Center(
                      child: TextFont(
                        text: l,
                        fontSize: 12,
                        textColor: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withOpacity(0.5),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 4),
          GridView.builder(
            physics: const NeverScrollableScrollPhysics(),
            shrinkWrap: true,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              childAspectRatio: 0.76,
              mainAxisSpacing: 3,
              crossAxisSpacing: 3,
            ),
            itemCount: startWeekday + daysInMonth,
            itemBuilder: (context, index) {
              if (index < startWeekday) return const SizedBox.shrink();
              final int day = index - startWeekday + 1;
              final DateTime date =
                  DateTime(focusedMonth.year, focusedMonth.month, day);
              final _DayTotals? totals = dailyTotals[day];
              final bool isToday = date.year == today.year &&
                  date.month == today.month &&
                  date.day == today.day;
              final bool isSelected = selectedDay != null &&
                  selectedDay!.day == day &&
                  selectedDay!.month == focusedMonth.month;

              return _DayCell(
                day: day,
                date: date,
                totals: totals,
                isToday: isToday,
                isSelected: isSelected,
                onTap: () => onDaySelected(date),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.day,
    required this.date,
    required this.totals,
    required this.isToday,
    required this.isSelected,
    required this.onTap,
  });
  final int day;
  final DateTime date;
  final _DayTotals? totals;
  final bool isToday;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final allWallets = Provider.of<AllWallets>(context);
    final Color bgColor = isSelected
        ? Theme.of(context).colorScheme.primary
        : isToday
            ? Theme.of(context).colorScheme.primaryContainer.withOpacity(0.6)
            : getColor(context, "lightDarkAccentHeavyLight");
    final Color textColor = isSelected
        ? Theme.of(context).colorScheme.onPrimary
        : Theme.of(context).colorScheme.onSurface;
    final bool hasTx = totals != null;

    double displayAmount = 0;
    if (hasTx) {
      displayAmount = totals!.expense > 0 ? totals!.expense : totals!.income;
    }
    String amountStr = convertToMoney(allWallets, displayAmount, forceCompactNumberFormatter: true);

    return Tappable(
      color: bgColor,
      borderRadius: 12,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 3),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextFont(
              text: "$day",
              fontSize: 13,
              fontWeight: (isToday || isSelected)
                  ? FontWeight.bold
                  : FontWeight.normal,
              textColor: textColor,
            ),
            const SizedBox(height: 2),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (hasTx && totals!.income > 0)
                  Container(
                    width: 5,
                    height: 5,
                    margin: const EdgeInsets.symmetric(horizontal: 1),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? textColor.withOpacity(0.8)
                          : Theme.of(context).colorScheme.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                if (hasTx && totals!.expense > 0)
                  Container(
                    width: 5,
                    height: 5,
                    margin: const EdgeInsets.symmetric(horizontal: 1),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? textColor.withOpacity(0.8)
                          : Theme.of(context).colorScheme.error,
                      shape: BoxShape.circle,
                    ),
                  ),
                if (!hasTx)
                  Container(
                    width: 4,
                    height: 4,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? textColor.withOpacity(0.4)
                          : Theme.of(context).colorScheme.outlineVariant.withOpacity(0.4),
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 2),
            TextFont(
              text: amountStr,
              fontSize: 10,
              fontWeight: FontWeight.w500,
              textColor: isSelected
                  ? textColor.withOpacity(0.9)
                  : (hasTx && totals!.expense > 0)
                      ? Theme.of(context).colorScheme.error.withOpacity(0.85)
                      : textColor.withOpacity(0.5),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Day Detail Panel ─────────────────────────────────────────────────────────

class _DayDetailPanel extends StatelessWidget {
  const _DayDetailPanel({
    required this.selectedDay,
    required this.transactions,
    required this.allWallets,
    required this.dailyTotals,
  });
  final DateTime selectedDay;
  final List<Transaction> transactions;
  final AllWallets allWallets;
  final _DayTotals? dailyTotals;

  @override
  Widget build(BuildContext context) {
    final double income = dailyTotals?.income ?? 0;
    final double expense = dailyTotals?.expense ?? 0;
    final double net = income - expense;
    final String dayLabel = DateFormat(
      "EEEE, d MMMM",
      context.locale.toLanguageTag(),
    ).format(selectedDay);

    return Padding(
      padding:
          const EdgeInsetsDirectional.only(start: 13, end: 13, top: 12),
      child: Container(
        decoration: BoxDecoration(
          color: getColor(context, "lightDarkAccentHeavyLight"),
          borderRadius: BorderRadius.circular(18),
          boxShadow: boxShadowCheck(boxShadowGeneral(context)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsetsDirectional.only(
                  start: 16, end: 8, top: 14, bottom: 8),
              child: Row(
                children: [
                  Expanded(
                    child: TextFont(
                      text: dayLabel,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => AddTransactionPage(
                            routesToPopAfterDelete:
                                RoutesToPopAfterDelete.None,
                            selectedDate: selectedDay,
                          ),
                        ),
                      );
                    },
                    icon: Icon(
                      appStateSettings["outlinedIcons"]
                          ? Icons.add_circle_outline
                          : Icons.add_circle_rounded,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    tooltip: "add-transaction".tr(),
                  ),
                ],
              ),
            ),
            // Amount badges
            Padding(
              padding: const EdgeInsetsDirectional.symmetric(horizontal: 16),
              child: Row(
                children: [
                  _AmountBadge(
                    label: "income".tr(),
                    amount: income,
                    allWallets: allWallets,
                    isPositive: true,
                  ),
                  const SizedBox(width: 16),
                  _AmountBadge(
                    label: "expense".tr(),
                    amount: expense,
                    allWallets: allWallets,
                    isPositive: false,
                  ),
                  const SizedBox(width: 16),
                  _AmountBadge(
                    label: "net".tr(),
                    amount: net,
                    allWallets: allWallets,
                    isPositive: net >= 0,
                    showSign: true,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            // Transactions
            if (transactions.isEmpty)
              Padding(
                padding: const EdgeInsetsDirectional.only(
                    start: 16, end: 16, bottom: 16),
                child: TextFont(
                  text: "no-transactions".tr(),
                  fontSize: 14,
                  textColor: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.5),
                ),
              )
            else ...[
              if (transactions.length > 3)
                Padding(
                  padding: const EdgeInsetsDirectional.symmetric(
                      horizontal: 16),
                  child: Tappable(
                    color: Colors.transparent,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => TransactionsSearchPage(
                            initialFilters: SearchFilters().copyWith(
                              dateTimeRange: DateTimeRange(
                                start: selectedDay,
                                end: DateTime(
                                  selectedDay.year,
                                  selectedDay.month,
                                  selectedDay.day,
                                  23,
                                  59,
                                  59,
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                    borderRadius: 8,
                    child: Padding(
                      padding: const EdgeInsetsDirectional.symmetric(
                          vertical: 6),
                      child: Row(
                        children: [
                          TextFont(
                            text:
                                "${transactions.length} ${"transactions".tr()}",
                            fontSize: 13,
                            textColor:
                                Theme.of(context).colorScheme.primary,
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            Icons.arrow_forward_ios_rounded,
                            size: 12,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              for (final tx in transactions.take(3))
                _MiniTransactionRow(tx: tx, allWallets: allWallets),
              const SizedBox(height: 8),
            ],
          ],
        ),
      ),
    );
  }
}

class _AmountBadge extends StatelessWidget {
  const _AmountBadge({
    required this.label,
    required this.amount,
    required this.allWallets,
    required this.isPositive,
    this.showSign = false,
  });
  final String label;
  final double amount;
  final AllWallets allWallets;
  final bool isPositive;
  final bool showSign;

  @override
  Widget build(BuildContext context) {
    final String sign = showSign && amount > 0 ? "+" : "";
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFont(
          text: label,
          fontSize: 11,
          textColor: Theme.of(context)
              .colorScheme
              .onSurface
              .withValues(alpha: 0.55),
        ),
        TextFont(
          text: "$sign${convertToMoney(allWallets, amount.abs())}",
          fontSize: 13,
          fontWeight: FontWeight.bold,
          textColor: isPositive
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.error,
        ),
      ],
    );
  }
}

class _MiniTransactionRow extends StatelessWidget {
  const _MiniTransactionRow({
    required this.tx,
    required this.allWallets,
  });
  final Transaction tx;
  final AllWallets allWallets;

  @override
  Widget build(BuildContext context) {
    final double ratio =
        amountRatioToPrimaryCurrencyGivenPk(allWallets, tx.walletFk);
    final double converted = tx.amount.abs() * ratio;

    return Padding(
      padding: const EdgeInsetsDirectional.only(
          start: 16, end: 16, top: 4, bottom: 4),
      child: Row(
        children: [
          Icon(
            tx.income
                ? (appStateSettings["outlinedIcons"]
                    ? Icons.arrow_upward_outlined
                    : Icons.arrow_upward_rounded)
                : (appStateSettings["outlinedIcons"]
                    ? Icons.arrow_downward_outlined
                    : Icons.arrow_downward_rounded),
            size: 16,
            color: tx.income
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.error,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextFont(
              text: tx.name.isNotEmpty ? tx.name : "transaction".tr(),
              fontSize: 13,
              maxLines: 1,
            ),
          ),
          TextFont(
            text: convertToMoney(allWallets, converted),
            fontSize: 13,
            fontWeight: FontWeight.bold,
            textColor: tx.income
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.error,
          ),
        ],
      ),
    );
  }
}
