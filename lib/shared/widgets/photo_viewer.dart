import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class PhotoViewer extends StatefulWidget {
  final List<String> photoUrls;
  final int initialIndex;

  const PhotoViewer({
    Key? key,
    required this.photoUrls,
    this.initialIndex = 0,
  }) : super(key: key);

  @override
  State<PhotoViewer> createState() => _PhotoViewerState();
}

class _PhotoViewerState extends State<PhotoViewer> {
  late PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: _currentIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _handleDoubleTap() {
    // Double tap zoom is handled by InteractiveViewer
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
        actions: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Center(
              child: Text(
                '${_currentIndex + 1} / ${widget.photoUrls.length}',
                style: const TextStyle(color: Colors.white, fontSize: 16),
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
          });
        },
        itemBuilder: (context, index) => GestureDetector(
          onDoubleTap: _handleDoubleTap,
          child: InteractiveViewer(
            minScale: 1.0,
            maxScale: 3.0,
            child: Image.network(
              widget.photoUrls[index],
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
            ),
          ),
        ),
      ),
    );
  }
}
