import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'dart:ui' as ui;
import 'dart:typed_data';
import '../local/models.dart';
import 'package:intl/intl.dart';

/// Widget that renders Sales Invoice as a visual layout for image export
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
        color: Colors.white,
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Center(
                child: Column(
                  children: [
                    Text(
                      'ပွဲစားထံမှ ရောင်းချမှု',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Padauk',
                      ),
                    ),
                    Text(
                      'ပွဲစားထံမှ ရောင်းချမှု',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Padauk',
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 16),

              // Invoice number and date
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'ဘောင်ချာ အုပ်စုံ: ${sales.isNotEmpty ? sales.first.invoiceNumber : ""}',
                    style: TextStyle(
                      fontSize: 12,
                      fontFamily: 'Padauk',
                    ),
                  ),
                  Text(
                    'မပ်စွဲ: ${DateFormat('yyyy-MM-dd').format(DateTime.fromMillisecondsSinceEpoch(sales.isNotEmpty ? sales.first.saleDate : 0))}',
                    style: TextStyle(
                      fontSize: 12,
                      fontFamily: 'Padauk',
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16),

              // Customer details box
              Container(
                padding: EdgeInsets.all(10),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ဖောက်သည်အချက်အလက်',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Padauk',
                      ),
                    ),
                    SizedBox(height: 8),
                    _buildCustomerDetails(),
                  ],
                ),
              ),
              SizedBox(height: 16),

              // Items table
              _buildItemsTable(),

              SizedBox(height: 16),

              // Footer
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'ရေးထိုးသူ: __________',
                    style: TextStyle(
                      fontSize: 10,
                      fontFamily: 'Padauk',
                    ),
                  ),
                  Text(
                    'နေ့စွဲ: __________',
                    style: TextStyle(
                      fontSize: 10,
                      fontFamily: 'Padauk',
                    ),
                  ),
                ],
              ),
              SizedBox(height: 8),
              Center(
                child: Text(
                  'စာမျက်နှာ 1 / 1',
                  style: TextStyle(
                    fontSize: 10,
                    fontFamily: 'Padauk',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

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
          'ကျောက်အမျိုးအစား: ${sales.map((s) => s.gemstoneType).toSet().join(", ")}',
          style: TextStyle(fontSize: 11, fontFamily: 'Padauk'),
        ),
        Text(
          'အရေအတွက်: $totalQty',
          style: TextStyle(fontSize: 11, fontFamily: 'Padauk'),
        ),
        Text(
          'ယူနစ်: kg',
          style: TextStyle(fontSize: 11, fontFamily: 'Padauk'),
        ),
        SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'စုစုပေါင်းရောင်းချမှု',
                  style: TextStyle(fontSize: 10, fontFamily: 'Padauk'),
                ),
                Text(
                  '${moneyFormat.format(totalAmount)} ကျပ်',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Padauk',
                  ),
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'စုစုပေါင်းကော်မရှင်',
                  style: TextStyle(fontSize: 10, fontFamily: 'Padauk'),
                ),
                Text(
                  '${moneyFormat.format(totalCommission)} ကျပ်',
                  style: TextStyle(fontSize: 10, fontFamily: 'Padauk'),
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'စုစုပေါင်းကျန်ရှိ',
                  style: TextStyle(fontSize: 10, fontFamily: 'Padauk'),
                ),
                Text(
                  '${moneyFormat.format(totalNet)} ကျပ်',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Padauk',
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildItemsTable() {
    final moneyFormat = NumberFormat('#,##0', 'en_US');

    double totalAmount = 0;
    double totalCommission = 0;
    int totalQty = 0;

    for (final sale in sales) {
      totalAmount += sale.amount;
      totalCommission += sale.commissionFee;
      totalQty += sale.quantity;
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columns: [
          DataColumn(label: Text('ល.ដ', style: TextStyle(fontFamily: 'Padauk', fontWeight: FontWeight.bold))),
          DataColumn(label: Text('ပစ္စည်းအမည်', style: TextStyle(fontFamily: 'Padauk', fontWeight: FontWeight.bold))),
          DataColumn(label: Text('အမျိုးအစား', style: TextStyle(fontFamily: 'Padauk', fontWeight: FontWeight.bold))),
          DataColumn(label: Text('အလေးချိန်', style: TextStyle(fontFamily: 'Padauk', fontWeight: FontWeight.bold))),
          DataColumn(label: Text('အရေအတွက်', style: TextStyle(fontFamily: 'Padauk', fontWeight: FontWeight.bold))),
          DataColumn(label: Text('ယူနစ်ဈေး', style: TextStyle(fontFamily: 'Padauk', fontWeight: FontWeight.bold))),
          DataColumn(label: Text('ကော်မရှင်', style: TextStyle(fontFamily: 'Padauk', fontWeight: FontWeight.bold))),
          DataColumn(label: Text('စုစုပေါင်း', style: TextStyle(fontFamily: 'Padauk', fontWeight: FontWeight.bold))),
        ],
        rows: [
          ...List<DataRow>.generate(
            sales.length,
            (index) {
              final sale = sales[index];
              return DataRow(cells: [
                DataCell(Text('${index + 1}', style: TextStyle(fontFamily: 'Padauk', fontSize: 10))),
                DataCell(Text(sale.gemstoneType, style: TextStyle(fontFamily: 'Padauk', fontSize: 10))),
                DataCell(Text(sale.stoneType, style: TextStyle(fontFamily: 'Padauk', fontSize: 10))),
                DataCell(Text('${sale.weight} kg', style: TextStyle(fontFamily: 'Padauk', fontSize: 10))),
                DataCell(Text('${sale.quantity}', style: TextStyle(fontFamily: 'Padauk', fontSize: 10))),
                DataCell(Text('${moneyFormat.format(sale.unitPrice)}', style: TextStyle(fontFamily: 'Padauk', fontSize: 10))),
                DataCell(Text('${moneyFormat.format(sale.commissionFee)}', style: TextStyle(fontFamily: 'Padauk', fontSize: 10))),
                DataCell(Text('${moneyFormat.format(sale.amount)}', style: TextStyle(fontFamily: 'Padauk', fontSize: 10))),
              ]);
            },
          ),
          // Totals row
          DataRow(cells: [
            DataCell(Text('', style: TextStyle(fontFamily: 'Padauk', fontWeight: FontWeight.bold))),
            DataCell(Text('စုစုပေါင်း', style: TextStyle(fontFamily: 'Padauk', fontWeight: FontWeight.bold, fontSize: 10))),
            DataCell(Text('', style: TextStyle(fontFamily: 'Padauk'))),
            DataCell(Text('', style: TextStyle(fontFamily: 'Padauk'))),
            DataCell(Text('$totalQty', style: TextStyle(fontFamily: 'Padauk', fontWeight: FontWeight.bold, fontSize: 10))),
            DataCell(Text('', style: TextStyle(fontFamily: 'Padauk'))),
            DataCell(Text('${moneyFormat.format(totalCommission)}', style: TextStyle(fontFamily: 'Padauk', fontWeight: FontWeight.bold, fontSize: 10))),
            DataCell(Text('${moneyFormat.format(totalAmount)}', style: TextStyle(fontFamily: 'Padauk', fontWeight: FontWeight.bold, fontSize: 10))),
          ]),
        ],
      ),
    );
  }

  /// Capture widget as image
  static Future<Uint8List?> captureAsImage(GlobalKey key) async {
    try {
      final RenderRepaintBoundary boundary = key.currentContext!.findRenderObject() as RenderRepaintBoundary;
      final ui.Image image = await boundary.toImage(pixelRatio: 2.0);
      final ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      return byteData?.buffer.asUint8List();
    } catch (e) {
      print('Error capturing image: $e');
      return null;
    }
  }
}
