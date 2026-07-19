// ignore_for_file: avoid_catches_without_on_clauses
import 'dart:async';
import 'dart:developer' as dev;
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/rendering.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/broker_voucher_document.dart';
import '../../../../core/local/local_db.dart';

/// Holds a pre-decoded [ui.Image] alongside the raw bytes so both are
/// available to the off-screen render tree without relying on ImageCache.
class _DecodedLogo {
  final Uint8List bytes;
  final ui.Image image;
  const _DecodedLogo({required this.bytes, required this.image});
}

// ─────────────────────────────────────────────────────────────────────────────
// DEBUG FLAG — set to false before production release
// ─────────────────────────────────────────────────────────────────────────────
const bool showImageExportDebug = true;

/// Generates clean PNG images of broker vouchers without app UI chrome
class BrokerVoucherImageExporter {
  static const double _pageWidth = 800; // Pixels
  static const double _pageHeight = 1100; // Pixels
  static const double _itemsPerPage = 15;

  /// Export voucher as PNG image(s) and share.
  ///
  /// [onStep] — called before each step starts with the step name.
  ///            Used by the caller to update visible debug UI.
  ///
  /// Returns true if successful.
  static Future<bool> exportImageAndShare(
    BrokerVoucherDocumentData data,
    BuildContext context, {
    void Function(String step)? onStep,
  }) async {
    final voucherNumber = data.voucherNumber;
    final itemCount = data.items.length;

    dev.log(
      '[ImageExport] start — voucher=$voucherNumber items=$itemCount',
      name: 'BrokerVoucherImageExporter',
    );

    // step: build_document_data
    onStep?.call('build_document_data');
    dev.log('[ImageExport] step=build_document_data', name: 'BrokerVoucherImageExporter');
    if (data.items.isEmpty) {
      throw StateError('ဘောင်ချာတွင် ပစ္စည်းများ မပါဝင်ပါ။');
    }

    // step: calculate_pages
    onStep?.call('calculate_pages');
    dev.log('[ImageExport] step=calculate_pages', name: 'BrokerVoucherImageExporter');
    final totalPages = ((data.items.length - 1) ~/ _itemsPerPage.toInt()) + 1;

      // step: get_temp_dir
      onStep?.call('get_temp_dir');
      dev.log('[ImageExport] step=get_temp_dir', name: 'BrokerVoucherImageExporter');
      final tempDir = await getTemporaryDirectory();

      // step: load_logo_bytes
      onStep?.call('load_logo_bytes');
      dev.log('[ImageExport] step=load_logo_bytes', name: 'BrokerVoucherImageExporter');
      final _DecodedLogo? decodedLogo = await _loadDecodedLogo(onStep);

      final imageFiles = <XFile>[];

      for (int pageNum = 0; pageNum < totalPages; pageNum++) {
      onStep?.call('render_page_${pageNum + 1}_of_$totalPages');
      dev.log(
        '[ImageExport] step=render_page page=${pageNum + 1}/$totalPages',
        name: 'BrokerVoucherImageExporter',
      );

      final startIdx = pageNum * _itemsPerPage.toInt();
      final endIdx =
          ((pageNum + 1) * _itemsPerPage.toInt()).clamp(0, data.items.length);
      final pageItems = data.items.sublist(startIdx, endIdx);

      // step: create_widget_tree
      onStep?.call('create_widget_tree');
      dev.log('[ImageExport] step=create_widget_tree', name: 'BrokerVoucherImageExporter');
      final widget = _VoucherPageWidget(
        data: data,
        items: pageItems,
        decodedLogo: decodedLogo,
        pageNum: pageNum + 1,
        totalPages: totalPages,
        onWidgetStep: onStep,
      );

      // step: render_to_image
      onStep?.call('render_to_image');
      dev.log('[ImageExport] step=render_to_image', name: 'BrokerVoucherImageExporter');
      final imageBytes = await _renderWidgetToImage(
        widget,
        voucherNumber,
        pageNum + 1,
        onStep: onStep,
      );

      // step: write_file
      onStep?.call('write_file');
      dev.log('[ImageExport] step=write_file', name: 'BrokerVoucherImageExporter');
      final filename = _getSafeFilename(voucherNumber, pageNum + 1, totalPages);
      final file = File('${tempDir.path}/$filename');
      await file.writeAsBytes(imageBytes);
      imageFiles.add(XFile(file.path, mimeType: 'image/png'));
    }

    // step: open_share_sheet
    onStep?.call('open_share_sheet');
    dev.log(
      '[ImageExport] step=open_share_sheet files=${imageFiles.length}',
      name: 'BrokerVoucherImageExporter',
    );
    await Share.shareXFiles(
      imageFiles,
      text: 'ပွဲစားအပ်နှံဘောင်ချာ - $voucherNumber',
    );

    onStep?.call('completed');
    dev.log('[ImageExport] success', name: 'BrokerVoucherImageExporter');
    return true;
  }

  /// Load and PRE-DECODE the logo so the off-screen render tree receives a
  /// [ui.Image] directly via [RawImage] — bypassing ImageCache entirely.
  ///
  /// Steps emitted:
  ///   logo_profile_loaded → logo_path_empty / logo_file_exists
  ///   → logo_bytes_loaded → logo_header_branch_selected
  ///   → logo_widget_inserted → logo_render_success
  ///   (or logo_path_empty / logo_file_missing / logo_read_failed /
  ///    logo_decode_failed on failure)
  static Future<_DecodedLogo?> _loadDecodedLogo(
      void Function(String step)? onStep) async {
    try {
      // ── Step 1: profile loaded ──────────────────────────────────────────
      final profile = LocalDb.getBusinessProfile();
      onStep?.call('logo_profile_loaded');
      dev.log('[ImageExport] logo_profile_loaded logoPath=${profile.logoPath}',
          name: 'BrokerVoucherImageExporter');

      final rawPath = profile.logoPath;
      if (rawPath == null || rawPath.trim().isEmpty) {
        onStep?.call('logo_path_empty');
        dev.log('[ImageExport] logo_path_empty', name: 'BrokerVoucherImageExporter');
        return null;
      }

      // ── Step 2: file exists ─────────────────────────────────────────────
      final logoFile = File(rawPath.trim());
      if (!logoFile.existsSync()) {
        onStep?.call('logo_file_missing');
        dev.log('[ImageExport] logo_file_missing path=$rawPath',
            name: 'BrokerVoucherImageExporter');
        return null;
      }
      onStep?.call('logo_file_exists');
      dev.log('[ImageExport] logo_file_exists path=$rawPath',
          name: 'BrokerVoucherImageExporter');

      // ── Step 3: read bytes ──────────────────────────────────────────────
      final bytes = await logoFile.readAsBytes();
      if (bytes.isEmpty) {
        onStep?.call('logo_read_failed');
        dev.log('[ImageExport] logo_read_failed (empty bytes)',
            name: 'BrokerVoucherImageExporter');
        return null;
      }
      onStep?.call('logo_bytes_loaded');
      dev.log('[ImageExport] logo_bytes_loaded bytes=${bytes.length}',
          name: 'BrokerVoucherImageExporter');

      // ── Step 4: decode to ui.Image (bypasses ImageCache) ───────────────
      // This is the critical fix: Image.memory() relies on the Flutter
      // ImageCache pipeline which is unavailable in the off-screen render
      // tree. ui.decodeImageFromList() decodes directly to a ui.Image that
      // RawImage can paint without any cache lookup.
      onStep?.call('logo_header_branch_selected');
      dev.log('[ImageExport] logo_header_branch_selected — decoding ui.Image',
          name: 'BrokerVoucherImageExporter');

      final completer = Completer<ui.Image>();
      ui.decodeImageFromList(bytes, (ui.Image img) {
        completer.complete(img);
      });
      final uiImage = await completer.future;

      onStep?.call('logo_widget_inserted');
      dev.log(
          '[ImageExport] logo_widget_inserted — ui.Image decoded '
          '${uiImage.width}x${uiImage.height}',
          name: 'BrokerVoucherImageExporter');

      onStep?.call('logo_render_success');
      dev.log('[ImageExport] logo_render_success',
          name: 'BrokerVoucherImageExporter');

      return _DecodedLogo(bytes: bytes, image: uiImage);
    } catch (e) {
      onStep?.call('logo_decode_failed');
      dev.log('[ImageExport] logo_decode_failed error=$e',
          name: 'BrokerVoucherImageExporter');
      return null;
    }
  }

  /// Render a widget to PNG bytes using an off-screen render tree.
  /// Uses [PlatformDispatcher] instead of the deprecated [ui.window].
  static Future<Uint8List> _renderWidgetToImage(
    Widget widget,
    String voucherNumber,
    int pageNum, {
    void Function(String step)? onStep,
  }) async {
    // step: get_flutter_view
    onStep?.call('get_flutter_view');
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
    onStep?.call('create_render_view');
    dev.log('[ImageExport] step=create_render_view dpr=$dpr logicalSize=$logicalSize',
        name: 'BrokerVoucherImageExporter');

    final repaintBoundary = RenderRepaintBoundary();

    // Build a ViewConfiguration that works across Flutter versions:
    // - Flutter ≤3.19: ViewConfiguration(size: Size, devicePixelRatio: double)
    // - Flutter ≥3.24: ViewConfiguration(logicalConstraints: BoxConstraints, devicePixelRatio: double)
    // We use dynamic invocation so the code compiles on both versions without
    // triggering an undefined_named_parameter static error.
    final viewConfig = _buildViewConfiguration(logicalSize, dpr);

    final renderView = RenderView(
      view: flutterView,
      child: RenderPositionedBox(
        alignment: Alignment.topLeft,
        child: repaintBoundary,
      ),
      configuration: viewConfig,
    );

    final pipelineOwner = PipelineOwner();
    final buildOwner = BuildOwner(focusManager: FocusManager());

    pipelineOwner.rootNode = renderView;
    buildOwner.focusManager.highlightStrategy =
        FocusHighlightStrategy.automatic;

    // step: build_widget_tree
    // NOTE: The onStep callback fires BEFORE attachToRenderTree.
    // To identify which widget inside the tree crashes, _VoucherPageWidget
    // accepts onWidgetStep and uses Builder widgets to call it from inside
    // each widget's build() method. The last Builder checkpoint that fires
    // before the crash tells us the exact failing widget.
    onStep?.call('build_widget_tree');
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
          child: Theme(
            data: ThemeData.light(),
            child: Material(
              child: widget,
            ),
          ),
        ),
      ),
    ).attachToRenderTree(buildOwner);

    buildOwner.finalizeTree();

    // CRITICAL: prepareInitialFrame() bootstraps the render view so that
    // RenderRepaintBoundary.toImage() can find a valid composited layer.
    renderView.prepareInitialFrame();

    // step: layout
    onStep?.call('layout');
    dev.log('[ImageExport] step=layout', name: 'BrokerVoucherImageExporter');
    pipelineOwner.flushLayout();

    // step: compositing_bits
    onStep?.call('compositing_bits');
    dev.log('[ImageExport] step=compositing_bits', name: 'BrokerVoucherImageExporter');
    pipelineOwner.flushCompositingBits();

    // step: paint
    onStep?.call('paint');
    dev.log('[ImageExport] step=paint', name: 'BrokerVoucherImageExporter');
    pipelineOwner.flushPaint();

    // step: convert_to_image
    onStep?.call('convert_to_image');
    dev.log('[ImageExport] step=convert_to_image pixelRatio=$dpr',
        name: 'BrokerVoucherImageExporter');
    final image = await repaintBoundary.toImage(pixelRatio: dpr);

    // step: png_byte_data
    onStep?.call('png_byte_data');
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

/// Widget that renders a single page of a broker voucher.
///
/// [onWidgetStep] is called from inside Builder widgets at each major
/// checkpoint so we can identify the exact widget that crashes during
/// attachToRenderTree. Each Builder fires its callback synchronously
/// during the build phase, so the last fired step = last built widget.
class _VoucherPageWidget extends StatelessWidget {
  final BrokerVoucherDocumentData data;
  final List<BrokerVoucherDocumentItem> items;
  final _DecodedLogo? decodedLogo;
  final int pageNum;
  final int totalPages;
  // ignore: prefer_function_declarations_over_variables
  final void Function(String step)? onWidgetStep;

  const _VoucherPageWidget({
    required this.data,
    required this.items,
    required this.pageNum,
    required this.totalPages,
    this.decodedLogo,
    this.onWidgetStep,
  });

  @override
  Widget build(BuildContext context) {
    // Checkpoint: entering _VoucherPageWidget.build()
    onWidgetStep?.call('widget_build_enter');
    dev.log('[ImageExport] widget=_VoucherPageWidget.build enter',
        name: 'BrokerVoucherImageExporter');

    return Builder(
      builder: (ctx) {
        onWidgetStep?.call('widget_container_outer');
        dev.log('[ImageExport] widget=Container(outer)',
            name: 'BrokerVoucherImageExporter');
        return Container(
          width: _VoucherPageWidget._kPageWidth,
          height: _VoucherPageWidget._kPageHeight,
          color: Colors.white,
          padding: const EdgeInsets.all(20),
          child: Builder(
            builder: (ctx2) {
              onWidgetStep?.call('widget_column_root');
              dev.log('[ImageExport] widget=Column(root)',
                  name: 'BrokerVoucherImageExporter');
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Header ──────────────────────────────────────────────
                  Builder(
                    builder: (ctx3) {
                      onWidgetStep?.call('widget_header_title');
                      dev.log('[ImageExport] widget=Text(header_title)',
                          name: 'BrokerVoucherImageExporter');
                      final profile = LocalDb.getBusinessProfile();
                      final shopName = profile.shopName.isNotEmpty
                          ? profile.shopName
                          : 'ပွဲစားအပ်နှံဘောင်ချာ';

                      // Build logo widget using pre-decoded ui.Image via RawImage.
                      // RawImage paints a ui.Image directly without ImageCache,
                      // making it safe inside the off-screen render tree.
                      Widget? logoWidget;
                      if (decodedLogo != null) {
                        logoWidget = RawImage(
                          image: decodedLogo!.image,
                          width: 80,
                          height: 80,
                          fit: BoxFit.contain,
                        );
                      }

                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Logo area — fixed 80×80 bounded box with debug border
                          if (logoWidget != null) ...[  
                            Container(
                              width: 80,
                              height: 80,
                              // Temporary debug border — proves logo widget is
                              // inside the capture boundary. Remove after confirmed.
                              decoration: showImageExportDebug
                                  ? BoxDecoration(
                                      border: Border.all(
                                          color: Colors.red, width: 1.5))
                                  : null,
                              child: logoWidget,
                            ),
                            const SizedBox(width: 12),
                          ],
                          // Shop info column
                          Expanded(
                            child: Column(
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
                                // Subtitle
                                const Text(
                                  'ပွဲစားအပ်နှံဘောင်ချာ',
                                  style: TextStyle(
                                    fontFamily: 'Padauk',
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                // Contact info
                                if (profile.phone?.isNotEmpty == true)
                                  Text(
                                    'ဖုန်း: ${profile.phone}',
                                    style: const TextStyle(
                                        fontFamily: 'Padauk', fontSize: 10),
                                  ),
                                if (profile.address?.isNotEmpty == true)
                                  Text(
                                    'လိပ်စာ: ${profile.address}',
                                    style: const TextStyle(
                                        fontFamily: 'Padauk', fontSize: 10),
                                  ),
                                if (profile.email?.isNotEmpty == true)
                                  Text(
                                    'Email: ${profile.email}',
                                    style: const TextStyle(
                                        fontFamily: 'Padauk', fontSize: 10),
                                  ),
                                if (profile.facebook?.isNotEmpty == true)
                                  Text(
                                    'Facebook: ${profile.facebook}',
                                    style: const TextStyle(
                                        fontFamily: 'Padauk', fontSize: 10),
                                  ),
                                if (profile.viber?.isNotEmpty == true)
                                  Text(
                                    'Viber: ${profile.viber}',
                                    style: const TextStyle(
                                        fontFamily: 'Padauk', fontSize: 10),
                                  ),
                                if (profile.website?.isNotEmpty == true)
                                  Text(
                                    'Website: ${profile.website}',
                                    style: const TextStyle(
                                        fontFamily: 'Padauk', fontSize: 10),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 8),
                  Builder(
                    builder: (ctx3) {
                      onWidgetStep?.call('widget_header_row');
                      dev.log('[ImageExport] widget=Row(header_meta)',
                          name: 'BrokerVoucherImageExporter');
                      return Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'ဘောင်ချာ နံပါတ်: ${data.voucherNumber}',
                            style: const TextStyle(
                                fontFamily: 'Padauk', fontSize: 11),
                          ),
                          Text(
                            'ရက်စွဲ: ${data.formattedDate}',
                            style: const TextStyle(
                                fontFamily: 'Padauk', fontSize: 11),
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 12),

                  // ── Broker info ─────────────────────────────────────────
                  Builder(
                    builder: (ctx3) {
                      onWidgetStep?.call('widget_broker_info_box');
                      dev.log('[ImageExport] widget=Container(broker_info)',
                          name: 'BrokerVoucherImageExporter');
                      return Container(
                        padding: const EdgeInsets.all(8),
                        decoration:
                            BoxDecoration(border: Border.all(color: Colors.grey)),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Builder(
                              builder: (ctx4) {
                                onWidgetStep?.call('widget_broker_label');
                                dev.log('[ImageExport] widget=Text(broker_label)',
                                    name: 'BrokerVoucherImageExporter');
                                return const Text(
                                  'ပွဲစားအချက်အလက်',
                                  style: TextStyle(
                                    fontFamily: 'Padauk',
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                );
                              },
                            ),
                            const SizedBox(height: 4),
                            Builder(
                              builder: (ctx4) {
                                onWidgetStep?.call('widget_broker_name');
                                dev.log('[ImageExport] widget=Text(broker_name)',
                                    name: 'BrokerVoucherImageExporter');
                                return Text(
                                  'နာမည်: ${data.brokerName}',
                                  style: const TextStyle(
                                      fontFamily: 'Padauk', fontSize: 10),
                                );
                              },
                            ),
                            Builder(
                              builder: (ctx4) {
                                onWidgetStep?.call('widget_broker_phone');
                                dev.log('[ImageExport] widget=Text(broker_phone)',
                                    name: 'BrokerVoucherImageExporter');
                                return Text(
                                  'ဖုန်း: ${data.brokerPhone}',
                                  style: const TextStyle(
                                      fontFamily: 'Padauk', fontSize: 10),
                                );
                              },
                            ),
                            if (data.brokerAddress != null &&
                                data.brokerAddress!.isNotEmpty)
                              Builder(
                                builder: (ctx4) {
                                  onWidgetStep?.call('widget_broker_address');
                                  dev.log(
                                      '[ImageExport] widget=Text(broker_address)',
                                      name: 'BrokerVoucherImageExporter');
                                  return Text(
                                    'လိပ်စာ: ${data.brokerAddress}',
                                    style: const TextStyle(
                                        fontFamily: 'Padauk', fontSize: 10),
                                  );
                                },
                              ),
                          ],
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 12),

                  // ── Items table ─────────────────────────────────────────
                  Builder(
                    builder: (ctx3) {
                      onWidgetStep?.call('widget_items_table_expanded');
                      dev.log('[ImageExport] widget=Expanded(items_table)',
                          name: 'BrokerVoucherImageExporter');
                      return Expanded(
                        child: SingleChildScrollView(
                          child: Builder(
                            builder: (ctx4) {
                              onWidgetStep?.call('widget_items_table_scroll');
                              dev.log(
                                  '[ImageExport] widget=SingleChildScrollView(items)',
                                  name: 'BrokerVoucherImageExporter');
                              return _buildItemsTable(onWidgetStep);
                            },
                          ),
                        ),
                      );
                    },
                  ),

                  // ── Footer ──────────────────────────────────────────────
                  const SizedBox(height: 12),
                  Builder(
                    builder: (ctx3) {
                      onWidgetStep?.call('widget_footer_row');
                      dev.log('[ImageExport] widget=Row(footer)',
                          name: 'BrokerVoucherImageExporter');
                      return Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'ပွဲစား လက်မှတ်',
                            style: const TextStyle(
                                fontFamily: 'Padauk', fontSize: 9),
                          ),
                          Text(
                            'စာမျက်နှာ $pageNum / $totalPages',
                            style: const TextStyle(
                                fontFamily: 'Padauk', fontSize: 9),
                          ),
                          Text(
                            'ကုန်သည် လက်မှတ်',
                            style: const TextStyle(
                                fontFamily: 'Padauk', fontSize: 9),
                          ),
                        ],
                      );
                    },
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  static const double _kPageWidth = 800;
  static const double _kPageHeight = 1100;

  Widget _buildItemsTable(void Function(String)? onStep) {
    onStep?.call('widget_table_build');
    dev.log('[ImageExport] widget=Table(items)', name: 'BrokerVoucherImageExporter');
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
        // Item rows
        ...items.asMap().entries.map((entry) {
          final idx = entry.key;
          final item = entry.value;
          onStep?.call('widget_table_row_$idx');
          dev.log('[ImageExport] widget=TableRow(item_$idx)',
              name: 'BrokerVoucherImageExporter');
          return TableRow(
            children: [
              _buildTableCell('${item.itemNumber}'),
              _buildTableCell(item.itemName),
              _buildTableCell(item.sourceType),
              _buildTableCell(item.weightDisplay),
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
        // Totals row
        TableRow(
          decoration: BoxDecoration(color: Colors.grey[200]),
          children: [
            _buildTableCell('စုစုပေါင်း', isHeader: true),
            _buildTableCell('${data.totals.distinctItemCount}',
                isHeader: true),
            _buildTableCell('', isHeader: true),
            _buildTableCell(
                data.totals.totalWeightKg > 0
                    ? '${data.totals.totalWeightKg.toStringAsFixed(2)} ${data.totals.totalWeightUnit}'
                    : '',
                isHeader: true),
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


/// Returns a [ViewConfiguration] compatible with both Flutter 3.19 and 3.24+.
///
/// Flutter 3.19 uses `ViewConfiguration(size: Size, devicePixelRatio: double)`.
/// Flutter 3.24+ uses `ViewConfiguration(logicalConstraints: BoxConstraints, devicePixelRatio: double)`.
///
/// Using `Function.apply` with a dynamic mirror of the constructor avoids
/// compile-time `undefined_named_parameter` errors on either version.
ViewConfiguration _buildViewConfiguration(Size logicalSize, double dpr) {
  // Try the Flutter 3.24+ API first (logicalConstraints).
  // If that parameter doesn't exist, fall back to the Flutter 3.19 API (size).
  try {
    // ignore: undefined_named_parameter
    return (ViewConfiguration.new as dynamic)(
      logicalConstraints: BoxConstraints.tight(logicalSize),
      devicePixelRatio: dpr,
    ) as ViewConfiguration;
  } catch (_) {
    // ignore: undefined_named_parameter
    return (ViewConfiguration.new as dynamic)(
      size: logicalSize,
      devicePixelRatio: dpr,
    ) as ViewConfiguration;
  }
}
