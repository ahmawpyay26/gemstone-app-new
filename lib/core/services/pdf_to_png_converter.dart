import 'dart:typed_data';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
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

      // The raster image is already in bitmap format
      // We need to save it as PNG
      final rasterImage = rasterImages.first;
      
      // Create a temporary file to store the PNG
      final tempDir = await getTemporaryDirectory();
      final tempFile = File('${tempDir.path}/temp_raster_${DateTime.now().millisecondsSinceEpoch}.png');
      
      // Write the raster image bytes to file
      await tempFile.writeAsBytes(rasterImage);
      
      // Read back as PNG bytes
      final pngBytes = await tempFile.readAsBytes();
      
      // Clean up temp file
      try {
        await tempFile.delete();
      } catch (_) {
        // Ignore cleanup errors
      }
      
      return pngBytes;
    } catch (e) {
      print('Error converting PDF to PNG: $e');
      return null;
    }
  }
}
