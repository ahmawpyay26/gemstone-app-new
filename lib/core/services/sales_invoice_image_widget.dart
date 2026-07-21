import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'dart:io';
import 'dart:ui' as ui;
import 'dart:typed_data';
import '../local/models.dart';
import '../local/local_db.dart';
import 'package:intl/intl.dart';

/// Widget that renders Sales Invoice as a visual layout for image export
/// Matches Broker Consignment Voucher design 1:1
class SalesInvoiceImageWidget extends StatelessWidget {
  final List<Sale> sales;
  final GlobalKey<State<StatefulWidget>> repaintKey;

  const SalesInvoiceImageWidget({
    Key? key,
    required this.sales,
    required this.repaintKey,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      key: repaintKey,
      child: Container(
        width: 800,
        height: 1100,
        color: Colors.white,
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header - matching Broker Voucher design
              _buildHeader(),
              const SizedBox(height: 12),

              // Invoice number and date row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'ဘောင်ချာ နံပါတ်: ${sales.isNotEmpty ? sales.first.invoiceNumber : ""}',
                    style: const TextStyle(
                      fontFamily: 'Padauk',
                      fontSize: 11,
                    ),
                  ),
                  Text(
                    'ရက်စွဲ: ${DateFormat('yyyy-MM-dd').format(DateTime.fromMillisecondsSinceEpoch(sales.isNotEmpty ? sales.first.saleDate : 0))}',
                    style: const TextStyle(
                      fontFamily: 'Padauk',
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Customer details box - matching Broker Info Box style
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'ဖောက်သည်အချက်အလက်',
                      style: TextStyle(
                        fontFamily: 'Padauk',
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    _buildCustomerDetails(),
                  ],
                ),
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

  /// Build header section (matching Broker Voucher)
  Widget _buildHeader() {
    final profile = LocalDb.getBusinessProfile();
    final shopName = profile.shopName.isNotEmpty
        ? profile.shopName
        : 'ပွဲစားအပ်နှံဘောင်ချာ';

    // Load logo if available
    Widget? logoWidget;
    try {
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
          ),
        ),
        const SizedBox(height: 2),

        // Voucher subtitle
        const Text(
          'ရောင်းချမှုဘောင်ချာ',
          style: TextStyle(
            fontFamily: 'Padauk',
            fontSize: 14,
            fontWeight: FontWeight.bold,
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
            ),
          ),
        if (profile.address?.isNotEmpty == true)
          Text(
            'လိပ်စာ: ${profile.address}',
            style: const TextStyle(
              fontFamily: 'Padauk',
              fontSize: 10,
            ),
          ),
        if (profile.email?.isNotEmpty == true)
          Text(
            'Email: ${profile.email}',
            style: const TextStyle(
              fontFamily: 'Padauk',
              fontSize: 10,
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

  /// Build customer details section
  Widget _buildCustomerDetails() {
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
          ),
        ),
        Text(
          'အရေအတွက်: $totalQty',
          style: const TextStyle(
            fontFamily: 'Padauk',
            fontSize: 10,
          ),
        ),
        Text(
          'ယူနစ်: kg',
          style: const TextStyle(
            fontFamily: 'Padauk',
            fontSize: 10,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'စုစုပေါင်းရောင်းချမှု',
                  style: TextStyle(
                    fontFamily: 'Padauk',
                    fontSize: 9,
                  ),
                ),
                Text(
                  '${moneyFormat.format(totalAmount)} ကျပ်',
                  style: const TextStyle(
                    fontFamily: 'Padauk',
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'စုစုပေါင်းကော်မရှင်',
                  style: TextStyle(
                    fontFamily: 'Padauk',
                    fontSize: 9,
                  ),
                ),
                Text(
                  '${moneyFormat.format(totalCommission)} ကျပ်',
                  style: const TextStyle(
                    fontFamily: 'Padauk',
                    fontSize: 9,
                  ),
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'စုစုပေါင်းကျန်ရှိ',
                  style: TextStyle(
                    fontFamily: 'Padauk',
                    fontSize: 9,
                  ),
                ),
                Text(
                  '${moneyFormat.format(totalNet)} ကျပ်',
                  style: const TextStyle(
                    fontFamily: 'Padauk',
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

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
        0: FixedColumnWidth(40),
        1: FixedColumnWidth(100),
        2: FixedColumnWidth(60),
        3: FixedColumnWidth(50),
        4: FixedColumnWidth(50),
        5: FixedColumnWidth(50),
        6: FixedColumnWidth(50),
        7: FixedColumnWidth(50),
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
            _buildTableCell('ကော်မရှင်', isHeader: true),
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
                _buildTableCell('${moneyFormat.format(sale.commissionFee)}'),
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
            _buildTableCell('${moneyFormat.format(totalCommission)}', isHeader: true),
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
