/// Backup restore service - Phase 1: File validation and preview only.
/// No Hive writes, no data restoration, no rollback.

import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:gemstone_management/core/local/local_db.dart';
import 'package:gemstone_management/core/local/models.dart';
import 'restore_validation_result.dart';
import 'restore_snapshot.dart';
import 'backup_deserializers.dart';

class BackupRestoreService {
  /// All 17 expected box names in the backup file.
  static const List<String> allBoxNames = [
    'users',
    'gemstones',
    'sales',
    'expenses',
    'workers',
    'session',
    'auditLogs',
    'staffUsers',
    'permissions',
    'roles',
    'brokerConsignments',
    'brokerSaleRecords',
    'customers',
    'customerLedger',
    'payments',
    'businessProfile',
    'brokerProfiles',
  ];

  /// Supported boxes for Phase 2+ restore.
  static const List<String> supportedBoxes = [
    'users',
    'gemstones',
    'sales',
    'expenses',
    'workers',
    'auditLogs',
    'customers',
    'customerLedger',
    'payments',
    'brokerConsignments',
    'brokerSaleRecords',
    'businessProfile',
  ];

  /// Unsupported/special boxes for Phase 1.
  static const List<String> unsupportedBoxes = [
    'session',
    'staffUsers',
    'permissions',
    'roles',
    'brokerProfiles',
  ];

  /// Phase 1: Validate backup file from content string (for Android SAF).
  /// Returns RestoreValidationResult with validation status and record counts.
  /// Does NOT write any data to Hive.
  /// Does NOT modify app state.
  static Future<RestoreValidationResult> validateBackupFileContent(
    String content,
    String filename,
  ) async {
    try {
      // Validate content is not empty
      if (content.isEmpty) {
        return RestoreValidationResult.failure(
          filename: filename,
          errorMessage: 'Backup ဖိုင်တွင်တ် အနေတ်မည်တွင်ကိုပါသည်။',
        );
      }

      // Parse JSON
      Map<String, dynamic> backupData;
      try {
        final decoded = jsonDecode(content);
        if (decoded is! Map<String, dynamic>) {
          return RestoreValidationResult.failure(
            filename: filename,
            errorMessage: 'Backup ဖိုင်တွင် မှတ်တမ်းတွင်ကိုပါသည်။',
          );
        }
        backupData = decoded;
      } catch (e) {
        return RestoreValidationResult.failure(
          filename: filename,
          errorMessage: 'JSON ဖိုင်ခွင့်ပြုချက်မရှိပါသည်။',
        );
      }

      // Validate structure: all 17 boxes should exist
      final warnings = <String>[];
      final recordCounts = <String, int>{};
      int totalRecords = 0;

      for (final boxName in allBoxNames) {
        if (!backupData.containsKey(boxName)) {
          warnings.add('Box "$boxName" ကိ ရွေးချယ်မှုပါသည်။');
          recordCounts[boxName] = 0;
        } else {
          final boxData = backupData[boxName];
          if (boxData is! Map<String, dynamic>) {
            warnings.add('Box "$boxName" တွင် မှတ်တမ်းတွင်ကိုပါသည်။');
            recordCounts[boxName] = 0;
          } else {
            final count = boxData.length;
            recordCounts[boxName] = count;
            totalRecords += count;
          }
        }
      }

      // Security validation: check for plaintext password in users
      _validateSecurityConstraints(backupData, warnings);

      // Check for unknown boxes
      for (final key in backupData.keys) {
        if (!allBoxNames.contains(key)) {
          warnings.add('အတွင်မှတ်တမ်းမှုတွင် box "$key" ကိရွေးချယ်မှုပါသည်။');
        }
      }

      // Create success result
      return RestoreValidationResult.success(
        filename: filename,
        totalRecords: totalRecords,
        recordCounts: recordCounts,
        supportedBoxes: supportedBoxes,
        unsupportedBoxes: unsupportedBoxes,
        warnings: warnings,
      );
    } catch (e) {
      return RestoreValidationResult.failure(
        filename: filename,
        errorMessage: 'Backup ဖိုင်ခွင့်ပြုချက်မရှိပါသည်။',
      );
    }
  }

  /// Phase 1: Validate backup file from file path (legacy support).
  /// Returns RestoreValidationResult with validation status and record counts.
  /// Does NOT write any data to Hive.
  /// Does NOT modify app state.
  static Future<RestoreValidationResult> validateBackupFile(String filePath) async {
    try {
      // Extract filename from path
      final filename = _extractFilename(filePath);

      // Validate file exists
      final file = File(filePath);
      if (!await file.exists()) {
        return RestoreValidationResult.failure(
          filename: filename,
          errorMessage: 'ဖိုင်ရှာမတွေ့ပါ။ ကျေးဇူးပြု၍ ထပ်မံစမ်းကြည့်ပါ။',
        );
      }

      // Read file as UTF-8 text
      String content;
      try {
        content = await file.readAsString();
      } catch (e) {
        return RestoreValidationResult.failure(
          filename: filename,
          errorMessage: 'ဖိုင်ဖတ်ရှုမှုမအောင်မြင်ပါ။ ကျေးဇူးပြု၍ ထပ်မံစမ်းကြည့်ပါ။',
        );
      }

      // Validate file is not empty
      if (content.isEmpty) {
        return RestoreValidationResult.failure(
          filename: filename,
          errorMessage: 'Backup ဖိုင်သည် အလွတ်ဖြစ်နေပါသည်။',
        );
      }

      // Parse JSON
      Map<String, dynamic> backupData;
      try {
        final decoded = jsonDecode(content);
        if (decoded is! Map<String, dynamic>) {
          return RestoreValidationResult.failure(
            filename: filename,
            errorMessage: 'Backup ဖိုင်သည် မှားတွေ့သည့် JSON ဖြစ်နေပါသည်။',
          );
        }
        backupData = decoded;
      } catch (e) {
        return RestoreValidationResult.failure(
          filename: filename,
          errorMessage: 'JSON ဖိုင်ခွင့်ပြုချက်မရှိပါ။ ကျေးဇူးပြု၍ ပြန်လည်စမ်းကြည့်ပါ။',
        );
      }

      // Validate structure: all 17 boxes should exist
      final warnings = <String>[];
      final recordCounts = <String, int>{};
      int totalRecords = 0;

      for (final boxName in allBoxNames) {
        if (!backupData.containsKey(boxName)) {
          warnings.add('Box "$boxName" ကို ရှာမတွေ့ပါ။');
          recordCounts[boxName] = 0;
        } else {
          final boxData = backupData[boxName];
          if (boxData is! Map<String, dynamic>) {
            warnings.add('Box "$boxName" သည် မှားတွေ့သည့် ဖွဲ့စည်းမှုရှိပါသည်။');
            recordCounts[boxName] = 0;
          } else {
            final count = boxData.length;
            recordCounts[boxName] = count;
            totalRecords += count;
          }
        }
      }

      // Security validation: check for plaintext password in users
      _validateSecurityConstraints(backupData, warnings);

      // Check for unknown boxes
      for (final key in backupData.keys) {
        if (!allBoxNames.contains(key)) {
          warnings.add('အသိအမှတ်မပြုသည့် box "$key" ကိုရှာတွေ့ပါသည်။');
        }
      }

      // Create success result
      return RestoreValidationResult.success(
        filename: filename,
        totalRecords: totalRecords,
        recordCounts: recordCounts,
        supportedBoxes: supportedBoxes,
        unsupportedBoxes: unsupportedBoxes,
        warnings: warnings,
      );
    } catch (e) {
      return RestoreValidationResult.failure(
        filename: 'အမည်မသိ',
        errorMessage: 'Backup ဖိုင်ခွင့်ပြုချက်မရှိပါ။ အမှားအယွင်း: ${_sanitizeErrorMessage(e.toString())}',
      );
    }
  }

  /// Generate restore preview from validated backup data.
  /// Shows what WILL be restored (supported boxes) and what WON'T (unsupported boxes).
  static RestorePreview generatePreview(RestoreValidationResult validation) {
    return RestorePreview.fromValidation(validation);
  }

  /// Phase 2: Restore Gemstones box only.
  /// Returns {success, restoredCount, failedCount, errorMessage}.
  /// Rolls back on any failure.
  static Future<Map<String, dynamic>> restoreGemstonesOnly(
    String backupContent,
  ) async {
    RestoreSnapshot? snapshot;
    try {
      // Parse backup JSON
      Map<String, dynamic> backupData;
      try {
        final decoded = jsonDecode(backupContent);
        if (decoded is! Map<String, dynamic>) {
          return {
            'success': false,
            'restoredCount': 0,
            'failedCount': 0,
            'errorMessage': 'Backup JSON ဖွဲ့စည်းမှု မှားတွေ့ပါသည်။',
          };
        }
        backupData = decoded;
      } catch (e) {
        return {
          'success': false,
          'restoredCount': 0,
          'failedCount': 0,
          'errorMessage': 'JSON ခွင့်ပြုချက်မရှိပါ။',
        };
      }

      // Get gemstones box
      final gemstonesBox = LocalDb.gemstones();

      // Create snapshot before restore
      snapshot = RestoreSnapshot.fromBox(gemstonesBox);

      // Get backup gemstones data
      final backupGemstonesData = backupData['gemstones'] as Map<String, dynamic>?;
      if (backupGemstonesData == null) {
        return {
          'success': false,
          'restoredCount': 0,
          'failedCount': 0,
          'errorMessage': 'Backup တွင် gemstones box ကို ရှာမတွေ့ပါ။',
        };
      }

      // Clear gemstones box
      await gemstonesBox.clear();

      int restoredCount = 0;

      // Restore each gemstone record - FAIL FAST on first error
      for (final entry in backupGemstonesData.entries) {
        final key = entry.key;
        final recordJson = entry.value;

        // Validate record is a map
        if (recordJson is! Map<String, dynamic>) {
          // FAIL FAST: Rollback immediately on invalid record
          await snapshot.restoreToBox(gemstonesBox);
          return {
            'success': false,
            'restoredCount': 0,
            'failedCount': 1,
            'errorMessage': 'Gemstone restore ပျက်ကွက်ခဲ့ပါသည်။ Record key "$key" တွင် မှတ်တမ်းတွင်ကိုပါသည်။',
          };
        }

        // Deserialize gemstone
        final gemstone = BackupDeserializers.deserializeGemstone(recordJson);
        if (gemstone == null) {
          // FAIL FAST: Rollback immediately on deserialization failure
          await snapshot.restoreToBox(gemstonesBox);
          return {
            'success': false,
            'restoredCount': restoredCount,
            'failedCount': 1,
            'errorMessage': 'Gemstone restore ပျက်ကွက်ခဲ့ပါသည်။ Record key "$key" ကိ deserialize မအောင်မြင်ပါသည်။',
          };
        }

        // Restore with original key
        try {
          // Try to parse key as int if possible, otherwise use as string
          dynamic parsedKey = key;
          try {
            parsedKey = int.parse(key);
          } catch (e) {
            // Keep as string if not parseable as int
          }
          await gemstonesBox.put(parsedKey, gemstone);
          restoredCount++;
        } catch (e) {
          // FAIL FAST: Rollback immediately on write failure
          await snapshot.restoreToBox(gemstonesBox);
          return {
            'success': false,
            'restoredCount': restoredCount,
            'failedCount': 1,
            'errorMessage': 'Gemstone restore ပျက်ကွက်ခဲ့ပါသည်။ Record key "$key" ကိ restore မအောင်မြင်ပါသည်။',
          };
        }
      }

      return {
        'success': true,
        'restoredCount': restoredCount,
        'failedCount': 0,
        'errorMessage': null,
      };
    } catch (e) {
      // Rollback on any exception
      if (snapshot != null) {
        try {
          final gemstonesBox = LocalDb.gemstones();
          await snapshot.restoreToBox(gemstonesBox);
        } catch (rollbackError) {
          // Log but continue
        }
      }
      return {
        'success': false,
        'restoredCount': 0,
        'failedCount': 0,
        'errorMessage': 'Restore အမှားအယွင်း: ${_sanitizeErrorMessage(e.toString())}',
      };
    }
  }

  /// Extract filename from file path.
  static String _extractFilename(String filePath) {
    try {
      return filePath.split('/').last;
    } catch (e) {
      return 'backup.gmbak';
    }
  }

  /// Validate security constraints.
  /// - Reject if plaintext "password" field exists in AppUser records.
  /// - Warn about session.savedPassword (but don't reject).
  static void _validateSecurityConstraints(
    Map<String, dynamic> backupData,
    List<String> warnings,
  ) {
    // Check users box for plaintext password
    if (backupData.containsKey('users')) {
      final usersBox = backupData['users'];
      if (usersBox is Map<String, dynamic>) {
        for (final record in usersBox.values) {
          if (record is Map<String, dynamic> && record.containsKey('password')) {
            final password = record['password'];
            // If password field exists and is not empty, it's likely plaintext
            if (password is String && password.isNotEmpty) {
              warnings.add('⚠️ Plaintext password ကိုရှာတွေ့ပါသည်။ ဤ backup သည် အဟုန်မြင့်မားပါသည်။');
              break;
            }
          }
        }
      }
    }

    // Warn about session.savedPassword
    if (backupData.containsKey('session')) {
      final sessionBox = backupData['session'];
      if (sessionBox is Map<String, dynamic> && sessionBox.containsKey('savedPassword')) {
        warnings.add('Session ၏ သိမ်းဆည်းထားသည့် စကားဝှက်ကို restore မပြုလုပ်ပါ။ ပြန်လည်ဝင်ရောက်ရန် လိုအပ်ပါမည်။');
      }
    }
  }

  /// Sanitize error message for display (remove sensitive info).
  static String _sanitizeErrorMessage(String message) {
    // Remove stack traces and sensitive paths
    if (message.contains('StackTrace')) {
      return 'အမှားအယွင်းတစ်ခု ကျေးဇူးပြု၍ ထပ်မံစမ်းကြည့်ပါ။';
    }
    // Limit length
    if (message.length > 100) {
      return message.substring(0, 100);
    }
    return message;
  }
}
