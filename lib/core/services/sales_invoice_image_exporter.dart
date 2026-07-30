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
import 'error_dialog_helper.dart';

/// Exports sales invoices as PDF and shares them
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
    String currentStep = 'initialization';

    dev.log(
      '[ImageExport] START — invoice=$invoiceNumber items=$itemCount',
      name: 'SalesInvoiceImageExporter',
    );

    try {
      // step: build_document_data
      currentStep = 'build_document_data';
      onStep?.call(currentStep);
      dev.log('[ImageExport] STEP: $currentStep', name: 'SalesInvoiceImageExporter');
      if (sales.isEmpty) {
        throw StateError('ရောင်းချမှုမှတ်တမ်း မရှိပါ။');
      }

      // step: get_temp_dir
      currentStep = 'get_temp_dir';
      onStep?.call(currentStep);
      dev.log('[ImageExport] STEP: $currentStep', name: 'SalesInvoiceImageExporter');
      final tempDir = await getTemporaryDirectory();
      dev.log('[ImageExport] Temp dir: ${tempDir.path}', name: 'SalesInvoiceImageExporter');

      // step: generate_pdf_bytes
      currentStep = 'generate_pdf_bytes';
      onStep?.call(currentStep);
      dev.log('[ImageExport] STEP: $currentStep', name: 'SalesInvoiceImageExporter');
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
      currentStep = 'create_file';
      onStep?.call(currentStep);
      dev.log('[ImageExport] STEP: $currentStep', name: 'SalesInvoiceImageExporter');
      final filename = _getSafeFilename(invoiceNumber);
      final filePath = '${tempDir.path}/$filename.pdf';
      dev.log('[ImageExport] File path: $filePath', name: 'SalesInvoiceImageExporter');
      
      final file = File(filePath);
      dev.log('[ImageExport] File object created', name: 'SalesInvoiceImageExporter');

      // step: write_file
      currentStep = 'write_file';
      onStep?.call(currentStep);
      dev.log('[ImageExport] STEP: $currentStep', name: 'SalesInvoiceImageExporter');
      await file.writeAsBytes(pdfBytes);
      dev.log('[ImageExport] File written to disk', name: 'SalesInvoiceImageExporter');

      // step: verify_file
      currentStep = 'verify_file';
      onStep?.call(currentStep);
      dev.log('[ImageExport] STEP: $currentStep', name: 'SalesInvoiceImageExporter');
      final fileExists = await file.exists();
      dev.log('[ImageExport] File exists: $fileExists', name: 'SalesInvoiceImageExporter');
      
      if (!fileExists) {
        dev.log('[ImageExport] ERROR: File does not exist after writing', name: 'SalesInvoiceImageExporter');
        throw StateError('ဖိုင်ရေးခြင်းမှာ ပြဿနာရှိပါသည်။');
      }
      
      final fileSize = await file.length();
      dev.log('[ImageExport] File size: $fileSize bytes', name: 'SalesInvoiceImageExporter');

      // step: create_xfile
      currentStep = 'create_xfile';
      onStep?.call(currentStep);
      dev.log('[ImageExport] STEP: $currentStep', name: 'SalesInvoiceImageExporter');
      final xFile = XFile(file.path, mimeType: 'application/pdf');
      dev.log('[ImageExport] XFile created: ${xFile.path}', name: 'SalesInvoiceImageExporter');

      // step: open_share_sheet
      currentStep = 'open_share_sheet';
      onStep?.call(currentStep);
      dev.log('[ImageExport] STEP: $currentStep', name: 'SalesInvoiceImageExporter');
      dev.log('[ImageExport] Calling Share.shareXFiles()', name: 'SalesInvoiceImageExporter');
      
      await Share.shareXFiles(
        [xFile],
        text: 'ရောင်းချခြင်းဖောင်သည် - $invoiceNumber',
      );
      dev.log('[ImageExport] Share.shareXFiles() completed successfully', name: 'SalesInvoiceImageExporter');

      currentStep = 'completed';
      onStep?.call(currentStep);
      dev.log('[ImageExport] SUCCESS - Export completed', name: 'SalesInvoiceImageExporter');
      return true;
    } catch (error, stackTrace) {
      dev.log(
        '[ImageExport] FATAL ERROR at step "$currentStep": $error\nStackTrace: $stackTrace',
        name: 'SalesInvoiceImageExporter',
      );

      // Show error dialog on mobile
      if (context.mounted) {
        await ErrorDialogHelper.showErrorDialog(
          context,
          step: currentStep,
          error: error,
          stackTrace: stackTrace,
          sourceFile: 'lib/core/services/sales_invoice_image_exporter.dart',
        );
      }

      return false;
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
