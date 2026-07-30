import 'dart:typed_data';
import 'package:printing/printing.dart';
import 'package:image/image.dart' as img;

/// Converts PDF bytes to PNG image bytes by rendering the first page
class PdfToPngConverter {
  /// Convert PDF bytes to PNG bytes
  /// 
  /// [pdfBytes] - The PDF document as bytes
  /// [dpi] - DPI for rasterization (default 300 for high quality)
  /// 
  /// Returns PNG bytes, or null if conversion fails
  static Future<Uint8List?> convertPdfToPng(
    Uint8List pdfBytes, {
    int dpi = 300,
  }) async {
    try {
      // Rasterize the first page of the PDF to bitmap
      final List<Uint8List> pages = await Printing.raster(
        pdfBytes,
        dpi: dpi,
        pages: [0], // Only first page
      ).toList();

      if (pages.isEmpty) {
        return null;
      }

      // The raster output is raw image data (typically RGBA)
      // We need to decode it as an image and encode as PNG
      final imageBytes = pages.first;
      
      // Decode the raster image
      // The raster output is typically in a specific format that needs decoding
      // For now, we'll use the image package to handle this
      final image = img.Image.fromBytes(
        width: 595, // A4 width in pixels at 72 DPI (approx)
        height: 842, // A4 height in pixels at 72 DPI (approx)
        bytes: imageBytes.buffer,
        format: img.Format.uint8,
      );

      // Encode as PNG
      final pngBytes = img.encodePng(image);
      return Uint8List.fromList(pngBytes);
    } catch (e) {
      print('Error converting PDF to PNG: $e');
      return null;
    }
  }
}
