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

  /// Build a mapping from old absolute paths to new restored paths
  /// Extracts media files and creates a mapping for path remapping
  /// Returns {archiveRelativePath: newAbsolutePath} for all successfully extracted files
  static Future<Map<String, String>> buildMediaPathMapping(Archive archive) async {
    final pathMapping = <String, String>{};
    
    try {
      final appDocDir = await getApplicationDocumentsDirectory();
      
      for (final file in archive) {
        // Only process files that are in media folders
        if (_isMediaFile(file.name)) {
          try {
            final filePath = '${appDocDir.path}/${file.name}';
            final targetFile = File(filePath);
            
            // Create parent directories if they don't exist
            await targetFile.parent.create(recursive: true);
            
            // Write file
            if (file.isFile) {
              await targetFile.writeAsBytes(file.content as List<int>);
              
              // Build mapping from archive relative path to new absolute path
              final newAbsolutePath = targetFile.absolute.path;
              final archiveRelativePath = file.name;
              
              // Store the mapping
              pathMapping[archiveRelativePath] = newAbsolutePath;
              
              developer.log('[MediaPathMapping] Mapped: $archiveRelativePath -> $newAbsolutePath');
            }
          } catch (e) {
            developer.log('[MediaPathMapping] Error processing file ${file.name}: $e');
          }
        }
      }
    } catch (e) {
      developer.log('[MediaPathMapping] Error building path mapping: $e');
    }
    
    developer.log('[MediaPathMapping] Total mappings created: ${pathMapping.length}');
    return pathMapping;
  }

  /// Remap a photo path from old absolute path to new restored path
  /// Handles old paths like /data/user/0/com.gemstone.management/app_flutter/photos/filename.jpg
  /// Returns the new path if found in mapping, null if path is missing or invalid
  static String? remapPhotoPath(String oldPath, Map<String, String> pathMapping) {
    if (oldPath.isEmpty) return null;
    
    // Extract the relative path from the old absolute path
    // Old paths are like: /data/user/0/com.gemstone.management/app_flutter/photos/filename.jpg
    // We need to extract: photos/filename.jpg
    
    // Try to extract from photos/ folder
    if (oldPath.contains('/photos/')) {
      final photoIndex = oldPath.indexOf('/photos/');
      if (photoIndex >= 0) {
        final relativePath = oldPath.substring(photoIndex + 1); // Remove leading /
        if (pathMapping.containsKey(relativePath)) {
          return pathMapping[relativePath];
        }
      }
    }
    
    // Try to extract from broker_media/ folder
    if (oldPath.contains('/broker_media/')) {
      final brokerIndex = oldPath.indexOf('/broker_media/');
      if (brokerIndex >= 0) {
        final relativePath = oldPath.substring(brokerIndex + 1); // Remove leading /
        if (pathMapping.containsKey(relativePath)) {
          return pathMapping[relativePath];
        }
      }
    }
    
    // Try to extract from business_profile/ folder
    if (oldPath.contains('/business_profile/')) {
      final profileIndex = oldPath.indexOf('/business_profile/');
      if (profileIndex >= 0) {
        final relativePath = oldPath.substring(profileIndex + 1); // Remove leading /
        if (pathMapping.containsKey(relativePath)) {
          return pathMapping[relativePath];
        }
      }
    }
    
    // Path not found in mapping (missing from archive)
    developer.log('[MediaPathMapping] Path not found in mapping: $oldPath');
    return null;
  }

  /// Filter photo paths to only include those that exist after restoration
  /// Removes dead paths that reference missing files
  static Future<List<String>> filterExistingPhotoPaths(List<String> photoPaths) async {
    final existingPaths = <String>[];
    
    for (final path in photoPaths) {
      if (path.isEmpty) continue;
      
      try {
        final file = File(path);
        if (await file.exists()) {
          existingPaths.add(path);
        } else {
          developer.log('[MediaPathMapping] Filtered out non-existent path: $path');
        }
      } catch (e) {
        developer.log('[MediaPathMapping] Error checking path existence: $path, error: $e');
      }
    }
    
    return existingPaths;
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
