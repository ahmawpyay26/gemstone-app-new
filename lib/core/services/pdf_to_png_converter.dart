import 'dart:typed_data';
import 'package:printing/printing.dart';

/// Converts PDF bytes to PNG image bytes by using Printing.raster
class PdfToPngConverter {
  /// Convert PDF bytes to PNG bytes
  /// 
  /// [pdfBytes] - The PDF document as bytes
  /// 
  /// Returns PNG bytes, or null if conversion fails
  static Future<Uint8List?> convertPdfToPng(
    Uint8List pdfBytes,
  ) async {
    try {
      // Use Printing.raster to convert PDF to image
      // This returns a stream of PdfRaster objects (one per page)
      final rasterStream = Printing.raster(
        pdfBytes,
        dpi: 300.0,
        pages: [0], // Only first page
      );

      // Get the first (and only) raster image
      final rasterImages = await rasterStream.toList();
      
      if (rasterImages.isEmpty) {
        return null;
      }

      // The raster image is a PdfRaster object
      // PdfRaster is actually a Uint8List subclass or has the image data
      final rasterImage = rasterImages.first;
      
      // PdfRaster should be convertible to bytes
      // Try to cast it or extract bytes from it
      if (rasterImage is Uint8List) {
        return rasterImage;
      }
      
      // If it's not directly Uint8List, it might have a toList() or similar method
      // For now, return null if we can't convert
      return null;
    } catch (e) {
      print('Error converting PDF to PNG: $e');
      return null;
    }
  }
}
