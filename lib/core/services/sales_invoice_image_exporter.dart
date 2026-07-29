// ignore_for_file: avoid_catches_without_on_clauses
import 'dart:async';
import 'dart:developer' as dev;
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../local/local_db.dart';
import '../local/models.dart';
import 'offscreen_widget_image_renderer.dart';
import 'sales_invoice_image_widget.dart';
import 'decoded_logo.dart';

/// Generates clean PNG images of sales invoices without app UI chrome
class SalesInvoiceImageExporter {
  static const double _pageWidth = 800; // Pixels
  static const double _pageHeight = 1100; // Pixels

  /// Export sales invoice as PNG image and share.
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

    // step: load_logo_bytes
    onStep?.call('load_logo_bytes');
    dev.log('[ImageExport] step=load_logo_bytes', name: 'SalesInvoiceImageExporter');
    final DecodedLogo? decodedLogo = await _loadDecodedLogo(onStep);

    // step: create_widget_tree
    onStep?.call('create_widget_tree');
    dev.log('[ImageExport] step=create_widget_tree', name: 'SalesInvoiceImageExporter');
    final widget = SalesInvoiceImageWidget(
      sales: sales,
      decodedLogo: decodedLogo,
      onWidgetStep: onStep,
    );

    // step: render_to_image
    onStep?.call('render_to_image');
    dev.log('[ImageExport] step=render_to_image', name: 'SalesInvoiceImageExporter');
    final imageBytes = await OffscreenWidgetImageRenderer.renderWidgetToPNG(
      widget,
      pageWidth: _pageWidth,
      pageHeight: _pageHeight,
      pixelRatio: 2.0,
      onStep: onStep,
      serviceName: 'SalesInvoiceImageExporter',
    );

    // step: write_file
    onStep?.call('write_file');
    dev.log('[ImageExport] step=write_file', name: 'SalesInvoiceImageExporter');
    final filename = _getSafeFilename(invoiceNumber);
    final file = File('${tempDir.path}/$filename');
    await file.writeAsBytes(imageBytes);

    // step: open_share_sheet
    onStep?.call('open_share_sheet');
    dev.log(
      '[ImageExport] step=open_share_sheet',
      name: 'SalesInvoiceImageExporter',
    );
    await Share.shareXFiles(
      [XFile(file.path, mimeType: 'image/png')],
      text: 'ရောင်းချခြင်းဖောင်သည် - $invoiceNumber',
    );

    onStep?.call('completed');
    dev.log('[ImageExport] success', name: 'SalesInvoiceImageExporter');
    return true;
  }

  /// Load and PRE-DECODE the logo so the off-screen render tree receives a
  /// [ui.Image] directly via [RawImage] — bypassing ImageCache entirely.
  static Future<DecodedLogo?> _loadDecodedLogo(
      void Function(String step)? onStep) async {
    try {
      // ── Step 1: profile loaded ──────────────────────────────────────────
      final profile = LocalDb.getBusinessProfile();
      onStep?.call('logo_profile_loaded');
      dev.log('[ImageExport] logo_profile_loaded logoPath=${profile.logoPath}',
          name: 'SalesInvoiceImageExporter');

      final rawPath = profile.logoPath;
      if (rawPath == null || rawPath.trim().isEmpty) {
        onStep?.call('logo_path_empty');
        dev.log('[ImageExport] logo_path_empty', name: 'SalesInvoiceImageExporter');
        return null;
      }

      // ── Step 2: file exists ─────────────────────────────────────────────
      final logoFile = File(rawPath.trim());
      if (!logoFile.existsSync()) {
        onStep?.call('logo_file_missing');
        dev.log('[ImageExport] logo_file_missing path=$rawPath',
            name: 'SalesInvoiceImageExporter');
        return null;
      }
      onStep?.call('logo_file_exists');
      dev.log('[ImageExport] logo_file_exists path=$rawPath',
          name: 'SalesInvoiceImageExporter');

      // ── Step 3: read bytes ──────────────────────────────────────────────
      final bytes = await logoFile.readAsBytes();
      if (bytes.isEmpty) {
        onStep?.call('logo_read_failed');
        dev.log('[ImageExport] logo_read_failed (empty bytes)',
            name: 'SalesInvoiceImageExporter');
        return null;
      }
      onStep?.call('logo_bytes_loaded');
      dev.log('[ImageExport] logo_bytes_loaded bytes=${bytes.length}',
          name: 'SalesInvoiceImageExporter');

      // ── Step 4: decode to ui.Image (bypasses ImageCache) ───────────────
      // This is the critical fix: Image.memory() relies on the Flutter
      // ImageCache pipeline which is unavailable in the off-screen render
      // tree. ui.decodeImageFromList() decodes directly to a ui.Image that
      // RawImage can paint without any cache lookup.
      onStep?.call('logo_header_branch_selected');
      dev.log('[ImageExport] logo_header_branch_selected — decoding ui.Image',
          name: 'SalesInvoiceImageExporter');

      final completer = Completer<ui.Image>();
      ui.decodeImageFromList(bytes, (ui.Image img) {
        completer.complete(img);
      });
      final uiImage = await completer.future;

      onStep?.call('logo_widget_inserted');
      dev.log(
          '[ImageExport] logo_widget_inserted — ui.Image decoded '
          '${uiImage.width}x${uiImage.height}',
          name: 'SalesInvoiceImageExporter');

      onStep?.call('logo_render_success');
      dev.log('[ImageExport] logo_render_success',
          name: 'SalesInvoiceImageExporter');

      return DecodedLogo(bytes: bytes, image: uiImage);
    } catch (e) {
      onStep?.call('logo_decode_failed');
      dev.log('[ImageExport] logo_decode_failed error=$e',
          name: 'SalesInvoiceImageExporter');
      return null;
    }
  }

  /// Get safe filename for image export
  static String _getSafeFilename(String invoiceNumber) {
    final safe = invoiceNumber
        .replaceAll(RegExp(r'[^a-zA-Z0-9\-]'), '-')
        .replaceAll(RegExp(r'-+'), '-')
        .toLowerCase();
    return 'sales-invoice-$safe.png';
  }
}
