// ignore_for_file: avoid_catches_without_on_clauses
import 'dart:async';
import 'dart:developer' as dev;
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../local/local_db.dart';
import '../local/models.dart';
import 'sales_invoice_png_exporter.dart';

/// Exports sales invoices as PNG images and shares them
/// Routes to SalesInvoicePngExporter for PNG export
class SalesInvoiceImageExporter {
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
    // Route to PNG exporter
    return await SalesInvoicePngExporter.exportImageAndShare(
      sales,
      context,
      onStep: onStep,
    );
  }

}
