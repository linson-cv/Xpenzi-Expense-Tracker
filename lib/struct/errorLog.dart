import 'dart:convert';
import 'package:budget/struct/databaseGlobal.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class AppErrorItem {
  final DateTime timestamp;
  final String tag;
  final String error;
  final String? stackTrace;
  final String? extraInfo;

  AppErrorItem({
    required this.timestamp,
    required this.tag,
    required this.error,
    this.stackTrace,
    this.extraInfo,
  });

  Map<String, dynamic> toMap() {
    return {
      'timestamp': timestamp.toIso8601String(),
      'tag': tag,
      'error': error,
      'stackTrace': stackTrace,
      'extraInfo': extraInfo,
    };
  }

  factory AppErrorItem.fromMap(Map<String, dynamic> map) {
    return AppErrorItem(
      timestamp: DateTime.tryParse(map['timestamp'] ?? '') ?? DateTime.now(),
      tag: map['tag'] ?? 'General',
      error: map['error'] ?? '',
      stackTrace: map['stackTrace'],
      extraInfo: map['extraInfo'],
    );
  }

  String formatForClipboard() {
    final buffer = StringBuffer();
    buffer.writeln("[$tag] ${timestamp.toLocal()}");
    buffer.writeln("Error: $error");
    if (extraInfo != null && extraInfo!.isNotEmpty) {
      buffer.writeln("Details: $extraInfo");
    }
    if (stackTrace != null && stackTrace!.isNotEmpty) {
      buffer.writeln("StackTrace:\n$stackTrace");
    }
    return buffer.toString();
  }
}

final List<AppErrorItem> _appErrorLogs = [];
final ValueNotifier<int> appErrorLogsCountNotifier = ValueNotifier<int>(0);
bool _isLogsInitialized = false;

Future<void> _initLogsFromDisk() async {
  if (_isLogsInitialized) return;
  _isLogsInitialized = true;
  try {
    String? stored = sharedPreferences.getString('persisted_app_error_logs');
    if (stored != null && stored.isNotEmpty) {
      List<dynamic> list = jsonDecode(stored);
      _appErrorLogs.clear();
      final cutoffDate = DateTime.now().subtract(const Duration(days: 30));
      for (var item in list) {
        if (item is Map<String, dynamic>) {
          final errorItem = AppErrorItem.fromMap(item);
          // Keep only logs from the last 30 days
          if (errorItem.timestamp.isAfter(cutoffDate)) {
            _appErrorLogs.add(errorItem);
          }
        }
      }
      appErrorLogsCountNotifier.value = _appErrorLogs.length;
    }
  } catch (e) {
    debugPrint("Failed to load persisted error logs: $e");
  }
}

void _saveLogsToDisk() {
  try {
    List<Map<String, dynamic>> rawList = _appErrorLogs.map((e) => e.toMap()).toList();
    sharedPreferences.setString('persisted_app_error_logs', jsonEncode(rawList));
  } catch (_) {}
}

List<AppErrorItem> getAppErrorLogs() {
  _initLogsFromDisk();
  return List.unmodifiable(_appErrorLogs);
}

void recordAppError(
  String tag,
  dynamic error, {
  StackTrace? stackTrace,
  String? extraInfo,
}) {
  _initLogsFromDisk();
  final item = AppErrorItem(
    timestamp: DateTime.now(),
    tag: tag,
    error: error.toString(),
    stackTrace: stackTrace?.toString(),
    extraInfo: extraInfo,
  );

  _appErrorLogs.insert(0, item);
  
  // Prune logs older than 30 days
  final cutoffDate = DateTime.now().subtract(const Duration(days: 30));
  _appErrorLogs.removeWhere((log) => log.timestamp.isBefore(cutoffDate));

  // Retain up to 500 most recent logs
  if (_appErrorLogs.length > 500) {
    _appErrorLogs.removeRange(500, _appErrorLogs.length);
  }
  appErrorLogsCountNotifier.value = _appErrorLogs.length;
  _saveLogsToDisk();

  debugPrint("🚨 [AppErrorLog][$tag]: ${item.error}");
  if (extraInfo != null) debugPrint("   Details: $extraInfo");
  if (stackTrace != null) debugPrint("   StackTrace: $stackTrace");
}

void clearAppErrorLogs() {
  _appErrorLogs.clear();
  appErrorLogsCountNotifier.value = 0;
  _saveLogsToDisk();
}

String exportAllLogsAsText() {
  if (_appErrorLogs.isEmpty) {
    return "No errors logged.";
  }
  final buffer = StringBuffer();
  buffer.writeln("=== XPENZI DIAGNOSTIC & ERROR LOGS ===");
  buffer.writeln("Generated: ${DateTime.now().toLocal()}\n");
  for (int i = 0; i < _appErrorLogs.length; i++) {
    buffer.writeln("--- Log #${i + 1} ---");
    buffer.writeln(_appErrorLogs[i].formatForClipboard());
    buffer.writeln();
  }
  return buffer.toString();
}
