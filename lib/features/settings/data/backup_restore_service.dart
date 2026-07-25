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

  /// Phase 3: Restore Sales box only.
  /// Returns {success, restoredCount, failedCount, errorMessage}.
  /// Rolls back on any failure.
  static Future<Map<String, dynamic>> restoreSalesOnly(
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

      // Get sales box
      final salesBox = LocalDb.sales();

      // Create snapshot before restore
      snapshot = RestoreSnapshot.fromBox(salesBox);

      // Get backup sales data
      final backupSalesData = backupData['sales'] as Map<String, dynamic>?;
      if (backupSalesData == null) {
        return {
          'success': false,
          'restoredCount': 0,
          'failedCount': 0,
          'errorMessage': 'Backup တွင် sales box ကို ရှာမတွေ့ပါ။',
        };
      }

      // Clear sales box
      await salesBox.clear();

      int restoredCount = 0;

      // Restore each sale record - FAIL FAST on first error
      for (final entry in backupSalesData.entries) {
        final key = entry.key;
        final recordJson = entry.value;

        // Validate record is a map
        if (recordJson is! Map<String, dynamic>) {
          // FAIL FAST: Rollback immediately on invalid record
          await snapshot.restoreToBox(salesBox);
          return {
            'success': false,
            'restoredCount': 0,
            'failedCount': 1,
            'errorMessage': 'Sale restore ပျက်ကွက်ခဲ့ပါသည်။ Record key "$key" တွင် မှတ်တမ်းတွင်ကိုပါသည်။',
          };
        }

        // Deserialize sale
        final sale = BackupDeserializers.deserializeSale(recordJson);
        if (sale == null) {
          // FAIL FAST: Rollback immediately on deserialization failure
          await snapshot.restoreToBox(salesBox);
          return {
            'success': false,
            'restoredCount': restoredCount,
            'failedCount': 1,
            'errorMessage': 'Sale restore ပျက်ကွက်ခဲ့ပါသည်။ Record key "$key" ကိ deserialize မအောင်မြင်ပါသည်။',
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
          await salesBox.put(parsedKey, sale);
          restoredCount++;
        } catch (e) {
          // FAIL FAST: Rollback immediately on write failure
          await snapshot.restoreToBox(salesBox);
          return {
            'success': false,
            'restoredCount': restoredCount,
            'failedCount': 1,
            'errorMessage': 'Sale restore ပျက်ကွက်ခဲ့ပါသည်။ Record key "$key" ကိ restore မအောင်မြင်ပါသည်။',
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
          final salesBox = LocalDb.sales();
          await snapshot.restoreToBox(salesBox);
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

  /// Phase 3: Atomic restore for both Gemstones and Sales boxes.
  /// ATOMIC: Both succeed together or both roll back together.
  /// Returns {success, restoredCount, failedCount, errorMessage}.
  /// If ANY failure: rolls back BOTH boxes to original state.
  static Future<Map<String, dynamic>> restoreGemstonesAndSalesOnly(
    String backupContent,
  ) async {
    RestoreSnapshot? gemstonesSnapshot;
    RestoreSnapshot? salesSnapshot;
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

      // Get both boxes
      final gemstonesBox = LocalDb.gemstones();
      final salesBox = LocalDb.sales();

      // ATOMIC: Create snapshots of BOTH boxes BEFORE any modification
      gemstonesSnapshot = RestoreSnapshot.fromBox(gemstonesBox);
      salesSnapshot = RestoreSnapshot.fromBox(salesBox);

      // Get backup data for both boxes
      final backupGemstonesData = backupData['gemstones'] as Map<String, dynamic>?;
      final backupSalesData = backupData['sales'] as Map<String, dynamic>?;

      if (backupGemstonesData == null || backupSalesData == null) {
        return {
          'success': false,
          'restoredCount': 0,
          'failedCount': 0,
          'errorMessage': 'Backup တွင် gemstones သို့မဟုတ် sales box ကို ရှာမတွေ့ပါ။',
        };
      }

      int gemstonesRestoredCount = 0;
      int salesRestoredCount = 0;

      // OPTIMIZE: Clear and restore Gemstones first to minimize empty-box window
      // Clear Gemstones box
      await gemstonesBox.clear();

      // RESTORE GEMSTONES - FAIL FAST
      for (final entry in backupGemstonesData.entries) {
        final key = entry.key;
        final recordJson = entry.value;

        if (recordJson is! Map<String, dynamic>) {
          // FAIL FAST: Rollback BOTH boxes immediately
          await gemstonesSnapshot.restoreToBox(gemstonesBox);
          await salesSnapshot.restoreToBox(salesBox);
          return {
            'success': false,
            'restoredCount': 0,
            'failedCount': 0,
            'errorMessage': 'Gemstone restore ပျက်ကွက်ခဲ့ပါသည်။ Record key "$key" တွင် မှတ်တမ်းတွင်ကိုပါသည်။',
          };
        }

        final gemstone = BackupDeserializers.deserializeGemstone(recordJson);
        if (gemstone == null) {
          // FAIL FAST: Rollback BOTH boxes immediately
          await gemstonesSnapshot.restoreToBox(gemstonesBox);
          await salesSnapshot.restoreToBox(salesBox);
          return {
            'success': false,
            'restoredCount': 0,
            'failedCount': 0,
            'errorMessage': 'Gemstone restore ပျက်ကွက်ခဲ့ပါသည်။ Record key "$key" ကိ deserialize မအောင်မြင်ပါသည်။',
          };
        }

        try {
          dynamic parsedKey = key;
          try {
            parsedKey = int.parse(key);
          } catch (e) {
            // Keep as string
          }
          await gemstonesBox.put(parsedKey, gemstone);
          gemstonesRestoredCount++;
        } catch (e) {
          // FAIL FAST: Rollback BOTH boxes immediately
          await gemstonesSnapshot.restoreToBox(gemstonesBox);
          await salesSnapshot.restoreToBox(salesBox);
          return {
            'success': false,
            'restoredCount': 0,
            'failedCount': 0,
            'errorMessage': 'Gemstone restore ပျက်ကွက်ခဲ့ပါသည်။ Record key "$key" ကိ restore မအောင်မြင်ပါသည်။',
          };
        }
      }

      // Gemstones restore succeeded, now clear and restore Sales
      // Clear Sales box
      await salesBox.clear();

      // RESTORE SALES - FAIL FAST
      for (final entry in backupSalesData.entries) {
        final key = entry.key;
        final recordJson = entry.value;

        if (recordJson is! Map<String, dynamic>) {
          // FAIL FAST: Rollback BOTH boxes immediately
          await gemstonesSnapshot.restoreToBox(gemstonesBox);
          await salesSnapshot.restoreToBox(salesBox);
          return {
            'success': false,
            'restoredCount': 0,
            'failedCount': 0,
            'errorMessage': 'Sale restore ပျက်ကွက်ခဲ့ပါသည်။ Record key "$key" တွင် မှတ်တမ်းတွင်ကိုပါသည်။',
          };
        }

        final sale = BackupDeserializers.deserializeSale(recordJson);
        if (sale == null) {
          // FAIL FAST: Rollback BOTH boxes immediately
          await gemstonesSnapshot.restoreToBox(gemstonesBox);
          await salesSnapshot.restoreToBox(salesBox);
          return {
            'success': false,
            'restoredCount': 0,
            'failedCount': 0,
            'errorMessage': 'Sale restore ပျက်ကွက်ခဲ့ပါသည်။ Record key "$key" ကိ deserialize မအောင်မြင်ပါသည်။',
          };
        }

        try {
          dynamic parsedKey = key;
          try {
            parsedKey = int.parse(key);
          } catch (e) {
            // Keep as string
          }
          await salesBox.put(parsedKey, sale);
          salesRestoredCount++;
        } catch (e) {
          // FAIL FAST: Rollback BOTH boxes immediately
          await gemstonesSnapshot.restoreToBox(gemstonesBox);
          await salesSnapshot.restoreToBox(salesBox);
          return {
            'success': false,
            'restoredCount': 0,
            'failedCount': 0,
            'errorMessage': 'Sale restore ပျက်ကွက်ခဲ့ပါသည်။ Record key "$key" ကိ restore မအောင်မြင်ပါသည်။',
          };
        }
      }

      // ATOMIC SUCCESS: Both boxes restored successfully
      return {
        'success': true,
        'restoredCount': gemstonesRestoredCount + salesRestoredCount,
        'failedCount': 0,
        'errorMessage': null,
        'gemstonesCount': gemstonesRestoredCount,
        'salesCount': salesRestoredCount,
      };
    } catch (e) {
      // Rollback BOTH boxes on any exception
      if (gemstonesSnapshot != null || salesSnapshot != null) {
        try {
          if (gemstonesSnapshot != null) {
            final gemstonesBox = LocalDb.gemstones();
            await gemstonesSnapshot.restoreToBox(gemstonesBox);
          }
          if (salesSnapshot != null) {
            final salesBox = LocalDb.sales();
            await salesSnapshot.restoreToBox(salesBox);
          }
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
