import 'package:budget/colors.dart';
import 'package:budget/pages/addTransactionPage.dart';
import 'package:budget/struct/settings.dart';
import 'package:budget/widgets/openBottomSheet.dart';
import 'package:budget/widgets/openPopup.dart';
import 'package:budget/widgets/tappable.dart';
import 'package:budget/widgets/textWidgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class HomeQuickActionDock extends StatelessWidget {
  const HomeQuickActionDock({super.key});

  void _openAddTransaction(BuildContext context, {bool? selectedIncome, bool transferBalancePopup = false}) {
    HapticFeedback.lightImpact();
    openBottomSheet(
      context,
      fullSnap: true,
      popupWithKeyboard: true,
      AddTransactionPage(
        routesToPopAfterDelete: RoutesToPopAfterDelete.None,
        selectedIncome: selectedIncome,
        transferBalancePopup: transferBalancePopup,
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
                ? const Color(0xFF262626)
                : getColor(context, "border").withOpacity(0.3),
            width: 1.2,
          ),
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
                onTap: () => _openAddTransaction(context, transferBalancePopup: true),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _QuickActionButton(
                label: "Pay Bill",
                icon: Icons.credit_card_rounded,
                color: const Color(0xFFFF9800),
                onTap: () => _openAddTransaction(context, selectedIncome: false),
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
      color: color.withOpacity(0.12),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 22, color: color),
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
