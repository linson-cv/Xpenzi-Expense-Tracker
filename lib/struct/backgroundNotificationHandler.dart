import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'dart:ui';
import 'package:budget/database/tables.dart' hide AppSettings;
import 'package:budget/struct/databaseGlobal.dart' as db_global;
import 'package:budget/struct/localNlpParser.dart';
import 'package:budget/struct/notificationEngine.dart'
    show
        getReadableAppNameFromPackage,
        getTransactionAmountFromEmail,
        getTransactionTitleFromEmail,
        kMainIsolatePingPortName;
import 'package:budget/struct/settings.dart';
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
  List<ScannerTemplate>? _cachedTemplates;
  List<TransactionCategory>? _cachedCategories;
  List<TransactionWallet>? _cachedWallets;
  DateTime? _lastCacheTime;

  Future<void> _refreshMetadataCacheIfNeeded() async {
    if (_bgDatabase == null) return;
    final now = DateTime.now();
    if (_lastCacheTime != null &&
        now.difference(_lastCacheTime!).inSeconds < 60 &&
        _cachedTemplates != null &&
        _cachedCategories != null &&
        _cachedWallets != null) {
      return;
    }
    try {
      _cachedTemplates = await _bgDatabase!.getAllScannerTemplates();
      _cachedCategories = await _bgDatabase!.getAllCategories();
      _cachedWallets = await _bgDatabase!.getAllWallets();
      _lastCacheTime = now;
    } catch (_) {}
  }

  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {
    try {
      print("[BackgroundService] Started foreground task with starter: ${starter.name}");
      await _initLightweightResources();
      _startListening();
    } catch (e, stack) {
      print("[BackgroundService] Error during onStart: $e\n$stack");
    }
  }

  @override
  void onRepeatEvent(DateTime timestamp) {
    try {
      _dedupCache.removeWhere(
        (_, time) => DateTime.now().difference(time).inSeconds.abs() > 300,
      );
    } catch (e) {
      print("[BackgroundService] Error in onRepeatEvent: $e");
    }
  }

  @override
  Future<void> onDestroy(DateTime timestamp) async {
    try {
      print("[BackgroundService] Destroying background service");
      await _notifSub?.cancel();
      _notifSub = null;
      await _closeBackgroundDatabase();
    } catch (e) {
      print("[BackgroundService] Error during onDestroy: $e");
    }
  }

  @override
  void onReceiveData(Object data) {
    try {
      if (data is Map<String, dynamic> && data["action"] == "process_notification") {
        final String messageString = data["messageString"] ?? "";
        final DateTime eventTime = data["eventTime"] != null
            ? DateTime.tryParse(data["eventTime"]) ?? DateTime.now()
            : DateTime.now();
        if (messageString.isNotEmpty) {
          _processAndInsertTransaction(messageString, eventTime);
        }
      }
    } catch (e, stack) {
      print("[BackgroundService] Error in onReceiveData: $e\n$stack");
    }
  }

  @override
  void onNotificationButtonPressed(String id) {}

  @override
  void onNotificationPressed() {
    try {
      FlutterForegroundTask.launchApp();
    } catch (e) {
      print("[BackgroundService] Error in onNotificationPressed: $e");
    }
  }

  @override
  void onNotificationDismissed() {}

  Future<void> _initLightweightResources() async {
    try {
      _bgPrefs ??= await SharedPreferences.getInstance();
      db_global.sharedPreferences = _bgPrefs!;

      if (_bgLocalNotifications == null) {
        _bgLocalNotifications = FlutterLocalNotificationsPlugin();
        const AndroidInitializationSettings initializationSettingsAndroid =
            AndroidInitializationSettings('notification_icon_android2');
        const InitializationSettings initializationSettings =
            InitializationSettings(android: initializationSettingsAndroid);
        await _bgLocalNotifications?.initialize(initializationSettings);
      }
    } catch (e, stack) {
      print("[BackgroundService] Error initializing lightweight resources: $e\n$stack");
    }
  }

  Future<void> _ensureBackgroundDatabaseOpen() async {
    if (_bgDatabase != null) return;
    try {
      await _initLightweightResources();
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
      db_global.database = _bgDatabase!;
      print("[BackgroundService] Background DB opened lazily");
    } catch (e, stack) {
      print("[BackgroundService] Error opening background DB: $e\n$stack");
    }
  }

  Future<void> _closeBackgroundDatabase() async {
    if (_bgDatabase != null) {
      try {
        await _bgDatabase!.close();
      } catch (_) {}
      _bgDatabase = null;
    }
  }

  /// Checks if the main UI isolate is alive and actively listening to notifications.
  /// If the main isolate is alive (app open or minimized in RAM), it handles the notification
  /// directly on its own database connection. If the user swiped the app away from Recents,
  /// this returns false and the background isolate seamlessly takes over auto-adding transactions.
  Future<bool> _isMainIsolateActive() async {
    ReceivePort? replyPort;
    try {
      final SendPort? mainPingPort =
          IsolateNameServer.lookupPortByName(kMainIsolatePingPortName);
      if (mainPingPort == null) return false;

      replyPort = ReceivePort();
      mainPingPort.send(replyPort.sendPort);

      final dynamic response = await replyPort.first
          .timeout(const Duration(milliseconds: 250), onTimeout: () => false);
      return response == true;
    } catch (_) {
      return false;
    } finally {
      replyPort?.close();
    }
  }

  void _startListening() {
    try {
      _notifSub?.cancel();
      _notifSub = NotificationListenerService.notificationsStream.listen((event) {
        try {
          _handleBackgroundNotification(event);
        } catch (e, stack) {
          print("[BackgroundService] Uncaught error in _handleBackgroundNotification callback: $e\n$stack");
        }
      }, onError: (err) {
        print("[BackgroundService] Notification stream error: $err");
      });
      print("[BackgroundService] Notification stream listening active in background isolate");
    } catch (e, stack) {
      print("[BackgroundService] Error starting notification listener: $e\n$stack");
    }
  }

  Future<Map<String, dynamic>> _loadUserSettingsMap() async {
    try {
      _bgPrefs ??= await SharedPreferences.getInstance();
      await _bgPrefs?.reload();
      String? settingsJson =
          _bgPrefs?.getString("userSettings") ?? _bgPrefs?.getString("appSettings");
      if (settingsJson != null && settingsJson.isNotEmpty) {
        Map<String, dynamic> map = Map<String, dynamic>.from(jsonDecode(settingsJson));
        map["sharedBudgets"] = false;
        appStateSettings = map;
        return map;
      }
    } catch (_) {}
    appStateSettings["sharedBudgets"] = false;
    return appStateSettings;
  }

  Future<void> _handleBackgroundNotification(ServiceNotificationEvent event) async {
    try {
      if (event.hasRemoved == true || event.onGoing == true) return;

      // If the main UI isolate is alive in memory, let it handle the notification exclusively
      if (await _isMainIsolateActive()) {
        await _closeBackgroundDatabase();
        return;
      }

      final String? pkg = event.packageName?.trim().toLowerCase();
      final Map<String, dynamic> settingsMap = await _loadUserSettingsMap();
      if (settingsMap["notificationScanning"] == false) return;

      final String? allowedPackagesString =
          settingsMap["notificationAllowedPackages"]?.toString().trim();

      if (isNonFinancialPackageByDefault(pkg, allowedPackagesString: allowedPackagesString)) {
        return;
      }

      if (allowedPackagesString != null && allowedPackagesString.isNotEmpty) {
        List<String> allowedList = allowedPackagesString
            .split(",")
            .map((e) => e.trim().toLowerCase())
            .where((e) => e.isNotEmpty)
            .toList();
        if (allowedList.isNotEmpty &&
            pkg != null &&
            !allowedList.any((allowed) => pkg.contains(allowed))) {
          return;
        }
      }

      String messageString =
          "Package name: ${event.packageName}\nNotification Title: ${event.title}\n\nNotification Content: ${event.content}";
      if (isChatOrMediaNotification(messageString)) {
        return;
      }

      print("[BackgroundService] Processing notification from $pkg: ${event.title} - ${event.content}");
      await _processAndInsertTransaction(messageString, DateTime.now());
    } catch (e, stack) {
      print("[BackgroundService] Error handling background notification: $e\n$stack");
    }
  }

  Future<void> _processAndInsertTransaction(String messageString, DateTime eventTime) async {
    try {
      if (isChatOrMediaNotification(messageString)) {
        return;
      }
      if (isPaymentReminderOrPendingNotice(messageString)) {
        print("[BackgroundService] Discarded notification: Detected payment reminder or upcoming bill notice without confirmed debit.");
        return;
      }
      if (isPromotionalOrMarketingNotification(messageString)) {
        print("[BackgroundService] Discarded notification: Detected promotional or marketing message without confirmed transaction.");
        return;
      }

      await _ensureBackgroundDatabaseOpen();
      if (_bgDatabase == null) return;
      await _refreshMetadataCacheIfNeeded();

      String? title;
      double? amountDouble;
      ScannerTemplate? templateFound;

      try {
        List<ScannerTemplate> templates =
            _cachedTemplates ?? await _bgDatabase!.getAllScannerTemplates();
        for (ScannerTemplate tmpl in templates) {
          if (tmpl.contains.isNotEmpty && messageString.contains(tmpl.contains)) {
            String? candidateTitle = getTransactionTitleFromEmail(
              messageString,
              tmpl.titleTransactionBefore,
              tmpl.titleTransactionAfter,
            );
            double? candidateAmount = getTransactionAmountFromEmail(
              messageString,
              tmpl.amountTransactionBefore,
              tmpl.amountTransactionAfter,
            );
            if (candidateTitle != null && candidateAmount != null) {
              templateFound = tmpl;
              title = candidateTitle;
              amountDouble = candidateAmount;
              break;
            }
          }
        }
      } catch (e) {
        print("[BackgroundService] Error matching template: $e");
      }

      bool isIncome = false;
      TransactionWallet? nlpWallet;

      // Local Regex NLP
      if (templateFound == null || amountDouble == null || title == null) {
        LocalNlpParsedTransaction? nlpParsed =
            await parseTransactionFromNotificationText(messageString, null);
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
      final String normTitle = title.trim().toLowerCase();
      final String dedupKey = "${normTitle}_${absoluteAmount.toStringAsFixed(2)}";
      final DateTime? lastSeen = _dedupCache[dedupKey];
      if (lastSeen != null && eventTime.difference(lastSeen).inMinutes.abs() <= 5) {
        print("[BackgroundService] Dedup: in-memory duplicate ignored ($dedupKey)");
        return;
      }

      try {
        Transaction? existingDbDuplicate = await _bgDatabase!.findDuplicateTransaction(
          amount: absoluteAmount,
          timestamp: eventTime,
          name: title,
          window: const Duration(minutes: 5),
        );
        if (existingDbDuplicate != null) {
          final Set<String> genericNames = {
            "transaction",
            "paid",
            "payment",
            "bank",
            "sms / messages",
            "notification"
          };
          final bool existingNameIsGeneric = genericNames
              .contains(existingDbDuplicate.name.trim().toLowerCase());
          final bool newNameIsSpecific =
              !genericNames.contains(title.trim().toLowerCase());
          final bool canUpgradeWallet = nlpWallet != null &&
              existingDbDuplicate.walletFk != nlpWallet.walletPk;

          if ((existingNameIsGeneric && newNameIsSpecific) || canUpgradeWallet) {
            await _bgDatabase!.createOrUpdateTransaction(
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
            print("[BackgroundService] Enriched duplicate transaction '${existingDbDuplicate.name}' -> '$title'");
          } else {
            print("[BackgroundService] Dedup: database duplicate ignored for $title ($absoluteAmount)");
          }
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
          List<TransactionCategory> allCats =
              _cachedCategories ?? await _bgDatabase!.getAllCategories();
          category = allCats.where((c) {
            String n = c.name.toLowerCase();
            return n.contains("other") ||
                n.contains("general") ||
                n.contains("uncategorized") ||
                n.contains("misc");
          }).firstOrNull ??
              allCats.where((c) => c.categoryPk != "0").firstOrNull ??
              allCats.firstOrNull;
        } catch (_) {}
      }

      if (wallet == null) {
        try {
          List<TransactionWallet> allW =
              _cachedWallets ?? await _bgDatabase!.getAllWallets();
          String? selectedWalletPk;
          try {
            final String? userSettingsRaw = _bgPrefs?.getString("userSettings");
            if (userSettingsRaw != null && userSettingsRaw.isNotEmpty) {
              final Map<String, dynamic> parsedSettings =
                  jsonDecode(userSettingsRaw);
              selectedWalletPk =
                  parsedSettings["selectedWalletPk"]?.toString();
            }
          } catch (_) {}
          wallet = (selectedWalletPk != null
                  ? allW
                      .where((w) => w.walletPk == selectedWalletPk)
                      .firstOrNull
                  : null) ??
              allW.firstOrNull;
        } catch (_) {}
      }

      String categoryPk = category?.categoryPk ?? "1";
      String walletPk = wallet?.walletPk ?? "0";

      final String dateStr =
          "${eventTime.year}-${eventTime.month.toString().padLeft(2, '0')}-${eventTime.day.toString().padLeft(2, '0')}";
      final String appName = getReadableAppNameFromPackage(messageString);
      final String transactionNote = "Auto-detected from $appName • $dateStr";
      final double signedAmount = isIncome ? absoluteAmount : -absoluteAmount;

      try {
        final int? rowId = await _bgDatabase!.createOrUpdateTransaction(
          Transaction(
            transactionPk: "-1",
            name: title,
            amount: signedAmount,
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
          updateSharedEntry: false,
        );

        String? transactionPk;
        if (rowId != null) {
          try {
            final tx = await _bgDatabase!.getTransactionFromRowId(rowId);
            transactionPk = tx.transactionPk;
          } catch (_) {}
        }

        print("[BackgroundService] Auto-inserted transaction: $title - $signedAmount (income: $isIncome, pk: $transactionPk)");

        // 1. Sync to SharedPreferences for UI summary snackbar on app resume
        try {
          await _bgPrefs?.reload();
          List<String> recordedList =
              _bgPrefs?.getStringList("recent_auto_added_transactions") ?? [];
          final item = jsonEncode({
            'title': title,
            'amount': signedAmount,
            'isIncome': isIncome,
            'timestamp': eventTime.toIso8601String(),
            'transactionPk': transactionPk,
          });
          recordedList.add(item);
          await _bgPrefs?.setStringList("recent_auto_added_transactions", recordedList);
        } catch (e) {
          print("[BackgroundService] Error saving auto-added transaction to prefs: $e");
        }

        // 2. Sync to SharedPreferences for UI review banner on Home Page
        try {
          final Set<String> dismissedKeys = (_bgPrefs
                      ?.getStringList("dismissed_review_transaction_keys") ??
                  [])
              .toSet();
          List<String> pendingList =
              (_bgPrefs?.getStringList("pending_review_transactions_json") ?? [])
                  .where((raw) {
            try {
              final map = jsonDecode(raw);
              final String? pk = map['transactionPk']?.toString();
              if (pk != null && pk.isNotEmpty && dismissedKeys.contains("pk_$pk")) {
                return false;
              }
            } catch (_) {}
            return true;
          }).toList();

          final item = jsonEncode({
            'title': title,
            'amount': signedAmount,
            'isIncome': isIncome,
            'timestamp': eventTime.toIso8601String(),
            'transactionPk': transactionPk,
          });
          pendingList.insert(0, item);
          await _bgPrefs?.setStringList("pending_review_transactions_json", pendingList);
        } catch (e) {
          print("[BackgroundService] Error saving pending review to prefs: $e");
        }

        // 3. Notify user via dismissible (swipeable) local status bar notification
        await _showAutoInsertedNotification(
          title: title,
          amount: absoluteAmount,
          isIncome: isIncome,
          transactionPk: transactionPk,
        );
      } catch (e) {
        print("[BackgroundService] Error inserting background transaction: $e");
      }
    } catch (e, stack) {
      print("[BackgroundService] Error in _processAndInsertTransaction: $e\n$stack");
    }
  }

  Future<void> _showAutoInsertedNotification({
    required String title,
    required double amount,
    required bool isIncome,
    required String? transactionPk,
  }) async {
    try {
      const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        'auto_transactions_channel',
        'Auto-Detected Transactions',
        channelDescription:
            'Alerts when payment or bank SMS notifications are automatically recorded',
        importance: Importance.high,
        priority: Priority.high,
        showWhen: true,
        enableVibration: true,
        playSound: true,
        autoCancel: true,
        ongoing: false,
      );

      const DarwinNotificationDetails darwinDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const NotificationDetails notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: darwinDetails,
      );

      int notificationId = DateTime.now().millisecondsSinceEpoch.remainder(100000);
      final String payload = transactionPk != null
          ? "openTransaction?transactionPk=$transactionPk"
          : "transactions";

      await _bgLocalNotifications?.show(
        notificationId,
        isIncome ? "Auto-Recorded Income" : "Auto-Recorded Transaction",
        "$title · ${amount.toStringAsFixed(2)}",
        notificationDetails,
        payload: payload,
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
      channelDescription:
          'Keeps Xpenzi notification listener active in the background for real-time transaction detection',
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
      eventAction: ForegroundTaskEventAction.nothing(),
      autoRunOnBoot: false,
      autoRunOnMyPackageReplaced: false,
      allowWakeLock: false,
      allowWifiLock: false,
    ),
  );
}

Future<bool> startBackgroundListenerService() async {
  try {
    await initForegroundTask();

    if (await FlutterForegroundTask.isRunningService) {
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
