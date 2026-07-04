import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

/// Service for managing media file storage (photos, videos)
/// Stores media in app's document directory under broker_media folder
class MediaStorageService {
  static const String _mediaFolder = 'broker_media';
  static const uuid = Uuid();

  /// Get the base media directory
  static Future<Directory> _getMediaDirectory() async {
    final appDocDir = await getApplicationDocumentsDirectory();
    final mediaDir = Directory('${appDocDir.path}/$_mediaFolder');
    
    // Create directory if it doesn't exist
    if (!await mediaDir.exists()) {
      await mediaDir.create(recursive: true);
    }
    
    return mediaDir;
  }

  /// Get the broker-specific media directory
  static Future<Directory> _getBrokerMediaDirectory(String brokerId) async {
    final mediaDir = await _getMediaDirectory();
    final brokerDir = Directory('${mediaDir.path}/$brokerId');
    
    // Create directory if it doesn't exist
    if (!await brokerDir.exists()) {
      await brokerDir.create(recursive: true);
    }
    
    return brokerDir;
  }

  /// Save a photo file for a specific broker consignment
  /// Returns the file path relative to app documents directory
  static Future<String> savePhoto(File sourceFile, String brokerId) async {
    try {
      final brokerDir = await _getBrokerMediaDirectory(brokerId);
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'photo_${timestamp}_${uuid.v4().substring(0, 8)}.jpg';
      final targetPath = '${brokerDir.path}/$fileName';
      
      // Copy file to broker media directory
      final savedFile = await sourceFile.copy(targetPath);
      
      return savedFile.path;
    } catch (e) {
      throw Exception('Failed to save photo: $e');
    }
  }

  /// Delete a photo file
  static Future<void> deletePhoto(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      throw Exception('Failed to delete photo: $e');
    }
  }

  /// Get all photos for a broker consignment
  static Future<List<String>> getBrokerPhotos(String brokerId) async {
    try {
      final brokerDir = await _getBrokerMediaDirectory(brokerId);
      
      if (!await brokerDir.exists()) {
        return [];
      }
      
      final files = brokerDir.listSync();
      final photoFiles = files
          .whereType<File>()
          .where((file) => file.path.endsWith('.jpg') || file.path.endsWith('.png'))
          .map((file) => file.path)
          .toList();
      
      // Sort by modification time (newest first)
      photoFiles.sort((a, b) {
        final fileA = File(a);
        final fileB = File(b);
        return fileB.lastModifiedSync().compareTo(fileA.lastModifiedSync());
      });
      
      return photoFiles;
    } catch (e) {
      throw Exception('Failed to get broker photos: $e');
    }
  }

  /// Get total storage used by a broker's media
  static Future<int> getBrokerMediaSize(String brokerId) async {
    try {
      final brokerDir = await _getBrokerMediaDirectory(brokerId);
      
      if (!await brokerDir.exists()) {
        return 0;
      }
      
      int totalSize = 0;
      final files = brokerDir.listSync();
      
      for (var file in files) {
        if (file is File) {
          totalSize += await file.length();
        }
      }
      
      return totalSize;
    } catch (e) {
      throw Exception('Failed to get broker media size: $e');
    }
  }

  /// Clean up all media for a broker (when deleting broker record)
  static Future<void> cleanupBrokerMedia(String brokerId) async {
    try {
      final brokerDir = await _getBrokerMediaDirectory(brokerId);
      
      if (await brokerDir.exists()) {
        await brokerDir.delete(recursive: true);
      }
    } catch (e) {
      throw Exception('Failed to cleanup broker media: $e');
    }
  }

  /// Check if a photo file exists
  static Future<bool> photoExists(String filePath) async {
    try {
      final file = File(filePath);
      return await file.exists();
    } catch (e) {
      return false;
    }
  }

  /// Get file size in human-readable format
  static String formatFileSize(int bytes) {
    if (bytes <= 0) return "0 B";
    const suffixes = ["B", "KB", "MB", "GB"];
    int i = (bytes.toString().length / 3).ceil();
    return '${(bytes / pow(1024, i - 1).toInt()).toStringAsFixed(2)} ${suffixes[i - 1]}';
  }

  /// Convert bytes to MB
  static double bytesToMB(int bytes) {
    return bytes / (1024 * 1024);
  }
}
