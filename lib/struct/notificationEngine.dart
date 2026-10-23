import 'dart:async';
import 'dart:isolate';
import 'dart:ui';
import 'package:app_settings/app_settings.dart';
import 'package:budget/database/tables.dart' hide AppSettings;
import 'package:budget/functions.dart';
import 'package:budget/pages/addTransactionPage.dart';
import 'package:budget/pages/offlineIntelligencePage.dart';
import 'package:budget/struct/autoTransactionTracker.dart';
import 'package:budget/struct/databaseGlobal.dart';
import 'package:budget/struct/geminiAi.dart';
import 'package:budget/struct/localNlpParser.dart';
import 'package:budget/struct/notificationsGlobal.dart';
import 'package:budget/struct/settings.dart';
import 'package:budget/widgets/globalSnackbar.dart';
import 'package:budget/widgets/navigationFramework.dart';
import 'package:budget/widgets/openPopup.dart';
import 'package:budget/widgets/openSnackbar.dart';
import 'package:budget/struct/backgroundNotificationHandler.dart';
import 'package:budget/struct/errorLog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:notification_listener_service/notification_event.dart';
import 'package:notification_listener_service/notification_listener_service.dart';
import 'package:provider/provider.dart';

StreamSubscription<ServiceNotificationEvent>? notificationListenerSubscription;
List<String> recentCapturedNotifications = [];
ReceivePort? _mainIsolatePingPort;
const String kMainIsolatePingPortName = 'xpenzi_main_isolate_ping';

void _registerMainIsolatePingPort() {
  try {
    _mainIsolatePingPort?.close();
    _mainIsolatePingPort = ReceivePort();
    IsolateNameServer.removePortNameMapping(kMainIsolatePingPortName);
    IsolateNameServer.registerPortWithName(
      _mainIsolatePingPort!.sendPort,
      kMainIsolatePingPortName,
    );
    _mainIsolatePingPort!.listen((message) {
      if (message is SendPort) {
        try {
          message.send(true);
        } catch (_) {}
      } else if (message is Map) {
        final dynamic replyPort = message['replyPort'];
        if (replyPort is SendPort) {
          try {
            replyPort.send(true);
          } catch (_) {}
        }
        try {
          final forwardedEvent = ServiceNotificationEvent(
            packageName: message['packageName']?.toString(),
            title: message['title']?.toString(),
            content: message['content']?.toString(),
            hasRemoved: message['hasRemoved'] == true,
            onGoing: message['onGoing'] == true,
          );
          onNotification(forwardedEvent);
        } catch (e) {
          print("[NotificationEngine] Error handling forwarded notification: $e");
        }
      }
    });
  } catch (e) {
    print("[NotificationEngine] Error registering main isolate ping port: $e");
  }
}

void _unregisterMainIsolatePingPort() {
  try {
    IsolateNameServer.removePortNameMapping(kMainIsolatePingPortName);
    _mainIsolatePingPort?.close();
    _mainIsolatePingPort = null;
  } catch (_) {}
}

List<ScannerTemplate> getAllDefaultScannerTemplates() {
  final now = DateTime.now();
  return [
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
      dateCreated: now,
      dateTimeModified: now,
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
      dateCreated: now,
      dateTimeModified: now,
      ignore: false,
    ),
    ScannerTemplate(
      scannerTemplatePk: "preset_bank_debit",
      templateName: "Bank Account Debit",
      contains: "debited",
      amountTransactionBefore: "debited",
      amountTransactionAfter: " on",
      titleTransactionBefore: "to ",
      titleTransactionAfter: " on",
      defaultCategoryFk: "0",
      walletFk: "-1",
      dateCreated: now,
      dateTimeModified: now,
      ignore: false,
    ),
    ScannerTemplate(
      scannerTemplatePk: "preset_bank_credit",
      templateName: "Bank Account Credit / Deposit",
      contains: "credited",
      amountTransactionBefore: "credited",
      amountTransactionAfter: " to",
      titleTransactionBefore: "by ",
      titleTransactionAfter: " on",
      defaultCategoryFk: "0",
      walletFk: "-1",
      dateCreated: now,
      dateTimeModified: now,
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
      dateCreated: now,
      dateTimeModified: now,
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
      dateCreated: now,
      dateTimeModified: now,
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
      dateCreated: now,
      dateTimeModified: now,
      ignore: false,
    ),
    ScannerTemplate(
      scannerTemplatePk: "preset_instant_payment",
      templateName: "Payment App / Instant Pay",
      contains: "paid to",
      amountTransactionBefore: "paid",
      amountTransactionAfter: " to",
      titleTransactionBefore: "paid to ",
      titleTransactionAfter: " using",
      defaultCategoryFk: "0",
      walletFk: "-1",
      dateCreated: now,
      dateTimeModified: now,
      ignore: false,
    ),
    ScannerTemplate(
      scannerTemplatePk: "preset_recurring_autopay",
      templateName: "Subscription / Auto-Debit",
      contains: "AutoPay debit",
      amountTransactionBefore: "for Rs.",
      amountTransactionAfter: " ",
      titleTransactionBefore: "AutoPay debit for ",
      titleTransactionAfter: " towards",
      defaultCategoryFk: "0",
      walletFk: "-1",
      dateCreated: now,
      dateTimeModified: now,
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
      dateCreated: now,
      dateTimeModified: now,
      ignore: false,
    ),
  ];
}

Future<int> populateDefaultScannerTemplatesIfEmpty({bool forceAll = false}) async {
  try {
    List<ScannerTemplate> existing = await database.getAllScannerTemplates();
    List<ScannerTemplate> defaults = getAllDefaultScannerTemplates();

    Set<String> existingPks = existing.map((e) => e.scannerTemplatePk).toSet();
    int addedCount = 0;

    for (var tmpl in defaults) {
      if (forceAll || !existingPks.contains(tmpl.scannerTemplatePk)) {
        await database.createOrUpdateScannerTemplate(tmpl);
        addedCount++;
      }
    }

    if (addedCount > 0) {
      print("Auto-loaded $addedCount default bank scanner templates");
    }
    return addedCount;
  } catch (e) {
    print("Error populating default scanner templates: $e");
    return 0;
  }
}

Future<void> updatePersistentBackgroundServiceNotification() async {
  if (getPlatform(ignoreEmulation: true) != PlatformOS.isAndroid) return;

  if (appStateSettings["notificationScanning"] == true &&
      appStateSettings["persistentBackgroundListener"] == true) {
    await startBackgroundListenerService();
  } else {
    await stopBackgroundListenerService();
  }
}

Future initNotificationScanning() async {
  if (getPlatform(ignoreEmulation: true) != PlatformOS.isAndroid) return;
  await notificationListenerSubscription?.cancel();
  notificationListenerSubscription = null;
  if (appStateSettings["notificationScanning"] != true) {
    _unregisterMainIsolatePingPort();
    await updatePersistentBackgroundServiceNotification();
    return;
  }

  bool status = await safeIsNotificationPermissionGranted();

  if (status == true) {
    _registerMainIsolatePingPort();
    try {
      await database.fixTransactionPolarity();
    } catch (_) {}
    await populateDefaultScannerTemplatesIfEmpty();
    // If persistent background listener is enabled, run the persistent foreground task to keep app alive
    if (appStateSettings["persistentBackgroundListener"] == true) {
      await startBackgroundListenerService();
    }
    
    // Always maintain main isolate listener subscription as well
    await notificationListenerSubscription?.cancel();
    notificationListenerSubscription =
        NotificationListenerService.notificationsStream.listen(
      (event) {
        try {
          onNotification(event);
        } catch (e, stack) {
          print("[NotificationEngine] Error processing notification: $e\n$stack");
        }
      },
      onError: (err) {
        print("[NotificationEngine] notificationsStream error: $err");
      },
    );
  }
}

Future<void> promptBatteryOptimizationPopup(BuildContext context) async {
  openPopup(
    context,
    title: "Disable Battery Optimization",
    icon: Icons.battery_charging_full_rounded,
    description:
        "To ensure continuous, real-time background detection of bank SMS & payment alerts when the app is closed, Android requires battery optimization to be turned off for Xpenzi.\n\n• Prevents Android from killing the notification listener\n• Ensures transactions are captured immediately in the background\n\n⚙️ You can customize auto-insert, NLP parsing rules, and templates anytime under Settings > Offline Intelligence.",
    onSubmitLabel: "Open Battery Settings",
    onCancelLabel: "Later",
    onSubmit: () async {
      popRoute(context);
      try {
        await AppSettings.openAppSettings(type: AppSettingsType.batteryOptimization);
      } catch (e) {
        print("Error opening battery optimization settings: $e");
        await AppSettings.openAppSettings();
      }
    },
    onCancel: () {
      popRoute(context);
      openSnackbar(
        SnackbarMessage(
          title: "Background Alerts May Be Delayed",
          icon: Icons.battery_saver_outlined,
          description:
              "Battery optimization remains enabled. Transactions will still be detected while the app is active, but background capture when closed might be delayed by Android.",
        ),
      );
    },
  );
}

/// Safely requests notification access without failing or leaking unhandled zone errors.
/// Some Android OEM versions return `null` from the native platform channel instead of a boolean,
/// causing a cast error `type 'Null' is not a subtype of type 'FutureOr<bool>'`.
Future<bool> safeRequestNotificationPermission() async {
  try {
    return await NotificationListenerService.requestPermission().catchError((error) {
      print("Notification permission request handled platform channel result: $error");
      return false;
    });
  } catch (e) {
    print("Notification permission request sync exception handled: $e");
    return false;
  }
}

/// Safely checks if notification access is granted.
Future<bool> safeIsNotificationPermissionGranted() async {
  try {
    return await NotificationListenerService.isPermissionGranted().catchError((_) => false);
  } catch (_) {
    return false;
  }
}

class _AppResumeObserver with WidgetsBindingObserver {
  final Future<void> Function() onResumed;
  _AppResumeObserver(this.onResumed) {
    WidgetsBinding.instance.addObserver(this);
  }
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      onResumed();
    }
  }
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
  }
}

Future<bool> promptNotificationPermissionPopup(BuildContext context) async {
  return await requestReadNotificationPermission(context: context);
}

Future<bool> requestReadNotificationPermission({
  BuildContext? context,
  bool showBatteryPopup = true,
}) async {
  if (getPlatform(ignoreEmulation: true) != PlatformOS.isAndroid) return false;

  bool alreadyGranted = await safeIsNotificationPermissionGranted();
  if (alreadyGranted) {
    // 2. Enable offline processing in settings with all default settings and templates
    await updateSettings("notificationScanning", true, updateGlobalState: true);
    await updateSettings("autoInsertNotificationsDirectly", true, updateGlobalState: true);
    await updateSettings("localNlpParsing", true, updateGlobalState: true);
    await populateDefaultScannerTemplatesIfEmpty(forceAll: true);
    await initNotificationScanning();
    return true;
  }

  BuildContext? popupContext = context ?? navigatorKey.currentContext;
  if (popupContext == null) return false;

  Completer<bool> completer = Completer<bool>();
  _AppResumeObserver? resumeObserver;

  void cleanup() {
    resumeObserver?.dispose();
    resumeObserver = null;
  }

  // 1. Read app notification popup that clearly states what it is used for
  // Complies with Google Play Android notification & SMS policy
  openPopup(
    popupContext,
    title: "Enable Notification Access",
    icon: Icons.notifications_active_rounded,
    description:
        "Xpenzi uses notification access to auto-detect bank transaction SMS & payment alerts on your device.\n\n"
        "• 100% Private: All parsing happens locally on this device\n"
        "• Bank & payment alerts only\n"
        "• No personal chats, sensitive messages, or credentials are read or stored\n"
        "• No data is ever uploaded or sent to external servers",
    onSubmitLabel: "Open Android Settings",
    onCancelLabel: "Cancel",
    onSubmit: () async {
      popRoute(popupContext);

      // Listen for app resumption after user returns from Android Settings
      resumeObserver = _AppResumeObserver(() async {
        cleanup();
        // Allow Android service binder to refresh permission state
        await Future.delayed(const Duration(milliseconds: 350));
        bool isGranted = await safeIsNotificationPermissionGranted();

        if (isGranted) {
          // 2. Enable offline processing with all default settings & templates
          await updateSettings("notificationScanning", true, updateGlobalState: true);
          await updateSettings("autoInsertNotificationsDirectly", true, updateGlobalState: true);
          await updateSettings("localNlpParsing", true, updateGlobalState: true);
          await populateDefaultScannerTemplatesIfEmpty(forceAll: true);
          await initNotificationScanning();

          // 3. Battery optimization popup; on accept open settings
          if (showBatteryPopup) {
            Future.delayed(const Duration(milliseconds: 400), () {
              BuildContext ctx = navigatorKey.currentContext ?? popupContext;
              promptBatteryOptimizationPopup(ctx);
            });
          }

          if (!completer.isCompleted) completer.complete(true);
        } else {
          // User returned without granting: abort all policy & settings and notify
          openSnackbar(
            SnackbarMessage(
              title: "Auto-Detection Not Enabled",
              icon: Icons.notifications_off_outlined,
              description:
                  "Notification access was not granted. Automatic transaction detection is disabled. You can enable it anytime in Settings.",
            ),
          );
          if (!completer.isCompleted) completer.complete(false);
        }
      });

      // Launch native Android Notification Access Settings
      await safeRequestNotificationPermission();
    },
    onCancel: () {
      popRoute(popupContext);
      cleanup();
      // If reject then abort all the policy and notify cleanly
      openSnackbar(
        SnackbarMessage(
          title: "Setup Cancelled",
          icon: Icons.info_outline_rounded,
          description:
              "Automatic transaction detection is disabled. All manual features continue to work normally.",
        ),
      );
      if (!completer.isCompleted) completer.complete(false);
    },
  ).then((_) {
    // If dismissed via barrier tap or system back gesture without tapping Cancel or Submit
    if (resumeObserver == null && !completer.isCompleted) {
      cleanup();
      openSnackbar(
        SnackbarMessage(
          title: "Setup Cancelled",
          icon: Icons.info_outline_rounded,
          description:
              "Automatic transaction detection is disabled. All manual features continue to work normally.",
        ),
      );
      completer.complete(false);
    }
  });

  return completer.future;
}

/// Periodic reminder to enable Offline Intelligence (notification scanning).
/// Only shows for users who explicitly skipped the notification popup during
/// onboarding. Shows every 5th app login on Android until the user enables
/// notification scanning or permanently dismisses with "Never".
bool openOfflineIntelligenceReminderCheck(BuildContext context) {
  if (getPlatform(ignoreEmulation: true) != PlatformOS.isAndroid) return false;
  if (appStateSettings["notificationScanning"] == true) return false;
  if (appStateSettings["skippedOfflineIntelligenceOnboarding"] != true) {
    return false;
  }
  if (appStateSettings["canShowOfflineIntelligenceReminder"] != true) {
    return false;
  }
  if ((appStateSettings["numLogins"] + 1) % 5 != 0) return false;

  openPopup(
    context,
    icon: Icons.notifications_active_rounded,
    title: "Enable Offline Intelligence?",
    description:
        "Xpenzi can automatically detect bank SMS, UPI payments, and card alerts to create transactions without manual typing.\n\n🔒 100% Private: All processing happens on your device. No data leaves your phone.",
    onSubmitLabel: "Enable Now",
    onCancelLabel: "Never",
    onExtraLabel: "Later",
    onSubmit: () async {
      popRoute(context);
      bool status =
          await requestReadNotificationPermission(context: context);
      if (status && context.mounted) {
        pushRoute(context, const OfflineIntelligencePage());
      }
    },
    onCancel: () async {
      popRoute(context);
      await updateSettings("canShowOfflineIntelligenceReminder", false,
          updateGlobalState: false);
    },
    onExtra: () {
      popRoute(context);
    },
  );
  return true;
}

final Map<String, DateTime> _recentlyProcessedNotificationKeys = {};
final Map<String, DateTime> _recentRawEventSignatures = {};

onNotification(ServiceNotificationEvent event) async {
  try {
    // 1. Ignore notification removal/dismissal or ongoing media/service events
    if (event.hasRemoved == true || event.onGoing == true) {
      return;
    }

    // 1b. Deduplicate raw event within 4 seconds (in case both main stream and background isolate forward it)
    final DateTime now = DateTime.now();
    _recentRawEventSignatures.removeWhere(
        (_, timestamp) => now.difference(timestamp).inSeconds.abs() > 4);
    final String rawSig =
        "${event.packageName ?? ''}|${event.title ?? ''}|${event.content ?? ''}";
    if (_recentRawEventSignatures.containsKey(rawSig)) {
      return;
    }
    _recentRawEventSignatures[rawSig] = now;

    // 2. App-specific package name filtering (if configured) and default non-financial app block
    String? pkg = event.packageName?.trim().toLowerCase();
    String? allowedPackagesString = appStateSettings["notificationAllowedPackages"]?.toString().trim();

    if (isNonFinancialPackageByDefault(pkg, allowedPackagesString: allowedPackagesString)) {
      return;
    }

    if (allowedPackagesString != null && allowedPackagesString.isNotEmpty) {
      List<String> allowedList = allowedPackagesString
          .split(",")
          .map((e) => e.trim().toLowerCase())
          .where((e) => e.isNotEmpty)
          .toList();
      if (allowedList.isNotEmpty && pkg != null && !allowedList.any((allowed) => pkg.contains(allowed))) {
        // Ignore notification from unselected packages
        return;
      }
    }

    String messageString = getNotificationMessage(event);
    if (isChatOrMediaNotification(messageString)) {
      return;
    }
    print("[NotificationEngine] Captured event from $pkg: ${event.title} - ${event.content}");

    final String trimmedLog = messageString.length > 500
        ? "${messageString.substring(0, 500)}..."
        : messageString;
    recentCapturedNotifications.insert(0, trimmedLog);
    int maxCount = int.tryParse(appStateSettings["notificationLogRetentionCount"]?.toString() ?? "25") ?? 25;
    if (recentCapturedNotifications.length > maxCount) {
      recentCapturedNotifications.removeRange(maxCount, recentCapturedNotifications.length);
    }
    await queueTransactionFromMessage(messageString, dateTime: DateTime.now());
  } catch (e, stack) {
    print("[NotificationEngine] Error in onNotification: $e\n$stack");
    recordAppError("NotificationListenerError", e, stackTrace: stack);
  }
}

Future<void> _showBackgroundInsertedNotification({
  required String title,
  required double amount,
  required bool isIncome,
  required String? transactionPk,
}) async {
  try {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'auto_transactions_channel',
      'Auto-Detected Transactions',
      channelDescription: 'Alerts when payment or bank SMS notifications are automatically recorded',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
      enableVibration: true,
      playSound: true,
      autoCancel: true,
      ongoing: false,
    );

    DarwinNotificationDetails darwinDetails = const DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: darwinDetails,
    );

    int notificationId = DateTime.now().millisecondsSinceEpoch.remainder(100000);
    String payload = transactionPk != null ? "openTransaction?transactionPk=$transactionPk" : "transactions";

    await flutterLocalNotificationsPlugin.show(
      notificationId,
      isIncome ? "Auto-Recorded Income" : "Auto-Recorded Transaction",
      "$title · ${amount.abs().toStringAsFixed(2)}",
      notificationDetails,
      payload: payload,
    );
  } catch (e) {
    print("Error showing background local notification: $e");
  }
}

class InitializeNotificationService extends StatefulWidget {
  const InitializeNotificationService({required this.child, super.key});
  final Widget child;

  @override
  State<InitializeNotificationService> createState() =>
      _InitializeNotificationServiceState();
}

class _InitializeNotificationServiceState
    extends State<InitializeNotificationService> {
  @override
  void initState() {
    super.initState();
    Future.delayed(Duration.zero, () async {
      initNotificationScanning();
    });
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}

String? getTransactionTitleFromEmail(String messageString,
    String titleTransactionBefore, String titleTransactionAfter) {
  if (titleTransactionBefore.isEmpty || titleTransactionAfter.isEmpty) {
    return null;
  }
  String? title;
  try {
    int rawStart = messageString.indexOf(titleTransactionBefore);
    if (rawStart == -1) return null;
    int startIndex = rawStart + titleTransactionBefore.length;
    int endIndex = messageString.indexOf(titleTransactionAfter, startIndex);
    if (endIndex == -1 || endIndex <= startIndex) return null;
    title = messageString.substring(startIndex, endIndex);
    title = title.replaceAll("\n", "").trim();
    if (title.isEmpty) return null;
    title = title.toLowerCase();
    title = title.capitalizeFirst;
  } catch (e) {}
  return title;
}

double? getTransactionAmountFromEmail(String messageString,
    String amountTransactionBefore, String amountTransactionAfter) {
  if (amountTransactionBefore.isEmpty || amountTransactionAfter.isEmpty) {
    return null;
  }
  double? amountDouble;
  try {
    int rawStart = messageString.indexOf(amountTransactionBefore);
    if (rawStart == -1) return null;
    int startIndex = rawStart + amountTransactionBefore.length;
    int endIndex = messageString.indexOf(amountTransactionAfter, startIndex);
    if (endIndex == -1 || endIndex <= startIndex) return null;
    String amountString = messageString.substring(startIndex, endIndex);
    String cleaned = amountString.replaceAll(RegExp('[^0-9.]'), '');
    if (cleaned.isEmpty) return null;
    amountDouble = double.parse(cleaned);
  } catch (e) {}
  return amountDouble;
}

String getReadableAppNameFromPackage(String? packageOrMessage) {
  if (packageOrMessage == null || packageOrMessage.isEmpty) return "Notification";
  
  // If messageString was passed, extract package name line
  String pkg = packageOrMessage;
  if (packageOrMessage.contains("Package name:")) {
    final match = RegExp(r'Package name:\s*([^\n\r]+)', caseSensitive: false).firstMatch(packageOrMessage);
    if (match != null && match.group(1) != null) {
      pkg = match.group(1)!.trim();
    }
  }
  
  String lower = pkg.toLowerCase();
  if (lower.contains("google.android.apps.messaging") ||
      lower.contains("samsung.android.messaging") ||
      lower.contains("messaging") ||
      lower.contains("mms") ||
      lower.contains("telephony")) {
    return "SMS / Messages";
  } else if (lower.contains("paisa") || lower.contains("gpay") || lower.contains("walletnfcrel")) {
    return "Google Pay";
  } else if (lower.contains("paypal")) {
    return "PayPal";
  } else if (lower.contains("venmo")) {
    return "Venmo";
  } else if (lower.contains("cashapp") || lower.contains("square.cash")) {
    return "Cash App";
  } else if (lower.contains("apple")) {
    return "Apple Pay";
  } else if (lower.contains("revolut")) {
    return "Revolut";
  } else if (lower.contains("monzo")) {
    return "Monzo";
  } else if (lower.contains("starlingbank") || lower.contains("starling")) {
    return "Starling Bank";
  } else if (lower.contains("n26")) {
    return "N26";
  } else if (lower.contains("wise")) {
    return "Wise";
  } else if (lower.contains("klarna")) {
    return "Klarna";
  } else if (lower.contains("chase")) {
    return "Chase";
  } else if (lower.contains("bofa") || lower.contains("bankofamerica")) {
    return "Bank of America";
  } else if (lower.contains("wellsfargo")) {
    return "Wells Fargo";
  } else if (lower.contains("citi")) {
    return "Citibank";
  } else if (lower.contains("capitalone")) {
    return "Capital One";
  } else if (lower.contains("barclays")) {
    return "Barclays";
  } else if (lower.contains("hsbc")) {
    return "HSBC";
  } else if (lower.contains("lloyds")) {
    return "Lloyds Bank";
  } else if (lower.contains("santander")) {
    return "Santander";
  } else if (lower.contains("natwest")) {
    return "NatWest";
  } else if (lower.contains("commbank") || lower.contains("commonwealth")) {
    return "CommBank";
  } else if (lower.contains("anz")) {
    return "ANZ";
  } else if (lower.contains("westpac")) {
    return "Westpac";
  } else if (lower.contains("nab")) {
    return "NAB";
  } else if (lower.contains("scotiabank")) {
    return "Scotiabank";
  } else if (lower.contains("td") && lower.contains("bank")) {
    return "TD Bank";
  } else if (lower.contains("rbc")) {
    return "RBC";
  } else if (lower.contains("phonepe")) {
    return "PhonePe";
  } else if (lower.contains("paytm")) {
    return "Paytm";
  } else if (lower.contains("dreamplug") || lower.contains("cred")) {
    return "CRED";
  } else if (lower.contains("whatsapp")) {
    return "WhatsApp";
  } else if (lower.contains("amazon")) {
    return "Amazon Pay";
  } else if (lower.contains("icici")) {
    return "ICICI Bank";
  } else if (lower.contains("hdfc")) {
    return "HDFC Bank";
  } else if (lower.contains("sbi")) {
    return "SBI";
  } else if (lower.contains("axis")) {
    return "Axis Bank";
  } else if (lower.contains("kotak")) {
    return "Kotak Bank";
  } else if (lower.contains("jupiter")) {
    return "Jupiter";
  } else if (lower.contains("fi.money") || lower.contains("epifi")) {
    return "Fi Money";
  } else if (lower.contains("slice")) {
    return "Slice";
  } else if (lower.contains("navi")) {
    return "Navi";
  } else if (lower.contains("onecard")) {
    return "OneCard";
  } else if (lower.contains("standardchartered") || lower.contains("sc.breeze")) {
    return "Standard Chartered";
  }

  // Fallback: format package name cleanly (e.g. "com.bbva.mobile" -> "BBVA", "fr.boursorama" -> "Boursorama")
  List<String> segments = pkg.split('.').where((s) => s.isNotEmpty && s != "android" && s != "app" && s != "mobile" && s != "com" && s != "net" && s != "org" && s != "co" && s != "uk").toList();
  if (segments.isNotEmpty) {
    String candidate = segments.firstWhere((s) => s.length > 2, orElse: () => segments.last);
    if (candidate.length > 2) {
      return candidate.capitalizeFirst;
    }
  }
  return "Notification";
}

Future queueTransactionFromMessage(String messageString,
    {bool willPushRoute = true, DateTime? dateTime}) async {
  try {
    // Step 0. Personal Chat & Media Notification Filter
    if (isChatOrMediaNotification(messageString)) {
      print("[NotificationEngine] Discarded notification: Detected personal chat or media message.");
      return false;
    }

    // Step 0a. Payment Reminder & Scheduled Pre-Debit Filter
    // Immediately discard payment reminders, scheduled bills, due-date notices, and pre-debit notifications
    if (isPaymentReminderOrPendingNotice(messageString)) {
      print("[NotificationEngine] Discarded notification: Detected payment reminder or upcoming bill notice without confirmed debit.");
      return false;
    }

    // Step 0b. Promotional, Marketing, and Rewards Filter
    // Discard promo pushes, rewards, coupons, and credit card solicitations
    if (isPromotionalOrMarketingNotification(messageString)) {
      print("[NotificationEngine] Discarded notification: Detected promotional or marketing message without confirmed transaction.");
      return false;
    }

  String? title;
  double? amountDouble;
  List<ScannerTemplate> scannerTemplates =
      await database.getAllScannerTemplates();
  ScannerTemplate? templateFound;

  // Step 1. Custom User-Defined Templates (explicitly created by the user)
  for (ScannerTemplate scannerTemplate in scannerTemplates) {
    if (scannerTemplate.ignore == true ||
        scannerTemplate.scannerTemplatePk.startsWith("preset_")) {
      continue;
    }
    if (scannerTemplate.contains.isNotEmpty &&
        messageString.contains(scannerTemplate.contains)) {
      String? candidateTitle = getTransactionTitleFromEmail(
          messageString,
          scannerTemplate.titleTransactionBefore,
          scannerTemplate.titleTransactionAfter);
      double? candidateAmount = getTransactionAmountFromEmail(
          messageString,
          scannerTemplate.amountTransactionBefore,
          scannerTemplate.amountTransactionAfter);
      if (candidateTitle != null && candidateAmount != null) {
        templateFound = scannerTemplate;
        title = candidateTitle;
        amountDouble = candidateAmount;
        break;
      }
    }
  }

  bool isIncome = false;
  TransactionWallet? nlpWallet;
  TransactionCategory? nlpCategory;

  // Step 2. Universal Local Natural Language Processing (Regex NLP Engine)
  if (templateFound == null || amountDouble == null || title == null) {
    BuildContext? ctx = navigatorKey.currentContext;
    LocalNlpParsedTransaction? nlpParsed =
        await parseTransactionFromNotificationText(messageString, ctx);
    if (nlpParsed != null) {
      title ??= nlpParsed.title;
      amountDouble ??= nlpParsed.amount;
      isIncome = nlpParsed.income;
      nlpWallet = nlpParsed.wallet;
      nlpCategory = nlpParsed.category;
    }
  }

  // Step 2b. Fallback to Built-in Preset Templates if NLP did not extract both title & amount
  if (amountDouble == null || title == null) {
    for (ScannerTemplate scannerTemplate in scannerTemplates) {
      if (scannerTemplate.ignore == true ||
          !scannerTemplate.scannerTemplatePk.startsWith("preset_")) {
        continue;
      }
      if (scannerTemplate.contains.isNotEmpty &&
          messageString.contains(scannerTemplate.contains)) {
        String? candidateTitle = getTransactionTitleFromEmail(
            messageString,
            scannerTemplate.titleTransactionBefore,
            scannerTemplate.titleTransactionAfter);
        double? candidateAmount = getTransactionAmountFromEmail(
            messageString,
            scannerTemplate.amountTransactionBefore,
            scannerTemplate.amountTransactionAfter);
        if (candidateTitle != null && candidateAmount != null) {
          templateFound = scannerTemplate;
          title ??= candidateTitle;
          amountDouble ??= candidateAmount;
          break;
        }
      }
    }
  }

  String? aiCategoryName;

  // Step 3. Fallback to AI Parsing if template and local NLP returned no result
  // Only invoke AI if the notification passes financial transaction context verification
  if ((amountDouble == null || title == null) &&
      hasConfirmedFinancialTransactionContext(messageString) &&
      appStateSettings["geminiEnabled"] == true &&
      appStateSettings["aiNotificationFallback"] != false &&
      aiManager.isConfigured()) {
    BuildContext? ctx = navigatorKey.currentContext;
    if (ctx != null) {
      ParsedAiTransaction? parsed =
          await parseTransactionWithGemini(messageString, ctx);
      if (parsed != null && parsed.title != null && parsed.amount != null) {
        title = parsed.title;
        amountDouble = parsed.amount;
        isIncome = parsed.income;
        aiCategoryName = parsed.categoryName;
      }
    }
  }

  if (amountDouble == null || title == null) return false;

  final DateTime eventTime = dateTime ?? DateTime.now();
  final double absoluteAmount = amountDouble.abs();

  // ─── Deduplication Check (In-Memory Key + Database Check) ─────────────────
  final String normTitle = title.trim().toLowerCase();
  final String dedupKey = "${normTitle}_${absoluteAmount.toStringAsFixed(2)}";
  final DateTime? lastSeen = _recentlyProcessedNotificationKeys[dedupKey];
  if (lastSeen != null && eventTime.difference(lastSeen).inMinutes.abs() <= 5) {
    print("Notification Engine: Ignored in-memory duplicate notification for $dedupKey within 5 minutes.");
    return false;
  }

  // Check existing database records with matching amount within 5 minutes window
  Transaction? existingDbDuplicate = await database.findDuplicateTransaction(
    amount: absoluteAmount,
    timestamp: eventTime,
    name: title,
    window: const Duration(minutes: 5),
  );
  if (existingDbDuplicate != null) {
    // Cross-App Smart Merge: If existing transaction has a generic name or default wallet,
    // and this second notification (e.g. GPay + Bank SMS) provides a better merchant name or specific wallet, enrich it!
    final Set<String> genericNames = {
      "transaction",
      "paid",
      "payment",
      "bank",
      "sms / messages",
      "notification"
    };
    final bool existingNameIsGeneric =
        genericNames.contains(existingDbDuplicate.name.trim().toLowerCase());
    final bool newNameIsSpecific =
        !genericNames.contains(title.trim().toLowerCase());
    final bool canUpgradeWallet =
        nlpWallet != null && existingDbDuplicate.walletFk != nlpWallet.walletPk;

    if (existingNameIsGeneric && newNameIsSpecific || canUpgradeWallet) {
      try {
        await database.createOrUpdateTransaction(
          existingDbDuplicate.copyWith(
            name: (existingNameIsGeneric && newNameIsSpecific)
                ? title
                : existingDbDuplicate.name,
            walletFk: canUpgradeWallet
                ? nlpWallet!.walletPk
                : existingDbDuplicate.walletFk,
          ),
          insert: false,
          updateSharedEntry: false,
        );
        print("Notification Engine: Enriched existing duplicate transaction '${existingDbDuplicate.name}' -> '$title'");
      } catch (_) {}
    } else {
      print("Notification Engine: Ignored database duplicate for $title ($absoluteAmount) matching '${existingDbDuplicate.name}'");
    }
    return false;
  }

  // Register in deduplication cache
  _recentlyProcessedNotificationKeys[dedupKey] = eventTime;
  // Prune keys older than 10 minutes
  _recentlyProcessedNotificationKeys.removeWhere(
      (_, time) => DateTime.now().difference(time).inMinutes.abs() > 10);

  TransactionCategory? category;
  TransactionAssociatedTitleWithCategory? foundTitle =
      (await database.getSimilarAssociatedTitles(title: title, limit: 1))
          .firstOrNull;
  category = foundTitle?.category ?? nlpCategory;
  if (templateFound != null) {
    category ??= await database
        .getCategoryInstanceOrNull(templateFound.defaultCategoryFk);
  }
  if (category == null && aiCategoryName != null) {
    try {
      var all = await database.getAllCategories();
      for (var c in all) {
        if (c.name.trim().toLowerCase() == aiCategoryName.trim().toLowerCase()) {
          category = c;
          break;
        }
      }
    } catch (_) {}
  }

  TransactionWallet? wallet = (templateFound == null || templateFound.walletFk == "-1")
      ? nlpWallet
      : await database.getWalletInstanceOrNull(templateFound.walletFk);

  // If amount represents an income, adjust sign/income tab
  if (isIncome && amountDouble > 0) {
    amountDouble = amountDouble * -1;
  }

  final String appName = getReadableAppNameFromPackage(messageString);
  final String transactionNote = "Auto-detected from $appName • ${getWordedDateShortMore(eventTime)}";

  if (willPushRoute && appStateSettings["autoInsertNotificationsDirectly"] != true) {
    registerAutoDetectedTransactionForReview(
      title,
      amountDouble,
      isIncome: isIncome,
      note: transactionNote,
    );
    BuildContext? currentCtx = navigatorKey.currentContext;
    if (currentCtx != null) {
      AllWallets? allWallets;
      try {
        allWallets = Provider.of<AllWallets>(currentCtx, listen: false);
      } catch (_) {}
      String formattedAmount = allWallets != null
          ? convertToMoney(allWallets, amountDouble.abs())
          : amountDouble.abs().toStringAsFixed(2);

      openSnackbar(
        SnackbarMessage(
          title: isIncome ? "Income Detected · $formattedAmount" : "Transaction Detected · $formattedAmount",
          description: "$title · Tap to review & add",
          icon: isIncome ? Icons.arrow_downward_rounded : Icons.auto_awesome_rounded,
          timeout: const Duration(seconds: 6),
          onTap: () {
            pushRoute(
              currentCtx,
              AddTransactionPage(
                useCategorySelectedIncome: false,
                selectedIncome: isIncome,
                routesToPopAfterDelete: RoutesToPopAfterDelete.None,
                selectedAmount: amountDouble,
                selectedTitle: title,
                selectedCategory: category,
                selectedNotes: transactionNote,
                startInitialAddTransactionSequence: false,
                selectedWallet: wallet,
                selectedDate: dateTime,
              ),
            );
          },
        ),
      );
    }
  } else {
    // Direct Silent Auto-Insert
    try {
      // Fallback category if none was matched: prefer General/Other category over arbitrary first category
      if (category == null) {
        try {
          List<TransactionCategory> allCats = await database.getAllCategories();
          category = allCats.where((c) {
            String n = c.name.toLowerCase();
            return n.contains("other") || n.contains("general") || n.contains("uncategorized") || n.contains("misc");
          }).firstOrNull ?? allCats.where((c) => c.categoryPk != "0").firstOrNull ?? allCats.firstOrNull;
        } catch (_) {}
      }
      String categoryPk = category?.categoryPk ?? "1";

      if (wallet == null) {
        try {
          List<TransactionWallet> allW = await database.getAllWallets();
          wallet = allW.where((w) => w.walletPk == appStateSettings["selectedWalletPk"]).firstOrNull ?? allW.firstOrNull;
        } catch (_) {}
      }
      String walletPk = wallet?.walletPk ?? "0";

      // Expenses must have negative amount in database when income: false,
      // and income transactions have income: true with positive amount
      double finalAmount = isIncome ? amountDouble.abs() : -amountDouble.abs();

      final int? rowId = await database.createOrUpdateTransaction(
        Transaction(
          transactionPk: "-1",
          name: title,
          amount: finalAmount,
          note: transactionNote,
          categoryFk: categoryPk,
          subCategoryFk: null,
          walletFk: walletPk,
          dateCreated: eventTime,
          income: isIncome,
          paid: true,
          skipPaid: false,
          methodAdded: MethodAdded.email,
        ),
        insert: true,
      );

      String? transactionPk;
      if (rowId != null) {
        try {
          final tx = await database.getTransactionFromRowId(rowId);
          transactionPk = tx.transactionPk;
        } catch (_) {}
      }

      if (title.isNotEmpty && category != null) {
        await addAssociatedTitles(title, category);
      }

      registerAutoAddedTransaction(
        title,
        amountDouble,
        isIncome: isIncome,
        transactionPk: transactionPk,
      );

      // Register for Home Page review banner so the user sees the review message
      registerAutoDetectedTransactionForReview(
        title,
        amountDouble,
        isIncome: isIncome,
        transactionPk: transactionPk,
      );

      // Check if the app is currently in the foreground
      BuildContext? currentCtx = navigatorKey.currentContext;
      if (currentCtx != null && rowId != null) {
        openSnackbar(
          SnackbarMessage(
            title: isIncome ? "Auto-Recorded Income" : "Auto-Recorded Transaction",
            description: "$title · ${amountDouble.abs().toStringAsFixed(2)} · Tap to review",
            icon: isIncome ? Icons.arrow_downward_rounded : Icons.auto_awesome_rounded,
            onTap: () {
              if (transactionPk != null) {
                database.getTransactionFromPk(transactionPk).then((tx) {
                  BuildContext? ctx = navigatorKey.currentContext;
                  if (ctx != null) {
                    pushRoute(
                      ctx,
                      AddTransactionPage(
                        transaction: tx,
                        routesToPopAfterDelete: RoutesToPopAfterDelete.None,
                      ),
                    );
                  }
                });
              }
            },
          ),
        );
      } else {
        // App is in the background or killed: Send a system status bar notification
        await _showBackgroundInsertedNotification(
          title: title,
          amount: amountDouble,
          isIncome: isIncome,
          transactionPk: transactionPk,
        );
      }
    } catch (e, stack) {
      print("Error directly auto-recording transaction: $e");
      recordAppError(
        "Notification Auto-Record Error",
        e,
        stackTrace: stack,
        extraInfo: "Title: $title | Amount: $amountDouble",
      );
    }
  }
    return true;
  } catch (e, stack) {
    print("[NotificationEngine] Error in queueTransactionFromMessage: $e\n$stack");
    recordAppError("QueueTransactionError", e, stackTrace: stack);
    return false;
  }
}

String getNotificationMessage(ServiceNotificationEvent event) {
  String output = "";
  output = "${output}Package name: ${event.packageName}\n";
  output =
      "${output}Notification removed: ${event.hasRemoved}\n";
  output = "$output\n----\n\n";
  output = "${output}Notification Title: ${event.title}\n\n";
  output = "${output}Notification Content: ${event.content}";
  return output;
}
