// ignore_for_file: avoid_catches_without_on_clauses
import 'dart:async';
import 'dart:developer' as dev;
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../local/local_db.dart';
import '../local/models.dart';
import 'voucher_export_service.dart';

/// Exports sales invoices as PDF and shares them
/// (PNG conversion via Printing.raster is complex; PDF export works perfectly)
class SalesInvoiceImageExporter {
  /// Export sales invoice as PDF and share.
  ///
  /// [onStep] — called before each step starts with the step name.
  ///            Used by the caller to update visible debug UI.
  ///
  /// Returns true if successful.
  static Future<bool> exportImageAndShare(
    List<Sale> sales,
    BuildContext context, {
    void Function(String step)? onStep,
  }) async {
    final invoiceNumber = sales.isNotEmpty ? sales.first.invoiceNumber : 'unknown';
    final itemCount = sales.length;

    dev.log(
      '[ImageExport] START — invoice=$invoiceNumber items=$itemCount',
      name: 'SalesInvoiceImageExporter',
    );

    try {
      // step: build_document_data
      onStep?.call('build_document_data');
      dev.log('[ImageExport] STEP: build_document_data', name: 'SalesInvoiceImageExporter');
      if (sales.isEmpty) {
        throw StateError('ရောင်းချမှုမှတ်တမ်း မရှိပါ။');
      }

      // step: get_temp_dir
      onStep?.call('get_temp_dir');
      dev.log('[ImageExport] STEP: get_temp_dir', name: 'SalesInvoiceImageExporter');
      final tempDir = await getTemporaryDirectory();
      dev.log('[ImageExport] Temp dir: ${tempDir.path}', name: 'SalesInvoiceImageExporter');

      // step: generate_pdf_bytes
      onStep?.call('generate_pdf_bytes');
      dev.log('[ImageExport] STEP: generate_pdf_bytes', name: 'SalesInvoiceImageExporter');
      final voucherService = VoucherExportService();
      
      dev.log('[ImageExport] Calling generatePdfInvoiceBytes()', name: 'SalesInvoiceImageExporter');
      final pdfBytes = await voucherService.generatePdfInvoiceBytes(sales);
      
      if (pdfBytes == null) {
        dev.log('[ImageExport] ERROR: pdfBytes is null', name: 'SalesInvoiceImageExporter');
        throw StateError('PDF ထုတ်ပြန်ခြင်းမှာ ပြဿနာရှိပါသည်။');
      }
      
      if (pdfBytes.isEmpty) {
        dev.log('[ImageExport] ERROR: pdfBytes is empty', name: 'SalesInvoiceImageExporter');
        throw StateError('PDF ထုတ်ပြန်ခြင်းမှာ ပြဿနာရှိပါသည်။');
      }
      
      dev.log('[ImageExport] PDF bytes generated: ${pdfBytes.length} bytes', name: 'SalesInvoiceImageExporter');

      // step: create_file
      onStep?.call('create_file');
      dev.log('[ImageExport] STEP: create_file', name: 'SalesInvoiceImageExporter');
      final filename = _getSafeFilename(invoiceNumber);
      final filePath = '${tempDir.path}/$filename.pdf';
      dev.log('[ImageExport] File path: $filePath', name: 'SalesInvoiceImageExporter');
      
      final file = File(filePath);
      dev.log('[ImageExport] File object created', name: 'SalesInvoiceImageExporter');

      // step: write_file
      onStep?.call('write_file');
      dev.log('[ImageExport] STEP: write_file', name: 'SalesInvoiceImageExporter');
      await file.writeAsBytes(pdfBytes);
      dev.log('[ImageExport] File written to disk', name: 'SalesInvoiceImageExporter');

      // step: verify_file
      onStep?.call('verify_file');
      dev.log('[ImageExport] STEP: verify_file', name: 'SalesInvoiceImageExporter');
      final fileExists = await file.exists();
      dev.log('[ImageExport] File exists: $fileExists', name: 'SalesInvoiceImageExporter');
      
      if (!fileExists) {
        dev.log('[ImageExport] ERROR: File does not exist after writing', name: 'SalesInvoiceImageExporter');
        throw StateError('ဖိုင်ရေးခြင်းမှာ ပြဿနာရှိပါသည်။');
      }
      
      final fileSize = await file.length();
      dev.log('[ImageExport] File size: $fileSize bytes', name: 'SalesInvoiceImageExporter');

      // step: create_xfile
      onStep?.call('create_xfile');
      dev.log('[ImageExport] STEP: create_xfile', name: 'SalesInvoiceImageExporter');
      final xFile = XFile(file.path, mimeType: 'application/pdf');
      dev.log('[ImageExport] XFile created: ${xFile.path}', name: 'SalesInvoiceImageExporter');

      // step: open_share_sheet
      onStep?.call('open_share_sheet');
      dev.log('[ImageExport] STEP: open_share_sheet', name: 'SalesInvoiceImageExporter');
      dev.log('[ImageExport] Calling Share.shareXFiles()', name: 'SalesInvoiceImageExporter');
      
      try {
        await Share.shareXFiles(
          [xFile],
          text: 'ရောင်းချခြင်းဖောင်သည် - $invoiceNumber',
        );
        dev.log('[ImageExport] Share.shareXFiles() completed successfully', name: 'SalesInvoiceImageExporter');
      } catch (shareError, shareStackTrace) {
        dev.log(
          '[ImageExport] ERROR in Share.shareXFiles(): $shareError\nStackTrace: $shareStackTrace',
          name: 'SalesInvoiceImageExporter',
        );
        rethrow;
      }

      onStep?.call('completed');
      dev.log('[ImageExport] SUCCESS - Export completed', name: 'SalesInvoiceImageExporter');
      return true;
    } catch (error, stackTrace) {
      dev.log(
        '[ImageExport] FATAL ERROR: $error\nStackTrace: $stackTrace',
        name: 'SalesInvoiceImageExporter',
      );
      rethrow;
    }
  }

  /// Get safe filename for export
  static String _getSafeFilename(String invoiceNumber) {
    final safe = invoiceNumber
        .replaceAll(RegExp(r'[^a-zA-Z0-9\-]'), '-')
        .replaceAll(RegExp(r'-+'), '-')
        .toLowerCase();
    return 'sales-invoice-$safe';
  }
}
