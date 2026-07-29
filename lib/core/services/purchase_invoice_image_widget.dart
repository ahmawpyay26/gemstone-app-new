import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:ui' as ui;
import 'dart:typed_data';
import '../local/models.dart';
import '../local/local_db.dart';
import 'package:intl/intl.dart';
import 'dart:developer' as dev;

/// Holds a pre-decoded [ui.Image] for logo rendering in off-screen context
class _DecodedLogo {
  final Uint8List bytes;
  final ui.Image image;
  const _DecodedLogo({required this.bytes, required this.image});
}

/// Widget that renders Purchase Invoice as a visual layout for image export
class PurchaseInvoiceImageWidget extends StatelessWidget {
  final Gemstone gemstone;
  final _DecodedLogo? decodedLogo;
  final void Function(String step)? onWidgetStep;

  const PurchaseInvoiceImageWidget({
    Key? key,
    required this.gemstone,
    this.decodedLogo,
    this.onWidgetStep,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
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
                    'ဝယ်ယူမှု နံပါတ်: ${gemstone.purchaseVoucherId ?? ""}',
                    style: const TextStyle(
                      fontFamily: 'Padauk',
                      fontSize: 11,
                      color: Colors.black,
                    ),
                  ),
                  Text(
                    'ရက်စွဲ: ${DateFormat('yyyy-MM-dd').format(DateTime.fromMillisecondsSinceEpoch(gemstone.purchaseDate ?? 0))}',
                    style: const TextStyle(
                      fontFamily: 'Padauk',
                      fontSize: 11,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Supplier details box
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'ရောင်းချသူအချက်အလက်',
                      style: TextStyle(
                        fontFamily: 'Padauk',
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 4),
                    _buildSupplierDetails(),
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

  /// Build header section (matching Broker Voucher design)
  Widget _buildHeader() {
    final profile = LocalDb.getBusinessProfile();
    final shopName = profile.shopName.isNotEmpty
        ? profile.shopName
        : 'ကျောက်မျက်ဆိုင်';

    // Load logo if available
    Widget? logoWidget;
    try {
      // If decodedLogo is available (off-screen rendering), use it
      if (decodedLogo != null) {
        onWidgetStep?.call('logo_widget_decoded');
        dev.log('[ImageExport] widget=logo_decoded', name: 'PurchaseInvoiceImageWidget');
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
          'ဝယ်ယူမှုဖောင်သည်အ',
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

  /// Build supplier details section
  Widget _buildSupplierDetails() {
    final moneyFormat = NumberFormat('#,##0', 'en_US');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'ကျောက်အမျိုးအစား: ${gemstone.name}',
          style: const TextStyle(
            fontFamily: 'Padauk',
            fontSize: 10,
            color: Colors.black,
          ),
        ),
        Text(
          'အရေအတွက်: ${gemstone.quantity}',
          style: const TextStyle(
            fontFamily: 'Padauk',
            fontSize: 10,
            color: Colors.black,
          ),
        ),
        Text(
          'ယူနစ်: ${gemstone.weightUnit ?? 'kg'}',
          style: const TextStyle(
            fontFamily: 'Padauk',
            fontSize: 10,
            color: Colors.black,
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
                  'ဝယ်ယူမှုစျေး',
                  style: TextStyle(
                    fontFamily: 'Padauk',
                    fontSize: 9,
                    color: Colors.black,
                  ),
                ),
                Text(
                  '${moneyFormat.format(gemstone.purchasePrice ?? 0)} ကျပ်',
                  style: const TextStyle(
                    fontFamily: 'Padauk',
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'စုစုပေါင်းဝယ်ယူမှု',
                  style: TextStyle(
                    fontFamily: 'Padauk',
                    fontSize: 9,
                    color: Colors.black,
                  ),
                ),
                Text(
                  '${moneyFormat.format((gemstone.purchasePrice ?? 0) * (gemstone.quantity ?? 0))} ကျပ်',
                  style: const TextStyle(
                    fontFamily: 'Padauk',
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  /// Build items table
  Widget _buildItemsTable() {
    final moneyFormat = NumberFormat('#,##0', 'en_US');

    return Table(
      border: TableBorder.all(color: Colors.grey),
      columnWidths: const {
        0: FlexColumnWidth(5),
        1: FlexColumnWidth(24),
        2: FlexColumnWidth(12),
        3: FlexColumnWidth(10),
        4: FlexColumnWidth(8),
        5: FlexColumnWidth(15),
        6: FlexColumnWidth(16),
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
        // Single item row
        TableRow(
          children: [
            _buildTableCell('1'),
            _buildTableCell(gemstone.name),
            _buildTableCell('ကျောက်လုံး'),
            _buildTableCell('${gemstone.weight} ${gemstone.weightUnit ?? 'kg'}'),
            _buildTableCell('${gemstone.quantity}'),
            _buildTableCell('${moneyFormat.format(gemstone.quantity > 0 ? (gemstone.purchasePrice ?? 0) / (gemstone.quantity ?? 1) : 0)}'),
            _buildTableCell('${moneyFormat.format((gemstone.purchasePrice ?? 0) * (gemstone.quantity ?? 0))}'),
          ],
        ),
        // Totals row
        TableRow(
          decoration: BoxDecoration(color: Colors.grey[200]),
          children: [
            _buildTableCell('', isHeader: true),
            _buildTableCell('စုစုပေါင်း', isHeader: true),
            _buildTableCell('', isHeader: true),
            _buildTableCell('', isHeader: true),
            _buildTableCell('${gemstone.quantity}', isHeader: true),
            _buildTableCell('', isHeader: true),
            _buildTableCell('${moneyFormat.format((gemstone.purchasePrice ?? 0) * (gemstone.quantity ?? 0))}', isHeader: true),
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
}
