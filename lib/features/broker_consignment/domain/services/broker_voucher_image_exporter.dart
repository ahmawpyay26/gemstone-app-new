import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/rendering.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:io';
import 'package:flutter/foundation.dart';
import '../models/broker_voucher_document.dart';

/// Generates clean PNG images of broker vouchers without app UI chrome
class BrokerVoucherImageExporter {
  static const double _pageWidth = 800; // Pixels
  static const double _pageHeight = 1100; // Pixels
  static const double _itemsPerPage = 15;

  /// Export voucher as PNG image(s) and share
  /// Returns true if successful
  static Future<bool> exportImageAndShare(
    BrokerVoucherDocumentData data,
    BuildContext context,
  ) async {
    try {
      // Calculate number of pages
      final totalPages = ((data.items.length - 1) ~/ _itemsPerPage.toInt()) + 1;

      // Generate PNG bytes for each page
      final imageFiles = <XFile>[];
      final tempDir = await getTemporaryDirectory();

      for (int pageNum = 0; pageNum < totalPages; pageNum++) {
        final startIdx = pageNum * _itemsPerPage.toInt();
        final endIdx = ((pageNum + 1) * _itemsPerPage.toInt()).clamp(0, data.items.length);
        final pageItems = data.items.sublist(startIdx, endIdx);

        // Create widget for this page
        final widget = _VoucherPageWidget(
          data: data,
          items: pageItems,
          pageNum: pageNum + 1,
          totalPages: totalPages,
        );

        // Render to image
        final imageBytes = await _renderWidgetToImage(widget);

        // Save to file
        final filename = _getSafeFilename(data.voucherNumber, pageNum + 1, totalPages);
        final file = File('${tempDir.path}/$filename');
        await file.writeAsBytes(imageBytes);
        imageFiles.add(XFile(file.path, mimeType: 'image/png'));
      }

      // Open native share sheet with all images
      await Share.shareXFiles(
        imageFiles,
        text: 'ပွဲစားအပ်နှံဘောင်ချာ - ${data.voucherNumber}',
      );

      return true;
    } catch (e) {
      rethrow;
    }
  }

  /// Render a widget to PNG bytes
  static Future<Uint8List> _renderWidgetToImage(Widget widget) async {
    final repaintBoundary = RenderRepaintBoundary();

    // Get device pixel ratio and logical size for off-screen rendering
    final dpr = ui.window.devicePixelRatio;
    final logicalSize = ui.window.physicalSize / dpr;

    final renderView = RenderView(
      view: ui.window,
      child: RenderPositionedBox(
        alignment: Alignment.topLeft,
        child: repaintBoundary,
      ),
    );

    final pipelineOwner = PipelineOwner();
    final buildOwner = BuildOwner(focusManager: FocusManager());

    pipelineOwner.rootNode = renderView;

    buildOwner.focusManager.highlightStrategy = FocusHighlightStrategy.automatic;

    final rootElement = RenderObjectToWidgetAdapter<RenderBox>(
      container: repaintBoundary,
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: MediaQuery(
          data: MediaQueryData(
            size: logicalSize,
            devicePixelRatio: dpr,
            padding: EdgeInsets.zero,
            viewPadding: EdgeInsets.zero,
            viewInsets: EdgeInsets.zero,
          ),
          child: Material(
            child: widget,
          ),
        ),
      ),
    ).attachToRenderTree(buildOwner);

    buildOwner.finalizeTree();

    pipelineOwner.flushLayout();
    pipelineOwner.flushCompositingBits();
    pipelineOwner.flushPaint();

    // Render to image with device pixel ratio
    final image = await repaintBoundary.toImage(pixelRatio: dpr);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);

    image.dispose();
    return byteData!.buffer.asUint8List();
  }

  /// Get safe filename for image export
  static String _getSafeFilename(String voucherNumber, int pageNum, int totalPages) {
    final safe = voucherNumber
        .replaceAll(RegExp(r'[^a-zA-Z0-9\-]'), '-')
        .replaceAll(RegExp(r'-+'), '-')
        .toLowerCase();

    if (totalPages > 1) {
      return 'broker-consignment-$safe-page-$pageNum.png';
    }
    return 'broker-consignment-$safe.png';
  }
}

/// Widget that renders a single page of a broker voucher
class _VoucherPageWidget extends StatelessWidget {
  final BrokerVoucherDocumentData data;
  final List<BrokerVoucherDocumentItem> items;
  final int pageNum;
  final int totalPages;

  const _VoucherPageWidget({
    required this.data,
    required this.items,
    required this.pageNum,
    required this.totalPages,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 800,
      height: 1100,
      color: Colors.white,
      padding: EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Text(
            'အတ္တကြ မြန်မာ ကျောက်မျ',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 4),
          Text(
            'ပွဲစားအပ်နှံဘောင်ချာ',
            style: TextStyle(
              fontFamily: 'Padauk',
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'ဘောင်ချာ နံပါတ်: ${data.voucherNumber}',
                style: TextStyle(fontFamily: 'Padauk', fontSize: 11),
              ),
              Text(
                'ရက်စွဲ: ${data.formattedDate}',
                style: TextStyle(fontFamily: 'Padauk', fontSize: 11),
              ),
            ],
          ),
          SizedBox(height: 12),

          // Broker info
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(border: Border.all(color: Colors.grey)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ပွဲစားအချက်အလက်',
                  style: TextStyle(
                    fontFamily: 'Padauk',
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'နာမည်: ${data.brokerName}',
                  style: TextStyle(fontFamily: 'Padauk', fontSize: 10),
                ),
                Text(
                  'ဖုန်း: ${data.brokerPhone}',
                  style: TextStyle(fontFamily: 'Padauk', fontSize: 10),
                ),
                if (data.brokerAddress != null && data.brokerAddress!.isNotEmpty)
                  Text(
                    'လိပ်စာ: ${data.brokerAddress}',
                    style: TextStyle(fontFamily: 'Padauk', fontSize: 10),
                  ),
              ],
            ),
          ),
          SizedBox(height: 12),

          // Items table
          Expanded(
            child: SingleChildScrollView(
              child: _buildItemsTable(),
            ),
          ),

          // Footer
          SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'ပွဲစား လက်မှတ်',
                style: TextStyle(fontFamily: 'Padauk', fontSize: 9),
              ),
              Text(
                'စာမျက်နှာ $pageNum / $totalPages',
                style: TextStyle(fontFamily: 'Padauk', fontSize: 9),
              ),
              Text(
                'ကုန်သည် လက်မှတ်',
                style: TextStyle(fontFamily: 'Padauk', fontSize: 9),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildItemsTable() {
    return Table(
      border: TableBorder.all(color: Colors.grey),
      columnWidths: {
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
        // Header
        TableRow(
          decoration: BoxDecoration(color: Colors.grey[300]),
          children: [
            _buildTableCell('စဉ်', isHeader: true),
            _buildTableCell('ပစ္စည်း', isHeader: true),
            _buildTableCell('အမျိုး', isHeader: true),
            _buildTableCell('အလေးချိန်', isHeader: true),
            _buildTableCell('အပ်ထား', isHeader: true),
            _buildTableCell('ရောင်းချ', isHeader: true),
            _buildTableCell('ပြန်ရယူ', isHeader: true),
            _buildTableCell('ကျန်ရှိ', isHeader: true),
          ],
        ),
        // Items
        ...items.map((item) {
          return TableRow(
            children: [
              _buildTableCell('${item.itemNumber}'),
              _buildTableCell(item.itemName),
              _buildTableCell(item.sourceType),
              _buildTableCell('${item.weight}${item.weightUnit}'),
              _buildTableCell('${item.consignedQuantity.toStringAsFixed(2)}'),
              _buildTableCell('${item.soldQuantity.toStringAsFixed(2)}'),
              _buildTableCell('${item.returnedQuantity.toStringAsFixed(2)}'),
              _buildTableCell('${item.remainingQuantity.toStringAsFixed(2)}'),
            ],
          );
        }),
        // Totals
        TableRow(
          decoration: BoxDecoration(color: Colors.grey[200]),
          children: [
            _buildTableCell('စုစုပေါင်း', isHeader: true),
            _buildTableCell('${data.totals.distinctItemCount}', isHeader: true),
            _buildTableCell('', isHeader: true),
            _buildTableCell('', isHeader: true),
            _buildTableCell('${data.totals.totalConsignedQuantity.toStringAsFixed(2)}', isHeader: true),
            _buildTableCell('${data.totals.totalSoldQuantity.toStringAsFixed(2)}', isHeader: true),
            _buildTableCell('${data.totals.totalReturnedQuantity.toStringAsFixed(2)}', isHeader: true),
            _buildTableCell('${data.totals.totalRemainingQuantity.toStringAsFixed(2)}', isHeader: true),
          ],
        ),
      ],
    );
  }

  Widget _buildTableCell(String text, {bool isHeader = false}) {
    return Padding(
      padding: EdgeInsets.all(4),
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
}
