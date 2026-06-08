import 'package:flutter/material.dart';

/// Image utility for offline-only mode with local fallback
class ImageUtils {
  /// Get placeholder image widget (no network images)
  static Widget getPlaceholderImage({
    double? width,
    double? height,
    BoxFit fit = BoxFit.cover,
  }) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: Icon(
          Icons.image_not_supported,
          color: Colors.grey[600],
          size: 40,
        ),
      ),
    );
  }

  /// Get gemstone image widget (local only)
  static Widget getGemstoneImage({
    String? imagePath,
    double? width,
    double? height,
    BoxFit fit = BoxFit.cover,
  }) {
    // In offline mode, always show placeholder
    // Network images are not supported
    return getPlaceholderImage(width: width, height: height, fit: fit);
  }

  /// Get avatar widget (local only)
  static Widget getAvatarImage({
    String? imagePath,
    double radius = 20,
  }) {
    return CircleAvatar(
      radius: radius,
      backgroundColor: Colors.grey[300],
      child: Icon(
        Icons.person,
        color: Colors.grey[600],
      ),
    );
  }
}
