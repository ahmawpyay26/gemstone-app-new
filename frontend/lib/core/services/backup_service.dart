// Backup Service - OFFLINE ONLY MODE
// Firebase backup disabled for fully offline operation

import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';

class BackupService {
  // Local backup only - no Firebase
  
  Future<void> performBackup(String userId) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final dbFile = File('${directory.path}/gemstone_local.db');
      
      if (await dbFile.exists()) {
        final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
        final backupName = 'backup_$timestamp.sqlite';
        final backupDir = Directory('${directory.path}/backups');
        
        // Create backups directory if it doesn't exist
        if (!await backupDir.exists()) {
          await backupDir.create(recursive: true);
        }
        
        // Create local backup copy
        final backupFile = File('${backupDir.path}/$backupName');
        await dbFile.copy(backupFile.path);
        
        print('Local backup created: ${backupFile.path}');
      }
    } catch (e) {
      print('Local backup failed: $e');
      // Fail silently - offline mode doesn't require backups
    }
  }

  Future<void> restoreLatestBackup(String userId) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final backupDir = Directory('${directory.path}/backups');
      
      if (!await backupDir.exists()) {
        print('No backups found');
        return;
      }

      // Get the latest backup file
      final backupFiles = backupDir
          .listSync()
          .whereType<File>()
          .where((f) => f.path.endsWith('.sqlite'))
          .toList();
      
      if (backupFiles.isEmpty) {
        print('No backup files found');
        return;
      }

      // Sort by modification time and get latest
      backupFiles.sort((a, b) => b.statSync().modified.compareTo(a.statSync().modified));
      final latestBackup = backupFiles.first;

      // Restore from local backup
      final dbFile = File('${directory.path}/gemstone_local.db');
      await latestBackup.copy(dbFile.path);
      
      print('Database restored from: ${latestBackup.path}');
    } catch (e) {
      print('Restore failed: $e');
      rethrow;
    }
  }
}

// Helper for path provider
Future<Directory> getApplicationDocumentsNavigatorDirectory() async {
  return await getApplicationDocumentsDirectory();
}
