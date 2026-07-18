import 'package:hive/hive.dart';
import 'dart:developer' as developer;

/// Service for capturing and storing diagnostic logs in-app
class DiagnosticLogService {
  static const String _logBoxName = 'diagnostic_logs';
  static const String _currentLogKey = 'current_log';
  
  static Future<void> init() async {
    if (!Hive.isBoxOpen(_logBoxName)) {
      await Hive.openBox<String>(_logBoxName);
    }
  }
  
  static void addLog(String message) {
    final timestamp = DateTime.now().toIso8601String();
    final logEntry = '[$timestamp] $message';
    
    // Log to console
    developer.log(logEntry);
    
    // Store in Hive
    try {
      final box = Hive.box<String>(_logBoxName);
      final currentLog = box.get(_currentLogKey, defaultValue: '') ?? '';
      final updatedLog = currentLog + '\n' + logEntry;
      box.put(_currentLogKey, updatedLog);
    } catch (e) {
      developer.log('Failed to store diagnostic log: $e');
    }
  }
  
  static String getCurrentLog() {
    try {
      final box = Hive.box<String>(_logBoxName);
      return box.get(_currentLogKey, defaultValue: '') ?? '';
    } catch (e) {
      return 'Error retrieving logs: $e';
    }
  }
  
  static void clearLog() {
    try {
      final box = Hive.box<String>(_logBoxName);
      box.delete(_currentLogKey);
    } catch (e) {
      developer.log('Failed to clear diagnostic log: $e');
    }
  }
  
  static Future<void> startNewSession() async {
    clearLog();
    addLog('=== NEW DIAGNOSTIC SESSION STARTED ===');
  }
}
