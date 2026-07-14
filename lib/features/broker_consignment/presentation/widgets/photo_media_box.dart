import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/local/models.dart';
import '../../../../core/services/media_storage_service.dart';

class PhotoMediaBox extends StatefulWidget {
  final String brokerId;
  final BrokerConsignment brokerConsignment;
  final VoidCallback onPhotosUpdated;

  const PhotoMediaBox({
    Key? key,
    required this.brokerId,
    required this.brokerConsignment,
    required this.onPhotosUpdated,
  }) : super(key: key);

  @override
  State<PhotoMediaBox> createState() => _PhotoMediaBoxState();
}

class _PhotoMediaBoxState extends State<PhotoMediaBox> {
  final ImagePicker _imagePicker = ImagePicker();
  List<String> _photos = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadPhotos();
  }

  Future<void> _loadPhotos() async {
    try {
      setState(() => _isLoading = true);
      final photos = await MediaStorageService.getBrokerPhotos(widget.brokerId);
      
      // Filter to only include photos that exist in the file system
      final validPhotos = <String>[];
      for (final photo in photos) {
        if (await MediaStorageService.photoExists(photo)) {
          validPhotos.add(photo);
        }
      }
      
      setState(() => _photos = validPhotos);
    } catch (e) {
      debugPrint('Error loading photos: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _takePhoto() async {
    try {
      final XFile? photo = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
      );

      if (photo != null) {
        _addPhoto(File(photo.path));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('ကင်မရာ အမှားအယွင်း: $e')),
        );
      }
    }
  }

  Future<void> _pickPhotoFromGallery() async {
    try {
      final XFile? photo = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );

      if (photo != null) {
        _addPhoto(File(photo.path));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('ဂ్যালারీ အမှားအယွင်း: $e')),
        );
      }
    }
  }

  Future<void> _addPhoto(File photoFile) async {
    try {
      setState(() => _isLoading = true);

      // Save photo using media storage service
      final savedPath = await MediaStorageService.savePhoto(
        photoFile,
        widget.brokerId,
      );

      // Add to broker consignment photoPaths
      widget.brokerConsignment.photoPaths.add(savedPath);
      widget.brokerConsignment.updatedAt = DateTime.now().millisecondsSinceEpoch;

      // Update in Hive
      final box = Hive.box<BrokerConsignment>('brokerConsignments');
      await box.put(widget.brokerId, widget.brokerConsignment);

      // Reload photos
      await _loadPhotos();

      // Notify parent
      widget.onPhotosUpdated();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('ဓာတ်ပုံ သိမ်းဆည်းမှု အောင်မြင်ပါသည်။')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('ဓာတ်ပုံ သိမ်းဆည်းမှု အမှားအယွင်း: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _deletePhoto(String photoPath) async {
    try {
      // Show confirmation dialog
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: Colors.grey[900],
          title: const Text('ဓာတ်ပုံ ဖျက်ရန်'),
          content: const Text('ဤဓာတ်ပုံကို ဖျက်မည်ဖြစ်သည်။ ဆက်လက်မည်ဖြစ်သည်။'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('ပယ်ဖျက်ရန်'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('ဖျက်ရန်'),
            ),
          ],
        ),
      );

      if (confirmed != true) return;

      setState(() => _isLoading = true);

      // Delete from file system
      await MediaStorageService.deletePhoto(photoPath);

      // Remove from broker consignment photoPaths
      widget.brokerConsignment.photoPaths.remove(photoPath);
      widget.brokerConsignment.updatedAt = DateTime.now().millisecondsSinceEpoch;

      // Update in Hive
      final box = Hive.box<BrokerConsignment>('brokerConsignments');
      await box.put(widget.brokerId, widget.brokerConsignment);

      // Reload photos
      await _loadPhotos();

      // Notify parent
      widget.onPhotosUpdated();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('ဓာတ်ပုံ ဖျက်မှု အောင်မြင်ပါသည်။')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('ဓာတ်ပုံ ဖျက်မှု အမှားအယွင်း: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header
        Padding(
          padding: const EdgeInsets.only(top: 16, bottom: 12),
          child: Text(
            'ဓာတ်ပုံမှတ်တမ်း',
            style: const TextStyle(
              color: AppTheme.primaryAccent,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),

        // Photo Grid
        if (_isLoading)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryAccent),
              ),
            ),
          )
        else if (_photos.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.3),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: Colors.grey[700]!,
                width: 1,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.image_not_supported_outlined,
                  size: 48,
                  color: Colors.grey[600],
                ),
                const SizedBox(height: 12),
                Text(
                  'ဓာတ်ပုံမရှိသေးပါ',
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          )
        else
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: _photos.length,
            itemBuilder: (context, index) {
              final photoPath = _photos[index];
              return _buildPhotoTile(photoPath, index);
            },
          ),

        const SizedBox(height: 12),

        // Add Photo Buttons
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _takePhoto,
                icon: const Icon(Icons.camera_alt),
                label: const Text('ကင်မရာ'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryAccent,
                  foregroundColor: Colors.black,
                  disabledBackgroundColor: Colors.grey[600],
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _pickPhotoFromGallery,
                icon: const Icon(Icons.photo_library),
                label: const Text('ပြခန်း'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryAccent,
                  foregroundColor: Colors.black,
                  disabledBackgroundColor: Colors.grey[600],
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),

        // Storage Info
        if (_photos.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: FutureBuilder<int>(
              future: MediaStorageService.getBrokerMediaSize(widget.brokerId),
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  final sizeInMB = MediaStorageService.bytesToMB(snapshot.data!);
                  return Text(
                    'စုစုပေါင်း: ${_photos.length} ဓာတ်ပုံ | အရွယ်အစား: ${sizeInMB.toStringAsFixed(2)} MB',
                    style: TextStyle(
                      color: Colors.grey[500],
                      fontSize: 12,
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ),
      ],
    );
  }

  Widget _buildPhotoTile(String photoPath, int index) {
    return GestureDetector(
      onTap: () => _showPhotoViewer(photoPath),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey[700]!, width: 1),
          color: Colors.black.withOpacity(0.3),
        ),
        child: Stack(
          children: [
            // Photo
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.file(
                  File(photoPath),
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: Colors.grey[800],
                      child: Icon(
                        Icons.broken_image,
                        color: Colors.grey[600],
                      ),
                    );
                  },
                ),
              ),
            ),

            // Delete Button
            Positioned(
              top: 4,
              right: 4,
              child: GestureDetector(
                onTap: () => _deletePhoto(photoPath),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.8),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.close,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
              ),
            ),

            // Photo Number Badge
            Positioned(
              bottom: 4,
              left: 4,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '${index + 1}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showPhotoViewer(String photoPath) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PhotoViewerPage(
          photoPath: photoPath,
          photos: _photos,
          initialIndex: _photos.indexOf(photoPath),
        ),
      ),
    );
  }
}

/// Full-screen photo viewer
class PhotoViewerPage extends StatefulWidget {
  final String photoPath;
  final List<String> photos;
  final int initialIndex;

  const PhotoViewerPage({
    Key? key,
    required this.photoPath,
    required this.photos,
    required this.initialIndex,
  }) : super(key: key);

  @override
  State<PhotoViewerPage> createState() => _PhotoViewerPageState();
}

class _PhotoViewerPageState extends State<PhotoViewerPage> {
  late PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black87,
        title: Text(
          'ဓာတ်ပုံ ${_currentIndex + 1} / ${widget.photos.length}',
          style: const TextStyle(color: Colors.white),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: PageView.builder(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() => _currentIndex = index);
        },
        itemCount: widget.photos.length,
        itemBuilder: (context, index) {
          final photoPath = widget.photos[index];
          return InteractiveViewer(
            minScale: 1.0,
            maxScale: 4.0,
            child: Image.file(
              File(photoPath),
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.broken_image,
                        size: 64,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'ဓာတ်ပုံ မတွေ့ရှိပါ',
                        style: TextStyle(color: Colors.grey[400]),
                      ),
                    ],
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
