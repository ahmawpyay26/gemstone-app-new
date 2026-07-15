import 'package:flutter/material.dart';
import 'dart:io';
import '../../core/theme/app_theme.dart';

/// Enhanced PhotoViewer with metadata display and long press menu
/// Features:
/// - Display item name and voucher number
/// - Show current photo index and total count
/// - Long press menu (Share, Save to Gallery, Delete in edit mode)
/// - Lazy loading for performance
class EnhancedPhotoViewer extends StatefulWidget {
  final List<String> photoUrls;
  final String? itemName;
  final String? voucherNumber;
  final int initialIndex;
  final bool isEditingMode;

  const EnhancedPhotoViewer({
    Key? key,
    required this.photoUrls,
    this.itemName,
    this.voucherNumber,
    this.initialIndex = 0,
    this.isEditingMode = false,
  }) : super(key: key);

  @override
  State<EnhancedPhotoViewer> createState() => _EnhancedPhotoViewerState();
}

class _EnhancedPhotoViewerState extends State<EnhancedPhotoViewer> {
  late PageController _pageController;
  late int _currentIndex;
  final Map<int, ImageProvider> _imageCache = {};

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: _currentIndex);
    // Pre-cache nearby images for smooth scrolling
    _precacheImages();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _imageCache.clear();
    super.dispose();
  }

  /// Lazy load images - cache current and adjacent images only
  void _precacheImages() {
    final indices = [
      _currentIndex - 1,
      _currentIndex,
      _currentIndex + 1,
    ].where((i) => i >= 0 && i < widget.photoUrls.length);

    for (var index in indices) {
      if (!_imageCache.containsKey(index)) {
        _cacheImage(index);
      }
    }
  }

  void _cacheImage(int index) {
    if (index < 0 || index >= widget.photoUrls.length) return;

    final photoPath = widget.photoUrls[index];
    final isLocalFile = !photoPath.startsWith('http');

    try {
      if (isLocalFile) {
        final file = File(photoPath);
        if (file.existsSync()) {
          _imageCache[index] = FileImage(file);
        }
      } else {
        _imageCache[index] = NetworkImage(photoPath);
      }
    } catch (e) {
      debugPrint('Error caching image at index $index: $e');
    }
  }

  Widget _buildPhotoImage(String photoPath) {
    final isLocalFile = !photoPath.startsWith('http');

    if (isLocalFile) {
      final file = File(photoPath);

      if (!file.existsSync()) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.image_not_supported, size: 80, color: Colors.grey[600]),
              const SizedBox(height: 12),
              Text(
                'ဓာတ်ပုံ မတွေ့နိုင်ပါ',
                style: TextStyle(color: Colors.grey[400]),
              ),
            ],
          ),
        );
      }

      return Image.file(
        file,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.broken_image, size: 80, color: Colors.grey[600]),
                const SizedBox(height: 12),
                Text(
                  'ဓာတ်ပုံ မဖွင့်နိုင်ပါ',
                  style: TextStyle(color: Colors.grey[400]),
                ),
              ],
            ),
          );
        },
      );
    } else {
      return Image.network(
        photoPath,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.broken_image, size: 80, color: Colors.grey[600]),
                const SizedBox(height: 12),
                Text(
                  'ဓာတ်ပုံ မဖွင့်နိုင်ပါ',
                  style: TextStyle(color: Colors.grey[400]),
                ),
              ],
            ),
          );
        },
      );
    }
  }

  /// Feature 4: Long press menu
  void _showPhotoMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey[900],
      builder: (context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Share option
            ListTile(
              leading: const Icon(Icons.share, color: Colors.blue),
              title: const Text('မျှဝေရန်'),
              onTap: () {
                Navigator.pop(context);
                _sharePhoto();
              },
            ),
            // Save to Gallery option
            ListTile(
              leading: const Icon(Icons.save, color: Colors.green),
              title: const Text('ပုံတိုက်သို့ သိမ်းဆည်းရန်'),
              onTap: () {
                Navigator.pop(context);
                _saveToGallery();
              },
            ),
            // Delete option (editing mode only)
            if (widget.isEditingMode)
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('ဖျက်ရန်'),
                onTap: () {
                  Navigator.pop(context);
                  _deletePhoto();
                },
              ),
          ],
        ),
      ),
    );
  }

  void _sharePhoto() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('မျှဝေမှု လုပ်ဆောင်ချက် မကြေးမုံရောင်းချမှု ကဏ္ဍတွင် ရှိသေးပါ။')),
    );
  }

  void _saveToGallery() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('ပုံတိုက်သို့ သိမ်းဆည်းမှု လုပ်ဆောင်ချက် မကြေးမုံရောင်းချမှု ကဏ္ဍတွင် ရှိသေးပါ။')),
    );
  }

  void _deletePhoto() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('ဖျက်မှု လုပ်ဆောင်ချက် မကြေးမုံရောင်းချမှု ကဏ္ဍတွင် ရှိသေးပါ။')),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.photoUrls.isEmpty) {
      return Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black,
          leading: IconButton(
            icon: const Icon(Icons.close, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.image_not_supported, size: 80, color: Colors.grey[600]),
              const SizedBox(height: 20),
              Text(
                'ဤမှတ်တမ်းတွင် ဓာတ်ပုံမရှိသေးပါ။',
                style: TextStyle(color: Colors.grey[400], fontSize: 16),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Feature 3: Photo Information - Item name and voucher number
            if (widget.itemName != null)
              Text(
                widget.itemName!,
                style: const TextStyle(color: Colors.white, fontSize: 14),
              ),
            if (widget.voucherNumber != null)
              Text(
                'ရည်ညွှန်း: ${widget.voucherNumber}',
                style: TextStyle(color: Colors.grey[400], fontSize: 12),
              ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Center(
              child: Text(
                '${_currentIndex + 1} / ${widget.photoUrls.length}',
                style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
      body: PageView.builder(
        controller: _pageController,
        itemCount: widget.photoUrls.length,
        onPageChanged: (index) {
          setState(() {
            _currentIndex = index;
            // Feature 5: Lazy load - cache nearby images
            _precacheImages();
          });
        },
        itemBuilder: (context, index) => GestureDetector(
          // Feature 4: Long press menu
          onLongPress: () => _showPhotoMenu(context),
          child: InteractiveViewer(
            minScale: 1.0,
            maxScale: 3.0,
            child: _buildPhotoImage(widget.photoUrls[index]),
          ),
        ),
      ),
    );
  }
}
