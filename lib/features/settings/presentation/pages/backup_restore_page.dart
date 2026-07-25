import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'dart:io';
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:hive/hive.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/local/local_db.dart';

class BackupRestorePage extends StatefulWidget {
  const BackupRestorePage({Key? key}) : super(key: key);

  @override
  State<BackupRestorePage> createState() => _BackupRestorePageState();
}

class _BackupRestorePageState extends State<BackupRestorePage> {
  bool _isBackingUp = false;

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
          for (final key in box.keys) {
            final value = box.get(key);
            // Convert to JSON-serializable format
            boxData[key.toString()] = _serializeValue(value);
          }
          backupData[boxName] = boxData;
        } catch (e) {
          developer.log('Error backing up box $boxName: $e');
        }
      }

      // Generate backup filename with timestamp
      final now = DateTime.now();
      final timestamp = DateFormat('yyyy-MM-dd_HH-mm-ss').format(now);
      final backupFileName = 'Gemstone_Backup_${timestamp}.gmbak';

      // Get Download directory
      final downloadsDir = await getDownloadsDirectory();
      if (downloadsDir == null) {
        throw Exception('Download directory မရှိပါ');
      }
      
      final backupDir = Directory('${downloadsDir.path}/Gemstone Backup');

      // Create Gemstone Backup directory if it doesn't exist
      if (!await backupDir.exists()) {
        await backupDir.create(recursive: true);
      }

      // Write backup file
      final backupFile = File('${backupDir.path}/$backupFileName');
      final backupJson = jsonEncode(backupData);
      await backupFile.writeAsString(backupJson);

      setState(() => _isBackingUp = false);

      // Show success message
      if (mounted) {
        _showSuccessDialog(backupFileName, backupDir.path);
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
    // For other types, convert to string
    return value.toString();
  }

  void _showSuccessDialog(String fileName, String location) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Backup အောင်မြင်ပါပြီ'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Backup File အောင်မြင်စွာ ဖန်တီးပြီးပါပြီ။'),
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
            Text(location),
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
      backgroundColor: AppTheme.primaryDark,
      appBar: AppBar(
        title: const Text('Backup & Restore'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () =>
              context.canPop() ? context.pop() : context.go('/settings'),
        ),
        backgroundColor: AppTheme.primaryDark,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Icon
              Icon(
                Icons.backup,
                size: 80,
                color: AppTheme.primaryAccent,
              ),
              const SizedBox(height: 24),

              // Title
              Text(
                'Backup & Restore',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),

              // Backup Section
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceDark,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppTheme.primaryAccent.withOpacity(0.3),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Backup ဖန်တီးမည်',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'သင်၏ အချက်အလက်များကို Local Storage တွင် Backup ဖန်တီးပါ။ အရေးပါသော အချက်အလက်များ ဆုံးရှုံးခြင်းမှ ကာကွယ်ပါ။',
                      style: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 13,
                        height: 1.5,
                      ),
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
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    AppTheme.primaryDark,
                                  ),
                                ),
                              )
                            : const Icon(Icons.cloud_upload, color: AppTheme.primaryDark),
                        label: Text(
                          _isBackingUp ? 'Backup လုပ်နေသည်...' : 'Backup Now',
                          style: const TextStyle(
                            color: AppTheme.primaryDark,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          disabledBackgroundColor: Colors.grey[600],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Restore Section (Coming Soon)
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceDark,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.grey[700]!,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Restore ဖြန်လည်ရယူမည်',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Backup ဖိုင်မှ အချက်အလက်များကို ပြန်လည်ရယူပါ။',
                      style: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 13,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: null,
                        icon: const Icon(Icons.cloud_download, color: Colors.grey),
                        label: const Text(
                          'Coming Soon',
                          style: TextStyle(
                            color: Colors.grey,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey[700],
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          disabledBackgroundColor: Colors.grey[700],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Back button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isBackingUp
                      ? null
                      : () => context.canPop()
                          ? context.pop()
                          : context.go('/settings'),
                  icon: const Icon(Icons.arrow_back, color: AppTheme.primaryDark),
                  label: const Text(
                    'ပြန်သွားမည်',
                    style: TextStyle(
                      color: AppTheme.primaryDark,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryAccent,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    disabledBackgroundColor: Colors.grey[600],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
