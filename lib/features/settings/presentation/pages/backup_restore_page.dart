import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'dart:io';
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:hive/hive.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/local/local_db.dart';
import '../../../../core/local/models.dart';

class BackupRestorePage extends StatefulWidget {
  const BackupRestorePage({Key? key}) : super(key: key);

  @override
  State<BackupRestorePage> createState() => _BackupRestorePageState();
}

class _BackupRestorePageState extends State<BackupRestorePage> {
  bool _isBackingUp = false;
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
          final box = Hive.box(boxName);
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
      final backupJson = jsonEncode(backupData);

      // Call native Android SAF to save file
      try {
        final result = await platform.invokeMethod<Map>('saveBackupFile', {
          'fileName': backupFileName,
          'content': backupJson,
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
    'gemstoneid': s.gemstoneid,
    'quantity': s.quantity,
    'salePrice': s.salePrice,
    'totalAmount': s.totalAmount,
    'soldAt': s.soldAt,
    'soldBy': s.soldBy,
    'customerid': s.customerid,
    'note': s.note,
  };

  Map<String, dynamic> _expenseToMap(Expense e) => {
    'id': e.id,
    'category': e.category,
    'amount': e.amount,
    'date': e.date,
    'note': e.note,
    'createdBy': e.createdBy,
  };

  Map<String, dynamic> _workerToMap(Worker w) => {
    'id': w.id,
    'name': w.name,
    'phone': w.phone,
    'address': w.address,
    'role': w.role,
    'salary': w.salary,
    'startDate': w.startDate,
    'status': w.status,
  };

  Map<String, dynamic> _customerToMap(Customer c) => {
    'id': c.id,
    'name': c.name,
    'phone': c.phone,
    'email': c.email,
    'address': c.address,
    'createdAt': c.createdAt,
  };

  Map<String, dynamic> _paymentToMap(Payment p) => {
    'id': p.id,
    'amount': p.amount,
    'date': p.date,
    'method': p.method,
    'reference': p.reference,
    'note': p.note,
  };

  Map<String, dynamic> _auditLogToMap(AuditLog a) => {
    'id': a.id,
    'action': a.action,
    'userId': a.userId,
    'timestamp': a.timestamp,
    'details': a.details,
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
                        onPressed: null,
                        icon: const Icon(Icons.restore),
                        label: const Text('Coming Soon'),
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
