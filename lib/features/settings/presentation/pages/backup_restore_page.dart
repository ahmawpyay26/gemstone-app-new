import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'dart:io';
import 'dart:convert';
import 'dart:developer' as developer;
import 'package:intl/intl.dart';
import 'package:hive/hive.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/local/local_db.dart';
import '../../../../core/local/models.dart';
import '../../data/backup_restore_service.dart';
import '../../data/restore_validation_result.dart';
import '../../data/media_backup_helper.dart';
import 'package:archive/archive.dart';

class BackupRestorePage extends StatefulWidget {
  const BackupRestorePage({Key? key}) : super(key: key);

  @override
  State<BackupRestorePage> createState() => _BackupRestorePageState();
}

class _BackupRestorePageState extends State<BackupRestorePage> {
  bool _isBackingUp = false;
  bool _isValidatingRestore = false;
  bool _isRestoringGemstones = false;
  String? _pendingRestoreContent; // Store backup content for restore confirmation
  static const platform = MethodChannel('com.gemstone.management/backup');

  Future<void> _createBackup() async {
    setState(() => _isBackingUp = true);

    try {
      // Get all Hive boxes
      final backupData = <String, dynamic>{};

      // Backup all boxes
      final boxes = [
        LocalDb.usersBox,
        LocalDb.gemstonesBox,
        LocalDb.salesBox,
        LocalDb.expensesBox,
        LocalDb.workersBox,
        LocalDb.sessionBox,
        LocalDb.auditLogsBox,
        LocalDb.staffUsersBox,
        LocalDb.permissionsBox,
        LocalDb.rolesBox,
        LocalDb.brokerConsignmentsBox,
        LocalDb.brokerSaleRecordsBox,
        LocalDb.customersBox,
        LocalDb.customerLedgerBox,
        LocalDb.paymentsBox,
        LocalDb.businessProfileBox,
        LocalDb.brokerProfilesBox,
      ];

      for (final boxName in boxes) {
        try {
          final box = boxName == LocalDb.gemstonesBox
              ? LocalDb.gemstones()
              : boxName == LocalDb.salesBox
              ? LocalDb.sales()
              : boxName == LocalDb.customersBox
              ? LocalDb.customers()
              : boxName == LocalDb.expensesBox
              ? LocalDb.expenses()
              : boxName == LocalDb.workersBox
              ? LocalDb.workers()
              : boxName == LocalDb.usersBox
              ? LocalDb.users()
              : boxName == LocalDb.auditLogsBox
              ? LocalDb.auditLogs()
              : boxName == LocalDb.brokerConsignmentsBox
              ? LocalDb.brokerConsignments()
              : boxName == LocalDb.paymentsBox
              ? LocalDb.payments()
              : boxName == LocalDb.brokerSaleRecordsBox
              ? LocalDb.brokerSaleRecords()
              : boxName == LocalDb.businessProfileBox
              ? LocalDb.businessProfiles()
              : boxName == LocalDb.customerLedgerBox
              ? LocalDb.customerLedger()
              : boxName == LocalDb.brokerProfilesBox
              ? Hive.box<BrokerProfile>(LocalDb.brokerProfilesBox)
              : Hive.box(boxName);
          final boxData = <String, dynamic>{};
          
          // Get all keys from the box
          final keys = box.keys.toList();
          developer.log('Box: $boxName, Keys count: ${keys.length}');
          
          for (final key in keys) {
            try {
              final value = box.get(key);
              // Convert to JSON-serializable format
              boxData[key.toString()] = _serializeValue(value);
            } catch (e) {
              developer.log('Error serializing key $key in box $boxName: $e');
            }
          }
          
          // Always add the box to backup, even if empty
          backupData[boxName] = boxData;
          developer.log('Backed up box: $boxName with ${boxData.length} records');
        } catch (e) {
          developer.log('Error backing up box $boxName: $e');
          // Add empty box to prevent data loss
          backupData[boxName] = {};
        }
      }
      
      developer.log('Total boxes backed up: ${backupData.length}');
      developer.log('Backup data keys: ${backupData.keys.toList()}');

      // Generate backup filename with timestamp
      final now = DateTime.now();
      final timestamp = DateFormat('yyyy-MM-dd_HH-mm-ss').format(now);
      final backupFileName = 'Gemstone_Backup_${timestamp}.gmbak';
      
      // Create archive and add JSON data
      final archive = Archive();
      
      // Add JSON data to archive
      final backupJson = jsonEncode(backupData);
      final jsonBytes = utf8.encode(backupJson);
      archive.addFile(ArchiveFile('backup_data.json', jsonBytes.length, jsonBytes));
      developer.log('Added backup_data.json to archive (${jsonBytes.length} bytes)');
      
      // Add media files to archive
      try {
        final mediaFilesCount = await MediaBackupHelper.addMediaFilesToArchive(archive);
        developer.log('Added $mediaFilesCount media files to archive');
      } catch (e) {
        developer.log('Warning: Error adding media files to backup: $e');
        // Continue with backup even if media files fail
      }
      
      // Encode archive to bytes
      final archiveBytes = ZipEncoder().encode(archive);
      if (archiveBytes == null) {
        throw Exception('Failed to encode archive');
      }
      
      developer.log('Archive created successfully (${archiveBytes.length} bytes)');
      
      // Convert archive bytes to base64 for transmission
      final archiveBase64 = base64Encode(archiveBytes);

      // Call native Android SAF to save file
      try {
        final result = await platform.invokeMethod<Map>('saveBackupFile', {
          'fileName': backupFileName,
          'content': archiveBase64,
          'isArchive': true,
        });

        setState(() => _isBackingUp = false);

        if (result != null) {
          final success = result['success'] as bool? ?? false;
          final cancelled = result['cancelled'] as bool? ?? false;
          final fileName = result['fileName'] as String? ?? backupFileName;
          final uri = result['uri'] as String? ?? '';

          if (mounted) {
            if (success) {
              _showSuccessDialog(fileName, uri);
            } else if (cancelled) {
              _showInfoDialog('Backup မသိမ်းရသေးပါ', 'Backup ဖန်တီးခြင်း ရပ်တန့်ခဲ့ပါသည်။');
            }
          }
        }
      } on PlatformException catch (e) {
        setState(() => _isBackingUp = false);
        if (mounted) {
          _showErrorDialog('Backup အမှားအယွင်း', 'Error: ${e.message}');
        }
      }
    } catch (e) {
      setState(() => _isBackingUp = false);
      if (mounted) {
        _showErrorDialog('Backup အမှားအယွင်း', 'Backup ဖန်တီးခြင်း ပျက်ကွက်ခဲ့ပါတယ်: $e');
      }
    }
  }

  dynamic _serializeValue(dynamic value) {
    if (value == null) return null;
    if (value is String || value is int || value is double || value is bool) {
      return value;
    }
    if (value is List) {
      return value.map(_serializeValue).toList();
    }
    if (value is Map) {
      return value.map((k, v) => MapEntry(k.toString(), _serializeValue(v)));
    }
    
    // For Hive objects, use explicit type checking and conversion
    try {
      // Handle specific Hive model types
      if (value is Gemstone) {
        return _gemstoneToMap(value);
      } else if (value is AppUser) {
        return _appUserToMap(value);
      } else if (value is Sale) {
        return _saleToMap(value);
      } else if (value is Expense) {
        return _expenseToMap(value);
      } else if (value is Worker) {
        return _workerToMap(value);
      } else if (value is Customer) {
        return _customerToMap(value);
      } else if (value is Payment) {
        return _paymentToMap(value);
      } else if (value is AuditLog) {
        return _auditLogToMap(value);
      } else if (value is BrokerProfile) {
        return _brokerProfileToMap(value);
      } else if (value is BrokerConsignment) {
        return _brokerConsignmentToMap(value);
      } else if (value is BrokerHistoricalData) {
        return _brokerHistoricalDataToMap(value);
      }
      
      // Fallback for unknown types
      developer.log('Warning: Object of type ${value.runtimeType} has no explicit serialization');
      return value.toString();
    } catch (e) {
      developer.log('Error serializing object of type ${value.runtimeType}: $e');
      return value.toString();
    }
  }

  // Explicit serialization methods for each Hive model
  Map<String, dynamic> _gemstoneToMap(Gemstone g) => {
    'id': g.id,
    'name': g.name,
    'type': g.type,
    'weightCarat': g.weightCarat,
    'weightUnit': g.weightUnit,
    'costPrice': g.costPrice,
    'commissionFee': g.commissionFee,
    'processingFee': g.processingFee,
    'repairFee': g.repairFee,
    'breakageFee': g.breakageFee,
    'bloodFee': g.bloodFee,
    'laborFee': g.laborFee,
    'miscFee': g.miscFee,
    'sellPrice': g.sellPrice,
    'quantity': g.quantity,
    'color': g.color,
    'origin': g.origin,
    'status': g.status,
    'note': g.note,
    'createdAt': g.createdAt,
    'totalCost': g.totalCost,
    'remainingCost': g.remainingCost,
    'remainingQuantity': g.remainingQuantity,
    'soldQuantity': g.soldQuantity,
    'photoPaths': g.photoPaths,
    'breakdownItems': g.breakdownItems,
    'originalPurchaseCost': g.originalPurchaseCost,
    'remainingCostBalance': g.remainingCostBalance,
    'recoveredCost': g.recoveredCost,
    'totalProfit': g.totalProfit,
    'totalSalesRevenue': g.totalSalesRevenue,
  };

  Map<String, dynamic> _appUserToMap(AppUser u) => {
    'id': u.id,
    'name': u.name,
    'email': u.email,
    'username': u.username,
    'passwordHash': u.passwordHash,
    'role': u.role,
    'createdAt': u.createdAt,
    'updatedAt': u.updatedAt,
  };

  Map<String, dynamic> _saleToMap(Sale s) => {
    'id': s.id,
    'gemstoneId': s.gemstoneId,
    'gemstoneName': s.gemstoneName,
    'customerId': s.customerId,
    'customerName': s.customerName,
    'amount': s.amount,
    'costPrice': s.costPrice,
    'commissionFee': s.commissionFee,
    'quantity': s.quantity,
    'weightCarat': s.weightCarat,
    'paymentMethod': s.paymentMethod,
    'note': s.note,
    'saleDate': s.saleDate,
    'netSale': s.netSale,
    'costUsed': s.costUsed,
    'remainingCostAfterSale': s.remainingCostAfterSale,
    'profitGenerated': s.profitGenerated,
    'accumulatedProfit': s.accumulatedProfit,
    'isDeleted': s.isDeleted,
    'deletedAt': s.deletedAt,
    'deletedBy': s.deletedBy,
    'deleteReason': s.deleteReason,
    'photoPaths': s.photoPaths,
    'invoiceNumber': s.invoiceNumber,
    'fragmentName': s.fragmentName,
    'isFragmentSource': s.isFragmentSource,
    'fragmentWeight': s.fragmentWeight,
    'fragmentWeightUnit': s.fragmentWeightUnit,
    'weightUnit': s.weightUnit,
    'invoiceItems': s.invoiceItems,
  };

  Map<String, dynamic> _expenseToMap(Expense e) => {
    'id': e.id,
    'title': e.title,
    'category': e.category,
    'amount': e.amount,
    'note': e.note,
    'expenseDate': e.expenseDate,
  };

  Map<String, dynamic> _workerToMap(Worker w) => {
    'id': w.id,
    'name': w.name,
    'role': w.role,
    'phone': w.phone,
    'salary': w.salary,
    'status': w.status,
    'note': w.note,
    'createdAt': w.createdAt,
  };

  Map<String, dynamic> _customerToMap(Customer c) => {
    'id': c.id,
    'name': c.name,
    'phone': c.phone,
    'address': c.address,
    'notes': c.notes,
    'openingBalance': c.openingBalance,
    'currentBalance': c.currentBalance,
    'creditLimit': c.creditLimit,
    'status': c.status,
    'isDeleted': c.isDeleted,
    'deletedAt': c.deletedAt,
    'createdAt': c.createdAt,
    'updatedAt': c.updatedAt,
  };

  Map<String, dynamic> _paymentToMap(Payment p) => {
    'id': p.id,
    'customerId': p.customerId,
    'saleId': p.saleId,
    'paymentDate': p.paymentDate,
    'amount': p.amount,
    'method': p.method,
    'referenceNo': p.referenceNo,
    'note': p.note,
    'isDeleted': p.isDeleted,
    'createdAt': p.createdAt,
  };

  Map<String, dynamic> _auditLogToMap(AuditLog a) => {
    'id': a.id,
    'action': a.action,
    'saleId': a.saleId,
    'gemstoneId': a.gemstoneId,
    'gemstoneName': a.gemstoneName,
    'quantity': a.quantity,
    'amount': a.amount,
    'userId': a.userId,
    'userName': a.userName,
    'timestamp': a.timestamp,
    'details': a.details,
  };

  Map<String, dynamic> _brokerHistoricalDataToMap(BrokerHistoricalData h) => {
    'purchaseName': h.purchaseName,
    'purchaseDate': h.purchaseDate,
    'originalSeller': h.originalSeller,
    'gemstoneType': h.gemstoneType,
    'sourceType': h.sourceType,
    'breakdownItemName': h.breakdownItemName,
    'originalQuantity': h.originalQuantity,
    'originalWeight': h.originalWeight,
    'capturedAt': h.capturedAt,
  };

  Map<String, dynamic> _brokerProfileToMap(BrokerProfile bp) => {
    'id': bp.id,
    'name': bp.name,
    'nationalId': bp.nationalId,
    'phone': bp.phone,
    'address': bp.address,
    'socialAccount': bp.socialAccount,
    'note': bp.note,
    'profileImagePath': bp.profileImagePath,
    'createdAt': bp.createdAt,
    'updatedAt': bp.updatedAt,
    'isDeleted': bp.isDeleted,
    'deletedAt': bp.deletedAt,
  };

  Map<String, dynamic> _brokerConsignmentToMap(BrokerConsignment bc) => {
    'id': bc.id,
    'purchaseId': bc.purchaseId,
    'sourceType': bc.sourceType,
    'breakdownItemName': bc.breakdownItemName,
    'voucherId': bc.voucherId,
    'voucherNumber': bc.voucherNumber,
    'consignedQuantity': bc.consignedQuantity,
    'soldQuantity': bc.soldQuantity,
    'returnedQuantity': bc.returnedQuantity,
    'historicalData': _brokerHistoricalDataToMap(bc.historicalData),
    'brokerName': bc.brokerName,
    'brokerPhone': bc.brokerPhone,
    'brokerAddress': bc.brokerAddress,
    'brokerSocialAccount': bc.brokerSocialAccount,
    'brokerProfileId': bc.brokerProfileId,
    'notes': bc.notes,
    'photoPaths': bc.photoPaths,
    'weight': bc.weight,
    'weightUnit': bc.weightUnit,
    'createdAt': bc.createdAt,
    'updatedAt': bc.updatedAt,
    'deletedAt': bc.deletedAt,
  };

  void _showSuccessDialog(String fileName, String location) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Backup အောင်မြင်ပါပြီ'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Backup File အောင်မြင်စွာ သိမ်းဆည်းပြီးပါပြီ။'),
            const SizedBox(height: 16),
            Text(
              'File Name:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            Text(fileName),
            const SizedBox(height: 12),
            Text(
              'Location:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            Text('ရွေးချယ်ထားသောနေရာတွင် သိမ်းပြီးပါပြီ'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('အိုကေ'),
          ),
        ],
      ),
    );
  }

  void _showInfoDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('အိုကေ'),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('အိုကေ'),
          ),
        ],
      ),
    );
  }

  /// Phase 1: Initiate restore by selecting a .gmbak file via Android SAF
  Future<void> _initiateRestore() async {
    setState(() => _isValidatingRestore = true);

    try {
      // Call Android SAF to open restore file picker
      final result = await platform.invokeMethod<Map>('openRestoreFile');

      if (!mounted) return;
      setState(() => _isValidatingRestore = false);

      if (result == null) {
        return;
      }

      final success = result['success'] as bool? ?? false;
      final cancelled = result['cancelled'] as bool? ?? false;
      final fileName = result['fileName'] as String? ?? '';
      final content = result['content'] as String? ?? '';

      // Handle cancellation silently
      if (cancelled) {
        return;
      }

      // Handle errors from platform channel
      if (!success) {
        _showErrorDialog('Restore အမှားအယွင်း', 'Backup ဖိုင်ရွေးချယ်ရန် ပျက်ကွက်ခဲ့ပါသည်။');
        return;
      }

      // Validate the backup file content (Phase 1)
      final validation = await BackupRestoreService.validateBackupFileContent(content, fileName);

      if (!validation.isValid) {
        _showErrorDialog('Backup အမှားအယွင်း', validation.errorMessage ?? 'အမည်မသိအမှားအယွင်း');
        return;
      }

      // Store backup content for restore confirmation
      _pendingRestoreContent = content;

      // Generate preview
      final preview = BackupRestoreService.generatePreview(validation);

      // Show preview dialog
      if (mounted) {
        _showRestorePreviewDialog(preview);
      }
    } on PlatformException catch (e) {
      setState(() => _isValidatingRestore = false);
      developer.log('Platform error: ${e.message}');
      if (mounted) {
        _showErrorDialog('Restore အမှားအယွင်း', 'Backup ဖိုင်ရွေးချယ်ရန် ပျက်ကွက်ခဲ့ပါသည်။');
      }
    } catch (e) {
      setState(() => _isValidatingRestore = false);
      developer.log('Restore error: $e');
      if (mounted) {
        _showErrorDialog('Restore အမှားအယွင်း', 'Backup ဖိုင်ရွေးချယ်ရန် ပျက်ကွက်ခဲ့ပါသည်။');
      }
    }
  }

  /// Show restore preview dialog (Phase 1 only - no actual restore)
  void _showRestorePreviewDialog(RestorePreview preview) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Restore အစီအစဉ်'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Warning: No data changed yet
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  border: Border.all(color: Colors.amber),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '⚠️ အရေးကြီးသတ်မှတ်ချက်',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    const Text('✓ ယခုအခါ ဒေတာမည်သည့်အရာမျှ ပြောင်းလဲမည်မဟုတ်ပါ။'),
                    const SizedBox(height: 4),
                    const Text('✓ Restore အကျင့်သုံးမည်မဟုတ်သေးပါ။'),
                    const SizedBox(height: 4),
                    const Text('✓ ဤသည်မှာ အစီအစဉ်ကြည့်ရှုမှုသာဖြစ်ပါသည်။'),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Filename
              Text(
                'ဖိုင်အမည်: ${preview.validation.filename}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),

              // Record counts
              const Text(
                'မှတ်တမ်းအရေအတွက်:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text('စုစုပေါင်း: ${preview.validation.totalRecords} မှတ်တမ်း'),
              const SizedBox(height: 8),

              // Supported boxes with data
              if (preview.boxesToRestore.isNotEmpty) ...[const SizedBox(height: 8),
                const Text(
                  'Restore ပြုလုပ်ရမည့် အချက်အလက်များ:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                ),
                const SizedBox(height: 4),
                ...preview.boxesToRestore.map((box) {
                  final count = preview.validation.getBoxCount(box);
                  return Text('  • $box: $count မှတ်တမ်း', style: const TextStyle(fontSize: 12));
                }).toList(),
              ],

              // Unsupported boxes with data
              if (preview.boxesNotRestored.isNotEmpty) ...[const SizedBox(height: 12),
                const Text(
                  'Phase 1 တွင် Restore မပြုလုပ်သည့် အချက်အလက်များ:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.orange),
                ),
                const SizedBox(height: 4),
                ...preview.boxesNotRestored.map((box) {
                  final count = preview.validation.getBoxCount(box);
                  return Text('  • $box: $count မှတ်တမ်း (ကြောင့်ခွင့်ပြုချက်မရှိ)', style: const TextStyle(fontSize: 12));
                }).toList(),
              ],

              // Warnings
              if (preview.userWarnings.isNotEmpty) ...[const SizedBox(height: 12),
                const Text(
                  'သတ်မှတ်ချက်များ:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.red),
                ),
                const SizedBox(height: 4),
                ...preview.userWarnings.map((warning) {
                  return Text('  ⚠️ $warning', style: const TextStyle(fontSize: 11));
                }).toList(),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ပိတ်မည်'),
          ),
          ElevatedButton(
            onPressed: _isRestoringGemstones
                ? null
                : () {
                    Navigator.pop(context);
                    _confirmRestoreGemstones();
                  },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              disabledBackgroundColor: Colors.grey,
            ),
            child: _isRestoringGemstones
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Restore ပြုလုပ်မည်'),
          ),
        ],
      ),
    );
  }

  /// Confirm restore and execute atomically for Gemstones and Sales
  /// ATOMIC: Both boxes succeed together or both roll back together
  Future<void> _confirmRestoreGemstones() async {
    if (_pendingRestoreContent == null) {
      _showErrorDialog('Restore အမှားအယွင်း', 'Backup တွင်တ် ရှာမတွေ့ပါသည်။');
      return;
    }

    setState(() => _isRestoringGemstones = true);

    try {
      // Execute atomic restore for Gemstones, Sales, Customers, Expenses, and Workers
      // ATOMIC: All succeed together or all roll back together
      final result = await BackupRestoreService.restoreGemstonesAndSalesAndCustomersAndExpensesAndWorkersAndBrokerConsignmentsOnly(
        _pendingRestoreContent!,
      );

      if (!mounted) return;
      setState(() => _isRestoringGemstones = false);

      final success = result['success'] as bool? ?? false;
      final totalRestored = result['restoredCount'] as int? ?? 0;
      final gemstonesCount = result['gemstonesCount'] as int? ?? 0;
      final salesCount = result['salesCount'] as int? ?? 0;
      final customersCount = result['customersCount'] as int? ?? 0;
      final expensesCount = result['expensesCount'] as int? ?? 0;
      final workersCount = result['workersCount'] as int? ?? 0;
      final brokerProfilesCount = result['brokerProfilesCount'] as int? ?? 0;
      final brokerConsignmentsCount = result['brokerConsignmentsCount'] as int? ?? 0;
      final errorMessage = result['errorMessage'] as String?;

      if (success) {
        _showRestoreSuccessDialog(
          'Restore တွင်တ်မြင်ပါသည်',
          'စုစုပေါ်င်း မှတ်တမ်း $totalRestored restore တွင်တ်မြင်ပါသည်။\n(Gemstones: $gemstonesCount, Sales: $salesCount, Customers: $customersCount, Expenses: $expensesCount, Workers: $workersCount, Broker Profiles: $brokerProfilesCount, Broker Consignments: $brokerConsignmentsCount)',
        );
        // Clear pending restore content
        _pendingRestoreContent = null;
      } else {
        _showErrorDialog(
          'Restore အမှားအယွင်း',
          errorMessage ?? 'အမည်မသိ အမှားအယွင်း',
        );
      }
    } catch (e) {
      setState(() => _isRestoringGemstones = false);
      developer.log('Restore error: $e');
      if (mounted) {
        _showErrorDialog(
          'Restore အမှားအယွင်း',
          'အမည်မသိ အမှားအယွင်း',
        );
      }
    }
  }

  /// Show restore success dialog
  void _showRestoreSuccessDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('တွင်တ်မြင်ပါ'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Backup & Restore'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Backup Section
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '💾 Backup Now',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Create a backup of all your data. You can save it to Download, Documents, or any other location.',
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _isBackingUp ? null : _createBackup,
                        icon: _isBackingUp
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.backup),
                        label: Text(_isBackingUp ? 'Creating Backup...' : 'Backup Now'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Restore Section
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '📂 Restore Backup',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Restore your data from a backup file.',
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _isValidatingRestore ? null : _initiateRestore,
                        icon: const Icon(Icons.restore),
                        label: _isValidatingRestore
                            ? const Text('ဆင်ဆာပြုလုပ်နေသည်...')
                            : const Text('ပြန်လည်ရယူမည်'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
