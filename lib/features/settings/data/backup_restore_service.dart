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
import 'media_backup_helper.dart';
import 'package:archive/archive.dart';
import 'dart:developer' as developer;

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
    developer.log('[DIAG-VALIDATE-ENTRY] validateBackupFileContent called: filename=$filename, contentLength=${content.length}');
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
        developer.log('[DIAG-JSON-DECODE-ERROR] JSON decode failed: ${e.runtimeType}: $e');
        developer.log('[DIAG-JSON-DECODE-CONTENT-START] Content starts with: ${content.substring(0, (content.length > 100 ? 100 : content.length))}');
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

  /// Phase 4: Atomic restore for Gemstones, Sales, and Customers boxes.
  /// ATOMIC: All succeed together or all roll back together.
  /// Returns {success, restoredCount, failedCount, errorMessage, gemstonesCount, salesCount, customersCount}.
  /// If ANY failure: rolls back ALL boxes to original state.
  static Future<Map<String, dynamic>> restoreGemstonesAndSalesAndCustomersOnly(
    String backupContent,
  ) async {
    RestoreSnapshot? gemstonesSnapshot;
    RestoreSnapshot? salesSnapshot;
    RestoreSnapshot? customersSnapshot;
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

      // Get all three boxes
      final gemstonesBox = LocalDb.gemstones();
      final salesBox = LocalDb.sales();
      final customersBox = LocalDb.customers();

      // ATOMIC: Create snapshots of ALL boxes BEFORE any modification
      gemstonesSnapshot = RestoreSnapshot.fromBox(gemstonesBox);
      salesSnapshot = RestoreSnapshot.fromBox(salesBox);
      customersSnapshot = RestoreSnapshot.fromBox(customersBox);

      // Get backup data for all boxes
      final backupGemstonesData = backupData['gemstones'] as Map<String, dynamic>?;
      final backupSalesData = backupData['sales'] as Map<String, dynamic>?;
      final backupCustomersData = backupData['customers'] as Map<String, dynamic>?;

      if (backupGemstonesData == null || backupSalesData == null || backupCustomersData == null) {
        return {
          'success': false,
          'restoredCount': 0,
          'failedCount': 0,
          'errorMessage': 'Backup တွင် gemstones သို့မဟုတ် sales သို့မဟုတ် customers box ကို ရှာမတွေ့ပါ။',
        };
      }

      int gemstonesRestoredCount = 0;
      int salesRestoredCount = 0;
      int customersRestoredCount = 0;

      // OPTIMIZE: Clear and restore Gemstones first
      // Clear Gemstones box
      await gemstonesBox.clear();

      // RESTORE GEMSTONES - FAIL FAST
      for (final entry in backupGemstonesData.entries) {
        final key = entry.key;
        final recordJson = entry.value;

        if (recordJson is! Map<String, dynamic>) {
          // FAIL FAST: Rollback ALL boxes immediately
          await gemstonesSnapshot.restoreToBox(gemstonesBox);
          await salesSnapshot.restoreToBox(salesBox);
          await customersSnapshot.restoreToBox(customersBox);
          return {
            'success': false,
            'restoredCount': 0,
            'failedCount': 0,
            'errorMessage': 'Gemstone restore ပျက်ကွက်ခဲ့ပါသည်။ Record key "$key" တွင် မှတ်တမ်းတွင်ကိုပါသည်။',
          };
        }

        final gemstone = BackupDeserializers.deserializeGemstone(recordJson);
        if (gemstone == null) {
          // FAIL FAST: Rollback ALL boxes immediately
          await gemstonesSnapshot.restoreToBox(gemstonesBox);
          await salesSnapshot.restoreToBox(salesBox);
          await customersSnapshot.restoreToBox(customersBox);
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
          // FAIL FAST: Rollback ALL boxes immediately
          await gemstonesSnapshot.restoreToBox(gemstonesBox);
          await salesSnapshot.restoreToBox(salesBox);
          await customersSnapshot.restoreToBox(customersBox);
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
          // FAIL FAST: Rollback ALL boxes immediately
          await gemstonesSnapshot.restoreToBox(gemstonesBox);
          await salesSnapshot.restoreToBox(salesBox);
          await customersSnapshot.restoreToBox(customersBox);
          return {
            'success': false,
            'restoredCount': 0,
            'failedCount': 0,
            'errorMessage': 'Sale restore ပျက်ကွက်ခဲ့ပါသည်။ Record key "$key" တွင် မှတ်တမ်းတွင်ကိုပါသည်။',
          };
        }

        final sale = BackupDeserializers.deserializeSale(recordJson);
        if (sale == null) {
          // FAIL FAST: Rollback ALL boxes immediately
          await gemstonesSnapshot.restoreToBox(gemstonesBox);
          await salesSnapshot.restoreToBox(salesBox);
          await customersSnapshot.restoreToBox(customersBox);
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
          // FAIL FAST: Rollback ALL boxes immediately
          await gemstonesSnapshot.restoreToBox(gemstonesBox);
          await salesSnapshot.restoreToBox(salesBox);
          await customersSnapshot.restoreToBox(customersBox);
          return {
            'success': false,
            'restoredCount': 0,
            'failedCount': 0,
            'errorMessage': 'Sale restore ပျက်ကွက်ခဲ့ပါသည်။ Record key "$key" ကိ restore မအောင်မြင်ပါသည်။',
          };
        }
      }

      // Sales restore succeeded, now clear and restore Customers
      // Clear Customers box
      await customersBox.clear();

      // RESTORE CUSTOMERS - FAIL FAST
      for (final entry in backupCustomersData.entries) {
        final key = entry.key;
        final recordJson = entry.value;

        if (recordJson is! Map<String, dynamic>) {
          // FAIL FAST: Rollback ALL boxes immediately
          await gemstonesSnapshot.restoreToBox(gemstonesBox);
          await salesSnapshot.restoreToBox(salesBox);
          await customersSnapshot.restoreToBox(customersBox);
          return {
            'success': false,
            'restoredCount': 0,
            'failedCount': 0,
            'errorMessage': 'Customer restore ပျက်ကွက်ခဲ့ပါသည်။ Record key "$key" တွင် မှတ်တမ်းတွင်ကိုပါသည်။',
          };
        }

        final customer = BackupDeserializers.deserializeCustomer(recordJson);
        if (customer == null) {
          // FAIL FAST: Rollback ALL boxes immediately
          await gemstonesSnapshot.restoreToBox(gemstonesBox);
          await salesSnapshot.restoreToBox(salesBox);
          await customersSnapshot.restoreToBox(customersBox);
          return {
            'success': false,
            'restoredCount': 0,
            'failedCount': 0,
            'errorMessage': 'Customer restore ပျက်ကွက်ခဲ့ပါသည်။ Record key "$key" ကိ deserialize မအောင်မြင်ပါသည်။',
          };
        }

        try {
          dynamic parsedKey = key;
          try {
            parsedKey = int.parse(key);
          } catch (e) {
            // Keep as string
          }
          await customersBox.put(parsedKey, customer);
          customersRestoredCount++;
        } catch (e) {
          // FAIL FAST: Rollback ALL boxes immediately
          await gemstonesSnapshot.restoreToBox(gemstonesBox);
          await salesSnapshot.restoreToBox(salesBox);
          await customersSnapshot.restoreToBox(customersBox);
          return {
            'success': false,
            'restoredCount': 0,
            'failedCount': 0,
            'errorMessage': 'Customer restore ပျက်ကွက်ခဲ့ပါသည်။ Record key "$key" ကိ restore မအောင်မြင်ပါသည်။',
          };
        }
      }

      // ATOMIC SUCCESS: All boxes restored successfully
      return {
        'success': true,
        'restoredCount': gemstonesRestoredCount + salesRestoredCount + customersRestoredCount,
        'failedCount': 0,
        'errorMessage': null,
        'gemstonesCount': gemstonesRestoredCount,
        'salesCount': salesRestoredCount,
        'customersCount': customersRestoredCount,
      };
    } catch (e) {
      // Rollback ALL boxes on any exception
      if (gemstonesSnapshot != null || salesSnapshot != null || customersSnapshot != null) {
        try {
          if (gemstonesSnapshot != null) {
            final gemstonesBox = LocalDb.gemstones();
            await gemstonesSnapshot.restoreToBox(gemstonesBox);
          }
          if (salesSnapshot != null) {
            final salesBox = LocalDb.sales();
            await salesSnapshot.restoreToBox(salesBox);
          }
          if (customersSnapshot != null) {
            final customersBox = LocalDb.customers();
            await customersSnapshot.restoreToBox(customersBox);
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

  /// Restore Gemstones, Sales, Customers, and Expenses atomically.
  /// Creates snapshots of all four boxes BEFORE any modification.
  /// If ANY record fails in ANY box, rolls back ALL boxes immediately.
  /// Returns combined result with breakdown counts.
  static Future<Map<String, dynamic>> restoreGemstonesAndSalesAndCustomersAndExpensesOnly(
    String backupContent,
  ) async {
    try {
      // Parse backup JSON
      final backupData = jsonDecode(backupContent) as Map<String, dynamic>?;
      if (backupData == null) {
        return {
          'success': false,
          'restoredCount': 0,
          'failedCount': 0,
          'errorMessage': 'Backup JSON parse ပျက်ကွက်ခဲ့ပါသည်။',
        };
      }

      // Extract box data from backup
      final backupGemstonesData = backupData['gemstones'] as Map<String, dynamic>? ?? {};
      final backupSalesData = backupData['sales'] as Map<String, dynamic>? ?? {};
      final backupCustomersData = backupData['customers'] as Map<String, dynamic>? ?? {};
      final backupExpensesData = backupData['expenses'] as Map<String, dynamic>? ?? {};

      // Get all four boxes
      final gemstonesBox = LocalDb.gemstones();
      final salesBox = LocalDb.sales();
      final customersBox = LocalDb.customers();
      final expensesBox = LocalDb.expenses();

      // CREATE SNAPSHOTS OF ALL FOUR BOXES BEFORE ANY MODIFICATION
      final gemstonesSnapshot = RestoreSnapshot.fromBox(gemstonesBox);
      final salesSnapshot = RestoreSnapshot.fromBox(salesBox);
      final customersSnapshot = RestoreSnapshot.fromBox(customersBox);
      final expensesSnapshot = RestoreSnapshot.fromBox(expensesBox);

      int gemstonesRestoredCount = 0;
      int salesRestoredCount = 0;
      int customersRestoredCount = 0;
      int expensesRestoredCount = 0;

      // RESTORE GEMSTONES - FAIL FAST
      await gemstonesBox.clear();
      for (final entry in backupGemstonesData.entries) {
        final key = entry.key;
        final recordJson = entry.value;

        if (recordJson is! Map<String, dynamic>) {
          await gemstonesSnapshot.restoreToBox(gemstonesBox);
          await salesSnapshot.restoreToBox(salesBox);
          await customersSnapshot.restoreToBox(customersBox);
          await expensesSnapshot.restoreToBox(expensesBox);
          return {
            'success': false,
            'restoredCount': 0,
            'failedCount': 0,
            'errorMessage': 'Gemstone restore ပျက်ကွက်ခဲ့ပါသည်။ Record key "$key" တွင် မှတ်တမ်းတွင်ကိုပါသည်။',
          };
        }

        final gemstone = BackupDeserializers.deserializeGemstone(recordJson);
        if (gemstone == null) {
          await gemstonesSnapshot.restoreToBox(gemstonesBox);
          await salesSnapshot.restoreToBox(salesBox);
          await customersSnapshot.restoreToBox(customersBox);
          await expensesSnapshot.restoreToBox(expensesBox);
          return {
            'success': false,
            'restoredCount': 0,
            'failedCount': 0,
            'errorMessage': 'Gemstone restore ပျက်ကွက်ခဲ့ပါသည်။ Record key "$key" ကိ deserialize မအောင်မြင်ပါသည်။',
          };
        }

        try {
          // Restore with original key (int or string)
          final originalKey = int.tryParse(key) ?? key;
          await gemstonesBox.put(originalKey, gemstone);
          gemstonesRestoredCount++;
        } catch (e) {
          await gemstonesSnapshot.restoreToBox(gemstonesBox);
          await salesSnapshot.restoreToBox(salesBox);
          await customersSnapshot.restoreToBox(customersBox);
          await expensesSnapshot.restoreToBox(expensesBox);
          return {
            'success': false,
            'restoredCount': 0,
            'failedCount': 0,
            'errorMessage': 'Gemstone restore ပျက်ကွက်ခဲ့ပါသည်။ Record key "$key" ကိ restore မအောင်မြင်ပါသည်။',
          };
        }
      }

      // RESTORE SALES - FAIL FAST
      await salesBox.clear();
      for (final entry in backupSalesData.entries) {
        final key = entry.key;
        final recordJson = entry.value;

        if (recordJson is! Map<String, dynamic>) {
          await gemstonesSnapshot.restoreToBox(gemstonesBox);
          await salesSnapshot.restoreToBox(salesBox);
          await customersSnapshot.restoreToBox(customersBox);
          await expensesSnapshot.restoreToBox(expensesBox);
          return {
            'success': false,
            'restoredCount': 0,
            'failedCount': 0,
            'errorMessage': 'Sale restore ပျက်ကွက်ခဲ့ပါသည်။ Record key "$key" တွင် မှတ်တမ်းတွင်ကိုပါသည်။',
          };
        }

        final sale = BackupDeserializers.deserializeSale(recordJson);
        if (sale == null) {
          await gemstonesSnapshot.restoreToBox(gemstonesBox);
          await salesSnapshot.restoreToBox(salesBox);
          await customersSnapshot.restoreToBox(customersBox);
          await expensesSnapshot.restoreToBox(expensesBox);
          return {
            'success': false,
            'restoredCount': 0,
            'failedCount': 0,
            'errorMessage': 'Sale restore ပျက်ကွက်ခဲ့ပါသည်။ Record key "$key" ကိ deserialize မအောင်မြင်ပါသည်။',
          };
        }

        try {
          final originalKey = int.tryParse(key) ?? key;
          await salesBox.put(originalKey, sale);
          salesRestoredCount++;
        } catch (e) {
          await gemstonesSnapshot.restoreToBox(gemstonesBox);
          await salesSnapshot.restoreToBox(salesBox);
          await customersSnapshot.restoreToBox(customersBox);
          await expensesSnapshot.restoreToBox(expensesBox);
          return {
            'success': false,
            'restoredCount': 0,
            'failedCount': 0,
            'errorMessage': 'Sale restore ပျက်ကွက်ခဲ့ပါသည်။ Record key "$key" ကိ restore မအောင်မြင်ပါသည်။',
          };
        }
      }

      // RESTORE CUSTOMERS - FAIL FAST
      await customersBox.clear();
      for (final entry in backupCustomersData.entries) {
        final key = entry.key;
        final recordJson = entry.value;

        if (recordJson is! Map<String, dynamic>) {
          await gemstonesSnapshot.restoreToBox(gemstonesBox);
          await salesSnapshot.restoreToBox(salesBox);
          await customersSnapshot.restoreToBox(customersBox);
          await expensesSnapshot.restoreToBox(expensesBox);
          return {
            'success': false,
            'restoredCount': 0,
            'failedCount': 0,
            'errorMessage': 'Customer restore ပျက်ကွက်ခဲ့ပါသည်။ Record key "$key" တွင် မှတ်တမ်းတွင်ကိုပါသည်။',
          };
        }

        final customer = BackupDeserializers.deserializeCustomer(recordJson);
        if (customer == null) {
          await gemstonesSnapshot.restoreToBox(gemstonesBox);
          await salesSnapshot.restoreToBox(salesBox);
          await customersSnapshot.restoreToBox(customersBox);
          await expensesSnapshot.restoreToBox(expensesBox);
          return {
            'success': false,
            'restoredCount': 0,
            'failedCount': 0,
            'errorMessage': 'Customer restore ပျက်ကွက်ခဲ့ပါသည်။ Record key "$key" ကိ deserialize မအောင်မြင်ပါသည်။',
          };
        }

        try {
          final originalKey = int.tryParse(key) ?? key;
          await customersBox.put(originalKey, customer);
          customersRestoredCount++;
        } catch (e) {
          await gemstonesSnapshot.restoreToBox(gemstonesBox);
          await salesSnapshot.restoreToBox(salesBox);
          await customersSnapshot.restoreToBox(customersBox);
          await expensesSnapshot.restoreToBox(expensesBox);
          return {
            'success': false,
            'restoredCount': 0,
            'failedCount': 0,
            'errorMessage': 'Customer restore ပျက်ကွက်ခဲ့ပါသည်။ Record key "$key" ကိ restore မအောင်မြင်ပါသည်။',
          };
        }
      }

      // RESTORE EXPENSES - FAIL FAST
      await expensesBox.clear();
      for (final entry in backupExpensesData.entries) {
        final key = entry.key;
        final recordJson = entry.value;

        if (recordJson is! Map<String, dynamic>) {
          await gemstonesSnapshot.restoreToBox(gemstonesBox);
          await salesSnapshot.restoreToBox(salesBox);
          await customersSnapshot.restoreToBox(customersBox);
          await expensesSnapshot.restoreToBox(expensesBox);
          return {
            'success': false,
            'restoredCount': 0,
            'failedCount': 0,
            'errorMessage': 'Expense restore ပျက်ကွက်ခဲ့ပါသည်။ Record key "$key" တွင် မှတ်တမ်းတွင်ကိုပါသည်။',
          };
        }

        final expense = BackupDeserializers.deserializeExpense(recordJson);
        if (expense == null) {
          await gemstonesSnapshot.restoreToBox(gemstonesBox);
          await salesSnapshot.restoreToBox(salesBox);
          await customersSnapshot.restoreToBox(customersBox);
          await expensesSnapshot.restoreToBox(expensesBox);
          return {
            'success': false,
            'restoredCount': 0,
            'failedCount': 0,
            'errorMessage': 'Expense restore ပျက်ကွက်ခဲ့ပါသည်။ Record key "$key" ကိ deserialize မအောင်မြင်ပါသည်။',
          };
        }

        try {
          final originalKey = int.tryParse(key) ?? key;
          await expensesBox.put(originalKey, expense);
          expensesRestoredCount++;
        } catch (e) {
          await gemstonesSnapshot.restoreToBox(gemstonesBox);
          await salesSnapshot.restoreToBox(salesBox);
          await customersSnapshot.restoreToBox(customersBox);
          await expensesSnapshot.restoreToBox(expensesBox);
          return {
            'success': false,
            'restoredCount': 0,
            'failedCount': 0,
            'errorMessage': 'Expense restore ပျက်ကွက်ခဲ့ပါသည်။ Record key "$key" ကိ restore မအောင်မြင်ပါသည်။',
          };
        }
      }

      // All boxes restored successfully
      final totalRestored = gemstonesRestoredCount + salesRestoredCount + customersRestoredCount + expensesRestoredCount;
      return {
        'success': true,
        'restoredCount': totalRestored,
        'gemstonesCount': gemstonesRestoredCount,
        'salesCount': salesRestoredCount,
        'customersCount': customersRestoredCount,
        'expensesCount': expensesRestoredCount,
        'failedCount': 0,
      };
    } catch (e) {
      return {
        'success': false,
        'restoredCount': 0,
        'failedCount': 0,
        'errorMessage': 'Restore အမှားအယွင်း: ${_sanitizeErrorMessage(e.toString())}',
      };
    }
  }

  /// Restore Gemstones, Sales, Customers, Expenses, and Workers atomically.
  /// Creates snapshots of all five boxes BEFORE any modification.
  /// If ANY record fails in ANY box, rolls back ALL boxes immediately.
  /// Returns combined result with breakdown counts.
  static Future<Map<String, dynamic>> restoreGemstonesAndSalesAndCustomersAndExpensesAndWorkersOnly(
    String backupContent,
  ) async {
    try {
      // Parse backup JSON
      final backupData = jsonDecode(backupContent) as Map<String, dynamic>?;
      if (backupData == null) {
        return {
          'success': false,
          'restoredCount': 0,
          'failedCount': 0,
          'errorMessage': 'Backup JSON parse ပျက်ကွက်ခဲ့ပါသည်။',
        };
      }

      // Extract box data from backup
      final backupGemstonesData = backupData['gemstones'] as Map<String, dynamic>? ?? {};
      final backupSalesData = backupData['sales'] as Map<String, dynamic>? ?? {};
      final backupCustomersData = backupData['customers'] as Map<String, dynamic>? ?? {};
      final backupExpensesData = backupData['expenses'] as Map<String, dynamic>? ?? {};
      final backupWorkersData = backupData['workers'] as Map<String, dynamic>? ?? {};

      // Get all five boxes
      final gemstonesBox = LocalDb.gemstones();
      final salesBox = LocalDb.sales();
      final customersBox = LocalDb.customers();
      final expensesBox = LocalDb.expenses();
      final workersBox = LocalDb.workers();

      // CREATE SNAPSHOTS OF ALL FIVE BOXES BEFORE ANY MODIFICATION
      final gemstonesSnapshot = RestoreSnapshot.fromBox(gemstonesBox);
      final salesSnapshot = RestoreSnapshot.fromBox(salesBox);
      final customersSnapshot = RestoreSnapshot.fromBox(customersBox);
      final expensesSnapshot = RestoreSnapshot.fromBox(expensesBox);
      final workersSnapshot = RestoreSnapshot.fromBox(workersBox);

      int gemstonesRestoredCount = 0;
      int salesRestoredCount = 0;
      int customersRestoredCount = 0;
      int expensesRestoredCount = 0;
      int workersRestoredCount = 0;

      // RESTORE GEMSTONES - FAIL FAST
      await gemstonesBox.clear();
      for (final entry in backupGemstonesData.entries) {
        final key = entry.key;
        final recordJson = entry.value;

        if (recordJson is! Map<String, dynamic>) {
          await gemstonesSnapshot.restoreToBox(gemstonesBox);
          await salesSnapshot.restoreToBox(salesBox);
          await customersSnapshot.restoreToBox(customersBox);
          await expensesSnapshot.restoreToBox(expensesBox);
          await workersSnapshot.restoreToBox(workersBox);
          return {
            'success': false,
            'restoredCount': 0,
            'failedCount': 0,
            'errorMessage': 'Gemstone restore ပျက်ကွက်ခဲ့ပါသည်။ Record key "$key" တွင် မှတ်တမ်းတွင်ကိုပါသည်။',
          };
        }

        final gemstone = BackupDeserializers.deserializeGemstone(recordJson);
        if (gemstone == null) {
          await gemstonesSnapshot.restoreToBox(gemstonesBox);
          await salesSnapshot.restoreToBox(salesBox);
          await customersSnapshot.restoreToBox(customersBox);
          await expensesSnapshot.restoreToBox(expensesBox);
          await workersSnapshot.restoreToBox(workersBox);
          return {
            'success': false,
            'restoredCount': 0,
            'failedCount': 0,
            'errorMessage': 'Gemstone restore ပျက်ကွက်ခဲ့ပါသည်။ Record key "$key" ကိ deserialize မအောင်မြင်ပါသည်။',
          };
        }

        try {
          final originalKey = int.tryParse(key) ?? key;
          await gemstonesBox.put(originalKey, gemstone);
          gemstonesRestoredCount++;
        } catch (e) {
          await gemstonesSnapshot.restoreToBox(gemstonesBox);
          await salesSnapshot.restoreToBox(salesBox);
          await customersSnapshot.restoreToBox(customersBox);
          await expensesSnapshot.restoreToBox(expensesBox);
          await workersSnapshot.restoreToBox(workersBox);
          return {
            'success': false,
            'restoredCount': 0,
            'failedCount': 0,
            'errorMessage': 'Gemstone restore ပျက်ကွက်ခဲ့ပါသည်။ Record key "$key" ကိ restore မအောင်မြင်ပါသည်။',
          };
        }
      }

      // RESTORE SALES - FAIL FAST
      await salesBox.clear();
      for (final entry in backupSalesData.entries) {
        final key = entry.key;
        final recordJson = entry.value;

        if (recordJson is! Map<String, dynamic>) {
          await gemstonesSnapshot.restoreToBox(gemstonesBox);
          await salesSnapshot.restoreToBox(salesBox);
          await customersSnapshot.restoreToBox(customersBox);
          await expensesSnapshot.restoreToBox(expensesBox);
          await workersSnapshot.restoreToBox(workersBox);
          return {
            'success': false,
            'restoredCount': 0,
            'failedCount': 0,
            'errorMessage': 'Sale restore ပျက်ကွက်ခဲ့ပါသည်။ Record key "$key" တွင် မှတ်တမ်းတွင်ကိုပါသည်။',
          };
        }

        final sale = BackupDeserializers.deserializeSale(recordJson);
        if (sale == null) {
          await gemstonesSnapshot.restoreToBox(gemstonesBox);
          await salesSnapshot.restoreToBox(salesBox);
          await customersSnapshot.restoreToBox(customersBox);
          await expensesSnapshot.restoreToBox(expensesBox);
          await workersSnapshot.restoreToBox(workersBox);
          return {
            'success': false,
            'restoredCount': 0,
            'failedCount': 0,
            'errorMessage': 'Sale restore ပျက်ကွက်ခဲ့ပါသည်။ Record key "$key" ကိ deserialize မအောင်မြင်ပါသည်။',
          };
        }

        try {
          final originalKey = int.tryParse(key) ?? key;
          await salesBox.put(originalKey, sale);
          salesRestoredCount++;
        } catch (e) {
          await gemstonesSnapshot.restoreToBox(gemstonesBox);
          await salesSnapshot.restoreToBox(salesBox);
          await customersSnapshot.restoreToBox(customersBox);
          await expensesSnapshot.restoreToBox(expensesBox);
          await workersSnapshot.restoreToBox(workersBox);
          return {
            'success': false,
            'restoredCount': 0,
            'failedCount': 0,
            'errorMessage': 'Sale restore ပျက်ကွက်ခဲ့ပါသည်။ Record key "$key" ကိ restore မအောင်မြင်ပါသည်။',
          };
        }
      }

      // RESTORE CUSTOMERS - FAIL FAST
      await customersBox.clear();
      for (final entry in backupCustomersData.entries) {
        final key = entry.key;
        final recordJson = entry.value;

        if (recordJson is! Map<String, dynamic>) {
          await gemstonesSnapshot.restoreToBox(gemstonesBox);
          await salesSnapshot.restoreToBox(salesBox);
          await customersSnapshot.restoreToBox(customersBox);
          await expensesSnapshot.restoreToBox(expensesBox);
          await workersSnapshot.restoreToBox(workersBox);
          return {
            'success': false,
            'restoredCount': 0,
            'failedCount': 0,
            'errorMessage': 'Customer restore ပျက်ကွက်ခဲ့ပါသည်။ Record key "$key" တွင် မှတ်တမ်းတွင်ကိုပါသည်။',
          };
        }

        final customer = BackupDeserializers.deserializeCustomer(recordJson);
        if (customer == null) {
          await gemstonesSnapshot.restoreToBox(gemstonesBox);
          await salesSnapshot.restoreToBox(salesBox);
          await customersSnapshot.restoreToBox(customersBox);
          await expensesSnapshot.restoreToBox(expensesBox);
          await workersSnapshot.restoreToBox(workersBox);
          return {
            'success': false,
            'restoredCount': 0,
            'failedCount': 0,
            'errorMessage': 'Customer restore ပျက်ကွက်ခဲ့ပါသည်။ Record key "$key" ကိ deserialize မအောင်မြင်ပါသည်။',
          };
        }

        try {
          final originalKey = int.tryParse(key) ?? key;
          await customersBox.put(originalKey, customer);
          customersRestoredCount++;
        } catch (e) {
          await gemstonesSnapshot.restoreToBox(gemstonesBox);
          await salesSnapshot.restoreToBox(salesBox);
          await customersSnapshot.restoreToBox(customersBox);
          await expensesSnapshot.restoreToBox(expensesBox);
          await workersSnapshot.restoreToBox(workersBox);
          return {
            'success': false,
            'restoredCount': 0,
            'failedCount': 0,
            'errorMessage': 'Customer restore ပျက်ကွက်ခဲ့ပါသည်။ Record key "$key" ကိ restore မအောင်မြင်ပါသည်။',
          };
        }
      }

      // RESTORE EXPENSES - FAIL FAST
      await expensesBox.clear();
      for (final entry in backupExpensesData.entries) {
        final key = entry.key;
        final recordJson = entry.value;

        if (recordJson is! Map<String, dynamic>) {
          await gemstonesSnapshot.restoreToBox(gemstonesBox);
          await salesSnapshot.restoreToBox(salesBox);
          await customersSnapshot.restoreToBox(customersBox);
          await expensesSnapshot.restoreToBox(expensesBox);
          await workersSnapshot.restoreToBox(workersBox);
          return {
            'success': false,
            'restoredCount': 0,
            'failedCount': 0,
            'errorMessage': 'Expense restore ပျက်ကွက်ခဲ့ပါသည်။ Record key "$key" တွင် မှတ်တမ်းတွင်ကိုပါသည်။',
          };
        }

        final expense = BackupDeserializers.deserializeExpense(recordJson);
        if (expense == null) {
          await gemstonesSnapshot.restoreToBox(gemstonesBox);
          await salesSnapshot.restoreToBox(salesBox);
          await customersSnapshot.restoreToBox(customersBox);
          await expensesSnapshot.restoreToBox(expensesBox);
          await workersSnapshot.restoreToBox(workersBox);
          return {
            'success': false,
            'restoredCount': 0,
            'failedCount': 0,
            'errorMessage': 'Expense restore ပျက်ကွက်ခဲ့ပါသည်။ Record key "$key" ကိ deserialize မအောင်မြင်ပါသည်။',
          };
        }

        try {
          final originalKey = int.tryParse(key) ?? key;
          await expensesBox.put(originalKey, expense);
          expensesRestoredCount++;
        } catch (e) {
          await gemstonesSnapshot.restoreToBox(gemstonesBox);
          await salesSnapshot.restoreToBox(salesBox);
          await customersSnapshot.restoreToBox(customersBox);
          await expensesSnapshot.restoreToBox(expensesBox);
          await workersSnapshot.restoreToBox(workersBox);
          return {
            'success': false,
            'restoredCount': 0,
            'failedCount': 0,
            'errorMessage': 'Expense restore ပျက်ကွက်ခဲ့ပါသည်။ Record key "$key" ကိ restore မအောင်မြင်ပါသည်။',
          };
        }
      }

      // RESTORE WORKERS - FAIL FAST
      await workersBox.clear();
      for (final entry in backupWorkersData.entries) {
        final key = entry.key;
        final recordJson = entry.value;

        if (recordJson is! Map<String, dynamic>) {
          await gemstonesSnapshot.restoreToBox(gemstonesBox);
          await salesSnapshot.restoreToBox(salesBox);
          await customersSnapshot.restoreToBox(customersBox);
          await expensesSnapshot.restoreToBox(expensesBox);
          await workersSnapshot.restoreToBox(workersBox);
          return {
            'success': false,
            'restoredCount': 0,
            'failedCount': 0,
            'errorMessage': 'Worker restore ပျက်ကွက်ခဲ့ပါသည်။ Record key "$key" တွင် မှတ်တမ်းတွင်ကိုပါသည်။',
          };
        }

        final worker = BackupDeserializers.deserializeWorker(recordJson);
        if (worker == null) {
          await gemstonesSnapshot.restoreToBox(gemstonesBox);
          await salesSnapshot.restoreToBox(salesBox);
          await customersSnapshot.restoreToBox(customersBox);
          await expensesSnapshot.restoreToBox(expensesBox);
          await workersSnapshot.restoreToBox(workersBox);
          return {
            'success': false,
            'restoredCount': 0,
            'failedCount': 0,
            'errorMessage': 'Worker restore ပျက်ကွက်ခဲ့ပါသည်။ Record key "$key" ကိ deserialize မအောင်မြင်ပါသည်။',
          };
        }

        try {
          final originalKey = int.tryParse(key) ?? key;
          await workersBox.put(originalKey, worker);
          workersRestoredCount++;
        } catch (e) {
          await gemstonesSnapshot.restoreToBox(gemstonesBox);
          await salesSnapshot.restoreToBox(salesBox);
          await customersSnapshot.restoreToBox(customersBox);
          await expensesSnapshot.restoreToBox(expensesBox);
          await workersSnapshot.restoreToBox(workersBox);
          return {
            'success': false,
            'restoredCount': 0,
            'failedCount': 0,
            'errorMessage': 'Worker restore ပျက်ကွက်ခဲ့ပါသည်။ Record key "$key" ကိ restore မအောင်မြင်ပါသည်။',
          };
        }
      }

      // All boxes restored successfully
      final totalRestored = gemstonesRestoredCount + salesRestoredCount + customersRestoredCount + expensesRestoredCount + workersRestoredCount;
      return {
        'success': true,
        'restoredCount': totalRestored,
        'gemstonesCount': gemstonesRestoredCount,
        'salesCount': salesRestoredCount,
        'customersCount': customersRestoredCount,
        'expensesCount': expensesRestoredCount,
        'workersCount': workersRestoredCount,
        'failedCount': 0,
      };
    } catch (e) {
      return {
        'success': false,
        'restoredCount': 0,
        'failedCount': 0,
        'errorMessage': 'Restore အမှားအယွင်း: ${_sanitizeErrorMessage(e.toString())}',
      };
    }
  }

  /// Restore all 6 boxes atomically: Gemstones, Sales, Customers, Expenses, Workers, and Broker Consignments.
  static Future<Map<String, dynamic>> restoreGemstonesAndSalesAndCustomersAndExpensesAndWorkersAndBrokerConsignmentsOnly(
    String backupContent,
  ) async {
    try {
      final backupData = jsonDecode(backupContent) as Map<String, dynamic>?;
      if (backupData == null) {
        return {
          'success': false,
          'restoredCount': 0,
          'failedCount': 0,
          'errorMessage': 'Backup JSON parse ပျက်ကွက်ခဲ့ပါသည်။',
        };
      }

      final backupGemstonesData = backupData['gemstones'] as Map<String, dynamic>? ?? {};
      final backupSalesData = backupData['sales'] as Map<String, dynamic>? ?? {};
      final backupCustomersData = backupData['customers'] as Map<String, dynamic>? ?? {};
      final backupExpensesData = backupData['expenses'] as Map<String, dynamic>? ?? {};
      final backupWorkersData = backupData['workers'] as Map<String, dynamic>? ?? {};
      final backupBrokerProfilesData = backupData['brokerProfiles'] as Map<String, dynamic>? ?? {};
      final backupBrokerConsignmentsData = backupData['brokerConsignments'] as Map<String, dynamic>? ?? {};

      final gemstonesBox = LocalDb.gemstones();
      final salesBox = LocalDb.sales();
      final customersBox = LocalDb.customers();
      final expensesBox = LocalDb.expenses();
      final workersBox = LocalDb.workers();
      final brokerProfilesBox = Hive.box<BrokerProfile>(LocalDb.brokerProfilesBox);
      final brokerConsignmentsBox = LocalDb.brokerConsignments();

      // CREATE SNAPSHOTS OF ALL SEVEN BOXES
      final gemstonesSnapshot = RestoreSnapshot.fromBox(gemstonesBox);
      final salesSnapshot = RestoreSnapshot.fromBox(salesBox);
      final customersSnapshot = RestoreSnapshot.fromBox(customersBox);
      final expensesSnapshot = RestoreSnapshot.fromBox(expensesBox);
      final workersSnapshot = RestoreSnapshot.fromBox(workersBox);
      final brokerProfilesSnapshot = RestoreSnapshot.fromBox(brokerProfilesBox);
      final brokerConsignmentsSnapshot = RestoreSnapshot.fromBox(brokerConsignmentsBox);

      int gemstonesRestoredCount = 0;
      int salesRestoredCount = 0;
      int customersRestoredCount = 0;
      int expensesRestoredCount = 0;
      int workersRestoredCount = 0;
      int brokerProfilesRestoredCount = 0;
      int brokerConsignmentsRestoredCount = 0;

      // RESTORE GEMSTONES
      await gemstonesBox.clear();
      for (final entry in backupGemstonesData.entries) {
        final key = entry.key;
        final recordJson = entry.value;
        if (recordJson is! Map<String, dynamic>) {
          await gemstonesSnapshot.restoreToBox(gemstonesBox);
          await salesSnapshot.restoreToBox(salesBox);
          await customersSnapshot.restoreToBox(customersBox);
          await expensesSnapshot.restoreToBox(expensesBox);
          await workersSnapshot.restoreToBox(workersBox);
          await brokerConsignmentsSnapshot.restoreToBox(brokerConsignmentsBox);
          return {'success': false, 'restoredCount': 0, 'failedCount': 0, 'errorMessage': 'Gemstone restore ပျက်ကွက်ခဲ့ပါသည်။ Record key "$key" တွင် မှတ်တမ်းတွင်ကိုပါသည်။'};
        }
        final gemstone = BackupDeserializers.deserializeGemstone(recordJson);
        if (gemstone == null) {
          await gemstonesSnapshot.restoreToBox(gemstonesBox);
          await salesSnapshot.restoreToBox(salesBox);
          await customersSnapshot.restoreToBox(customersBox);
          await expensesSnapshot.restoreToBox(expensesBox);
          await workersSnapshot.restoreToBox(workersBox);
          await brokerConsignmentsSnapshot.restoreToBox(brokerConsignmentsBox);
          return {'success': false, 'restoredCount': 0, 'failedCount': 0, 'errorMessage': 'Gemstone restore ပျက်ကွက်ခဲ့ပါသည်။ Record key "$key" ကိ deserialize မအောင်မြင်ပါသည်။'};
        }
        try {
          final originalKey = int.tryParse(key) ?? key;
          await gemstonesBox.put(originalKey, gemstone);
          gemstonesRestoredCount++;
        } catch (e) {
          await gemstonesSnapshot.restoreToBox(gemstonesBox);
          await salesSnapshot.restoreToBox(salesBox);
          await customersSnapshot.restoreToBox(customersBox);
          await expensesSnapshot.restoreToBox(expensesBox);
          await workersSnapshot.restoreToBox(workersBox);
          await brokerConsignmentsSnapshot.restoreToBox(brokerConsignmentsBox);
          return {'success': false, 'restoredCount': 0, 'failedCount': 0, 'errorMessage': 'Gemstone restore ပျက်ကွက်ခဲ့ပါသည်။ Record key "$key" ကိ restore မအောင်မြင်ပါသည်။'};
        }
      }

      // RESTORE SALES
      await salesBox.clear();
      for (final entry in backupSalesData.entries) {
        final key = entry.key;
        final recordJson = entry.value;
        if (recordJson is! Map<String, dynamic>) {
          await gemstonesSnapshot.restoreToBox(gemstonesBox);
          await salesSnapshot.restoreToBox(salesBox);
          await customersSnapshot.restoreToBox(customersBox);
          await expensesSnapshot.restoreToBox(expensesBox);
          await workersSnapshot.restoreToBox(workersBox);
          await brokerConsignmentsSnapshot.restoreToBox(brokerConsignmentsBox);
          return {'success': false, 'restoredCount': 0, 'failedCount': 0, 'errorMessage': 'Sale restore ပျက်ကွက်ခဲ့ပါသည်။ Record key "$key" တွင် မှတ်တမ်းတွင်ကိုပါသည်။'};
        }
        final sale = BackupDeserializers.deserializeSale(recordJson);
        if (sale == null) {
          await gemstonesSnapshot.restoreToBox(gemstonesBox);
          await salesSnapshot.restoreToBox(salesBox);
          await customersSnapshot.restoreToBox(customersBox);
          await expensesSnapshot.restoreToBox(expensesBox);
          await workersSnapshot.restoreToBox(workersBox);
          await brokerConsignmentsSnapshot.restoreToBox(brokerConsignmentsBox);
          return {'success': false, 'restoredCount': 0, 'failedCount': 0, 'errorMessage': 'Sale restore ပျက်ကွက်ခဲ့ပါသည်။ Record key "$key" ကိ deserialize မအောင်မြင်ပါသည်။'};
        }
        try {
          final originalKey = int.tryParse(key) ?? key;
          await salesBox.put(originalKey, sale);
          salesRestoredCount++;
        } catch (e) {
          await gemstonesSnapshot.restoreToBox(gemstonesBox);
          await salesSnapshot.restoreToBox(salesBox);
          await customersSnapshot.restoreToBox(customersBox);
          await expensesSnapshot.restoreToBox(expensesBox);
          await workersSnapshot.restoreToBox(workersBox);
          await brokerConsignmentsSnapshot.restoreToBox(brokerConsignmentsBox);
          return {'success': false, 'restoredCount': 0, 'failedCount': 0, 'errorMessage': 'Sale restore ပျက်ကွက်ခဲ့ပါသည်။ Record key "$key" ကိ restore မအောင်မြင်ပါသည်။'};
        }
      }

      // RESTORE CUSTOMERS
      await customersBox.clear();
      for (final entry in backupCustomersData.entries) {
        final key = entry.key;
        final recordJson = entry.value;
        if (recordJson is! Map<String, dynamic>) {
          await gemstonesSnapshot.restoreToBox(gemstonesBox);
          await salesSnapshot.restoreToBox(salesBox);
          await customersSnapshot.restoreToBox(customersBox);
          await expensesSnapshot.restoreToBox(expensesBox);
          await workersSnapshot.restoreToBox(workersBox);
          await brokerConsignmentsSnapshot.restoreToBox(brokerConsignmentsBox);
          return {'success': false, 'restoredCount': 0, 'failedCount': 0, 'errorMessage': 'Customer restore ပျက်ကွက်ခဲ့ပါသည်။ Record key "$key" တွင် မှတ်တမ်းတွင်ကိုပါသည်။'};
        }
        final customer = BackupDeserializers.deserializeCustomer(recordJson);
        if (customer == null) {
          await gemstonesSnapshot.restoreToBox(gemstonesBox);
          await salesSnapshot.restoreToBox(salesBox);
          await customersSnapshot.restoreToBox(customersBox);
          await expensesSnapshot.restoreToBox(expensesBox);
          await workersSnapshot.restoreToBox(workersBox);
          await brokerConsignmentsSnapshot.restoreToBox(brokerConsignmentsBox);
          return {'success': false, 'restoredCount': 0, 'failedCount': 0, 'errorMessage': 'Customer restore ပျက်ကွက်ခဲ့ပါသည်။ Record key "$key" ကိ deserialize မအောင်မြင်ပါသည်။'};
        }
        try {
          final originalKey = int.tryParse(key) ?? key;
          await customersBox.put(originalKey, customer);
          customersRestoredCount++;
        } catch (e) {
          await gemstonesSnapshot.restoreToBox(gemstonesBox);
          await salesSnapshot.restoreToBox(salesBox);
          await customersSnapshot.restoreToBox(customersBox);
          await expensesSnapshot.restoreToBox(expensesBox);
          await workersSnapshot.restoreToBox(workersBox);
          await brokerConsignmentsSnapshot.restoreToBox(brokerConsignmentsBox);
          return {'success': false, 'restoredCount': 0, 'failedCount': 0, 'errorMessage': 'Customer restore ပျက်ကွက်ခဲ့ပါသည်။ Record key "$key" ကိ restore မအောင်မြင်ပါသည်။'};
        }
      }

      // RESTORE EXPENSES
      await expensesBox.clear();
      for (final entry in backupExpensesData.entries) {
        final key = entry.key;
        final recordJson = entry.value;
        if (recordJson is! Map<String, dynamic>) {
          await gemstonesSnapshot.restoreToBox(gemstonesBox);
          await salesSnapshot.restoreToBox(salesBox);
          await customersSnapshot.restoreToBox(customersBox);
          await expensesSnapshot.restoreToBox(expensesBox);
          await workersSnapshot.restoreToBox(workersBox);
          await brokerConsignmentsSnapshot.restoreToBox(brokerConsignmentsBox);
          return {'success': false, 'restoredCount': 0, 'failedCount': 0, 'errorMessage': 'Expense restore ပျက်ကွက်ခဲ့ပါသည်။ Record key "$key" တွင် မှတ်တမ်းတွင်ကိုပါသည်။'};
        }
        final expense = BackupDeserializers.deserializeExpense(recordJson);
        if (expense == null) {
          await gemstonesSnapshot.restoreToBox(gemstonesBox);
          await salesSnapshot.restoreToBox(salesBox);
          await customersSnapshot.restoreToBox(customersBox);
          await expensesSnapshot.restoreToBox(expensesBox);
          await workersSnapshot.restoreToBox(workersBox);
          await brokerConsignmentsSnapshot.restoreToBox(brokerConsignmentsBox);
          return {'success': false, 'restoredCount': 0, 'failedCount': 0, 'errorMessage': 'Expense restore ပျက်ကွက်ခဲ့ပါသည်။ Record key "$key" ကိ deserialize မအောင်မြင်ပါသည်။'};
        }
        try {
          final originalKey = int.tryParse(key) ?? key;
          await expensesBox.put(originalKey, expense);
          expensesRestoredCount++;
        } catch (e) {
          await gemstonesSnapshot.restoreToBox(gemstonesBox);
          await salesSnapshot.restoreToBox(salesBox);
          await customersSnapshot.restoreToBox(customersBox);
          await expensesSnapshot.restoreToBox(expensesBox);
          await workersSnapshot.restoreToBox(workersBox);
          await brokerConsignmentsSnapshot.restoreToBox(brokerConsignmentsBox);
          return {'success': false, 'restoredCount': 0, 'failedCount': 0, 'errorMessage': 'Expense restore ပျက်ကွက်ခဲ့ပါသည်။ Record key "$key" ကိ restore မအောင်မြင်ပါသည်။'};
        }
      }

      // RESTORE WORKERS
      await workersBox.clear();
      for (final entry in backupWorkersData.entries) {
        final key = entry.key;
        final recordJson = entry.value;
        if (recordJson is! Map<String, dynamic>) {
          await gemstonesSnapshot.restoreToBox(gemstonesBox);
          await salesSnapshot.restoreToBox(salesBox);
          await customersSnapshot.restoreToBox(customersBox);
          await expensesSnapshot.restoreToBox(expensesBox);
          await workersSnapshot.restoreToBox(workersBox);
          await brokerConsignmentsSnapshot.restoreToBox(brokerConsignmentsBox);
          return {'success': false, 'restoredCount': 0, 'failedCount': 0, 'errorMessage': 'Worker restore ပျက်ကွက်ခဲ့ပါသည်။ Record key "$key" တွင် မှတ်တမ်းတွင်ကိုပါသည်။'};
        }
        final worker = BackupDeserializers.deserializeWorker(recordJson);
        if (worker == null) {
          await gemstonesSnapshot.restoreToBox(gemstonesBox);
          await salesSnapshot.restoreToBox(salesBox);
          await customersSnapshot.restoreToBox(customersBox);
          await expensesSnapshot.restoreToBox(expensesBox);
          await workersSnapshot.restoreToBox(workersBox);
          await brokerConsignmentsSnapshot.restoreToBox(brokerConsignmentsBox);
          return {'success': false, 'restoredCount': 0, 'failedCount': 0, 'errorMessage': 'Worker restore ပျက်ကွက်ခဲ့ပါသည်။ Record key "$key" ကိ deserialize မအောင်မြင်ပါသည်။'};
        }
        try {
          final originalKey = int.tryParse(key) ?? key;
          await workersBox.put(originalKey, worker);
          workersRestoredCount++;
        } catch (e) {
          await gemstonesSnapshot.restoreToBox(gemstonesBox);
          await salesSnapshot.restoreToBox(salesBox);
          await customersSnapshot.restoreToBox(customersBox);
          await expensesSnapshot.restoreToBox(expensesBox);
          await workersSnapshot.restoreToBox(workersBox);
          await brokerConsignmentsSnapshot.restoreToBox(brokerConsignmentsBox);
          return {'success': false, 'restoredCount': 0, 'failedCount': 0, 'errorMessage': 'Worker restore ပျက်ကွက်ခဲ့ပါသည်။ Record key "$key" ကိ restore မအောင်မြင်ပါသည်။'};
        }
      }

      // RESTORE BROKER PROFILES (before broker consignments)
      await brokerProfilesBox.clear();
      for (final entry in backupBrokerProfilesData.entries) {
        final key = entry.key;
        final recordJson = entry.value;
        if (recordJson is! Map<String, dynamic>) {
          await gemstonesSnapshot.restoreToBox(gemstonesBox);
          await salesSnapshot.restoreToBox(salesBox);
          await customersSnapshot.restoreToBox(customersBox);
          await expensesSnapshot.restoreToBox(expensesBox);
          await workersSnapshot.restoreToBox(workersBox);
          await brokerProfilesSnapshot.restoreToBox(brokerProfilesBox);
          await brokerConsignmentsSnapshot.restoreToBox(brokerConsignmentsBox);
          return {'success': false, 'restoredCount': 0, 'failedCount': 0, 'errorMessage': 'Broker Profile restore ပျက်ကွက်ခဲ့ပါသည်။ Record key "$key" တွင် မှတ်တမ်းတွင်ကိုပါသည်။'};
        }
        final brokerProfile = BackupDeserializers.deserializeBrokerProfile(recordJson);
        if (brokerProfile == null) {
          await gemstonesSnapshot.restoreToBox(gemstonesBox);
          await salesSnapshot.restoreToBox(salesBox);
          await customersSnapshot.restoreToBox(customersBox);
          await expensesSnapshot.restoreToBox(expensesBox);
          await workersSnapshot.restoreToBox(workersBox);
          await brokerProfilesSnapshot.restoreToBox(brokerProfilesBox);
          await brokerConsignmentsSnapshot.restoreToBox(brokerConsignmentsBox);
          return {'success': false, 'restoredCount': 0, 'failedCount': 0, 'errorMessage': 'Broker Profile restore ပျက်ကွက်ခဲ့ပါသည်။ Record key "$key" ကိ deserialize မအောင်မြင်ပါသည်။'};
        }
        try {
          final originalKey = int.tryParse(key) ?? key;
          await brokerProfilesBox.put(originalKey, brokerProfile);
          brokerProfilesRestoredCount++;
        } catch (e) {
          await gemstonesSnapshot.restoreToBox(gemstonesBox);
          await salesSnapshot.restoreToBox(salesBox);
          await customersSnapshot.restoreToBox(customersBox);
          await expensesSnapshot.restoreToBox(expensesBox);
          await workersSnapshot.restoreToBox(workersBox);
          await brokerProfilesSnapshot.restoreToBox(brokerProfilesBox);
          await brokerConsignmentsSnapshot.restoreToBox(brokerConsignmentsBox);
          return {'success': false, 'restoredCount': 0, 'failedCount': 0, 'errorMessage': 'Broker Profile restore ပျက်ကွက်ခဲ့ပါသည်။ Record key "$key" ကိ restore မအောင်မြင်ပါသည်။'};
        }
      }

      // VERIFY BROKER PROFILE ID REFERENCES BEFORE RESTORING BROKER CONSIGNMENTS
      final restoredBrokerProfileIds = brokerProfilesBox.values
          .map((bp) => bp.id)
          .toSet();
      
      for (final entry in backupBrokerConsignmentsData.entries) {
        final recordJson = entry.value;
        if (recordJson is Map<String, dynamic>) {
          final brokerProfileId = recordJson['brokerProfileId'] as String?;
          if (brokerProfileId != null && brokerProfileId.isNotEmpty) {
            if (!restoredBrokerProfileIds.contains(brokerProfileId)) {
              // Missing broker profile - fail restore with full rollback
              await gemstonesSnapshot.restoreToBox(gemstonesBox);
              await salesSnapshot.restoreToBox(salesBox);
              await customersSnapshot.restoreToBox(customersBox);
              await expensesSnapshot.restoreToBox(expensesBox);
              await workersSnapshot.restoreToBox(workersBox);
              await brokerProfilesSnapshot.restoreToBox(brokerProfilesBox);
              await brokerConsignmentsSnapshot.restoreToBox(brokerConsignmentsBox);
              return {'success': false, 'restoredCount': 0, 'failedCount': 0, 'errorMessage': 'Broker Consignment restore ပျက်ကွက်ခဲ့ပါသည်။ Record key "${entry.key}" သည် ပွဲစား Profile ID "$brokerProfileId" ကို ရည်ညွှန်းထားသည်။ သို့သော် ယင်းပွဲစား Profile မတွေ့ရှိပါ။'};
            }
          }
        }
      }

      // RESTORE BROKER CONSIGNMENTS
      await brokerConsignmentsBox.clear();
      for (final entry in backupBrokerConsignmentsData.entries) {
        final key = entry.key;
        final recordJson = entry.value;
        if (recordJson is! Map<String, dynamic>) {
          await gemstonesSnapshot.restoreToBox(gemstonesBox);
          await salesSnapshot.restoreToBox(salesBox);
          await customersSnapshot.restoreToBox(customersBox);
          await expensesSnapshot.restoreToBox(expensesBox);
          await workersSnapshot.restoreToBox(workersBox);
          await brokerProfilesSnapshot.restoreToBox(brokerProfilesBox);
          await brokerConsignmentsSnapshot.restoreToBox(brokerConsignmentsBox);
          return {'success': false, 'restoredCount': 0, 'failedCount': 0, 'errorMessage': 'Broker Consignment restore ပျက်ကွက်ခဲ့ပါသည်။ Record key "$key" တွင် မှတ်တမ်းတွင်ကိုပါသည်။'};
        }
        final brokerConsignment = BackupDeserializers.deserializeBrokerConsignment(recordJson);
        if (brokerConsignment == null) {
          await gemstonesSnapshot.restoreToBox(gemstonesBox);
          await salesSnapshot.restoreToBox(salesBox);
          await customersSnapshot.restoreToBox(customersBox);
          await expensesSnapshot.restoreToBox(expensesBox);
          await workersSnapshot.restoreToBox(workersBox);
          await brokerProfilesSnapshot.restoreToBox(brokerProfilesBox);
          await brokerConsignmentsSnapshot.restoreToBox(brokerConsignmentsBox);
          return {'success': false, 'restoredCount': 0, 'failedCount': 0, 'errorMessage': 'Broker Consignment restore ပျက်ကွက်ခဲ့ပါသည်။ Record key "$key" ကိ deserialize မအောင်မြင်ပါသည်။'};
        }
        try {
          final originalKey = int.tryParse(key) ?? key;
          await brokerConsignmentsBox.put(originalKey, brokerConsignment);
          brokerConsignmentsRestoredCount++;
        } catch (e) {
          await gemstonesSnapshot.restoreToBox(gemstonesBox);
          await salesSnapshot.restoreToBox(salesBox);
          await customersSnapshot.restoreToBox(customersBox);
          await expensesSnapshot.restoreToBox(expensesBox);
          await workersSnapshot.restoreToBox(workersBox);
          await brokerProfilesSnapshot.restoreToBox(brokerProfilesBox);
          await brokerConsignmentsSnapshot.restoreToBox(brokerConsignmentsBox);
          return {'success': false, 'restoredCount': 0, 'failedCount': 0, 'errorMessage': 'Broker Consignment restore ပျက်ကွက်ခဲ့ပါသည်။ Record key "$key" ကိ restore မအောင်မြင်ပါသည်။'};
        }
      }

      final totalRestored = gemstonesRestoredCount + salesRestoredCount + customersRestoredCount + expensesRestoredCount + workersRestoredCount + brokerProfilesRestoredCount + brokerConsignmentsRestoredCount;
      return {
        'success': true,
        'restoredCount': totalRestored,
        'gemstonesCount': gemstonesRestoredCount,
        'salesCount': salesRestoredCount,
        'customersCount': customersRestoredCount,
        'expensesCount': expensesRestoredCount,
        'workersCount': workersRestoredCount,
        'brokerProfilesCount': brokerProfilesRestoredCount,
        'brokerConsignmentsCount': brokerConsignmentsRestoredCount,
        'failedCount': 0,
      };
    } catch (e) {
      return {
        'success': false,
        'restoredCount': 0,
        'failedCount': 0,
        'errorMessage': 'Restore အမှားအယွင်း: ${_sanitizeErrorMessage(e.toString())}',
      };
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
