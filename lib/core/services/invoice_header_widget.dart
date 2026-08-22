import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import 'dart:ui' as ui;
import '../local/models.dart';
import '../local/local_db.dart';
import 'decoded_logo.dart';

/// Shared header widget for Own Sales invoice exports (PNG and PDF).
/// Implements the standardized 5-row header layout:
/// Row 1: Shop Info (left) | Voucher Type "ကိုယ်တိုင်ရောင်းချမှု" (right)
/// Row 2: Voucher # (left) | Date (right)
/// Row 3: Source "ကိုယ်တိုင်ရောင်းချမှု"
/// Row 4: Customer info (conditional)
/// Row 5: Summary box
/// Row 6: Item table (handled by parent)
///
/// NOTE: This widget is for OWN SALES ONLY (Sale model).
/// Broker sales use separate BrokerVoucherDocumentData system.
class InvoiceHeaderWidget extends StatelessWidget {
  final List<Sale> sales;
  final DecodedLogo? decodedLogo;
  final void Function(String step)? onWidgetStep;

  const InvoiceHeaderWidget({
    Key? key,
    required this.sales,
    this.decodedLogo,
    this.onWidgetStep,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Row 1: Shop Info (left) | Voucher Type (right)
        _buildRow1(),
        const SizedBox(height: 8),

        // Row 2: Voucher # (left) | Date (right)
        _buildRow2(),
        const SizedBox(height: 8),

        // Row 3: Source info (always "ကိုယ်တိုင်ရောင်းချမှု" for own sales)
        _buildRow3(),
        const SizedBox(height: 8),

        // Row 4: Customer info (conditional)
        _buildRow4(),
        const SizedBox(height: 8),

        // Row 5: Summary box
        _buildRow5(),
      ],
    );
  }

  /// Row 1: Shop Info (left) | Voucher Type (right)
  Widget _buildRow1() {
    final profile = LocalDb.getBusinessProfile();
    final shopName = profile.shopName.isNotEmpty
        ? profile.shopName
        : 'ပွဲစားအပ်နှံဘောင်ချာ';

    // Load logo if available
    Widget? logoWidget;
    try {
      if (decodedLogo != null) {
        onWidgetStep?.call('logo_widget_decoded');
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

    final leftContent = Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (logoWidget != null) ...[
          logoWidget,
          const SizedBox(width: 12),
        ],
        Expanded(child: infoColumn),
      ],
    );

    // Right side: Voucher Type (Fixed: Own Sale)
    final rightContent = Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        const Text(
          'ဘောင်ချာအမျိုးအစား',
          style: TextStyle(
            fontFamily: 'Padauk',
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'ကိုယ်တိုင်ရောင်းချမှု',
          style: TextStyle(
            fontFamily: 'Padauk',
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
      ],
    );

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: leftContent),
        const SizedBox(width: 16),
        rightContent,
      ],
    );
  }

  /// Row 2: Voucher # (left) | Date (right)
  Widget _buildRow2() {
    final invoiceNumber = sales.isNotEmpty ? sales.first.invoiceNumber : 'N/A';
    final saleDate = sales.isNotEmpty ? sales.first.saleDate : DateTime.now().millisecondsSinceEpoch;
    // The PNG surface is built synchronously in an OverlayEntry. Intl requires
    // asynchronous locale-symbol initialization for `my`, which otherwise
    // throws while this child subtree is building. The voucher date is numeric,
    // so use the default initialized date symbols; Myanmar labels remain in the
    // bundled Padauk font widgets below.
    final dateStr = DateFormat('dd/MM/yyyy').format(
      DateTime.fromMillisecondsSinceEpoch(saleDate),
    );

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'ဘောင်ချာနံပါတ်',
              style: TextStyle(
                fontFamily: 'Padauk',
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              invoiceNumber,
              style: const TextStyle(
                fontFamily: 'Padauk',
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
          ],
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            const Text(
              'ရက်စွဲ',
              style: TextStyle(
                fontFamily: 'Padauk',
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              dateStr,
              style: const TextStyle(
                fontFamily: 'Padauk',
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Row 3: Source info (always own sale for this widget)
  /// Shows "အရင်းအမြစ်: ကိုယ်တိုင်ရောင်းချမှု"
  Widget _buildRow3() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'အရင်းအမြစ်',
          style: TextStyle(
            fontFamily: 'Padauk',
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 2),
        const Text(
          'ကိုယ်တိုင်ရောင်းချမှု',
          style: TextStyle(
            fontFamily: 'Padauk',
            fontSize: 11,
            color: Colors.black,
          ),
        ),
      ],
    );
  }

  /// Row 4: Customer info (conditional)
  /// Only shown if customer data is present
  Widget _buildRow4() {
    if (sales.isEmpty) return const SizedBox.shrink();

    final firstSale = sales.first;
    final hasCustomer = firstSale.customerName.isNotEmpty || firstSale.customerId != null;

    if (!hasCustomer) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black, width: 1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'ဝယ်ယူသူ',
            style: TextStyle(
              fontFamily: 'Padauk',
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 4),
          if (firstSale.customerName.isNotEmpty)
            Text(
              'အမည်: ${firstSale.customerName}',
              style: const TextStyle(
                fontFamily: 'Padauk',
                fontSize: 10,
                color: Colors.black,
              ),
            ),
          // Note: Phone and address would come from Customer model if available
          // For now, only showing name from Sale record
        ],
      ),
    );
  }

  /// Row 5: Summary box
  Widget _buildRow5() {
    double totalAmount = 0;
    int totalQty = 0;
    double totalWeight = 0;

    for (final sale in sales) {
      totalAmount += sale.amount;
      totalQty += sale.quantity;
      totalWeight += sale.weightCarat;
    }

    final moneyFormat = NumberFormat('#,##0', 'en_US');
    final gemstoneTypes = sales.map((s) => s.gemstoneName).toSet().join(", ");

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black, width: 1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'စုစုပေါင်းအမျိုးအစား: $gemstoneTypes',
            style: const TextStyle(
              fontFamily: 'Padauk',
              fontSize: 10,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'အရေအတွက်: $totalQty',
            style: const TextStyle(
              fontFamily: 'Padauk',
              fontSize: 10,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'အလေးချိန်: ${totalWeight.toStringAsFixed(2)} kg',
            style: const TextStyle(
              fontFamily: 'Padauk',
              fontSize: 10,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'စုစုပေါင်းတန်ဖိုး: ${moneyFormat.format(totalAmount)} ကျပ်',
            style: const TextStyle(
              fontFamily: 'Padauk',
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
        ],
      ),
    );
  }
}
