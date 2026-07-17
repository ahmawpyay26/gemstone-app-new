import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/broker_voucher_document.dart';
import 'broker_voucher_pdf_generator.dart';

/// Handles PDF export, file management, and native sharing for broker vouchers
class BrokerVoucherExportService {
  /// Generate and share PDF file
  /// Returns true if successful, false if failed
  static Future<bool> exportPdfAndShare(
    BrokerVoucherDocumentData data,
  ) async {
    try {
      // Generate PDF bytes
      final pdfBytes = await BrokerVoucherPdfGenerator.generatePdf(data);

      // Create safe filename
      final filename = _getSafeFilename(data.voucherNumber, 'pdf');

      // Write to temporary cache directory
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/$filename');
      await file.writeAsBytes(pdfBytes);

      // Open native share sheet
      await Share.shareXFiles(
        [XFile(file.path, mimeType: 'application/pdf')],
        text: 'ပွဲစားအပ်နှံဘောင်ချာ - ${data.voucherNumber}',
      );

      return true;
    } catch (e) {
      rethrow;
    }
  }

  /// Get PDF bytes for printing (without sharing)
  static Future<Uint8List> getPdfBytes(
    BrokerVoucherDocumentData data,
  ) async {
    return await BrokerVoucherPdfGenerator.generatePdf(data);
  }

  /// Generate safe filename from voucher number
  static String _getSafeFilename(String voucherNumber, String extension) {
    // Remove special characters and replace with hyphens
    final safe = voucherNumber
        .replaceAll(RegExp(r'[^a-zA-Z0-9\-]'), '-')
        .replaceAll(RegExp(r'-+'), '-')
        .toLowerCase();
    return 'broker-consignment-$safe.$extension';
  }

  /// Clean up old temporary export files
  static Future<void> cleanupOldExports() async {
    try {
      final tempDir = await getTemporaryDirectory();
      final files = tempDir.listSync();

      for (final file in files) {
        if (file is File && file.path.contains('broker-consignment-')) {
          final lastModified = file.lastModifiedSync();
          final age = DateTime.now().difference(lastModified);

          // Delete files older than 24 hours
          if (age.inHours > 24) {
            await file.delete();
          }
        }
      }
    } catch (e) {
      // Silently ignore cleanup errors
    }
  }
}
