import 'package:intl/intl.dart';

/// Singleton service to collect RCA instrumentation logs in memory
/// This is a TEMPORARY debugging tool for RCA analysis only
class RCALogCollector {
  static final RCALogCollector _instance = RCALogCollector._internal();

  factory RCALogCollector() {
    return _instance;
  }

  RCALogCollector._internal();

  final List<RCALogEntry> _logs = [];
  final List<String> _rcaLogNames = [
    'HIVE_LOOKUP_DEBUG',
    'RCA_BROKER_CONSIGNMENT',
    'RCA_FINAL_SAVE',
  ];

  /// Add a log entry
  void addLog(String name, String message, int level) {
    // Only capture RCA-related logs
    if (_rcaLogNames.contains(name)) {
      _logs.add(
        RCALogEntry(
          timestamp: DateTime.now(),
          name: name,
          message: message,
          level: level,
        ),
      );
    }
  }

  /// Get all logs as formatted strings
  List<String> getFormattedLogs() {
    return _logs.map((log) => log.toString()).toList();
  }

  /// Get all logs as a single string
  String getAllLogsAsString() {
    return _logs.map((log) => log.toString()).join('\n');
  }

  /// Clear all logs
  void clearLogs() {
    _logs.clear();
  }

  /// Get log count
  int getLogCount() {
    return _logs.length;
  }

  /// Get logs for a specific name
  List<String> getLogsByName(String name) {
    return _logs
        .where((log) => log.name == name)
        .map((log) => log.toString())
        .toList();
  }
}

/// Single RCA log entry
class RCALogEntry {
  final DateTime timestamp;
  final String name;
  final String message;
  final int level;

  RCALogEntry({
    required this.timestamp,
    required this.name,
    required this.message,
    required this.level,
  });

  @override
  String toString() {
    final timeStr = DateFormat('HH:mm:ss.SSS').format(timestamp);
    return '[$timeStr] [$name] $message';
  }
}
