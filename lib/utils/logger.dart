import 'package:flutter/foundation.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'logger.freezed.dart';
part 'logger.g.dart';

enum LogLevel { info, warning, error, debug }

@freezed
class LogEntry with _$LogEntry {
  const factory LogEntry({
    required DateTime timestamp,
    required LogLevel level,
    required String message,
    Map<String, dynamic>? details,
  }) = _LogEntry;
  
  factory LogEntry.fromJson(Map<String, dynamic> json) => _$LogEntryFromJson(json);
}

class AppLogger {
  static final List<LogEntry> _logs = [];
  static const int maxLogs = 1000;  // Limit log storage
  
  static void log(LogLevel level, String message, {Map<String, dynamic>? details}) {
    final entry = LogEntry(
      timestamp: DateTime.now(),
      level: level,
      message: message,
      details: details,
    );
    
    _logs.add(entry);
    
    // Remove old logs if we exceed the limit
    if (_logs.length > maxLogs) {
      _logs.removeAt(0);
    }
    
    // Also print to console in debug mode
    if (kDebugMode) {
      print('[${entry.timestamp.toIso8601String()}] ${level.name.toUpperCase()}: $message');
      if (details != null) {
        print('  Details: $details');
      }
    }
  }
  
  static void info(String message, {Map<String, dynamic>? details}) {
    log(LogLevel.info, message, details: details);
  }
  
  static void warning(String message, {Map<String, dynamic>? details}) {
    log(LogLevel.warning, message, details: details);
  }
  
  static void error(String message, {Map<String, dynamic>? details}) {
    log(LogLevel.error, message, details: details);
  }
  
  static void debug(String message, {Map<String, dynamic>? details}) {
    log(LogLevel.debug, message, details: details);
  }
  
  static List<LogEntry> getLogs() => List.unmodifiable(_logs);
  static void clearLogs() => _logs.clear();
  
  static List<LogEntry> getFilteredLogs(LogLevel? filter) {
    if (filter == null) return getLogs();
    return _logs.where((log) => log.level == filter).toList();
  }
}
