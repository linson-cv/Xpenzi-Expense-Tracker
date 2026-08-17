import 'dart:async';
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
import 'package:budget/widgets/openBottomSheet.dart';
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
import 'package:notification_listener_service/notification_event.dart';
import 'package:notification_listener_service/notification_listener_service.dart';

class OfflineIntelligencePage extends StatefulWidget {
  const OfflineIntelligencePage({super.key});

  @override
  State<OfflineIntelligencePage> createState() => _OfflineIntelligencePageState();
}

class _OfflineIntelligencePageState extends State<OfflineIntelligencePage> {
  bool isPermissionGranted = false;
  bool isCheckingPermission = true;
  StreamSubscription<ServiceNotificationEvent>? _uiNotificationSub;

  @override
  void initState() {
    super.initState();
    _checkPermission();
    if (getPlatform(ignoreEmulation: true) == PlatformOS.isAndroid) {
      _uiNotificationSub = NotificationListenerService.notificationsStream.listen((event) {
        if (mounted) {
          setState(() {});
        }
      });
    }
  }

  @override
  void dispose() {
    _uiNotificationSub?.cancel();
    super.dispose();
  }

  Future<void> _checkPermission() async {
    setState(() => isCheckingPermission = true);
    if (getPlatform(ignoreEmulation: true) == PlatformOS.isAndroid) {
      bool status = await NotificationListenerService.isPermissionGranted();
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
        scannerTemplatePk: "preset_credit_card_debit",
        templateName: "Credit Card Debited / Spent",
        contains: "Credit Card",
        amountTransactionBefore: "debited for Rs.",
        amountTransactionAfter: " on",
        titleTransactionBefore: "at ",
        titleTransactionAfter: " on",
        defaultCategoryFk: "0",
        walletFk: "-1",
        dateCreated: DateTime.now(),
        dateTimeModified: DateTime.now(),
        ignore: false,
      ),
      ScannerTemplate(
        scannerTemplatePk: "preset_upi_debit",
        templateName: "Bank / UPI Debit",
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
        templateName: "Bank / UPI Credit",
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
      ScannerTemplate(
        scannerTemplatePk: "preset_phonepe_paid",
        templateName: "PhonePe UPI Paid",
        contains: "paid to",
        amountTransactionBefore: "₹",
        amountTransactionAfter: " paid",
        titleTransactionBefore: "paid to ",
        titleTransactionAfter: " is",
        defaultCategoryFk: "0",
        walletFk: "-1",
        dateCreated: DateTime.now(),
        dateTimeModified: DateTime.now(),
        ignore: false,
      ),
      ScannerTemplate(
        scannerTemplatePk: "preset_sib_upi_debit",
        templateName: "Regular Bank UPI Debit",
        contains: "A/c *",
        amountTransactionBefore: "debited by ",
        amountTransactionAfter: " on",
        titleTransactionBefore: "transfer to ",
        titleTransactionAfter: " Ref",
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

  void _openAppFilterBottomSheet(BuildContext context) {
    String currentRaw = (appStateSettings["notificationAllowedPackages"] ?? "").toString();
    List<String> selectedKeywords = currentRaw
        .split(',')
        .map((e) => e.trim().toLowerCase())
        .where((e) => e.isNotEmpty)
        .toList();

    // Collect package names from captured logs
    Set<String> detectedPackages = {};
    for (String log in recentCapturedNotifications) {
      for (String line in log.split('\n')) {
        if (line.toLowerCase().startsWith("package name:")) {
          String pkg = line.replaceFirst(RegExp(r'package name:\s*', caseSensitive: false), '').trim();
          if (pkg.isNotEmpty) detectedPackages.add(pkg);
        }
      }
    }

    final List<Map<String, String>> presets = [
      {"name": "SMS & Messages", "key": "sms,mms,messaging,telephony,samsung.android.messaging,google.android.apps.messaging", "desc": "All device SMS & messaging apps", "icon": "sms"},
      {"name": "Google Pay", "key": "com.google.android.apps.nbu.paisa.user,com.google.android.apps.walletnfcrel,gpay", "desc": "GPay UPI & Wallet payments", "icon": "gpay"},
      {"name": "PhonePe", "key": "com.phonepe.app,phonepe", "desc": "PhonePe wallet & UPI", "icon": "phonepe"},
      {"name": "Paytm", "key": "net.one97.paytm,paytm", "desc": "Paytm UPI & wallet", "icon": "paytm"},
      {"name": "Banking & Cards", "key": "bank,card,citi,hdfc,icici,sbi,chase,wellsfargo,bofa,revolut,axis,kotak", "desc": "Bank transaction alerts & apps", "icon": "bank"},
      {"name": "WhatsApp Pay", "key": "com.whatsapp,whatsapp", "desc": "WhatsApp payment alerts", "icon": "whatsapp"},
      {"name": "CRED", "key": "com.dreamplug.androidapp,cred", "desc": "CRED credit card & UPI alerts", "icon": "cred"},
      {"name": "Amazon Pay", "key": "in.amazon.mShop.android.shopping,com.amazon.mShop.android.shopping,amazon", "desc": "Amazon Pay UPI alerts", "icon": "amazon"},
    ];

    TextEditingController customController = TextEditingController();

    openBottomSheet(
      context,
      StatefulBuilder(
        builder: (context, setSheetState) {
          bool isSelected(String key) {
            return selectedKeywords.any((k) => k == key.toLowerCase() || key.toLowerCase().contains(k));
          }

          void toggleSelection(String key) {
            String lower = key.toLowerCase().trim();
            if (selectedKeywords.contains(lower)) {
              selectedKeywords.remove(lower);
            } else {
              selectedKeywords.add(lower);
            }
            setSheetState(() {});
          }

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.apps_rounded,
                        color: Theme.of(context).colorScheme.primary,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          TextFont(
                            text: "Select Apps & Services",
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                          TextFont(
                            text: selectedKeywords.isEmpty
                                ? "Currently listening to ALL apps & SMS"
                                : "${selectedKeywords.length} filter keyword${selectedKeywords.length > 1 ? 's' : ''} active",
                            fontSize: 12.5,
                            textColor: getColor(context, "textLight"),
                          ),
                        ],
                      ),
                    ),
                    if (selectedKeywords.isNotEmpty)
                      IconButton(
                        tooltip: "Allow All Apps",
                        icon: const Icon(Icons.clear_all_rounded, size: 22),
                        onPressed: () {
                          selectedKeywords.clear();
                          setSheetState(() {});
                        },
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.tertiaryContainer.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline_rounded,
                        size: 16,
                        color: Theme.of(context).colorScheme.onTertiaryContainer,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextFont(
                          text:
                              "Note: Notifications from non-whitelisted apps are ignored. Custom keywords must match the Android Package ID (e.g. com.whatsapp, com.google.android.apps.messaging).",
                          fontSize: 11.5,
                          textColor: Theme.of(context).colorScheme.onTertiaryContainer,
                          maxLines: 4,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                TextFont(
                  text: "Popular Payment Apps & Services",
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  textColor: getColor(context, "textLight"),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (var preset in presets)
                      FilterChip(
                        label: Text(preset["name"]!),
                        selected: isSelected(preset["key"]!),
                        onSelected: (_) => toggleSelection(preset["key"]!),
                        selectedColor: Theme.of(context).colorScheme.primaryContainer,
                        checkmarkColor: Theme.of(context).colorScheme.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                  ],
                ),
                if (detectedPackages.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  TextFont(
                    text: "Detected from Recent Notifications",
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    textColor: getColor(context, "textLight"),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (String pkg in detectedPackages)
                        FilterChip(
                          label: Text(pkg.split('.').last.capitalizeFirst),
                          selected: isSelected(pkg),
                          onSelected: (_) => toggleSelection(pkg),
                          selectedColor: Theme.of(context).colorScheme.secondaryContainer,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                    ],
                  ),
                ],
                const SizedBox(height: 16),
                TextFont(
                  text: "Add Custom Package / Keyword",
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  textColor: getColor(context, "textLight"),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: customController,
                        decoration: InputDecoration(
                          hintText: "e.g. revolut, sbi, chase",
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          filled: true,
                          fillColor: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Button(
                      label: "Add",
                      icon: Icons.add_rounded,
                      padding: const EdgeInsetsDirectional.symmetric(horizontal: 14, vertical: 10),
                      onTap: () {
                        if (customController.text.trim().isNotEmpty) {
                          toggleSelection(customController.text.trim());
                          customController.clear();
                        }
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: Button(
                        label: "Cancel",
                        color: Theme.of(context).colorScheme.surfaceContainerHighest,
                        textColor: getColor(context, "blackAndWhite"),
                        onTap: () => popRoute(context),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Button(
                        label: "Apply Selection",
                        color: Theme.of(context).colorScheme.primary,
                        textColor: Theme.of(context).colorScheme.onPrimary,
                        onTap: () async {
                          await updateSettings(
                            "notificationAllowedPackages",
                            selectedKeywords.join(','),
                            updateGlobalState: true,
                          );
                          popRoute(context);
                          if (mounted) setState(() {});
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    bool isScanningActive =
        appStateSettings["notificationScanning"] == true && isPermissionGranted;

    return PageFramework(
      title: "Auto-Detect SMS",
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
        SettingsGroupCard(
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
                              size: 16,
                            ),
                            const SizedBox(width: 5),
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
                      const SizedBox(width: 8),
                      TextFont(
                        text: "100% On-Device",
                        fontSize: 12,
                        textColor: getColor(context, "textLight"),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  TextFont(
                    text:
                        "Offline Intelligence listens for payment and banking notifications on your device. All parsing runs completely locally without using an API key or sending data online.",
                    fontSize: 13,
                    textColor: getColor(context, "textLight"),
                  ),
                ],
              ),
            ),
          ],
        ),

        // Permission & Status Toggle Card
        SettingsGroupCard(
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
                    await populateDefaultScannerTemplatesIfEmpty();
                    initNotificationScanning();
                    Future.delayed(const Duration(milliseconds: 400), () {
                      if (mounted) promptBatteryOptimizationPopup(context);
                    });
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
              title: "Direct Silent Auto-Insert",
              description: appStateSettings["autoInsertNotificationsDirectly"] == true
                  ? "Directly record detected transactions silently without showing review prompt"
                  : "Prompt review dialog when a new transaction is detected",
              icon: Icons.flash_on_rounded,
              initialValue: appStateSettings["autoInsertNotificationsDirectly"] ?? false,
              onSwitched: (val) {
                updateSettings("autoInsertNotificationsDirectly", val,
                    updateGlobalState: true);
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
              title: "App Filter / Whitelist",
              description: (appStateSettings["notificationAllowedPackages"] ?? "")
                      .toString()
                      .trim()
                      .isNotEmpty
                  ? "Filtering active (${(appStateSettings["notificationAllowedPackages"] as String).split(',').where((e) => e.trim().isNotEmpty).length} selected)"
                  : "All apps and SMS (tap to select specific apps)",
              icon: Icons.filter_list_rounded,
              onTap: () {
                _openAppFilterBottomSheet(context);
              },
            ),
            const Divider(height: 1),
            SettingsContainerSwitch(
              title: "Persistent Background Monitor",
              description: appStateSettings["persistentBackgroundListener"] == true
                  ? "Maintains a silent, low-priority monitor so alerts are captured even when swiped away"
                  : "Allow background execution only while app remains in memory",
              icon: Icons.shield_outlined,
              initialValue: appStateSettings["persistentBackgroundListener"] ?? true,
              onSwitched: (val) async {
                await updateSettings("persistentBackgroundListener", val,
                    updateGlobalState: true);
                await updatePersistentBackgroundServiceNotification();
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

        // Custom Templates & Presets Section
        SettingsGroupCard(
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

        // Diagnostic & Service Control Card
        SettingsGroupCard(
          title: "Service Control & Force Re-Scan",
          icon: Icons.sync_rounded,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextFont(
                    text:
                        "If Android froze the background listener or a notification arrived while the app was closed, use the actions below to immediately re-initialize the OS event stream or pull notifications.",
                    fontSize: 13,
                    textColor: getColor(context, "textLight"),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: Button(
                          label: "Re-bind OS Listener",
                          icon: Icons.sync_rounded,
                          onTap: () async {
                            initNotificationScanning();
                            await _checkPermission();
                            if (mounted) {
                              openSnackbar(
                                SnackbarMessage(
                                  title: "OS Listener Re-bound",
                                  description: isScanningActive
                                      ? "Real-time notification stream is active and listening"
                                      : "Notification access permission required",
                                  icon: Icons.check_circle_rounded,
                                ),
                              );
                              setState(() {});
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),

        // Captured Notifications Raw Log Inspector
        SettingsGroupCard(
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
      ],
    );
  }
}
