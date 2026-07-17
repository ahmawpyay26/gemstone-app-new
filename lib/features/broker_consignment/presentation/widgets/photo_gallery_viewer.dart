import 'dart:io';
import 'package:flutter/material.dart';

/// Reusable full-screen photo gallery viewer with zoom, swipe, and index
class PhotoGalleryViewer extends StatefulWidget {
  final List<String> photoPaths;
  final String title;
  final bool allowZoom;

  const PhotoGalleryViewer({
    Key? key,
    required this.photoPaths,
    required this.title,
    this.allowZoom = true,
  }) : super(key: key);

  @override
  State<PhotoGalleryViewer> createState() => _PhotoGalleryViewerState();
}

class _PhotoGalleryViewerState extends State<PhotoGalleryViewer> {
  late PageController _pageController;
  int _currentIndex = 0;
  late List<String> _validPhotos;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _validPhotos = widget.photoPaths.where((path) => File(path).existsSync()).toList();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_validPhotos.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.title)),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.image_not_supported, size: 64, color: Colors.grey),
              SizedBox(height: 16),
              Text(
                'ဓာတ်ပုံများ မရှိသေးပါ',
                style: TextStyle(fontFamily: 'Padauk', fontSize: 16),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          Padding(
            padding: EdgeInsets.all(16),
            child: Center(
              child: Text(
                '${_currentIndex + 1} / ${_validPhotos.length}',
                style: TextStyle(fontSize: 14),
              ),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          // Photo carousel
          PageView.builder(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() => _currentIndex = index);
            },
            children: _validPhotos.map((path) {
              return GestureDetector(
                onTap: () {
                  // Toggle UI visibility or zoom
                },
                child: InteractiveViewer(
                  minScale: 1.0,
                  maxScale: 4.0,
                  child: Image.file(
                    File(path),
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.broken_image, size: 64, color: Colors.grey),
                            SizedBox(height: 8),
                            Text(
                              'ဓာတ်ပုံ မဖွင့်နိုင်ပါ',
                              style: TextStyle(fontFamily: 'Padauk'),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              );
            }).toList(),
          ),

          // Navigation buttons
          if (_validPhotos.length > 1)
            Positioned(
              left: 16,
              top: 0,
              bottom: 0,
              child: Center(
                child: FloatingActionButton(
                  mini: true,
                  backgroundColor: Colors.black54,
                  onPressed: () {
                    if (_currentIndex > 0) {
                      _pageController.previousPage(
                        duration: Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    }
                  },
                  child: Icon(Icons.chevron_left),
                ),
              ),
            ),
          if (_validPhotos.length > 1)
            Positioned(
              right: 16,
              top: 0,
              bottom: 0,
              child: Center(
                child: FloatingActionButton(
                  mini: true,
                  backgroundColor: Colors.black54,
                  onPressed: () {
                    if (_currentIndex < _validPhotos.length - 1) {
                      _pageController.nextPage(
                        duration: Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    }
                  },
                  child: Icon(Icons.chevron_right),
                ),
              ),
            ),

          // Dots indicator
          if (_validPhotos.length > 1)
            Positioned(
              bottom: 16,
              left: 0,
              right: 0,
              child: Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    _validPhotos.length,
                    (index) => Container(
                      width: 8,
                      height: 8,
                      margin: EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _currentIndex == index
                            ? Colors.white
                            : Colors.white54,
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
