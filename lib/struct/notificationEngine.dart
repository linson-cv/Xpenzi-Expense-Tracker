import 'dart:async';
import 'package:app_settings/app_settings.dart';
import 'package:budget/database/tables.dart' hide AppSettings;
import 'package:budget/functions.dart';
import 'package:budget/pages/addTransactionPage.dart';
import 'package:budget/struct/autoTransactionTracker.dart';
import 'package:budget/struct/databaseGlobal.dart';
import 'package:budget/struct/geminiAi.dart';
import 'package:budget/struct/localNlpParser.dart';
import 'package:budget/struct/settings.dart';
import 'package:budget/widgets/globalSnackbar.dart';
import 'package:budget/widgets/navigationFramework.dart';
import 'package:budget/widgets/openPopup.dart';
import 'package:budget/widgets/openSnackbar.dart';
import 'package:flutter/material.dart';
import 'package:notification_listener_service/notification_event.dart';
import 'package:notification_listener_service/notification_listener_service.dart';
import 'package:provider/provider.dart';

StreamSubscription<ServiceNotificationEvent>? notificationListenerSubscription;
List<String> recentCapturedNotifications = [];

Future<void> populateDefaultScannerTemplatesIfEmpty() async {
  try {
    List<ScannerTemplate> existing = await database.getAllScannerTemplates();
    if (existing.isEmpty) {
      List<ScannerTemplate> defaults = [
        ScannerTemplate(
          scannerTemplatePk: "preset_credit_card_debit",
          templateName: "Card Purchase / Debit Alert",
          contains: "Card",
          amountTransactionBefore: "debited",
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
          scannerTemplatePk: "preset_bank_debit",
          templateName: "Bank Account Debit",
          contains: "debited",
          amountTransactionBefore: "debited",
          amountTransactionAfter: " on",
          titleTransactionBefore: "to ",
          titleTransactionAfter: " on",
          defaultCategoryFk: "0",
          walletFk: "-1",
          dateCreated: DateTime.now(),
          dateTimeModified: DateTime.now(),
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
          dateCreated: DateTime.now(),
          dateTimeModified: DateTime.now(),
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
          dateCreated: DateTime.now(),
          dateTimeModified: DateTime.now(),
          ignore: false,
        ),
        ScannerTemplate(
          scannerTemplatePk: "preset_recurring_autopay",
          templateName: "Subscription / Auto-Debit",
          contains: "scheduled",
          amountTransactionBefore: "debit of",
          amountTransactionAfter: " is",
          titleTransactionBefore: "for ",
          titleTransactionAfter: " is scheduled",
          defaultCategoryFk: "0",
          walletFk: "-1",
          dateCreated: DateTime.now(),
          dateTimeModified: DateTime.now(),
          ignore: false,
        ),
      ];

      for (var tmpl in defaults) {
        await database.createOrUpdateScannerTemplate(tmpl);
      }
      print("Auto-loaded default bank scanner templates");
    }
  } catch (e) {
    print("Error populating default scanner templates: $e");
  }
}

Future initNotificationScanning() async {
  if (getPlatform(ignoreEmulation: true) != PlatformOS.isAndroid) return;
  notificationListenerSubscription?.cancel();
  if (appStateSettings["notificationScanning"] != true) return;

  bool status = await NotificationListenerService.isPermissionGranted();

  if (status == true) {
    await populateDefaultScannerTemplatesIfEmpty();
    notificationListenerSubscription =
        NotificationListenerService.notificationsStream.listen(onNotification);
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
    },
  );
}

Future<bool> promptNotificationPermissionPopup(BuildContext context) async {
  bool isGranted = await NotificationListenerService.isPermissionGranted();
  if (isGranted) return true;

  Completer<bool> completer = Completer<bool>();

  openPopup(
    context,
    title: "Enable Notification Access",
    icon: Icons.notifications_active_rounded,
    description:
        "Xpenzi uses notification access to auto-detect bank transaction SMS & payment alerts on your device.\n\n• 100% Private & Local processing\n• Bank & payment alerts only\n• No personal chats or sensitive data read",
    onSubmitLabel: "Open Android Settings",
    onCancelLabel: "Cancel",
    onSubmit: () async {
      popRoute(context);
      try {
        await NotificationListenerService.requestPermission();
      } catch (e) {
        print("Error requesting notification permission: $e");
      }
      bool status = await NotificationListenerService.isPermissionGranted();
      if (status == true) {
        Future.delayed(const Duration(milliseconds: 400), () {
          BuildContext? ctx = navigatorKey.currentContext ?? context;
          promptBatteryOptimizationPopup(ctx);
        });
      }
      completer.complete(status);
    },
    onCancel: () {
      completer.complete(false);
    },
  );

  return completer.future;
}

Future<bool> requestReadNotificationPermission({BuildContext? context}) async {
  bool status = await NotificationListenerService.isPermissionGranted();
  if (status != true) {
    BuildContext? popupContext = context ?? navigatorKey.currentContext;
    if (popupContext != null) {
      status = await promptNotificationPermissionPopup(popupContext);
    } else {
      try {
        await NotificationListenerService.requestPermission();
      } catch (e) {
        print("Error requesting notification permission: $e");
      }
      status = await NotificationListenerService.isPermissionGranted();
    }
  }

  if (status == true) {
    // Automatically enable all essential app-side intelligence settings
    await updateSettings("notificationScanning", true, updateGlobalState: false);
    await updateSettings("autoInsertNotificationsDirectly", true, updateGlobalState: false);
    await populateDefaultScannerTemplatesIfEmpty();
    initNotificationScanning();
  }

  return status;
}

onNotification(ServiceNotificationEvent event) async {
  String messageString = getNotificationMessage(event);
  recentCapturedNotifications.insert(0, messageString);
  int maxCount = int.tryParse(appStateSettings["notificationLogRetentionCount"]?.toString() ?? "50") ?? 50;
  if (recentCapturedNotifications.length > maxCount) {
    recentCapturedNotifications.removeRange(maxCount, recentCapturedNotifications.length);
  }
  queueTransactionFromMessage(messageString);
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
  String? title;
  try {
    int startIndex = messageString.indexOf(titleTransactionBefore) +
        titleTransactionBefore.length;
    int endIndex = messageString.indexOf(titleTransactionAfter, startIndex);
    title = messageString.substring(startIndex, endIndex);
    title = title.replaceAll("\n", "");
    title = title.toLowerCase();
    title = title.capitalizeFirst;
  } catch (e) {}
  return title;
}

double? getTransactionAmountFromEmail(String messageString,
    String amountTransactionBefore, String amountTransactionAfter) {
  double? amountDouble;
  try {
    int startIndex = messageString.indexOf(amountTransactionBefore) +
        amountTransactionBefore.length;
    int endIndex = messageString.indexOf(amountTransactionAfter, startIndex);
    String amountString = messageString.substring(startIndex, endIndex);
    amountDouble = double.parse(amountString.replaceAll(RegExp('[^0-9.]'), ''));
  } catch (e) {}
  return amountDouble;
}

Future queueTransactionFromMessage(String messageString,
    {bool willPushRoute = true, DateTime? dateTime}) async {
  String? title;
  double? amountDouble;
  List<ScannerTemplate> scannerTemplates =
      await database.getAllScannerTemplates();
  ScannerTemplate? templateFound;

  for (ScannerTemplate scannerTemplate in scannerTemplates) {
    if (messageString.contains(scannerTemplate.contains)) {
      templateFound = scannerTemplate;
      title = getTransactionTitleFromEmail(
          messageString,
          scannerTemplate.titleTransactionBefore,
          scannerTemplate.titleTransactionAfter);
      amountDouble = getTransactionAmountFromEmail(
          messageString,
          scannerTemplate.amountTransactionBefore,
          scannerTemplate.amountTransactionAfter);
      break;
    }
  }

  bool isIncome = false;
  TransactionWallet? nlpWallet;

  // Step 2. Local Natural Language Processing (Regex NLP Engine)
  if (templateFound == null || amountDouble == null || title == null) {
    BuildContext? ctx = navigatorKey.currentContext;
    LocalNlpParsedTransaction? nlpParsed =
        await parseTransactionFromNotificationText(messageString, ctx);
    if (nlpParsed != null) {
      title ??= nlpParsed.title;
      amountDouble ??= nlpParsed.amount;
      isIncome = nlpParsed.income;
      nlpWallet = nlpParsed.wallet;
    }
  }

  // Step 3. Fallback to Gemini AI Parsing if template and local NLP returned no result
  if ((amountDouble == null || title == null) &&
      appStateSettings["geminiEnabled"] == true &&
      (appStateSettings["geminiApiKey"] ?? "").toString().trim().isNotEmpty) {
    BuildContext? ctx = navigatorKey.currentContext;
    if (ctx != null) {
      GeminiParsedTransaction? parsed =
          await parseTransactionWithGemini(messageString, ctx);
      if (parsed != null && parsed.title != null && parsed.amount != null) {
        title = parsed.title;
        amountDouble = parsed.amount;
      }
    }
  }

  if (amountDouble == null || title == null) return false;

  TransactionCategory? category;
  TransactionAssociatedTitleWithCategory? foundTitle =
      (await database.getSimilarAssociatedTitles(title: title, limit: 1))
          .firstOrNull;
  category = foundTitle?.category;
  if (templateFound != null) {
    category ??= await database
        .getCategoryInstanceOrNull(templateFound.defaultCategoryFk);
  }

  TransactionWallet? wallet = (templateFound == null || templateFound.walletFk == "-1")
      ? nlpWallet
      : await database.getWalletInstanceOrNull(templateFound.walletFk);

  // If amount represents an income, adjust sign/income tab
  if (isIncome && amountDouble > 0) {
    amountDouble = amountDouble * -1;
  }

  if (willPushRoute && appStateSettings["autoInsertNotificationsDirectly"] != true) {
    registerAutoDetectedTransactionForReview(title, amountDouble, isIncome: isIncome);
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
      // Fallback category if none was matched
      category ??= (await database.getAllCategories()).firstOrNull;
      String categoryPk = category?.categoryPk ?? "0";
      String walletPk = wallet?.walletPk ?? appStateSettings["selectedWalletPk"] ?? "0";

      // Expenses should have positive amount in database when income: false,
      // and income transactions have income: true with positive amount
      double finalAmount = amountDouble.abs();

      final int? rowId = await database.createOrUpdateTransaction(
        Transaction(
          transactionPk: "-1",
          name: title,
          amount: finalAmount,
          note: "Auto-detected notification",
          categoryFk: categoryPk,
          subCategoryFk: null,
          walletFk: walletPk,
          dateCreated: dateTime ?? DateTime.now(),
          income: isIncome,
          paid: true,
          skipPaid: false,
          methodAdded: MethodAdded.email,
        ),
        insert: true,
      );

      if (title.isNotEmpty && category != null) {
        await addAssociatedTitles(title, category);
      }

      registerAutoAddedTransaction(title, amountDouble);

      if (rowId != null) {
        openSnackbar(
          SnackbarMessage(
            title: isIncome ? "Auto-Recorded Income" : "Auto-Recorded Transaction",
            description: "$title · ${amountDouble.abs().toStringAsFixed(2)}",
            icon: isIncome ? Icons.arrow_downward_rounded : Icons.auto_awesome_rounded,
          ),
        );
      }
    } catch (e) {
      print("Error directly auto-recording transaction: $e");
    }
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
