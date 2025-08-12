import 'package:flutter/foundation.dart';

enum LogLevel { info, warning, error, debug }

class LogEntry {
  final DateTime timestamp;
  final LogLevel level;
  final String message;
  final Map<String, dynamic>? details;

  const LogEntry({
    required this.timestamp,
    required this.level,
    required this.message,
    this.details,
  });

  factory LogEntry.fromJson(Map<String, dynamic> json) {
    return LogEntry(
      timestamp: DateTime.parse(json['timestamp']),
      level: LogLevel.values.firstWhere(
        (e) => e.name == json['level'],
        orElse: () => LogLevel.info,
      ),
      message: json['message'] ?? '',
      details: json['details'] != null 
          ? Map<String, dynamic>.from(json['details'])
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'timestamp': timestamp.toIso8601String(),
    'level': level.name,
    'message': message,
    'details': details,
  };
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
