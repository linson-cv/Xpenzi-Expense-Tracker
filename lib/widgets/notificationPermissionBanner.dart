import 'package:budget/colors.dart';
import 'package:budget/functions.dart';
import 'package:budget/struct/errorLog.dart';
import 'package:budget/struct/notificationEngine.dart';
import 'package:budget/struct/settings.dart';
import 'package:budget/widgets/button.dart';
import 'package:budget/widgets/globalSnackbar.dart';
import 'package:budget/widgets/openSnackbar.dart';
import 'package:budget/widgets/tappable.dart';
import 'package:budget/widgets/textWidgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:notification_listener_service/notification_listener_service.dart';

class NotificationPermissionBanner extends StatefulWidget {
  const NotificationPermissionBanner({super.key});

  @override
  State<NotificationPermissionBanner> createState() =>
      _NotificationPermissionBannerState();
}

class _NotificationPermissionBannerState
    extends State<NotificationPermissionBanner> {
  bool isPermissionGranted = true;

  @override
  void initState() {
    super.initState();
    checkPermissionStatus();
  }

  Future checkPermissionStatus() async {
    if (getPlatform(ignoreEmulation: true) != PlatformOS.isAndroid) return;
    try {
      bool status = await NotificationListenerService.isPermissionGranted();
      if (mounted) {
        setState(() {
          isPermissionGranted = status;
        });
      }
    } catch (e, stack) {
      recordAppError("NotificationBannerCheck", e, stackTrace: stack);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (getPlatform(ignoreEmulation: true) != PlatformOS.isAndroid) {
      return const SizedBox.shrink();
    }
    if (isPermissionGranted ||
        appStateSettings["neverShowNotificationPermissionBanner"] == true) {
      return const SizedBox.shrink();
    }

    // Check periodic snooze (e.g., re-prompt after 7 days if user chose "Remind Later")
    if (appStateSettings["snoozedNotificationBannerUntil"] != null) {
      DateTime? snoozeUntil = DateTime.tryParse(
          appStateSettings["snoozedNotificationBannerUntil"].toString());
      if (snoozeUntil != null && DateTime.now().isBefore(snoozeUntil)) {
        return const SizedBox.shrink();
      }
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bool isAmoled =
        appStateSettings["forceFullDarkBackground"] == true && isDark;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      child: Container(
        decoration: BoxDecoration(
          color: isAmoled
              ? const Color(0xFF0F0F0F)
              : dynamicPastel(
                  context,
                  Theme.of(context).colorScheme.primaryContainer,
                  amount: 0.15,
                ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
            width: 1.2,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row: Icon, Title, Badge & Dismiss Button
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Theme.of(context)
                          .colorScheme
                          .primary
                          .withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.notifications_active_rounded,
                      size: 18,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextFont(
                          text: "Auto-Detect Bank SMS & Alerts",
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          textColor: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(height: 2),
                        TextFont(
                          text: "🔒 100% Private · On-Device",
                          fontSize: 11,
                          textColor: getColor(context, "textLight"),
                        ),
                      ],
                    ),
                  ),
                  Tappable(
                    color: Colors.transparent,
                    borderRadius: 14,
                    onTap: () {
                      HapticFeedback.lightImpact();
                      updateSettings(
                        "neverShowNotificationPermissionBanner",
                        true,
                        updateGlobalState: true,
                      );
                      setState(() {});
                    },
                    child: Tooltip(
                      message: "Don't show again",
                      child: Padding(
                        padding: const EdgeInsets.all(4),
                        child: Icon(
                          Icons.close_rounded,
                          size: 18,
                          color: getColor(context, "textLight"),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              // Subtitle / Description
              TextFont(
                text:
                    "Enable notification access to automatically record transactions from bank SMS, UPI payments, and card alerts without manual typing.",
                fontSize: 12.5,
                textColor: getColor(context, "textLight"),
                maxLines: 4,
              ),
              const SizedBox(height: 14),
              // Action Buttons Row: Primary CTA & Remind Later
              Row(
                children: [
                  Expanded(
                    child: Button(
                      label: "Enable Auto-Detect",
                      icon: Icons.check_circle_rounded,
                      fontSize: 13,
                      padding: const EdgeInsetsDirectional.symmetric(
                          vertical: 10, horizontal: 12),
                      onTap: () async {
                        HapticFeedback.selectionClick();
                        bool status = await requestReadNotificationPermission(
                            context: context);
                        if (status) {
                          openSnackbar(
                            SnackbarMessage(
                              title: "Auto-Detect Enabled",
                              icon: Icons.check_circle_rounded,
                              description:
                                  "Bank SMS and payment alerts will auto-record. Configure anytime in Settings > Offline Intelligence.",
                            ),
                          );
                        }
                        setState(() {
                          isPermissionGranted = status;
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Tappable(
                    color: Theme.of(context)
                        .colorScheme
                        .surface
                        .withValues(alpha: 0.5),
                    borderRadius: 14,
                    onTap: () {
                      HapticFeedback.lightImpact();
                      DateTime remindDate =
                          DateTime.now().add(const Duration(days: 7));
                      updateSettings(
                        "snoozedNotificationBannerUntil",
                        remindDate.toIso8601String(),
                        updateGlobalState: true,
                      );
                      setState(() {});
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      child: TextFont(
                        text: "Remind Later",
                        fontSize: 13,
                        textColor: getColor(context, "textLight"),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
