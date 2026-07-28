import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:archive/archive.dart';
import 'dart:developer' as developer;

/// Helper service to collect and archive media files for backup
class MediaBackupHelper {
  /// Media folders to include in backup
  static const List<String> _mediaFolders = [
    'photos',                  // Sales and Inventory photos
    'broker_media',            // Broker consignment photos
    'business_profile',        // Business logo
  ];

  /// Collect all media files and add them to the archive
  /// Returns the number of files added
  static Future<int> addMediaFilesToArchive(Archive archive) async {
    int filesAdded = 0;
    
    try {
      final appDocDir = await getApplicationDocumentsDirectory();
      
      for (final folderName in _mediaFolders) {
        final folderPath = '${appDocDir.path}/$folderName';
        final folder = Directory(folderPath);
        
        if (!await folder.exists()) {
          developer.log('[MediaBackup] Folder does not exist: $folderPath');
          continue;
        }
        
        try {
          // Recursively add all files in this folder
          final files = folder.listSync(recursive: true);
          
          for (final entity in files) {
            if (entity is File) {
              try {
                final fileBytes = await entity.readAsBytes();
                
                // Create archive path relative to app documents directory
                final relativePath = entity.path.replaceFirst(appDocDir.path, '').replaceFirst('/', '');
                
                // Add file to archive
                archive.addFile(ArchiveFile(
                  relativePath,
                  fileBytes.length,
                  fileBytes,
                ));
                
                filesAdded++;
                developer.log('[MediaBackup] Added file to archive: $relativePath (${fileBytes.length} bytes)');
              } catch (e) {
                developer.log('[MediaBackup] Error adding file ${entity.path}: $e');
                // Continue with next file instead of failing
              }
            }
          }
        } catch (e) {
          developer.log('[MediaBackup] Error processing folder $folderPath: $e');
          // Continue with next folder instead of failing
        }
      }
    } catch (e) {
      developer.log('[MediaBackup] Error collecting media files: $e');
      // Return whatever files were successfully added
    }
    
    developer.log('[MediaBackup] Total files added to archive: $filesAdded');
    return filesAdded;
  }

  /// Extract media files from archive and restore them
  /// Returns the number of files restored
  static Future<int> extractMediaFilesFromArchive(Archive archive) async {
    int filesRestored = 0;
    
    try {
      final appDocDir = await getApplicationDocumentsDirectory();
      
      for (final file in archive) {
        // Only extract files that are in media folders
        if (_isMediaFile(file.name)) {
          try {
            final filePath = '${appDocDir.path}/${file.name}';
            final targetFile = File(filePath);
            
            // Create parent directories if they don't exist
            await targetFile.parent.create(recursive: true);
            
            // Write file
            if (file.isFile) {
              await targetFile.writeAsBytes(file.content as List<int>);
              filesRestored++;
              developer.log('[MediaRestore] Extracted file: ${file.name} (${file.size} bytes)');
            }
          } catch (e) {
            developer.log('[MediaRestore] Error extracting file ${file.name}: $e');
            // Continue with next file instead of failing
          }
        }
      }
    } catch (e) {
      developer.log('[MediaRestore] Error extracting media files: $e');
      // Return whatever files were successfully extracted
    }
    
    developer.log('[MediaRestore] Total files extracted from archive: $filesRestored');
    return filesRestored;
  }

  /// Check if a file path belongs to a media folder
  static bool _isMediaFile(String filePath) {
    for (final folderName in _mediaFolders) {
      if (filePath.startsWith(folderName)) {
        return true;
      }
    }
    return false;
  }

  /// Get total size of all media files (for progress indication)
  static Future<int> getMediaFilesSize() async {
    int totalSize = 0;
    
    try {
      final appDocDir = await getApplicationDocumentsDirectory();
      
      for (final folderName in _mediaFolders) {
        final folderPath = '${appDocDir.path}/$folderName';
        final folder = Directory(folderPath);
        
        if (!await folder.exists()) {
          continue;
        }
        
        try {
          final files = folder.listSync(recursive: true);
          for (final entity in files) {
            if (entity is File) {
              try {
                totalSize += await entity.length();
              } catch (e) {
                developer.log('[MediaBackup] Error getting file size: $e');
              }
            }
          }
        } catch (e) {
          developer.log('[MediaBackup] Error calculating folder size: $e');
        }
      }
    } catch (e) {
      developer.log('[MediaBackup] Error calculating total media size: $e');
    }
    
    return totalSize;
  }
}
