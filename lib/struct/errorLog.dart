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

List<AppErrorItem> getAppErrorLogs() {
  return List.unmodifiable(_appErrorLogs);
}

void recordAppError(
  String tag,
  dynamic error, {
  StackTrace? stackTrace,
  String? extraInfo,
}) {
  final item = AppErrorItem(
    timestamp: DateTime.now(),
    tag: tag,
    error: error.toString(),
    stackTrace: stackTrace?.toString(),
    extraInfo: extraInfo,
  );

  _appErrorLogs.insert(0, item);
  if (_appErrorLogs.length > 100) {
    _appErrorLogs.removeRange(100, _appErrorLogs.length);
  }
  appErrorLogsCountNotifier.value = _appErrorLogs.length;

  debugPrint("🚨 [AppErrorLog][$tag]: ${item.error}");
  if (extraInfo != null) debugPrint("   Details: $extraInfo");
  if (stackTrace != null) debugPrint("   StackTrace: $stackTrace");
}

void clearAppErrorLogs() {
  _appErrorLogs.clear();
  appErrorLogsCountNotifier.value = 0;
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
