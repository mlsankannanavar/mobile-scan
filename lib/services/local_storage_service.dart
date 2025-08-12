import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/batch_info.dart';
import '../models/session_data.dart';
import '../utils/logger.dart';

class LocalStorageService {
  static Database? _database;
  static SharedPreferences? _prefs;
  
  /// Initialize the service
  static Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
    await _initDatabase();
  }
  
  /// Initialize SQLite database
  static Future<void> _initDatabase() async {
    try {
      final dbPath = await getDatabasesPath();
      final path = join(dbPath, 'batch_scanner.db');
      
      _database = await openDatabase(
        path,
        version: 1,
        onCreate: (db, version) async {
          // Create sessions table
          await db.execute('''
            CREATE TABLE sessions (
              session_id TEXT PRIMARY KEY,
              location_code TEXT,
              item_codes TEXT,
              download_timestamp INTEGER,
              batch_count INTEGER
            )
          ''');
          
          // Create batches table
          await db.execute('''
            CREATE TABLE batches (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              session_id TEXT,
              batch_number TEXT,
              expiry_date TEXT,
              item_name TEXT,
              item_code TEXT,
              location_code TEXT,
              FOREIGN KEY (session_id) REFERENCES sessions (session_id)
            )
          ''');
          
          // Create logs table
          await db.execute('''
            CREATE TABLE logs (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              timestamp INTEGER,
              level TEXT,
              message TEXT,
              details TEXT
            )
          ''');
          
          AppLogger.info('Database created successfully');
        },
      );
    } catch (e) {
      AppLogger.error('Failed to initialize database', details: {'error': e.toString()});
    }
  }
  
  /// Store session data with batches
  static Future<void> storeBatches(String sessionId, Map<String, BatchInfo> batches) async {
    try {
      if (_database == null) await _initDatabase();
      
      final db = _database!;
      
      // Start transaction
      await db.transaction((txn) async {
        // Clear existing data for this session
        await txn.delete('sessions', where: 'session_id = ?', whereArgs: [sessionId]);
        await txn.delete('batches', where: 'session_id = ?', whereArgs: [sessionId]);
        
        // Get first batch to extract common data
        if (batches.isNotEmpty) {
          final firstBatch = batches.values.first;
          final itemCodes = batches.values.map((b) => b.itemCode).toSet().toList();
          
          // Insert session data
          await txn.insert('sessions', {
            'session_id': sessionId,
            'location_code': firstBatch.locationCode,
            'item_codes': json.encode(itemCodes),
            'download_timestamp': DateTime.now().millisecondsSinceEpoch,
            'batch_count': batches.length,
          });
          
          // Insert batch data
          for (final entry in batches.entries) {
            final batch = entry.value;
            await txn.insert('batches', {
              'session_id': sessionId,
              'batch_number': batch.batchNumber,
              'expiry_date': batch.expiryDate,
              'item_name': batch.itemName,
              'item_code': batch.itemCode,
              'location_code': batch.locationCode,
            });
          }
        }
      });
      
      AppLogger.info('Stored batches locally', details: {
        'sessionId': sessionId,
        'batchCount': batches.length,
      });
    } catch (e) {
      AppLogger.error('Failed to store batches', details: {
        'sessionId': sessionId,
        'error': e.toString(),
      });
    }
  }
  
  /// Retrieve stored batches for a session
  static Future<Map<String, BatchInfo>?> getBatches(String sessionId) async {
    try {
      if (_database == null) await _initDatabase();
      
      final db = _database!;
      
      // Check if session exists
      final sessionResult = await db.query(
        'sessions',
        where: 'session_id = ?',
        whereArgs: [sessionId],
      );
      
      if (sessionResult.isEmpty) {
        return null;
      }
      
      // Get batches for session
      final batchResults = await db.query(
        'batches',
        where: 'session_id = ?',
        whereArgs: [sessionId],
      );
      
      final batches = <String, BatchInfo>{};
      for (final row in batchResults) {
        final batchNumber = row['batch_number'] as String;
        batches[batchNumber] = BatchInfo(
          batchNumber: batchNumber,
          expiryDate: row['expiry_date'] as String,
          itemName: row['item_name'] as String,
          itemCode: row['item_code'] as String,
          locationCode: row['location_code'] as String,
        );
      }
      
      AppLogger.info('Retrieved batches from local storage', details: {
        'sessionId': sessionId,
        'batchCount': batches.length,
      });
      
      return batches;
    } catch (e) {
      AppLogger.error('Failed to retrieve batches', details: {
        'sessionId': sessionId,
        'error': e.toString(),
      });
      return null;
    }
  }
  
  /// Get session data
  static Future<SessionData?> getSessionData(String sessionId) async {
    try {
      if (_database == null) await _initDatabase();
      
      final db = _database!;
      
      final sessionResult = await db.query(
        'sessions',
        where: 'session_id = ?',
        whereArgs: [sessionId],
      );
      
      if (sessionResult.isEmpty) {
        return null;
      }
      
      final row = sessionResult.first;
      final batches = await getBatches(sessionId) ?? {};
      final itemCodes = json.decode(row['item_codes'] as String).cast<String>();
      
      return SessionData(
        sessionId: sessionId,
        availableBatches: batches,
        locationCode: row['location_code'] as String,
        itemCodes: itemCodes,
        downloadTimestamp: DateTime.fromMillisecondsSinceEpoch(row['download_timestamp'] as int),
        batchCount: row['batch_count'] as int,
      );
    } catch (e) {
      AppLogger.error('Failed to get session data', details: {
        'sessionId': sessionId,
        'error': e.toString(),
      });
      return null;
    }
  }
  
  /// Clear old sessions (keep only last 5)
  static Future<void> clearOldSessions() async {
    try {
      if (_database == null) await _initDatabase();
      
      final db = _database!;
      
      // Get all sessions ordered by download timestamp
      final sessions = await db.query(
        'sessions',
        orderBy: 'download_timestamp DESC',
      );
      
      if (sessions.length > 5) {
        final sessionsToDelete = sessions.skip(5).toList();
        
        for (final session in sessionsToDelete) {
          final sessionId = session['session_id'] as String;
          await db.delete('sessions', where: 'session_id = ?', whereArgs: [sessionId]);
          await db.delete('batches', where: 'session_id = ?', whereArgs: [sessionId]);
        }
        
        AppLogger.info('Cleaned up old sessions', details: {
          'deletedCount': sessionsToDelete.length,
        });
      }
    } catch (e) {
      AppLogger.error('Failed to clean up old sessions', details: {'error': e.toString()});
    }
  }
  
  /// Store logs to database
  static Future<void> storeLogs(List<LogEntry> logs) async {
    try {
      if (_database == null) await _initDatabase();
      
      final db = _database!;
      
      await db.transaction((txn) async {
        for (final log in logs) {
          await txn.insert('logs', {
            'timestamp': log.timestamp.millisecondsSinceEpoch,
            'level': log.level.name,
            'message': log.message,
            'details': log.details != null ? json.encode(log.details!) : null,
          });
        }
      });
    } catch (e) {
      AppLogger.error('Failed to store logs', details: {'error': e.toString()});
    }
  }
  
  /// Retrieve logs from database
  static Future<List<LogEntry>> getLogs() async {
    try {
      if (_database == null) await _initDatabase();
      
      final db = _database!;
      
      final results = await db.query(
        'logs',
        orderBy: 'timestamp DESC',
        limit: 1000,
      );
      
      return results.map((row) {
        final details = row['details'] as String?;
        return LogEntry(
          timestamp: DateTime.fromMillisecondsSinceEpoch(row['timestamp'] as int),
          level: LogLevel.values.firstWhere((l) => l.name == row['level']),
          message: row['message'] as String,
          details: details != null ? json.decode(details) : null,
        );
      }).toList();
    } catch (e) {
      AppLogger.error('Failed to retrieve logs', details: {'error': e.toString()});
      return [];
    }
  }
  
  /// Clear all logs
  static Future<void> clearLogs() async {
    try {
      if (_database == null) await _initDatabase();
      
      final db = _database!;
      await db.delete('logs');
      
      AppLogger.info('Cleared all stored logs');
    } catch (e) {
      AppLogger.error('Failed to clear logs', details: {'error': e.toString()});
    }
  }
  
  /// Store app settings
  static Future<void> storeSetting(String key, String value) async {
    await _prefs?.setString(key, value);
  }
  
  /// Get app setting
  static String? getSetting(String key) {
    return _prefs?.getString(key);
  }
  
  /// Store boolean setting
  static Future<void> storeBoolSetting(String key, bool value) async {
    await _prefs?.setBool(key, value);
  }
  
  /// Get boolean setting
  static bool? getBoolSetting(String key) {
    return _prefs?.getBool(key);
  }
}
