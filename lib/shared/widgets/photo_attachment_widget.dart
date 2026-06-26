import 'dart:io';
import 'package:flutter/material.dart';
import '../../core/services/photo_service.dart';
import '../../core/theme/app_theme.dart';

class PhotoAttachmentWidget extends StatefulWidget {
  final List<String> photoPaths;
  final ValueChanged<List<String>> onPhotosChanged;
  final String recordType; // 'purchase' or 'sale'

  const PhotoAttachmentWidget({
    Key? key,
    required this.photoPaths,
    required this.onPhotosChanged,
    required this.recordType,
  }) : super(key: key);

  @override
  State<PhotoAttachmentWidget> createState() => _PhotoAttachmentWidgetState();
}

class _PhotoAttachmentWidgetState extends State<PhotoAttachmentWidget> {
  final PhotoService _photoService = PhotoService();
  late List<String> _currentPhotos;

  @override
  void initState() {
    super.initState();
    _currentPhotos = List.from(widget.photoPaths);
  }

  Future<void> _addPhotoFromCamera() async {
    try {
      final String? photoPath = await _photoService.pickPhotoFromCamera();
      if (photoPath != null) {
        setState(() {
          _currentPhotos.add(photoPath);
        });
        widget.onPhotosChanged(_currentPhotos);
      }
    } catch (e) {
      _showError('ကင်မရာမှ ဓာတ်ပုံ ရွေးချယ်မှု ပျက်ခဲ့သည်');
    }
  }

  Future<void> _addPhotoFromGallery() async {
    try {
      final String? photoPath = await _photoService.pickPhotoFromGallery();
      if (photoPath != null) {
        setState(() {
          _currentPhotos.add(photoPath);
        });
        widget.onPhotosChanged(_currentPhotos);
      }
    } catch (e) {
      _showError('ဂ్যალারီမှ ဓာတ်ပုံ ရွေးချယ်မှု ပျက်ခဲ့သည်');
    }
  }

  Future<void> _deletePhoto(int index) async {
    final String photoPath = _currentPhotos[index];
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          'ဓာတ်ပုံ ဖျက်ရန်',
          style: TextStyle(fontFamily: 'NotoSansMyammer'),
        ),
        content: const Text(
          'ဤဓာတ်ပုံကို ဖျက်ရန် သေချာပါသလား?',
          style: TextStyle(fontFamily: 'NotoSansMyammer'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(
              'ပယ်ဖျက်ရန်',
              style: TextStyle(fontFamily: 'NotoSansMyammer'),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'ဖျက်ရန်',
              style: TextStyle(fontFamily: 'NotoSansMyammer'),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _photoService.deletePhoto(photoPath);
      setState(() {
        _currentPhotos.removeAt(index);
      });
      widget.onPhotosChanged(_currentPhotos);
    }
  }

  void _showPhotoPreview(String photoPath) {
    final File? file = _photoService.getPhotoFile(photoPath);
    if (file != null) {
      showDialog(
        context: context,
        builder: (context) => Dialog(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppBar(
                title: const Text(
                'ဓာတ်ပုံ အစမ်း',
                style: TextStyle(fontFamily: 'NotoSansMyammer'),
              ),
                automaticallyImplyLeading: true,
              ),
              Expanded(
                child: Image.file(
                  file,
                  fit: BoxFit.contain,
                ),
              ),
            ],
          ),
        ),
      );
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Photo action buttons
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _addPhotoFromCamera,
                icon: const Icon(Icons.camera_alt),
                label: Text(
                  '📷 ကင်မရာ',
                  style: const TextStyle(
                    fontFamily: 'NotoSansMyammer',
                    fontSize: 14,
                  ),
                  textScaleFactor: 1.0,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _addPhotoFromGallery,
                icon: const Icon(Icons.photo_library),
                label: Text(
                  '🖼 ပြခန်း',
                  style: const TextStyle(
                    fontFamily: 'NotoSansMyammer',
                    fontSize: 14,
                  ),
                  textScaleFactor: 1.0,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Photo thumbnails
        if (_currentPhotos.isNotEmpty)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'ဓာတ်ပုံများ (${_currentPhotos.length})',
                style: const TextStyle(
                  fontFamily: 'NotoSansMyammer',
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
                textScaleFactor: 1.0,
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 100,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _currentPhotos.length,
                  itemBuilder: (context, index) {
                    final photoPath = _currentPhotos[index];
                    final file = _photoService.getPhotoFile(photoPath);

                    if (file == null) return const SizedBox.shrink();

                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: Stack(
                        children: [
                          GestureDetector(
                            onTap: () => _showPhotoPreview(photoPath),
                            child: Container(
                              width: 100,
                              height: 100,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: AppTheme.primaryAccent,
                                  width: 2,
                                ),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(6),
                                child: Image.file(
                                  file,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                          ),
                          Positioned(
                            top: 0,
                            right: 0,
                            child: GestureDetector(
                              onTap: () => _deletePhoto(index),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.red,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                padding: const EdgeInsets.all(4),
                                child: const Icon(
                                  Icons.close,
                                  color: Colors.white,
                                  size: 16,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
      ],
    );
  }
}
