import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'dart:io';
import 'dart:ui' as ui;
import 'dart:typed_data';
import '../local/models.dart';
import '../local/local_db.dart';
import 'package:intl/intl.dart';
import 'dart:developer' as dev;
import 'decoded_logo.dart';
import 'invoice_header_widget.dart';

/// Widget that renders Sales Invoice as a visual layout for image export
/// Matches Broker Consignment Voucher design 1:1
class SalesInvoiceImageWidget extends StatelessWidget {
  final List<Sale> sales;
  final GlobalKey<State<StatefulWidget>>? repaintKey;
  final DecodedLogo? decodedLogo;
  final void Function(String step)? onWidgetStep;
  final bool isPngExport;

  const SalesInvoiceImageWidget({
    Key? key,
    required this.sales,
    this.repaintKey,
    this.decodedLogo,
    this.onWidgetStep,
    this.isPngExport = false,
  }) : super(key: key);

  /// PNG export variant with optimized sizing
  factory SalesInvoiceImageWidget.forPngExport({
    required List<Sale> sales,
    required GlobalKey<State<StatefulWidget>>? repaintKey,
  }) {
    return SalesInvoiceImageWidget(
      sales: sales,
      repaintKey: repaintKey,
      isPngExport: true,
    );
  }

  /// Legacy constructor for in-dialog rendering (backward compatibility)
  factory SalesInvoiceImageWidget.forDialog({
    required List<Sale> sales,
    required GlobalKey<State<StatefulWidget>> repaintKey,
  }) {
    return SalesInvoiceImageWidget(
      sales: sales,
      repaintKey: repaintKey,
    );
  }

  @override
  Widget build(BuildContext context) {
    // PNG export uses smaller dimensions for phone display
    final width = isPngExport ? 600.0 : 800.0;
    final padding = isPngExport ? 12.0 : 20.0;
    final height = isPngExport ? null : 1100.0;  // Auto-fit for PNG

    return RepaintBoundary(
      key: repaintKey,
      child: Container(
        width: width,
        height: height,
        color: Colors.white,
        padding: EdgeInsets.all(padding),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Shared header widget (standardized across PNG and PDF)
              InvoiceHeaderWidget(
                sales: sales,
                decodedLogo: decodedLogo,
                onWidgetStep: onWidgetStep,
              ),
              const SizedBox(height: 15),

              // Items table
              _buildItemsTable(),

              const SizedBox(height: 15),

              // Footer
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'ရေးထိုးသူ: __________',
                    style: TextStyle(
                      fontFamily: 'Padauk',
                      fontSize: 9,
                    ),
                  ),
                  const Text(
                    'စာမျက်နှာ 1 / 1',
                    style: TextStyle(
                      fontFamily: 'Padauk',
                      fontSize: 9,
                    ),
                  ),
                  const Text(
                    'ကုန်သည် လက်မှတ်: __________',
                    style: TextStyle(
                      fontFamily: 'Padauk',
                      fontSize: 9,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// OLD: _buildHeader() moved to InvoiceHeaderWidget
  /// This method is no longer used
  /*
  Widget _buildHeader_DEPRECATED() {
    final profile = LocalDb.getBusinessProfile();
    final shopName = profile.shopName.isNotEmpty
        ? profile.shopName
        : 'ပွဲစားအပ်နှံဘောင်ချာ';

    // Load logo if available
    Widget? logoWidget;
    try {
      // If decodedLogo is available (off-screen rendering), use it
      if (decodedLogo != null) {
        onWidgetStep?.call('logo_widget_decoded');
        dev.log('[ImageExport] widget=logo_decoded', name: 'SalesInvoiceImageWidget');
        logoWidget = Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.transparent),
          ),
          child: RawImage(
            image: decodedLogo!.image,
            fit: BoxFit.contain,
          ),
        );
      } else if (repaintKey != null) {
        // Fallback for dialog rendering: use Image.file()
        final rawPath = profile.logoPath;
        if (rawPath != null && rawPath.trim().isNotEmpty) {
          final logoFile = File(rawPath.trim());
          if (logoFile.existsSync()) {
            logoWidget = Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.transparent),
              ),
              child: Image.file(
                logoFile,
                fit: BoxFit.contain,
              ),
            );
          }
        }
      }
    } catch (_) {
      logoWidget = null;
    }

    // Build the info column
    final infoColumn = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Shop name — large bold title
        Text(
          shopName,
          style: const TextStyle(
            fontFamily: 'Padauk',
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 2),

        // Voucher subtitle
        const Text(
          'ရောင်းချခြင်းဖောင်သည်အ',
          style: TextStyle(
            fontFamily: 'Padauk',
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 4),

        // Business contact info — only show non-empty fields
        if (profile.phone?.isNotEmpty == true)
          Text(
            'ဖုန်း: ${profile.phone}',
            style: const TextStyle(
              fontFamily: 'Padauk',
              fontSize: 10,
              color: Colors.black,
            ),
          ),
        if (profile.address?.isNotEmpty == true)
          Text(
            'လိပ်စာ: ${profile.address}',
            style: const TextStyle(
              fontFamily: 'Padauk',
              fontSize: 10,
              color: Colors.black,
            ),
          ),
        if (profile.email?.isNotEmpty == true)
          Text(
            'Email: ${profile.email}',
            style: const TextStyle(
              fontFamily: 'Padauk',
              fontSize: 10,
              color: Colors.black,
            ),
          ),
      ],
    );

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (logoWidget != null) ...[
          logoWidget,
          const SizedBox(width: 12),
        ],
        Expanded(child: infoColumn),
      ],
    );
  }
  */

  /// OLD: _buildCustomerDetails() moved to InvoiceHeaderWidget
  /// This method is no longer used
  /*
  Widget _buildCustomerDetails_DEPRECATED() {
    double totalAmount = 0;
    double totalCommission = 0;
    double totalNet = 0;
    int totalQty = 0;

    for (final sale in sales) {
      totalAmount += sale.amount;
      totalCommission += sale.commissionFee;
      totalNet += sale.netSale;
      totalQty += sale.quantity;
    }

    final moneyFormat = NumberFormat('#,##0', 'en_US');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'ကျောက်အမျိုးအစား: ${sales.map((s) => s.gemstoneName).toSet().join(", ")}',
          style: const TextStyle(
            fontFamily: 'Padauk',
            fontSize: 10,
            color: Colors.black,
          ),
        ),
        Text(
          'အရေအတွက်: $totalQty',
          style: const TextStyle(
            fontFamily: 'Padauk',
            fontSize: 10,
            color: Colors.black,
          ),
        ),
        Text(
          'ယူနစ်: kg',
          style: const TextStyle(
            fontFamily: 'Padauk',
            fontSize: 10,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'စုစုပေါင်းရောင်းချမှု: ${moneyFormat.format(totalAmount)} ကျပ်',
          style: const TextStyle(
            fontFamily: 'Padauk',
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
      ],
    );
  }
  */

  /// Build items table (matching Broker Voucher table design)
  Widget _buildItemsTable() {
    double totalAmount = 0;
    double totalCommission = 0;
    int totalQty = 0;

    for (final sale in sales) {
      totalAmount += sale.amount;
      totalCommission += sale.commissionFee;
      totalQty += sale.quantity;
    }

    final moneyFormat = NumberFormat('#,##0', 'en_US');

    return Table(
      border: TableBorder.all(color: Colors.grey),
      columnWidths: const {
        0: FlexColumnWidth(5),
        1: FlexColumnWidth(24),
        2: FlexColumnWidth(12),
        3: FlexColumnWidth(10),
        4: FlexColumnWidth(8),
        5: FlexColumnWidth(11),    // Reduced from 15 (Unit Price)
        6: FlexColumnWidth(14),    // Increased from 10 (Total)
        7: FlexColumnWidth(16),
      },
      children: [
        // Header row
        TableRow(
          decoration: BoxDecoration(color: Colors.grey[300]),
          children: [
            _buildTableCell('ល.ដ', isHeader: true),
            _buildTableCell('ပစ္စည်းအမည်', isHeader: true),
            _buildTableCell('အမျိုးအစား', isHeader: true),
            _buildTableCell('အလေးချိန်', isHeader: true),
            _buildTableCell('အရေအတွက်', isHeader: true),
            _buildTableCell('ယူနစ်ဈေး', isHeader: true),
            _buildTableCell('စုစုပေါင်း', isHeader: true),
          ],
        ),
        // Item rows
        ...List<TableRow>.generate(
          sales.length,
          (index) {
            final sale = sales[index];
            return TableRow(
              children: [
                _buildTableCell('${index + 1}'),
                _buildTableCell(sale.gemstoneName),
                _buildTableCell('ကျောက်လုံး'),
                _buildTableCell('${sale.weightCarat} ${sale.weightUnit ?? 'kg'}'),
                _buildTableCell('${sale.quantity}'),
                _buildTableCell('${moneyFormat.format(sale.quantity > 0 ? sale.amount / sale.quantity : 0)}'),
                _buildTableCell('${moneyFormat.format(sale.amount)}'),
              ],
            );
          },
        ),
        // Totals row
        TableRow(
          decoration: BoxDecoration(color: Colors.grey[200]),
          children: [
            _buildTableCell('', isHeader: true),
            _buildTableCell('စုစုပေါင်း', isHeader: true),
            _buildTableCell('', isHeader: true),
            _buildTableCell('', isHeader: true),
            _buildTableCell('$totalQty', isHeader: true),
            _buildTableCell('', isHeader: true),
            _buildTableCell('${moneyFormat.format(totalAmount)}', isHeader: true),
          ],
        ),
      ],
    );
  }

  /// Build a single table cell
  Widget _buildTableCell(String text, {bool isHeader = false}) {
    return Padding(
      padding: const EdgeInsets.all(4),
      child: Text(
        text,
        style: TextStyle(
          fontFamily: 'Padauk',
          fontSize: isHeader ? 9 : 8,
          fontWeight: isHeader ? FontWeight.bold : FontWeight.normal,
          color: Colors.black,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  /// Capture widget as image
  static Future<Uint8List?> captureAsImage(GlobalKey<State<StatefulWidget>> repaintKey) async {
    try {
      final RenderRepaintBoundary boundary = repaintKey.currentContext!
          .findRenderObject() as RenderRepaintBoundary;
      final ui.Image image = await boundary.toImage(pixelRatio: 2.0);
      final ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      return byteData?.buffer.asUint8List();
    } catch (e) {
      print('Error capturing image: $e');
      return null;
    }
  }
}
