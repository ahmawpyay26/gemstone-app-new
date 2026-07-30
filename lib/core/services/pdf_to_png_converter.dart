import 'dart:typed_data';
import 'package:pdf_render/pdf_render.dart';
import 'package:image/image.dart' as img;

/// Converts PDF bytes to PNG image bytes by rendering the first page
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
      // Load PDF document from bytes
      final document = await PdfDocument.openData(pdfBytes);
      
      if (document.pageCount == 0) {
        return null;
      }

      // Get the first page
      final page = await document.getPage(1);
      
      // Render page to image at high DPI (300 DPI equivalent)
      // Page size is typically in points (1/72 inch)
      // For 300 DPI, we need to scale up: 300/72 = 4.167
      final pageSize = page.pageSize;
      final scale = 4.0; // Approximately 288 DPI
      
      final image = await page.render(
        width: (pageSize.width * scale).toInt(),
        height: (pageSize.height * scale).toInt(),
      );
      
      if (image == null) {
        return null;
      }

      // The rendered image is already in the correct format
      // Convert to PNG bytes
      final pngBytes = img.encodePng(image);
      return Uint8List.fromList(pngBytes);
    } catch (e) {
      print('Error converting PDF to PNG: $e');
      return null;
    }
  }
}
