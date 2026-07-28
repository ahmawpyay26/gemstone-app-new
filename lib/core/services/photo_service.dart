import 'dart:io';
import 'dart:developer' as developer;
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import 'sales_photo_diagnostic_service.dart';

class PhotoService {
  static final PhotoService _instance = PhotoService._internal();
  final ImagePicker _picker = ImagePicker();

  PhotoService._internal();

  factory PhotoService() {
    return _instance;
  }

  /// Pick photo from camera
  Future<String?> pickPhotoFromCamera() async {
    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
      );
      if (photo != null) {
        developer.log('[SALES-PHOTO-A] ImagePicker source path (camera): ${photo.path}');
        return await _savePhotoLocally(File(photo.path));
      }
    } catch (e) {
      print('Error picking photo from camera: $e');
    }
    return null;
  }

  /// Pick photo from gallery
  Future<String?> pickPhotoFromGallery() async {
    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );
      if (photo != null) {
        developer.log('[SALES-PHOTO-A] ImagePicker source path (gallery): ${photo.path}');
        return await _savePhotoLocally(File(photo.path));
      }
    } catch (e) {
      print('Error picking photo from gallery: $e');
    }
    return null;
  }

  /// Save photo to app's local storage
  Future<String> _savePhotoLocally(File photoFile) async {
    try {
      final Directory appDir = await getApplicationDocumentsDirectory();
      developer.log('[SALES-PHOTO-M] App documents directory at save time: ${appDir.path}');
      final String photoDir = '${appDir.path}/photos';
      final Directory photoDirObj = Directory(photoDir);

      // Create photos directory if it doesn't exist
      if (!await photoDirObj.exists()) {
        await photoDirObj.create(recursive: true);
      }

      // Generate unique filename
      const uuid = Uuid();
      final String fileName = '${uuid.v4()}.jpg';
      final String filePath = '$photoDir/$fileName';

      // Copy photo to app directory
      await photoFile.copy(filePath);
      developer.log('[SALES-PHOTO-B] Destination path after File.copy(): $filePath');
      SalesPhotoDiagnosticService().log(
        checkpoint: '[SALES-PHOTO-B]',
        message: 'Destination path after File.copy()',
        path: filePath,
      );
      
      // Check if file exists immediately after copy
      final exists = File(filePath).existsSync();
      developer.log('[SALES-PHOTO-C] File exists immediately after copy: $exists');
      
      // Get file size
      if (exists) {
        try {
          final size = File(filePath).lengthSync();
          developer.log('[SALES-PHOTO-D] File size after copy: $size bytes');
        } catch (e) {
          developer.log('[SALES-PHOTO-D] Error getting file size: $e');
        }
      }
      
      return filePath;
    } catch (e) {
      print('Error saving photo locally: $e');
      rethrow;
    }
  }

  /// Get photo file from path
  File? getPhotoFile(String photoPath) {
    try {
      final File file = File(photoPath);
      if (file.existsSync()) {
        return file;
      }
    } catch (e) {
      print('Error getting photo file: $e');
    }
    return null;
  }

  /// Delete photo file
  Future<bool> deletePhoto(String photoPath) async {
    try {
      final File file = File(photoPath);
      if (await file.exists()) {
        developer.log('[SALES-PHOTO-DELETE] Deleting photo: $photoPath');
        await file.delete();
        developer.log('[SALES-PHOTO-DELETE-DONE] Photo deleted: $photoPath');
        return true;
      }
    } catch (e) {
      print('Error deleting photo: $e');
    }
    return false;
  }

  /// Check if photo exists
  bool photoExists(String photoPath) {
    try {
      return File(photoPath).existsSync();
    } catch (e) {
      return false;
    }
  }

  /// Get all photos for a record
  List<File> getPhotosForRecord(List<String> photoPaths) {
    final List<File> photos = [];
    for (final path in photoPaths) {
      final file = getPhotoFile(path);
      if (file != null) {
        photos.add(file);
      }
    }
    return photos;
  }

  /// Cleanup orphaned photos (photos not referenced in any record)
  Future<void> cleanupOrphanedPhotos(List<String> activePhotoPaths) async {
    try {
      final Directory appDir = await getApplicationDocumentsDirectory();
      final String photoDir = '${appDir.path}/photos';
      final Directory photoDirObj = Directory(photoDir);

      if (!await photoDirObj.exists()) return;

      developer.log('[SALES-PHOTO-CLEANUP] Starting orphaned photo cleanup');
      final List<FileSystemEntity> files = photoDirObj.listSync();
      for (final file in files) {
        if (file is File) {
          if (!activePhotoPaths.contains(file.path)) {
            developer.log('[SALES-PHOTO-CLEANUP-DELETE] Deleting orphaned: ${file.path}');
            await file.delete();
          }
        }
      }
      developer.log('[SALES-PHOTO-CLEANUP-DONE] Orphaned photo cleanup completed');
    } catch (e) {
      print('Error cleaning up orphaned photos: $e');
    }
  }
}
