import 'dart:typed_data';
import 'package:pdfx/pdfx.dart';

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
      
      if (document.pagesCount == 0) {
        return null;
      }

      // Get the first page
      final page = await document.getPage(1);
      
      if (page == null) {
        return null;
      }

      // Render page to image at high DPI (approximately 288 DPI)
      // Use 2.0 scale factor for good quality
      final image = await page.render(
        width: (page.width * 2.0).toInt(),
        height: (page.height * 2.0).toInt(),
        format: PdfPageImageFormat.png,
      );
      
      if (image == null) {
        return null;
      }

      // Image is a PdfPageImage object, extract the bytes
      return image.bytes;
    } catch (e) {
      print('Error converting PDF to PNG: $e');
      return null;
    }
  }
}
