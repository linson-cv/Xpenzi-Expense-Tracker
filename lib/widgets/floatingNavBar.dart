import 'package:budget/colors.dart';
import 'package:budget/struct/navBarIconsData.dart';
import 'package:budget/struct/settings.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class FloatingNavBar extends StatelessWidget {
  const FloatingNavBar({
    required this.selectedIndex,
    required this.onItemTapped,
    super.key,
  });

  final int selectedIndex;
  final Function(int) onItemTapped;

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final bool isAmoled = appStateSettings["forceFullDarkBackground"] == true && isDark;

    final bool showLabels = appStateSettings["showFloatingNavBarLabels"] ?? true;

    Color navBgColor = isAmoled
        ? Colors.black
        : getBottomNavbarBackgroundColor(
            colorScheme: Theme.of(context).colorScheme,
            brightness: Theme.of(context).brightness,
            lightDarkAccent: getColor(context, "lightDarkAccent"),
          );

    Color borderColor = isAmoled
        ? const Color(0xFF262626)
        : getColor(context, "border").withOpacity(0.4);

    Color activeIndicatorColor = Theme.of(context).colorScheme.primaryContainer.withOpacity(0.85);
    Color activeIconColor = Theme.of(context).colorScheme.onPrimaryContainer;
    Color inactiveIconColor = Theme.of(context).colorScheme.onSurface.withOpacity(0.65);

    List<String> navShortcutKeys = [
      "customNavBarShortcut0",
      "customNavBarShortcut1",
      "customNavBarShortcut2",
    ];

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.only(left: 16, right: 16, bottom: 12, top: 4),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          height: showLabels ? 64 : 56,
          decoration: BoxDecoration(
            color: navBgColor,
            borderRadius: BorderRadius.circular(32),
            border: Border.all(color: borderColor, width: 1.2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.45 : 0.08),
                blurRadius: 16,
                spreadRadius: 2,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              for (int i = 0; i < 3; i++) ...[
                Builder(builder: (context) {
                  String shortcutKey = appStateSettings[navShortcutKeys[i]] ?? "";
                  NavBarIconData iconData = navBarIconsData[shortcutKey] ??
                      navBarIconsData[i == 0
                          ? "home"
                          : i == 1
                              ? "transactions"
                              : "budgets"]!;

                  bool isSelected = selectedIndex == i;

                  return Expanded(
                    child: InkWell(
                      borderRadius: BorderRadius.circular(24),
                      onTap: () {
                        HapticFeedback.lightImpact();
                        onItemTapped(i);
                      },
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 220),
                            curve: Curves.easeOutCubic,
                            width: isSelected ? 56 : 36,
                            height: 32,
                            decoration: BoxDecoration(
                              color: isSelected ? activeIndicatorColor : Colors.transparent,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Center(
                              child: Icon(
                                iconData.iconData,
                                size: 22,
                                color: isSelected ? activeIconColor : inactiveIconColor,
                              ),
                            ),
                          ),
                          if (showLabels) ...[
                            const SizedBox(height: 2),
                            Text(
                              iconData.label.tr().length > 12 &&
                                      iconData.labelShort != null
                                  ? (iconData.labelShort ?? "").tr()
                                  : iconData.label.tr(),
                              style: TextStyle(
                                fontFamily: appStateSettings["font"],
                                fontSize: 10.5,
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                                color: isSelected
                                    ? Theme.of(context).colorScheme.primary
                                    : Theme.of(context)
                                        .colorScheme
                                        .onSurface
                                        .withOpacity(0.7),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                }),
              ],
              // More / Settings Item
              Expanded(
                child: InkWell(
                  borderRadius: BorderRadius.circular(24),
                  onTap: () {
                    HapticFeedback.lightImpact();
                    onItemTapped(3);
                  },
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 220),
                        curve: Curves.easeOutCubic,
                        width: selectedIndex == 3 ? 56 : 36,
                        height: 32,
                        decoration: BoxDecoration(
                          color: selectedIndex == 3 ? activeIndicatorColor : Colors.transparent,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Center(
                          child: Icon(
                            navBarIconsData["more"]!.iconData,
                            size: 22,
                            color: selectedIndex == 3 ? activeIconColor : inactiveIconColor,
                          ),
                        ),
                      ),
                      if (showLabels) ...[
                        const SizedBox(height: 2),
                        Text(
                          navBarIconsData["more"]!.label.tr(),
                          style: TextStyle(
                            fontFamily: appStateSettings["font"],
                            fontSize: 10.5,
                            fontWeight: selectedIndex == 3
                                ? FontWeight.bold
                                : FontWeight.normal,
                            color: selectedIndex == 3
                                ? Theme.of(context).colorScheme.primary
                                : Theme.of(context)
                                    .colorScheme
                                    .onSurface
                                    .withOpacity(0.7),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
