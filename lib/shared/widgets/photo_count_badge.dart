import 'package:flutter/material.dart';

/// Reusable photo count badge widget
/// Shows a compact badge with camera icon and count
/// Only displays if count > 0
class PhotoCountBadge extends StatelessWidget {
  final int count;
  final double? fontSize;
  final Color? backgroundColor;
  final Color? textColor;

  const PhotoCountBadge({
    Key? key,
    required this.count,
    this.fontSize,
    this.backgroundColor,
    this.textColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Don't show badge if count is 0
    if (count == 0) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor ?? Colors.grey[800],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.camera_alt_outlined,
            size: (fontSize ?? 12) + 2,
            color: textColor ?? Colors.white70,
          ),
          const SizedBox(width: 4),
          Text(
            count.toString(),
            style: TextStyle(
              fontSize: fontSize ?? 12,
              color: textColor ?? Colors.white70,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
