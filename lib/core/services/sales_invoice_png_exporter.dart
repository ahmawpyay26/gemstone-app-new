// ignore_for_file: avoid_catches_without_on_clauses
import 'dart:developer' as dev;
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../local/models.dart';
import 'offscreen_widget_image_renderer.dart';
import 'sales_invoice_image_widget.dart';

/// Exports sales invoices as PNG images and shares them
class SalesInvoicePngExporter {
  /// Export sales invoice as PNG and share.
  ///
  /// Renders the invoice widget off-screen, captures as PNG, and shares.
  ///
  /// [onStep] — called before each step starts with the step name.
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
      '[PngExport] START — invoice=$invoiceNumber items=$itemCount',
      name: 'SalesInvoicePngExporter',
    );

    try {
      // step: validate_sales
      currentStep = 'validate_sales';
      onStep?.call(currentStep);
      dev.log('[PngExport] STEP: $currentStep', name: 'SalesInvoicePngExporter');
      if (sales.isEmpty) {
        throw StateError('ရောင်းချမှုမှတ်တမ်း မရှိပါ။');
      }

      // step: get_temp_dir
      currentStep = 'get_temp_dir';
      onStep?.call(currentStep);
      dev.log('[PngExport] STEP: $currentStep', name: 'SalesInvoicePngExporter');
      final tempDir = await getTemporaryDirectory();
      dev.log('[PngExport] Temp dir: ${tempDir.path}', name: 'SalesInvoicePngExporter');

      // step: render_and_capture
      currentStep = 'render_and_capture';
      onStep?.call(currentStep);
      dev.log('[PngExport] STEP: $currentStep', name: 'SalesInvoicePngExporter');
      
      final pngBytes = await _captureInvoiceAsImage(sales, onStep: onStep);

      if (pngBytes.isEmpty) {
        dev.log('[PngExport] ERROR: Failed to capture invoice as image', name: 'SalesInvoicePngExporter');
        throw StateError('ဘောင်ချာပုံထုတ်ခြင်းမှာ ပြဿနာရှိပါသည်။');
      }
      dev.log('[PngExport] Image captured: ${pngBytes.length} bytes', name: 'SalesInvoicePngExporter');

      // step: create_file
      currentStep = 'create_file';
      onStep?.call(currentStep);
      dev.log('[PngExport] STEP: $currentStep', name: 'SalesInvoicePngExporter');
      final filename = _getSafeFilename(invoiceNumber);
      final filePath = '${tempDir.path}/$filename.png';
      dev.log('[PngExport] File path: $filePath', name: 'SalesInvoicePngExporter');
      
      final file = File(filePath);

      // step: write_file
      currentStep = 'write_file';
      onStep?.call(currentStep);
      dev.log('[PngExport] STEP: $currentStep', name: 'SalesInvoicePngExporter');
      await file.writeAsBytes(pngBytes);
      dev.log('[PngExport] File written to disk', name: 'SalesInvoicePngExporter');

      // step: verify_file
      currentStep = 'verify_file';
      onStep?.call(currentStep);
      dev.log('[PngExport] STEP: $currentStep', name: 'SalesInvoicePngExporter');
      final fileExists = await file.exists();
      dev.log('[PngExport] File exists: $fileExists', name: 'SalesInvoicePngExporter');
      
      if (!fileExists) {
        dev.log('[PngExport] ERROR: File does not exist after writing', name: 'SalesInvoicePngExporter');
        throw StateError('ဖိုင်ရေးခြင်းမှာ ပြဿနာရှိပါသည်။');
      }
      
      final fileSize = await file.length();
      dev.log('[PngExport] File size: $fileSize bytes', name: 'SalesInvoicePngExporter');

      if (fileSize == 0) {
        throw StateError('PNG ဖိုင်သည် အလွတ်ဖြစ်နေပါသည်။');
      }

      // step: create_xfile
      currentStep = 'create_xfile';
      onStep?.call(currentStep);
      dev.log('[PngExport] STEP: $currentStep', name: 'SalesInvoicePngExporter');
      final xFile = XFile(file.path, mimeType: 'image/png');
      dev.log('[PngExport] XFile created: ${xFile.path}', name: 'SalesInvoicePngExporter');

      // step: open_share_sheet
      currentStep = 'open_share_sheet';
      onStep?.call(currentStep);
      dev.log('[PngExport] STEP: $currentStep', name: 'SalesInvoicePngExporter');
      dev.log('[PngExport] Calling Share.shareXFiles()', name: 'SalesInvoicePngExporter');
      
      await Share.shareXFiles(
        [xFile],
        text: 'ရောင်းချခြင်းဖောင်သည် - $invoiceNumber',
      );
      dev.log('[PngExport] Share.shareXFiles() completed successfully', name: 'SalesInvoicePngExporter');

      currentStep = 'completed';
      onStep?.call(currentStep);
      dev.log('[PngExport] SUCCESS - Export completed', name: 'SalesInvoicePngExporter');
      return true;
    } catch (error, stackTrace) {
      dev.log(
        '[PngExport] FATAL ERROR at step "$currentStep": $error\nStackTrace: $stackTrace',
        name: 'SalesInvoicePngExporter',
      );

      // Re-throw the original exception to expose it to the caller
      Error.throwWithStackTrace(error, stackTrace);
    }
  }

  /// Capture invoice widget as PNG image bytes
  static Future<Uint8List> _captureInvoiceAsImage(
    List<Sale> sales,
    {void Function(String step)? onStep},
  ) {
    // The former transparent-dialog approach captured a boundary whose paint
    // completion was not guaranteed. This renders the same invoice widget in
    // the app's established off-screen pipeline, which explicitly completes
    // layout, compositing, and paint before `toImage()` is invoked.
    return OffscreenWidgetImageRenderer.renderWidgetToPNG(
      SalesInvoiceImageWidget.forPngExport(
        sales: sales,
        repaintKey: null,
      ),
      pageWidth: 600,
      pageHeight: _pngInvoiceHeightFor(sales),
      pixelRatio: 2.0,
      onStep: onStep,
      serviceName: 'SalesInvoicePngExporter',
    );
  }

  /// Provides the PNG render tree enough height for the actual invoice rows
  /// while avoiding a fixed A4 canvas full of unused space for short invoices.
  static double _pngInvoiceHeightFor(List<Sale> sales) {
    const headerAndFooterHeight = 560.0;
    const rowHeightAllowance = 64.0;
    return headerAndFooterHeight + (sales.length * rowHeightAllowance);
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
