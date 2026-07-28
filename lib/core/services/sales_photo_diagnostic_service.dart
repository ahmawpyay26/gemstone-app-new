import 'dart:developer' as developer;

class SalesPhotoDiagnosticEntry {
  final DateTime timestamp;
  final String checkpoint;
  final String message;
  final String? path;
  final bool? fileExists;
  final int? fileSize;
  final String? exception;

  SalesPhotoDiagnosticEntry({
    required this.timestamp,
    required this.checkpoint,
    required this.message,
    this.path,
    this.fileExists,
    this.fileSize,
    this.exception,
  });

  @override
  String toString() {
    final buffer = StringBuffer();
    buffer.write('[${timestamp.toIso8601String()}] $checkpoint: $message');
    if (path != null) buffer.write('\n  Path: $path');
    if (fileExists != null) buffer.write('\n  Exists: $fileExists');
    if (fileSize != null) buffer.write('\n  Size: $fileSize bytes');
    if (exception != null) buffer.write('\n  Exception: $exception');
    return buffer.toString();
  }
}

class SalesPhotoDiagnosticService {
  static final SalesPhotoDiagnosticService _instance = SalesPhotoDiagnosticService._internal();
  final List<SalesPhotoDiagnosticEntry> _logs = [];

  SalesPhotoDiagnosticService._internal();

  factory SalesPhotoDiagnosticService() {
    return _instance;
  }

  /// Add a diagnostic entry
  void log({
    required String checkpoint,
    required String message,
    String? path,
    bool? fileExists,
    int? fileSize,
    String? exception,
  }) {
    final entry = SalesPhotoDiagnosticEntry(
      timestamp: DateTime.now(),
      checkpoint: checkpoint,
      message: message,
      path: path,
      fileExists: fileExists,
      fileSize: fileSize,
      exception: exception,
    );
    
    _logs.add(entry);
    
    // Also log to developer console
    developer.log('[DIAG] $checkpoint: $message');
  }

  /// Get all logs
  List<SalesPhotoDiagnosticEntry> getLogs() => List.from(_logs);

  /// Clear all logs
  void clearLogs() {
    _logs.clear();
  }

  /// Export logs as formatted string
  String exportLogs() {
    return _logs.map((e) => e.toString()).join('\n\n');
  }

  /// Get logs count
  int getLogsCount() => _logs.length;
}
