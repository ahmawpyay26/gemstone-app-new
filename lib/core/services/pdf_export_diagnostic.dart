import 'package:flutter/foundation.dart';
import 'dart:developer' as developer;

/// Diagnostic state for PDF export flow
/// Tracks checkpoints, exceptions, and timeouts for real-time display
class PdfExportDiagnostic extends ChangeNotifier {
  static final PdfExportDiagnostic _instance = PdfExportDiagnostic._internal();

  factory PdfExportDiagnostic() {
    return _instance;
  }

  PdfExportDiagnostic._internal();

  String _currentCheckpoint = '';
  String _lastCompletedCheckpoint = '';
  String? _exceptionMessage;
  String? _stackTraceLine;
  bool _isActive = false;
  DateTime? _checkpointStartTime;
  Map<String, Duration> _checkpointDurations = {};

  // Getters
  String get currentCheckpoint => _currentCheckpoint;
  String get lastCompletedCheckpoint => _lastCompletedCheckpoint;
  String? get exceptionMessage => _exceptionMessage;
  String? get stackTraceLine => _stackTraceLine;
  bool get isActive => _isActive;
  Map<String, Duration> get checkpointDurations => _checkpointDurations;

  /// Start PDF export diagnostic
  void startExport() {
    _currentCheckpoint = 'PDF export entered';
    _lastCompletedCheckpoint = '';
    _exceptionMessage = null;
    _stackTraceLine = null;
    _isActive = true;
    _checkpointDurations.clear();
    _checkpointStartTime = DateTime.now();
    developer.log('[PDF_DIAGNOSTIC] Export started');
    notifyListeners();
  }

  /// Record a checkpoint
  void checkpoint(String name) {
    if (!_isActive) return;

    final now = DateTime.now();
    if (_checkpointStartTime != null) {
      final duration = now.difference(_checkpointStartTime!);
      _checkpointDurations[name] = duration;
    }

    _lastCompletedCheckpoint = _currentCheckpoint;
    _currentCheckpoint = name;
    developer.log('[PDF_DIAGNOSTIC] Checkpoint: $name (duration: ${_checkpointDurations[name]})');
    notifyListeners();
  }

  /// Record an exception
  void recordException(Object error, StackTrace stackTrace) {
    if (!_isActive) return;

    _exceptionMessage = error.toString();
    
    // Extract first line of stack trace
    final lines = stackTrace.toString().split('\n');
    if (lines.isNotEmpty) {
      _stackTraceLine = lines.first;
    }

    developer.log('[PDF_DIAGNOSTIC] Exception: $_exceptionMessage');
    developer.log('[PDF_DIAGNOSTIC] Stack trace line: $_stackTraceLine');
    notifyListeners();
  }

  /// Record a timeout
  void recordTimeout(String checkpointName, Duration timeout) {
    if (!_isActive) return;

    _currentCheckpoint = 'TIMEOUT: $checkpointName (${timeout.inSeconds}s)';
    _exceptionMessage = 'Timeout waiting for $checkpointName';
    developer.log('[PDF_DIAGNOSTIC] Timeout: $checkpointName after ${timeout.inSeconds}s');
    notifyListeners();
  }

  /// End export diagnostic
  void endExport() {
    _isActive = false;
    developer.log('[PDF_DIAGNOSTIC] Export ended');
    notifyListeners();
  }

  /// Clear diagnostic state
  void clear() {
    _currentCheckpoint = '';
    _lastCompletedCheckpoint = '';
    _exceptionMessage = null;
    _stackTraceLine = null;
    _isActive = false;
    _checkpointDurations.clear();
    notifyListeners();
  }

  /// Get formatted diagnostic summary
  String getDiagnosticSummary() {
    return '''Current: $_currentCheckpoint
Last: $_lastCompletedCheckpoint
Error: ${_exceptionMessage ?? 'None'}
Stack: ${_stackTraceLine ?? 'N/A'}''';
  }
}
