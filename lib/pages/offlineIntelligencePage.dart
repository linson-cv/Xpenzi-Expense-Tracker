import 'package:budget/colors.dart';
import 'package:budget/database/tables.dart' hide AppSettings;
import 'package:budget/functions.dart';
import 'package:budget/pages/addEmailTemplate.dart';
import 'package:budget/pages/autoTransactionsPageEmail.dart';
import 'package:budget/struct/databaseGlobal.dart';
import 'package:budget/struct/settings.dart';
import 'package:budget/widgets/button.dart';
import 'package:budget/widgets/framework/pageFramework.dart';
import 'package:budget/widgets/globalSnackbar.dart';
import 'package:budget/widgets/openContainerNavigation.dart';
import 'package:budget/widgets/openPopup.dart';
import 'package:budget/widgets/openSnackbar.dart';
import 'package:budget/widgets/settingsContainers.dart';
import 'package:budget/widgets/statusBox.dart';
import 'package:budget/widgets/tappable.dart';
import 'package:budget/widgets/textWidgets.dart';
import 'package:app_settings/app_settings.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class OfflineIntelligencePage extends StatefulWidget {
  const OfflineIntelligencePage({super.key});

  @override
  State<OfflineIntelligencePage> createState() => _OfflineIntelligencePageState();
}

class _OfflineIntelligencePageState extends State<OfflineIntelligencePage> {
  bool isPermissionGranted = false;
  bool isCheckingPermission = true;

  @override
  void initState() {
    super.initState();
    _checkPermission();
  }

  Future<void> _checkPermission() async {
    setState(() => isCheckingPermission = true);
    if (getPlatform(ignoreEmulation: true) == PlatformOS.isAndroid) {
      bool status = await requestReadNotificationPermission();
      if (mounted) {
        setState(() {
          isPermissionGranted = status;
          isCheckingPermission = false;
        });
      }
    } else {
      if (mounted) {
        setState(() {
          isPermissionGranted = false;
          isCheckingPermission = false;
        });
      }
    }
  }

  Future<void> _loadDefaultTemplates() async {
    HapticFeedback.mediumImpact();
    // Default presets for common bank alerts & UPI notifications
    List<ScannerTemplate> defaults = [
      ScannerTemplate(
        scannerTemplatePk: "preset_upi_debit",
        templateName: "UPI & Bank Debit",
        contains: "debited",
        amountTransactionBefore: "Rs.",
        amountTransactionAfter: " ",
        titleTransactionBefore: "to ",
        titleTransactionAfter: " on",
        defaultCategoryFk: "0",
        walletFk: "-1",
        dateCreated: DateTime.now(),
        dateTimeModified: DateTime.now(),
        ignore: false,
      ),
      ScannerTemplate(
        scannerTemplatePk: "preset_upi_credit",
        templateName: "UPI & Bank Credit",
        contains: "credited",
        amountTransactionBefore: "Rs.",
        amountTransactionAfter: " ",
        titleTransactionBefore: "from ",
        titleTransactionAfter: " on",
        defaultCategoryFk: "0",
        walletFk: "-1",
        dateCreated: DateTime.now(),
        dateTimeModified: DateTime.now(),
        ignore: false,
      ),
      ScannerTemplate(
        scannerTemplatePk: "preset_card_spent",
        templateName: "Card Spending Alert",
        contains: "spent",
        amountTransactionBefore: "INR ",
        amountTransactionAfter: " at",
        titleTransactionBefore: "at ",
        titleTransactionAfter: " on",
        defaultCategoryFk: "0",
        walletFk: "-1",
        dateCreated: DateTime.now(),
        dateTimeModified: DateTime.now(),
        ignore: false,
      ),
    ];

    int added = 0;
    for (var tmpl in defaults) {
      try {
        await database.createOrUpdateScannerTemplate(tmpl);
        added++;
      } catch (e) {
        print("Error inserting default template: $e");
      }
    }

    if (mounted) {
      openSnackbar(
        SnackbarMessage(
          title: "Default Presets Installed",
          description: "Installed $added ready-to-use notification templates",
          icon: Icons.check_circle_rounded,
        ),
      );
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isScanningActive =
        appStateSettings["notificationScanning"] == true && isPermissionGranted;

    return PageFramework(
      title: "Offline Intelligence",
      dragDownToDismiss: true,
      actions: [
        IconButton(
          tooltip: "Refresh Permissions & Logs",
          icon: const Icon(Icons.refresh_rounded),
          onPressed: () {
            _checkPermission();
            setState(() {});
          },
        ),
      ],
      listWidgets: [
        // Highlight Header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          child: SettingsGroupCard(
            title: "On-Device Private Engine",
            icon: Icons.lock_outline_rounded,
            children: [
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: isScanningActive
                                ? Colors.green.withOpacity(0.15)
                                : Colors.orange.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                isScanningActive
                                    ? Icons.check_circle
                                    : Icons.info_outline,
                                color: isScanningActive
                                    ? Colors.green
                                    : Colors.orange,
                                size: 14,
                              ),
                              const SizedBox(width: 4),
                              TextFont(
                                text: isScanningActive
                                    ? "Active & Listening"
                                    : "Setup Required",
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                textColor: isScanningActive
                                    ? Colors.green
                                    : Colors.orange,
                              ),
                            ],
                          ),
                        ),
                        const Spacer(),
                        TextFont(
                          text: "100% Offline & Private",
                          fontSize: 11,
                          textColor: getColor(context, "textLight"),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    TextFont(
                      text:
                          "Xpenzi automatically reads incoming bank SMS, UPI alerts, and payment receipts right on your device. Zero data is sent to external servers.",
                      fontSize: 13,
                      textColor: getColor(context, "textLight"),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Permission & Status Toggle Card
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          child: SettingsGroupCard(
            title: "Notification Listening Access",
            icon: Icons.notifications_active_rounded,
            children: [
              SettingsContainerSwitch(
                title: "Auto-Detect Bank & Payment Alerts",
                description: isPermissionGranted
                    ? "Notification listener granted. Listening for payment receipts."
                    : "Tap to grant Android notification listener permission.",
                icon: isScanningActive
                    ? Icons.notifications_active_rounded
                    : Icons.notifications_paused_rounded,
                initialValue: isScanningActive,
                onSwitched: (val) async {
                  if (val == true) {
                    bool status = await requestReadNotificationPermission(
                        context: context);
                    if (status) {
                      await updateSettings("notificationScanning", true,
                          updateGlobalState: true);
                      initNotificationScanning();
                    }
                    if (mounted) {
                      setState(() {
                        isPermissionGranted = status;
                      });
                    }
                  } else {
                    await updateSettings("notificationScanning", false,
                        updateGlobalState: true);
                    notificationListenerSubscription?.cancel();
                    if (mounted) {
                      setState(() {});
                    }
                  }
                },
              ),
              const Divider(height: 1),
              SettingsContainerSwitch(
                title: "Local NLP Parsing Engine",
                description:
                    "Extract title, amount, and merchant using smart regex rules",
                icon: Icons.bolt_rounded,
                initialValue: appStateSettings["localNlpParsing"] ?? true,
                onSwitched: (val) {
                  updateSettings("localNlpParsing", val,
                      updateGlobalState: true);
                },
              ),
              const Divider(height: 1),
              SettingsContainer(
                title: "Battery Optimization Settings",
                description: "Ensure Android doesn't put background listener to sleep",
                icon: Icons.battery_charging_full_rounded,
                onTap: () async {
                  await AppSettings.openAppSettings(type: AppSettingsType.batteryOptimization);
                },
              ),
            ],
          ),
        ),

        // Custom Templates & Presets Section
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          child: SettingsGroupCard(
            title: "Parsing Templates",
            icon: Icons.pattern_rounded,
            children: [
              Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Expanded(
                      child: TextFont(
                        text:
                            "Templates teach Xpenzi how to parse different bank formats and match categories.",
                        fontSize: 12.5,
                        textColor: getColor(context, "textLight"),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Button(
                      label: "Load Defaults",
                      icon: Icons.download_rounded,
                      padding: const EdgeInsetsDirectional.symmetric(
                          horizontal: 12, vertical: 8),
                      fontSize: 12,
                      onTap: _loadDefaultTemplates,
                    ),
                  ],
                ),
              ),
              StreamBuilder<List<ScannerTemplate>>(
                stream: database.watchAllScannerTemplates(),
                builder: (context, snapshot) {
                  if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                    return Column(
                      children: [
                        for (ScannerTemplate tmpl in snapshot.data!)
                          ScannerTemplateEntry(
                            messagesList: recentCapturedNotifications,
                            scannerTemplate: tmpl,
                          ),
                      ],
                    );
                  }
                  return Padding(
                    padding: const EdgeInsets.all(12),
                    child: StatusBox(
                      title: "No Templates Configured",
                      description:
                          "Tap 'Load Defaults' above or add a custom template below.",
                      icon: Icons.info_outline_rounded,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  );
                },
              ),
              OpenContainerNavigation(
                openPage: AddEmailTemplate(
                  messagesList: recentCapturedNotifications,
                ),
                borderRadius: 15,
                button: (openContainer) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    child: Button(
                      label: "Add Custom Template",
                      icon: Icons.add_rounded,
                      onTap: openContainer,
                    ),
                  );
                },
              ),
              const SizedBox(height: 6),
            ],
          ),
        ),

        // Captured Notifications Raw Log Inspector
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          child: SettingsGroupCard(
            title: "Captured Notification Logs",
            icon: Icons.history_rounded,
            children: [
              SettingsContainerDropdown(
                title: "Log Retention Limit",
                description: "Maximum recent raw notifications kept in memory",
                icon: Icons.filter_list_rounded,
                initial: (appStateSettings["notificationLogRetentionCount"] ?? "50").toString(),
                items: const ["20", "50", "100", "200"],
                onChanged: (val) {
                  updateSettings("notificationLogRetentionCount", val, updateGlobalState: true);
                  int max = int.tryParse(val) ?? 50;
                  if (recentCapturedNotifications.length > max) {
                    setState(() {
                      recentCapturedNotifications.removeRange(max, recentCapturedNotifications.length);
                    });
                  } else {
                    setState(() {});
                  }
                },
              ),
              const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Expanded(
                      child: TextFont(
                        text:
                            "Shows ${recentCapturedNotifications.length} of max ${appStateSettings["notificationLogRetentionCount"] ?? "50"} notifications intercepted on this device.",
                        fontSize: 12.5,
                        textColor: getColor(context, "textLight"),
                      ),
                    ),
                    if (recentCapturedNotifications.isNotEmpty)
                      IconButton(
                        tooltip: "Clear Logs",
                        icon: const Icon(Icons.delete_sweep_rounded, size: 20),
                        onPressed: () {
                          setState(() {
                            recentCapturedNotifications.clear();
                          });
                        },
                      ),
                  ],
                ),
              ),
              if (recentCapturedNotifications.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Center(
                    child: TextFont(
                      text: isScanningActive
                          ? "No notifications captured yet. As soon as you receive a transaction SMS or payment push alert, it will appear here."
                          : "Enable notification access above to begin logging incoming alerts.",
                      fontSize: 13,
                      textAlign: TextAlign.center,
                      textColor: getColor(context, "textLight"),
                    ),
                  ),
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: recentCapturedNotifications.length,
                  separatorBuilder: (context, index) =>
                      const Divider(height: 1, indent: 16, endIndent: 16),
                  itemBuilder: (context, index) {
                    final log = recentCapturedNotifications[index];
                    return Tappable(
                      onTap: () {
                        openPopup(
                          context,
                          title: "Notification Log Details",
                          description: log,
                          onSubmit: () {
                            Clipboard.setData(ClipboardData(text: log));
                            popRoute(context);
                            openSnackbar(
                              SnackbarMessage(
                                title: "Copied to clipboard",
                                icon: Icons.copy_rounded,
                              ),
                            );
                          },
                          onSubmitLabel: "Copy Text",
                          onCancel: () => popRoute(context),
                          onCancelLabel: "Close",
                        );
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Theme.of(context)
                                    .colorScheme
                                    .primaryContainer
                                    .withOpacity(0.4),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                Icons.sms_outlined,
                                color: Theme.of(context).colorScheme.primary,
                                size: 18,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  TextFont(
                                    text: log.split('\n').firstOrNull ?? "Notification",
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    maxLines: 1,
                                  ),
                                  const SizedBox(height: 3),
                                  TextFont(
                                    text: log.replaceAll('\n', ' '),
                                    fontSize: 12,
                                    maxLines: 2,
                                    textColor: getColor(context, "textLight"),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(
                              Icons.chevron_right_rounded,
                              size: 18,
                              color: Colors.grey,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ],
    );
  }
}
