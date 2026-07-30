// ignore_for_file: avoid_catches_without_on_clauses
import 'dart:async';
import 'dart:developer' as dev;
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/rendering.dart';
import 'package:flutter/material.dart';

/// Reusable off-screen widget renderer for generating PNG images without app UI.
///
/// This service provides a proven rendering pipeline that works reliably across
/// Flutter versions by:
/// - Using PlatformDispatcher for FlutterView access (not deprecated ui.window)
/// - Creating an off-screen render tree with proper PipelineOwner/BuildOwner
/// - Calling prepareInitialFrame() to bootstrap the render view
/// - Flushing layout, compositing bits, and paint in order
/// - Converting to PNG with proper pixel ratio
class OffscreenWidgetImageRenderer {
  /// Render a widget to PNG bytes using an off-screen render tree.
  ///
  /// [widget] - The widget to render
  /// [pageWidth] - Logical width in pixels (default 800)
  /// [pageHeight] - Logical height in pixels (default 1100)
  /// [pixelRatio] - Device pixel ratio for rendering (default 2.0)
  /// [onStep] - Optional callback for step tracking (for debugging)
  /// [serviceName] - Name for debug logging (e.g., 'SalesInvoiceRenderer')
  ///
  /// Returns PNG bytes or throws StateError with detailed error message.
  static Future<Uint8List> renderWidgetToPNG(
    Widget widget, {
    double pageWidth = 800,
    double pageHeight = 1100,
    double pixelRatio = 2.0,
    void Function(String step)? onStep,
    String serviceName = 'OffscreenWidgetImageRenderer',
  }) async {
    // step: get_flutter_view
    onStep?.call('get_flutter_view');
    dev.log('[ImageExport] step=get_flutter_view', name: serviceName);

    // Obtain the first available FlutterView via PlatformDispatcher.
    // This replaces the deprecated ui.window accessor.
    final views = ui.PlatformDispatcher.instance.views;
    if (views.isEmpty) {
      throw StateError(
        'ပုံ ထုတ်ယူ၍မရပါ။ FlutterView မတွေ့ပါ။ ထပ်မံကြိုးစားပါ။',
      );
    }
    final flutterView = views.first;

    final dpr = flutterView.devicePixelRatio;
    final physicalSize = flutterView.physicalSize;
    if (physicalSize.isEmpty) {
      throw StateError(
        'ပုံ ထုတ်ယူ၍မရပါ။ FlutterView အရွယ်အစား မမှန်ပါ။ ထပ်မံကြိုးစားပါ။',
      );
    }

    // Use provided logical size instead of device size
    final logicalSize = Size(pageWidth, pageHeight);

    // step: create_render_view
    onStep?.call('create_render_view');
    dev.log('[ImageExport] step=create_render_view dpr=$dpr logicalSize=$logicalSize',
        name: serviceName);

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
    onStep?.call('build_widget_tree');
    dev.log('[ImageExport] step=build_widget_tree', name: serviceName);

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
    dev.log('[ImageExport] step=layout', name: serviceName);
    pipelineOwner.flushLayout();

    // step: compositing_bits
    onStep?.call('compositing_bits');
    dev.log('[ImageExport] step=compositing_bits', name: serviceName);
    pipelineOwner.flushCompositingBits();

    // step: paint
    onStep?.call('paint');
    dev.log('[ImageExport] step=paint', name: serviceName);
    pipelineOwner.flushPaint();

    // Allow render tree to stabilize before capturing image
    await Future.delayed(const Duration(milliseconds: 10));

    // step: convert_to_image
    onStep?.call('convert_to_image');
    dev.log('[ImageExport] step=convert_to_image pixelRatio=$pixelRatio',
        name: serviceName);
    final image = await repaintBoundary.toImage(pixelRatio: pixelRatio);

    // step: png_byte_data
    onStep?.call('png_byte_data');
    dev.log('[ImageExport] step=png_byte_data', name: serviceName);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();

    if (byteData == null) {
      throw StateError(
        'ပုံ ထုတ်ယူ၍မရပါ။ PNG encoding မအောင်မြင်ပါ။ ထပ်မံကြိုးစားပါ။',
      );
    }

    dev.log('[ImageExport] step=png_byte_data done bytes=${byteData.lengthInBytes}',
        name: serviceName);
    return byteData.buffer.asUint8List();
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
