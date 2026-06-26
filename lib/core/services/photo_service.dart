import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

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
        await file.delete();
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

      final List<FileSystemEntity> files = photoDirObj.listSync();
      for (final file in files) {
        if (file is File) {
          if (!activePhotoPaths.contains(file.path)) {
            await file.delete();
          }
        }
      }
    } catch (e) {
      print('Error cleaning up orphaned photos: $e');
    }
  }
}
