import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:budget/database/tables.dart' hide AppSettings;
import 'package:budget/functions.dart';
import 'package:budget/struct/databaseGlobal.dart' as db_global;
import 'package:budget/struct/localNlpParser.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:notification_listener_service/notification_event.dart';
import 'package:notification_listener_service/notification_listener_service.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

// The callback function must be a top-level or static function with vm:entry-point
@pragma('vm:entry-point')
void startBackgroundListenerCallback() {
  FlutterForegroundTask.setTaskHandler(BackgroundNotificationTaskHandler());
}

class BackgroundNotificationTaskHandler extends TaskHandler {
  StreamSubscription<ServiceNotificationEvent>? _notifSub;
  FinanceDatabase? _bgDatabase;
  SharedPreferences? _bgPrefs;
  final Map<String, DateTime> _dedupCache = {};
  FlutterLocalNotificationsPlugin? _bgLocalNotifications;

  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {
    print("[BackgroundService] Started foreground task with starter: ${starter.name}");
    await _initBackgroundResources();
    _startListening();
  }

  @override
  void onRepeatEvent(DateTime timestamp) {
    // Health check / periodic cleanup
    _dedupCache.removeWhere(
      (_, time) => DateTime.now().difference(time).inSeconds.abs() > 120,
    );
  }

  @override
  Future<void> onDestroy(DateTime timestamp) async {
    print("[BackgroundService] Destroying background service");
    await _notifSub?.cancel();
    _notifSub = null;
    await _bgDatabase?.close();
    _bgDatabase = null;
  }

  @override
  void onReceiveData(Object data) {
    print("[BackgroundService] Received data from main isolate: $data");
  }

  @override
  void onNotificationButtonPressed(String id) {}

  @override
  void onNotificationPressed() {
    FlutterForegroundTask.launchApp();
  }

  @override
  void onNotificationDismissed() {}

  Future<void> _initBackgroundResources() async {
    try {
      _bgPrefs = await SharedPreferences.getInstance();
      
      // Initialize local notifications in background isolate
      _bgLocalNotifications = FlutterLocalNotificationsPlugin();
      const AndroidInitializationSettings initializationSettingsAndroid =
          AndroidInitializationSettings('@mipmap/ic_launcher');
      const InitializationSettings initializationSettings =
          InitializationSettings(android: initializationSettingsAndroid);
      await _bgLocalNotifications?.initialize(initializationSettings);

      // Construct a background database instance
      final dbFolder = await getApplicationDocumentsDirectory();
      final file = File(p.join(dbFolder.path, 'db.sqlite'));
      
      void setupDb(dynamic database) {
        try {
          database.execute('PRAGMA journal_mode = WAL;');
          database.execute('PRAGMA busy_timeout = 5000;');
          database.execute('PRAGMA synchronous = NORMAL;');
        } catch (e) {
          print("[BackgroundService] PRAGMA error: $e");
        }
      }

      QueryExecutor executor = NativeDatabase(file, setup: setupDb);
      _bgDatabase = FinanceDatabase(executor);
      
      // Make accessible to localNlpParser if needed
      db_global.database = _bgDatabase!;
      db_global.sharedPreferences = _bgPrefs!;
      
      print("[BackgroundService] Background DB and Prefs initialized successfully");
    } catch (e) {
      print("[BackgroundService] Error initializing background resources: $e");
    }
  }

  void _startListening() {
    _notifSub?.cancel();
    _notifSub = NotificationListenerService.notificationsStream.listen((event) {
      _handleBackgroundNotification(event);
    }, onError: (err) {
      print("[BackgroundService] Notification stream error: $err");
    });
    print("[BackgroundService] Notification stream listening active in background isolate");
  }

  Future<void> _handleBackgroundNotification(ServiceNotificationEvent event) async {
    if (event.hasRemoved == true) return;

    final String? pkg = event.packageName?.trim().toLowerCase();
    
    // Check allowed packages from shared preferences
    String? allowedPackagesString;
    try {
      String? settingsJson = _bgPrefs?.getString("appSettings");
      if (settingsJson != null) {
        Map<String, dynamic> settingsMap = jsonDecode(settingsJson);
        allowedPackagesString = settingsMap["notificationAllowedPackages"]?.toString().trim();
      }
    } catch (_) {}

    if (allowedPackagesString != null && allowedPackagesString.isNotEmpty) {
      List<String> allowedList = allowedPackagesString
          .split(",")
          .map((e) => e.trim().toLowerCase())
          .where((e) => e.isNotEmpty)
          .toList();
      if (allowedList.isNotEmpty && pkg != null && !allowedList.any((allowed) => pkg.contains(allowed))) {
        return;
      }
    }

    String messageString = "Package name: ${event.packageName}\nNotification Title: ${event.title}\n\nNotification Content: ${event.content}";
    print("[BackgroundService] Processing notification from $pkg: ${event.title} - ${event.content}");

    await _processAndInsertTransaction(messageString, DateTime.now());
  }

  Future<void> _processAndInsertTransaction(String messageString, DateTime eventTime) async {
    if (_bgDatabase == null) {
      await _initBackgroundResources();
      if (_bgDatabase == null) return;
    }

    String? title;
    double? amountDouble;
    ScannerTemplate? templateFound;

    try {
      List<ScannerTemplate> templates = await _bgDatabase!.getAllScannerTemplates();
      for (ScannerTemplate tmpl in templates) {
        if (messageString.contains(tmpl.contains)) {
          templateFound = tmpl;
          try {
            int sIdx = messageString.indexOf(tmpl.titleTransactionBefore) + tmpl.titleTransactionBefore.length;
            int eIdx = messageString.indexOf(tmpl.titleTransactionAfter, sIdx);
            title = messageString.substring(sIdx, eIdx).replaceAll("\n", "").toLowerCase().capitalizeFirst;
          } catch (_) {}

          try {
            int sIdx = messageString.indexOf(tmpl.amountTransactionBefore) + tmpl.amountTransactionBefore.length;
            int eIdx = messageString.indexOf(tmpl.amountTransactionAfter, sIdx);
            String amtStr = messageString.substring(sIdx, eIdx);
            amountDouble = double.parse(amtStr.replaceAll(RegExp('[^0-9.]'), ''));
          } catch (_) {}
          break;
        }
      }
    } catch (e) {
      print("[BackgroundService] Error matching template: $e");
    }

    bool isIncome = false;
    TransactionWallet? nlpWallet;

    // Local Regex NLP
    if (templateFound == null || amountDouble == null || title == null) {
      LocalNlpParsedTransaction? nlpParsed = await parseTransactionFromNotificationText(messageString, null);
      if (nlpParsed != null) {
        title ??= nlpParsed.title;
        amountDouble ??= nlpParsed.amount;
        isIncome = nlpParsed.income;
        nlpWallet = nlpParsed.wallet;
      }
    }

    if (amountDouble == null || title == null) return;

    final double absoluteAmount = amountDouble.abs();

    // Deduplication check
    final String dedupKey = "${title.trim().toLowerCase()}_${absoluteAmount.toStringAsFixed(2)}";
    final DateTime? lastSeen = _dedupCache[dedupKey];
    if (lastSeen != null && eventTime.difference(lastSeen).inSeconds.abs() <= 60) {
      print("[BackgroundService] Dedup: in-memory duplicate ignored ($dedupKey)");
      return;
    }

    try {
      Transaction? existingDbDuplicate = await _bgDatabase!.findDuplicateTransaction(
        amount: absoluteAmount,
        timestamp: eventTime,
        name: title,
        window: const Duration(seconds: 60),
      );
      if (existingDbDuplicate != null) {
        print("[BackgroundService] Dedup: database duplicate ignored for $title ($absoluteAmount)");
        return;
      }
    } catch (e) {
      print("[BackgroundService] Error querying DB duplicate: $e");
    }

    _dedupCache[dedupKey] = eventTime;

    TransactionCategory? category;
    try {
      TransactionAssociatedTitleWithCategory? foundTitle =
          (await _bgDatabase!.getSimilarAssociatedTitles(title: title, limit: 1)).firstOrNull;
      category = foundTitle?.category;
      if (templateFound != null) {
        category ??= await _bgDatabase!.getCategoryInstanceOrNull(templateFound.defaultCategoryFk);
      }
    } catch (_) {}

    TransactionWallet? wallet = (templateFound == null || templateFound.walletFk == "-1")
        ? nlpWallet
        : await _bgDatabase!.getWalletInstanceOrNull(templateFound.walletFk);

    if (category == null) {
      try {
        List<TransactionCategory> allCats = await _bgDatabase!.getAllCategories();
        category = allCats.where((c) => c.categoryPk != "0").firstOrNull ?? allCats.firstOrNull;
      } catch (_) {}
    }

    String categoryPk = category?.categoryPk ?? "1";
    String walletPk = wallet?.walletPk ?? "0";

    final String transactionNote = "Auto-detected from background notification • ${getWordedDateShortMore(eventTime)}";

    try {
      await _bgDatabase!.createOrUpdateTransaction(
        Transaction(
          transactionPk: "-1",
          name: title,
          amount: absoluteAmount,
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

      print("[BackgroundService] Auto-inserted transaction: $title - $absoluteAmount (income: $isIncome)");

      // Notify user via local status bar notification
      await _showAutoInsertedNotification(
        title: title,
        amount: absoluteAmount,
        isIncome: isIncome,
      );

      // Update Foreground Task notification banner to show latest recorded info
      FlutterForegroundTask.updateService(
        notificationTitle: "Xpenzi Auto-Detection Active",
        notificationText: "Last recorded: $title · ${absoluteAmount.toStringAsFixed(2)}",
      );
    } catch (e) {
      print("[BackgroundService] Error inserting background transaction: $e");
    }
  }

  Future<void> _showAutoInsertedNotification({
    required String title,
    required double amount,
    required bool isIncome,
  }) async {
    try {
      const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        'auto_transactions_channel',
        'Auto-Detected Transactions',
        channelDescription: 'Alerts when payment or bank SMS notifications are automatically recorded',
        importance: Importance.high,
        priority: Priority.high,
        showWhen: true,
      );

      const NotificationDetails notificationDetails = NotificationDetails(
        android: androidDetails,
      );

      int notificationId = DateTime.now().millisecondsSinceEpoch.remainder(100000);

      await _bgLocalNotifications?.show(
        notificationId,
        isIncome ? "Auto-Recorded Income" : "Auto-Recorded Transaction",
        "$title · ${amount.toStringAsFixed(2)}",
        notificationDetails,
        payload: "transactions",
      );
    } catch (e) {
      print("[BackgroundService] Error showing alert notification: $e");
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Service Lifecycle Helpers (Callable from UI Isolate)
// ─────────────────────────────────────────────────────────────────────────────

Future<void> initForegroundTask() async {
  FlutterForegroundTask.init(
    androidNotificationOptions: AndroidNotificationOptions(
      channelId: 'persistent_listener_channel',
      channelName: 'SMS & Alert Background Monitor',
      channelDescription: 'Keeps Xpenzi notification listener active in the background for real-time transaction detection',
      channelImportance: NotificationChannelImportance.LOW,
      priority: NotificationPriority.LOW,
      enableVibration: false,
      playSound: false,
      showWhen: false,
    ),
    iosNotificationOptions: const IOSNotificationOptions(
      showNotification: false,
      playSound: false,
    ),
    foregroundTaskOptions: ForegroundTaskOptions(
      eventAction: ForegroundTaskEventAction.repeat(15000),
      autoRunOnBoot: true,
      autoRunOnMyPackageReplaced: true,
      allowWakeLock: true,
      allowWifiLock: true,
    ),
  );
}

Future<bool> startBackgroundListenerService() async {
  try {
    await initForegroundTask();

    if (await FlutterForegroundTask.isRunningService) {
      await FlutterForegroundTask.restartService();
      return true;
    }

    ServiceRequestResult result = await FlutterForegroundTask.startService(
      serviceId: 888123,
      notificationTitle: "Xpenzi Auto-Detection Active",
      notificationText: "Monitoring bank SMS & payment alerts in real time",
      callback: startBackgroundListenerCallback,
    );

    return result is ServiceRequestSuccess;
  } catch (e) {
    print("[ForegroundService] Failed to start background listener service: $e");
    return false;
  }
}

Future<bool> stopBackgroundListenerService() async {
  try {
    if (await FlutterForegroundTask.isRunningService) {
      ServiceRequestResult result = await FlutterForegroundTask.stopService();
      return result is ServiceRequestSuccess;
    }
    return true;
  } catch (e) {
    print("[ForegroundService] Failed to stop background listener service: $e");
    return false;
  }
}
