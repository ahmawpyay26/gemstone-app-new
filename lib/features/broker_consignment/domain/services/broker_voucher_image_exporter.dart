import 'dart:developer' as dev;
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/rendering.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:io';
import '../models/broker_voucher_document.dart';

/// Generates clean PNG images of broker vouchers without app UI chrome
class BrokerVoucherImageExporter {
  static const double _pageWidth = 800; // Pixels
  static const double _pageHeight = 1100; // Pixels
  static const double _itemsPerPage = 15;

  /// Export voucher as PNG image(s) and share.
  /// Returns true if successful.
  /// Throws a [StateError] with a Burmese message on any null-safety failure.
  static Future<bool> exportImageAndShare(
    BrokerVoucherDocumentData data,
    BuildContext context,
  ) async {
    final voucherNumber = data.voucherNumber;
    final itemCount = data.items.length;

    dev.log(
      '[ImageExport] start — voucher=$voucherNumber items=$itemCount',
      name: 'BrokerVoucherImageExporter',
    );

    // step: build_document_data
    dev.log('[ImageExport] step=build_document_data', name: 'BrokerVoucherImageExporter');
    if (data.items.isEmpty) {
      throw StateError('ဘောင်ချာတွင် ပစ္စည်းများ မပါဝင်ပါ။');
    }

    // step: calculate_pages
    dev.log('[ImageExport] step=calculate_pages', name: 'BrokerVoucherImageExporter');
    final totalPages = ((data.items.length - 1) ~/ _itemsPerPage.toInt()) + 1;

    // step: get_temp_dir
    dev.log('[ImageExport] step=get_temp_dir', name: 'BrokerVoucherImageExporter');
    final tempDir = await getTemporaryDirectory();

    final imageFiles = <XFile>[];

    for (int pageNum = 0; pageNum < totalPages; pageNum++) {
      dev.log(
        '[ImageExport] step=render_page page=${pageNum + 1}/$totalPages',
        name: 'BrokerVoucherImageExporter',
      );

      final startIdx = pageNum * _itemsPerPage.toInt();
      final endIdx =
          ((pageNum + 1) * _itemsPerPage.toInt()).clamp(0, data.items.length);
      final pageItems = data.items.sublist(startIdx, endIdx);

      // step: create_widget_tree
      dev.log('[ImageExport] step=create_widget_tree', name: 'BrokerVoucherImageExporter');
      final widget = _VoucherPageWidget(
        data: data,
        items: pageItems,
        pageNum: pageNum + 1,
        totalPages: totalPages,
      );

      // step: render_to_image
      dev.log('[ImageExport] step=render_to_image', name: 'BrokerVoucherImageExporter');
      final imageBytes = await _renderWidgetToImage(widget, voucherNumber, pageNum + 1);

      // step: write_file
      dev.log('[ImageExport] step=write_file', name: 'BrokerVoucherImageExporter');
      final filename = _getSafeFilename(voucherNumber, pageNum + 1, totalPages);
      final file = File('${tempDir.path}/$filename');
      await file.writeAsBytes(imageBytes);
      imageFiles.add(XFile(file.path, mimeType: 'image/png'));
    }

    // step: open_share_sheet
    dev.log(
      '[ImageExport] step=open_share_sheet files=${imageFiles.length}',
      name: 'BrokerVoucherImageExporter',
    );
    await Share.shareXFiles(
      imageFiles,
      text: 'ပွဲစားအပ်နှံဘောင်ချာ - $voucherNumber',
    );

    dev.log('[ImageExport] success', name: 'BrokerVoucherImageExporter');
    return true;
  }

  /// Render a widget to PNG bytes using an off-screen render tree.
  /// Uses [PlatformDispatcher] instead of the deprecated [ui.window].
  static Future<Uint8List> _renderWidgetToImage(
    Widget widget,
    String voucherNumber,
    int pageNum,
  ) async {
    // step: get_flutter_view
    dev.log('[ImageExport] step=get_flutter_view', name: 'BrokerVoucherImageExporter');

    // Obtain the first available FlutterView via PlatformDispatcher.
    // This replaces the deprecated ui.window accessor.
    final views = ui.PlatformDispatcher.instance.views;
    if (views.isEmpty) {
      throw StateError(
        'ဘောင်ချာပုံ ထုတ်ယူ၍မရပါ။ FlutterView မတွေ့ပါ။ ထပ်မံကြိုးစားပါ။',
      );
    }
    final flutterView = views.first;

    final dpr = flutterView.devicePixelRatio;
    final physicalSize = flutterView.physicalSize;
    if (physicalSize.isEmpty) {
      throw StateError(
        'ဘောင်ချာပုံ ထုတ်ယူ၍မရပါ။ FlutterView အရွယ်အစား မမှန်ပါ။ ထပ်မံကြိုးစားပါ။',
      );
    }
    final logicalSize = physicalSize / dpr;

    // step: create_render_view
    dev.log('[ImageExport] step=create_render_view dpr=$dpr logicalSize=$logicalSize',
        name: 'BrokerVoucherImageExporter');

    final repaintBoundary = RenderRepaintBoundary();

    final renderView = RenderView(
      view: flutterView,
      child: RenderPositionedBox(
        alignment: Alignment.topLeft,
        child: repaintBoundary,
      ),
    );

    final pipelineOwner = PipelineOwner();
    final buildOwner = BuildOwner(focusManager: FocusManager());

    pipelineOwner.rootNode = renderView;
    buildOwner.focusManager.highlightStrategy =
        FocusHighlightStrategy.automatic;

    // step: build_widget_tree
    dev.log('[ImageExport] step=build_widget_tree', name: 'BrokerVoucherImageExporter');

    RenderObjectToWidgetAdapter<RenderBox>(
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

    // step: layout
    dev.log('[ImageExport] step=layout', name: 'BrokerVoucherImageExporter');
    pipelineOwner.flushLayout();

    // step: compositing_bits
    dev.log('[ImageExport] step=compositing_bits', name: 'BrokerVoucherImageExporter');
    pipelineOwner.flushCompositingBits();

    // step: paint
    dev.log('[ImageExport] step=paint', name: 'BrokerVoucherImageExporter');
    pipelineOwner.flushPaint();

    // step: convert_to_image
    dev.log('[ImageExport] step=convert_to_image pixelRatio=$dpr',
        name: 'BrokerVoucherImageExporter');
    final image = await repaintBoundary.toImage(pixelRatio: dpr);

    // step: png_byte_data
    dev.log('[ImageExport] step=png_byte_data', name: 'BrokerVoucherImageExporter');
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();

    if (byteData == null) {
      throw StateError(
        'ဘောင်ချာပုံ ထုတ်ယူ၍မရပါ။ PNG encoding မအောင်မြင်ပါ။ ထပ်မံကြိုးစားပါ။',
      );
    }

    dev.log('[ImageExport] step=png_byte_data done bytes=${byteData.lengthInBytes}',
        name: 'BrokerVoucherImageExporter');
    return byteData.buffer.asUint8List();
  }

  /// Get safe filename for image export
  static String _getSafeFilename(
      String voucherNumber, int pageNum, int totalPages) {
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
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Text(
            'အတ္တကြ မြန်မာ ကျောက်မျ',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            'ပွဲစားအပ်နှံဘောင်ချာ',
            style: const TextStyle(
              fontFamily: 'Padauk',
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'ဘောင်ချာ နံပါတ်: ${data.voucherNumber}',
                style: const TextStyle(fontFamily: 'Padauk', fontSize: 11),
              ),
              Text(
                'ရက်စွဲ: ${data.formattedDate}',
                style: const TextStyle(fontFamily: 'Padauk', fontSize: 11),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Broker info
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(border: Border.all(color: Colors.grey)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ပွဲစားအချက်အလက်',
                  style: const TextStyle(
                    fontFamily: 'Padauk',
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'နာမည်: ${data.brokerName}',
                  style: const TextStyle(fontFamily: 'Padauk', fontSize: 10),
                ),
                Text(
                  'ဖုန်း: ${data.brokerPhone}',
                  style: const TextStyle(fontFamily: 'Padauk', fontSize: 10),
                ),
                // null-safe: brokerAddress is String? — only show if non-null and non-empty
                if (data.brokerAddress != null &&
                    data.brokerAddress!.isNotEmpty)
                  Text(
                    'လိပ်စာ: ${data.brokerAddress}',
                    style:
                        const TextStyle(fontFamily: 'Padauk', fontSize: 10),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Items table
          Expanded(
            child: SingleChildScrollView(
              child: _buildItemsTable(),
            ),
          ),

          // Footer
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'ပွဲစား လက်မှတ်',
                style: const TextStyle(fontFamily: 'Padauk', fontSize: 9),
              ),
              Text(
                'စာမျက်နှာ $pageNum / $totalPages',
                style: const TextStyle(fontFamily: 'Padauk', fontSize: 9),
              ),
              Text(
                'ကုန်သည် လက်မှတ်',
                style: const TextStyle(fontFamily: 'Padauk', fontSize: 9),
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
              _buildTableCell(
                  '${item.consignedQuantity.toStringAsFixed(2)}'),
              _buildTableCell(
                  '${item.soldQuantity.toStringAsFixed(2)}'),
              _buildTableCell(
                  '${item.returnedQuantity.toStringAsFixed(2)}'),
              _buildTableCell(
                  '${item.remainingQuantity.toStringAsFixed(2)}'),
            ],
          );
        }),
        // Totals
        TableRow(
          decoration: BoxDecoration(color: Colors.grey[200]),
          children: [
            _buildTableCell('စုစုပေါင်း', isHeader: true),
            _buildTableCell('${data.totals.distinctItemCount}',
                isHeader: true),
            _buildTableCell('', isHeader: true),
            _buildTableCell('', isHeader: true),
            _buildTableCell(
                '${data.totals.totalConsignedQuantity.toStringAsFixed(2)}',
                isHeader: true),
            _buildTableCell(
                '${data.totals.totalSoldQuantity.toStringAsFixed(2)}',
                isHeader: true),
            _buildTableCell(
                '${data.totals.totalReturnedQuantity.toStringAsFixed(2)}',
                isHeader: true),
            _buildTableCell(
                '${data.totals.totalRemainingQuantity.toStringAsFixed(2)}',
                isHeader: true),
          ],
        ),
      ],
    );
  }

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
}
