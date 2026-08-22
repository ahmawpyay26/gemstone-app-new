// ignore_for_file: avoid_catches_without_on_clauses
import 'dart:developer' as dev;
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../local/models.dart';
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
      
      final pngBytes = await _captureInvoiceAsImage(
        sales,
        context,
        onStep: onStep,
      );

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
    BuildContext context, {
    void Function(String step)? onStep,
  }) async {
    final pngKey = GlobalKey();
    late final OverlayEntry invoiceEntry;

    invoiceEntry = OverlayEntry(
      builder: (_) => IgnorePointer(
        ignoring: true,
        child: Opacity(
          // Zero opacity prevents a child from painting. A near-transparent
          // ancestor keeps the invoice invisible to the user while allowing
          // the keyed boundary to receive a complete layout and paint pass.
          opacity: 0.01,
          child: Align(
            alignment: Alignment.topLeft,
            child: RepaintBoundary(
              key: pngKey,
              child: SalesInvoiceImageWidget.forPngExport(
                sales: sales,
                repaintKey: null,
              ),
            ),
          ),
        ),
      ),
    );

    Overlay.of(context, rootOverlay: true).insert(invoiceEntry);

    try {
      // These are frame lifecycle waits, not time delays: the first frame
      // mounts/layouts the entry and the second settles its paint/compositing.
      onStep?.call('png_overlay_mounted');
      await WidgetsBinding.instance.endOfFrame;
      await WidgetsBinding.instance.endOfFrame;

      final captureContext = pngKey.currentContext;
      if (captureContext == null) {
        throw StateError('PNG capture boundary is not mounted.');
      }

      final renderObject = captureContext.findRenderObject();
      if (renderObject is! RenderRepaintBoundary) {
        throw StateError(
          'PNG capture target is not RenderRepaintBoundary: '
          '${renderObject.runtimeType}',
        );
      }

      if (!renderObject.hasSize ||
          renderObject.size.width <= 0 ||
          renderObject.size.height <= 0) {
        throw StateError('PNG capture boundary has no valid size.');
      }

      if (renderObject.debugNeedsPaint) {
        await WidgetsBinding.instance.endOfFrame;
        if (renderObject.debugNeedsPaint) {
          throw StateError('PNG invoice boundary has not completed painting.');
        }
      }

      onStep?.call('png_invoice_painted');
      final image = await renderObject.toImage(pixelRatio: 2.0);
      try {
        final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
        if (byteData == null || byteData.lengthInBytes == 0) {
          throw StateError('PNG encoding returned empty bytes.');
        }
        return byteData.buffer.asUint8List();
      } finally {
        image.dispose();
      }
    } finally {
      invoiceEntry.remove();
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
