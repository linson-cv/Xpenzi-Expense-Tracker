import 'package:budget/colors.dart';
import 'package:budget/functions.dart';
import 'package:budget/pages/autoTransactionsPageEmail.dart';
import 'package:budget/struct/settings.dart';
import 'package:budget/widgets/button.dart';
import 'package:budget/widgets/globalSnackbar.dart';
import 'package:budget/widgets/openSnackbar.dart';
import 'package:budget/widgets/settingsContainers.dart';
import 'package:budget/widgets/textWidgets.dart';
import 'package:flutter/material.dart';

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
    bool status = await requestReadNotificationPermission();
    if (mounted) {
      setState(() {
        isPermissionGranted = status;
      });
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

    // Check periodic snooze (e.g., re-prompt after 14 days if user chose "Remind Later")
    if (appStateSettings["snoozedNotificationBannerUntil"] != null) {
      DateTime? snoozeUntil = DateTime.tryParse(
          appStateSettings["snoozedNotificationBannerUntil"].toString());
      if (snoozeUntil != null && DateTime.now().isBefore(snoozeUntil)) {
        return const SizedBox.shrink();
      }
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: SettingsGroupCard(
        title: "Auto-Detect Bank SMS & Alerts",
        icon: Icons.notifications_active_rounded,
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFont(
                  text:
                      "Enable notification access so Xpenzi can auto-detect bank SMS, payment alerts, and merchant transactions without manual typing.",
                  fontSize: 13,
                  textColor: getColor(context, "textLight"),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Button(
                        label: "Enable Permission",
                        icon: Icons.check_circle_rounded,
                        onTap: () async {
                          bool status = await requestReadNotificationPermission(context: context);
                          if (status) {
                            await updateSettings(
                                "notificationScanning", true,
                                updateGlobalState: false);
                            initNotificationScanning();
                            openSnackbar(
                              SnackbarMessage(
                                title: "Notification Access Granted",
                                icon: Icons.check_circle_rounded,
                                description: "Auto transaction detection enabled.",
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
                    Button(
                      label: "Remind Later",
                      color: Colors.transparent,
                      textColor: getColor(context, "textLight"),
                      onTap: () {
                        DateTime remindDate = DateTime.now().add(const Duration(days: 14));
                        updateSettings(
                            "snoozedNotificationBannerUntil", remindDate.toIso8601String(),
                            updateGlobalState: true);
                        setState(() {});
                      },
                    ),
                    const SizedBox(width: 4),
                    IconButton(
                      tooltip: "Never Ask Again",
                      icon: Icon(Icons.close_rounded, size: 18, color: getColor(context, "textLight")),
                      onPressed: () {
                        updateSettings(
                            "neverShowNotificationPermissionBanner", true,
                            updateGlobalState: true);
                        setState(() {});
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
