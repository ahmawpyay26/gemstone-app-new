import 'dart:typed_data';
import 'dart:ui' as ui;

/// Holds a pre-decoded [ui.Image] alongside raw bytes for off-screen rendering.
///
/// This shared type is used by all invoice exporters to avoid duplication
/// and type mismatches when passing decoded logos to off-screen render trees.
class DecodedLogo {
  final Uint8List bytes;
  final ui.Image image;
  
  const DecodedLogo({
    required this.bytes,
    required this.image,
  });
}
