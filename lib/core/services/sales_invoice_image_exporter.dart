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
      '[ImageExport] start — invoice=$invoiceNumber items=$itemCount',
      name: 'SalesInvoiceImageExporter',
    );

    // step: build_document_data
    onStep?.call('build_document_data');
    dev.log('[ImageExport] step=build_document_data', name: 'SalesInvoiceImageExporter');
    if (sales.isEmpty) {
      throw StateError('ရောင်းချမှုမှတ်တမ်း မရှိပါ။');
    }

    // step: get_temp_dir
    onStep?.call('get_temp_dir');
    dev.log('[ImageExport] step=get_temp_dir', name: 'SalesInvoiceImageExporter');
    final tempDir = await getTemporaryDirectory();

    // step: generate_pdf_bytes
    onStep?.call('generate_pdf_bytes');
    dev.log('[ImageExport] step=generate_pdf_bytes', name: 'SalesInvoiceImageExporter');
    final voucherService = VoucherExportService();
    final pdfBytes = await voucherService.generatePdfInvoiceBytes(sales);
    
    if (pdfBytes == null || pdfBytes.isEmpty) {
      dev.log('[ImageExport] error: PDF generation failed', name: 'SalesInvoiceImageExporter');
      throw StateError('PDF ထုတ်ပြန်ခြင်းမှာ ပြဿနာရှိပါသည်။');
    }
    dev.log('[ImageExport] pdf_bytes_generated size=${pdfBytes.length}', name: 'SalesInvoiceImageExporter');

    // step: write_file
    onStep?.call('write_file');
    dev.log('[ImageExport] step=write_file', name: 'SalesInvoiceImageExporter');
    final filename = _getSafeFilename(invoiceNumber);
    final file = File('${tempDir.path}/$filename.pdf');
    await file.writeAsBytes(pdfBytes);
    dev.log('[ImageExport] file_written path=${file.path}', name: 'SalesInvoiceImageExporter');

    // step: open_share_sheet
    onStep?.call('open_share_sheet');
    dev.log(
      '[ImageExport] step=open_share_sheet',
      name: 'SalesInvoiceImageExporter',
    );
    await Share.shareXFiles(
      [XFile(file.path, mimeType: 'application/pdf')],
      text: 'ရောင်းချခြင်းဖောင်သည် - $invoiceNumber',
    );

    onStep?.call('completed');
    dev.log('[ImageExport] success', name: 'SalesInvoiceImageExporter');
    return true;
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
