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
    double dpi = 300.0,
  }) async {
    try {
      // Rasterize the first page of the PDF to bitmap
      final pages = await Printing.raster(
        pdfBytes,
        dpi: dpi,
        pages: [0], // Only first page
      ).toList();

      if (pages.isEmpty) {
        return null;
      }

      // The raster output is a PdfRaster object with image data
      final pdfRaster = pages.first;
      
      // Convert PdfRaster to image bytes
      // PdfRaster has width, height, and image properties
      final imageBytes = pdfRaster.image;
      
      if (imageBytes == null || imageBytes.isEmpty) {
        return null;
      }

      // Decode the raster image from the raw bytes
      // PdfRaster.image is typically RGBA format
      final image = img.Image.fromBytes(
        width: pdfRaster.width,
        height: pdfRaster.height,
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
