import 'package:budget/colors.dart';
import 'package:budget/pages/addTransactionPage.dart';
import 'package:budget/pages/addWalletPage.dart';
import 'package:budget/pages/creditDebtTransactionsPage.dart';
import 'package:budget/struct/settings.dart';
import 'package:budget/widgets/openBottomSheet.dart';
import 'package:budget/widgets/openPopup.dart';
import 'package:budget/widgets/tappable.dart';
import 'package:budget/widgets/textWidgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:budget/functions.dart';

class HomeQuickActionDock extends StatelessWidget {
  const HomeQuickActionDock({super.key});

  void _openAddTransaction(BuildContext context, {bool? selectedIncome}) {
    HapticFeedback.lightImpact();
    pushRoute(
      context,
      AddTransactionPage(
        routesToPopAfterDelete: RoutesToPopAfterDelete.None,
        selectedIncome: selectedIncome,
      ),
    );
  }

  void _openTransfer(BuildContext context) {
    HapticFeedback.lightImpact();
    openBottomSheet(
      context,
      const TransferBalancePopup(
        wallet: null,
        allowEditWallet: true,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final bool isAmoled = appStateSettings["forceFullDarkBackground"] == true && isDark;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      child: Container(
        decoration: BoxDecoration(
          color: isAmoled
              ? const Color(0xFF0F0F0F)
              : getColor(context, "lightDarkAccent"),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isAmoled
                ? const Color(0xFF222222)
                : Theme.of(context).colorScheme.outline.withValues(alpha: 0.15),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.1),
              blurRadius: 12,
              offset: const Offset(0, 4),
            )
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        child: Row(
          children: [
            Expanded(
              child: _QuickActionButton(
                label: "Expense",
                icon: Icons.remove_circle_outline_rounded,
                color: const Color(0xFFFF5252),
                onTap: () => _openAddTransaction(context, selectedIncome: false),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _QuickActionButton(
                label: "Income",
                icon: Icons.add_circle_outline_rounded,
                color: const Color(0xFF4CAF50),
                onTap: () => _openAddTransaction(context, selectedIncome: true),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _QuickActionButton(
                label: "Transfer",
                icon: Icons.swap_horiz_rounded,
                color: const Color(0xFF2196F3),
                onTap: () => _openTransfer(context),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _QuickActionButton(
                label: "Pay Bill",
                icon: Icons.credit_card_rounded,
                color: const Color(0xFFFF9800),
                onTap: () {
                  HapticFeedback.lightImpact();
                  pushRoute(
                    context,
                    const CreditDebtTransactions(isCredit: null),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  const _QuickActionButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tappable(
      borderRadius: 16,
      color: color.withValues(alpha: 0.12),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.18),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 20, color: color),
            ),
            const SizedBox(height: 4),
            TextFont(
              text: label,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              textColor: Theme.of(context).colorScheme.onSurface,
              maxLines: 1,
            ),
          ],
        ),
      ),
    );
  }
}
