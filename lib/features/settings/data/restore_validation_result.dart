/// Data structures for backup restore validation and preview.
/// Phase 1: File validation and preview only (no Hive writes).

class RestoreValidationResult {
  /// Whether the backup file is valid and can be previewed.
  final bool isValid;

  /// Error message if validation failed (null if valid).
  final String? errorMessage;

  /// Filename of the backup file.
  final String filename;

  /// Total record count across all boxes.
  final int totalRecords;

  /// Record count per box: box name → count.
  /// Includes all 17 boxes, even if count is 0.
  final Map<String, int> recordCounts;

  /// List of supported boxes that can be restored in Phase 2+.
  /// Currently: users, gemstones, sales, expenses, workers, auditLogs,
  /// customers, customerLedger, payments, brokerConsignments, brokerSaleRecords, businessProfile.
  final List<String> supportedBoxes;

  /// List of special/unsupported boxes for Phase 1.
  /// Currently: session, staffUsers, permissions, roles, brokerProfiles.
  final List<String> unsupportedBoxes;

  /// List of warnings (e.g., "Unknown box detected", "Empty boxes", etc.).
  final List<String> warnings;

  RestoreValidationResult({
    required this.isValid,
    this.errorMessage,
    required this.filename,
    required this.totalRecords,
    required this.recordCounts,
    required this.supportedBoxes,
    required this.unsupportedBoxes,
    required this.warnings,
  });

  /// Create a validation failure result.
  factory RestoreValidationResult.failure({
    required String filename,
    required String errorMessage,
  }) {
    return RestoreValidationResult(
      isValid: false,
      errorMessage: errorMessage,
      filename: filename,
      totalRecords: 0,
      recordCounts: {},
      supportedBoxes: [],
      unsupportedBoxes: [],
      warnings: [],
    );
  }

  /// Create a validation success result.
  factory RestoreValidationResult.success({
    required String filename,
    required int totalRecords,
    required Map<String, int> recordCounts,
    required List<String> supportedBoxes,
    required List<String> unsupportedBoxes,
    List<String> warnings = const [],
  }) {
    return RestoreValidationResult(
      isValid: true,
      errorMessage: null,
      filename: filename,
      totalRecords: totalRecords,
      recordCounts: recordCounts,
      supportedBoxes: supportedBoxes,
      unsupportedBoxes: unsupportedBoxes,
      warnings: warnings,
    );
  }

  /// Get record count for a specific box.
  int getBoxCount(String boxName) => recordCounts[boxName] ?? 0;

  /// Get list of boxes with data (count > 0).
  List<String> getBoxesWithData() {
    return recordCounts.entries
        .where((e) => e.value > 0)
        .map((e) => e.key)
        .toList();
  }

  /// Get list of supported boxes with data.
  List<String> getSupportedBoxesWithData() {
    final withData = getBoxesWithData();
    return withData.where((box) => supportedBoxes.contains(box)).toList();
  }

  /// Get list of unsupported boxes with data.
  List<String> getUnsupportedBoxesWithData() {
    final withData = getBoxesWithData();
    return withData.where((box) => unsupportedBoxes.contains(box)).toList();
  }
}

/// Restore preview data shown to user before actual restore.
class RestorePreview {
  /// Validation result from Phase 1.
  final RestoreValidationResult validation;

  /// Supported boxes that will be restored (have data).
  final List<String> boxesToRestore;

  /// Unsupported boxes that will NOT be restored (have data).
  final List<String> boxesNotRestored;

  /// User-facing warnings about restore risks.
  final List<String> userWarnings;

  RestorePreview({
    required this.validation,
    required this.boxesToRestore,
    required this.boxesNotRestored,
    required this.userWarnings,
  });

  /// Create preview from validation result.
  factory RestorePreview.fromValidation(RestoreValidationResult validation) {
    final supportedWithData = validation.getSupportedBoxesWithData();
    final unsupportedWithData = validation.getUnsupportedBoxesWithData();

    final warnings = <String>[
      ...validation.warnings,
    ];

    // Add warnings for unsupported boxes with data
    if (unsupportedWithData.isNotEmpty) {
      if (unsupportedWithData.contains('session')) {
        warnings.add('Session သည် restore မှ ခွဲထုတ်ထားပါသည်။ ပြန်လည်ဝင်ရောက်ရန် လိုအပ်ပါမည်။');
      }
      if (unsupportedWithData.contains('staffUsers')) {
        warnings.add('Staff Users သည် Phase 2 တွင် support ပြုလုပ်ရန် ကျန်ရှိသေးပါသည်။');
      }
      if (unsupportedWithData.contains('permissions') ||
          unsupportedWithData.contains('roles')) {
        warnings.add('RBAC (Permissions/Roles) သည် Phase 2 တွင် support ပြုလုပ်ရန် ကျန်ရှိသေးပါသည်။');
      }
      if (unsupportedWithData.contains('brokerProfiles')) {
        warnings.add('Broker Profiles သည် Phase 2 တွင် support ပြုလုပ်ရန် ကျန်ရှိသေးပါသည်။');
      }
    }

    return RestorePreview(
      validation: validation,
      boxesToRestore: supportedWithData,
      boxesNotRestored: unsupportedWithData,
      userWarnings: warnings,
    );
  }

  /// Get total records to be restored (supported boxes only).
  int getTotalRecordsToRestore() {
    return boxesToRestore.fold<int>(
      0,
      (sum, box) => sum + (validation.getBoxCount(box) ?? 0),
    );
  }

  /// Get total records NOT to be restored (unsupported boxes only).
  int getTotalRecordsNotRestored() {
    return boxesNotRestored.fold<int>(
      0,
      (sum, box) => sum + (validation.getBoxCount(box) ?? 0),
    );
  }
}
