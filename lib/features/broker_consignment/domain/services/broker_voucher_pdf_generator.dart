import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../models/broker_voucher_document.dart';
import '../../../../core/local/local_db.dart';

/// Generates multi-page PDF bytes for broker vouchers with Myanmar text support
class BrokerVoucherPdfGenerator {
  static const double _margin = 20;
  static const double _itemsPerPage = 15;
  
  // Page dimensions (cannot be const due to PdfPageFormat.a4 runtime evaluation)
  static final double _pageWidth = PdfPageFormat.a4.width;
  static final double _pageHeight = PdfPageFormat.a4.height;
  static final double _contentWidth = _pageWidth - (2 * _margin);

  /// Load logo bytes safely for PDF. Returns null if unavailable.
  static Future<Uint8List?> _loadLogoBytes() async {
    try {
      final profile = LocalDb.getBusinessProfile();
      final rawPath = profile.logoPath;
      if (rawPath == null || rawPath.trim().isEmpty) return null;
      final logoFile = File(rawPath.trim());
      if (!logoFile.existsSync()) return null;
      final bytes = await logoFile.readAsBytes();
      return bytes.isEmpty ? null : bytes;
    } catch (_) {
      return null;
    }
  }

  /// Generate PDF bytes from voucher document data
  static Future<Uint8List> generatePdf(
    BrokerVoucherDocumentData data,
  ) async {
    // Load Padauk fonts (regular and bold)
    final padaukRegular = await _loadPadaukFont('Regular');
    final padaukBold = await _loadPadaukFont('Bold');

    // Load logo bytes before building pages
    final Uint8List? logoBytes = await _loadLogoBytes();
    
    final pdf = pw.Document(
      theme: pw.ThemeData.withFont(
        base: padaukRegular,
        bold: padaukBold,
      ),
    );

    // Calculate number of pages needed
    final totalPages = ((data.items.length - 1) ~/ _itemsPerPage.toInt()) + 1;

    // Generate pages
    for (int pageNum = 0; pageNum < totalPages; pageNum++) {
      final startIdx = pageNum * _itemsPerPage.toInt();
      final endIdx = ((pageNum + 1) * _itemsPerPage.toInt()).clamp(0, data.items.length);
      final pageItems = data.items.sublist(startIdx, endIdx);

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: pw.EdgeInsets.all(_margin),
          build: (context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Header
                _buildHeader(data, padaukRegular, padaukBold, logoBytes),
                pw.SizedBox(height: 12),

                // Broker Information
                _buildBrokerInfo(data, padaukRegular, padaukBold),
                pw.SizedBox(height: 12),

                // Items Table
                _buildItemsTable(pageItems, data.totals, padaukRegular, padaukBold),

                // Page break space
                pw.Spacer(),

                // Footer with page number
                _buildFooter(pageNum + 1, totalPages, padaukRegular, padaukBold),
              ],
            );
          },
        ),
      );
    }

    return pdf.save();
  }

  /// Load Padauk font from assets
  /// [variant] can be 'Regular' or 'Bold'
  static Future<pw.Font> _loadPadaukFont(String variant) async {
    final fontPath = 'assets/fonts/Padauk-$variant.ttf';
    final fontData = await rootBundle.load(fontPath);
    return pw.Font.ttf(fontData);
  }

  /// Build header section with business profile info, logo, and voucher title
  static pw.Widget _buildHeader(
      BrokerVoucherDocumentData data, pw.Font padaukRegular, pw.Font padaukBold, Uint8List? logoBytes) {
    final profile = LocalDb.getBusinessProfile();
    final shopName = profile.shopName.isNotEmpty
        ? profile.shopName
        : 'ပွဲစားအပ်နှံဘောင်ချာ';

    // Build logo widget from pre-loaded bytes
    pw.Widget? logoWidget;
    if (logoBytes != null && logoBytes.isNotEmpty) {
      try {
        final pdfImage = pw.MemoryImage(logoBytes);
        logoWidget = pw.Container(
          width: 60,
          height: 60,
          child: pw.Image(pdfImage, fit: pw.BoxFit.contain),
        );
      } catch (_) {
        logoWidget = null; // fallback: omit logo cleanly
      }
    }

    // Build the info column
    final infoColumn = pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        // Shop name — large bold title
        pw.Text(
          shopName,
          style: pw.TextStyle(
            font: padaukBold,
            fontSize: 18,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        pw.SizedBox(height: 2),

        // Voucher subtitle
        pw.Text(
          'ပွဲစားအပ်နှံဘောင်ချာ',
          style: pw.TextStyle(
            font: padaukBold,
            fontSize: 14,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        pw.SizedBox(height: 4),

        // Business contact info — only show non-empty fields
        if (profile.phone?.isNotEmpty == true)
          pw.Text(
            'ဖုန်း: ${profile.phone}',
            style: pw.TextStyle(font: padaukRegular, fontSize: 10),
          ),
        if (profile.address?.isNotEmpty == true)
          pw.Text(
            'လိပ်စာ: ${profile.address}',
            style: pw.TextStyle(font: padaukRegular, fontSize: 10),
          ),
        if (profile.email?.isNotEmpty == true)
          pw.Text(
            'Email: ${profile.email}',
            style: pw.TextStyle(font: padaukRegular, fontSize: 10),
          ),
        if (profile.facebook?.isNotEmpty == true)
          pw.Text(
            'Facebook: ${profile.facebook}',
            style: pw.TextStyle(font: padaukRegular, fontSize: 10),
          ),
        if (profile.viber?.isNotEmpty == true)
          pw.Text(
            'Viber: ${profile.viber}',
            style: pw.TextStyle(font: padaukRegular, fontSize: 10),
          ),
        if (profile.website?.isNotEmpty == true)
          pw.Text(
            'Website: ${profile.website}',
            style: pw.TextStyle(font: padaukRegular, fontSize: 10),
          ),
      ],
    );

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        // Logo + info row
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            if (logoWidget != null) ...[logoWidget, pw.SizedBox(width: 10)],
            pw.Expanded(child: infoColumn),
          ],
        ),
        pw.SizedBox(height: 8),

        // Voucher number and date
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              'ဘောင်ချာ နေပြာတ်: ${data.voucherNumber}',
              style: pw.TextStyle(
                font: padaukRegular,
                fontSize: 11,
              ),
            ),
            pw.Text(
              'မပ်စွဲ: ${data.formattedDate}',
              style: pw.TextStyle(
                font: padaukRegular,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Build broker information section
  static pw.Widget _buildBrokerInfo(BrokerVoucherDocumentData data, pw.Font padaukRegular, pw.Font padaukBold) {
    return pw.Container(
      padding: pw.EdgeInsets.all(8),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey400),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'ပွဲစားအပ်နှံအချိပ်အခြိင်',
            style: pw.TextStyle(
              font: padaukBold,
              fontSize: 11,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            'နာနိတ်: ${data.brokerName}',
            style: pw.TextStyle(
              font: padaukRegular,
              fontSize: 10,
            ),
          ),
          pw.Text(
            'ဖုန်း: ${data.brokerPhone}',
            style: pw.TextStyle(
              font: padaukRegular,
              fontSize: 10,
            ),
          ),
          if (data.brokerAddress != null && data.brokerAddress!.isNotEmpty)
            pw.Text(
              'လိပ်စာ: ${data.brokerAddress}',
              style: pw.TextStyle(
                font: padaukRegular,
                fontSize: 10,
              ),
            ),
          if (data.notes != null && data.notes!.isNotEmpty)
            pw.Text(
              'မျိတ်ချိပ်: ${data.notes}',
              style: pw.TextStyle(
                font: padaukRegular,
                fontSize: 10,
              ),
            ),
        ],
      ),
    );
  }

  /// Build items table with all columns
  static pw.Widget _buildItemsTable(
    List<BrokerVoucherDocumentItem> items,
    BrokerVoucherDocumentTotals totals,
    pw.Font padaukRegular,
    pw.Font padaukBold,
  ) {

    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey400),
      columnWidths: {
        0: pw.FixedColumnWidth(25), // No.
        1: pw.FixedColumnWidth(80), // Item name
        2: pw.FixedColumnWidth(50), // Type
        3: pw.FixedColumnWidth(40), // Weight
        4: pw.FixedColumnWidth(45), // Consigned
        5: pw.FixedColumnWidth(40), // Sold
        6: pw.FixedColumnWidth(40), // Returned
        7: pw.FixedColumnWidth(40), // Remaining
      },
      children: [
        // Header row
        pw.TableRow(
          decoration: pw.BoxDecoration(color: PdfColors.grey300),
          children: [
            _buildTableCell('စြု', padaukBold, isHeader: true),
            _buildTableCell('ပစ်စွဲအချိပ်', padaukBold, isHeader: true),
            _buildTableCell('အချိတ်အစွဲ', padaukBold, isHeader: true),
            _buildTableCell('အခြဲတ်ချိပ်', padaukBold, isHeader: true),
            _buildTableCell('အပ်န္တား\nချတ္နူး', padaukBold, isHeader: true),
            _buildTableCell('မေန်တ်', padaukBold, isHeader: true),
            _buildTableCell('ပွဲန်လိ\nမပ်ချိ', padaukBold, isHeader: true),
            _buildTableCell('က္န်မျိ', padaukBold, isHeader: true),
          ],
        ),

        // Item rows
        ...items.map((item) {
          return pw.TableRow(
            children: [
              _buildTableCell('${item.itemNumber}', padaukRegular),
              _buildTableCell(item.itemName, padaukRegular),
              _buildTableCell(item.sourceType, padaukRegular),
              _buildTableCell(item.weightDisplay, padaukRegular),
              _buildTableCell('${item.consignedQuantity.toStringAsFixed(2)}', padaukRegular),
              _buildTableCell('${item.soldQuantity.toStringAsFixed(2)}', padaukRegular),
              _buildTableCell('${item.returnedQuantity.toStringAsFixed(2)}', padaukRegular),
              _buildTableCell('${item.remainingQuantity.toStringAsFixed(2)}', padaukRegular),
            ],
          );
        }),

        // Totals row
        pw.TableRow(
          decoration: pw.BoxDecoration(color: PdfColors.grey200),
          children: [
            _buildTableCell('စျစျပဲအပ်း', padaukBold, isHeader: true),
            _buildTableCell('${totals.distinctItemCount} ပစ်စွဲ', padaukBold, isHeader: true),
            _buildTableCell('', padaukBold, isHeader: true),
            _buildTableCell(totals.totalWeightKg > 0 ? '${totals.totalWeightKg.toStringAsFixed(2)} ${totals.totalWeightUnit}' : '', padaukBold, isHeader: true),
            _buildTableCell('${totals.totalConsignedQuantity.toStringAsFixed(2)}', padaukBold, isHeader: true),
            _buildTableCell('${totals.totalSoldQuantity.toStringAsFixed(2)}', padaukBold, isHeader: true),
            _buildTableCell('${totals.totalReturnedQuantity.toStringAsFixed(2)}', padaukBold, isHeader: true),
            _buildTableCell('${totals.totalRemainingQuantity.toStringAsFixed(2)}', padaukBold, isHeader: true),
          ],
        ),
      ],
    );
  }

  /// Build a single table cell
  static pw.Widget _buildTableCell(
    String text,
    pw.Font padaukRegular, {
    bool isHeader = false,
  }) {
    return pw.Padding(
      padding: pw.EdgeInsets.all(4),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          font: padaukRegular,
          fontSize: isHeader ? 9 : 8,
          fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
        textAlign: isHeader ? pw.TextAlign.center : pw.TextAlign.center,
      ),
    );
  }

  /// Build footer with signatures and page number
  static pw.Widget _buildFooter(int pageNum, int totalPages, pw.Font padaukRegular, pw.Font padaukBold) {
    return pw.Column(
      children: [
        pw.SizedBox(height: 12),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.SizedBox(height: 20),
                pw.Text(
                  'ပွဲစား လက်မှတ်',
                  style: pw.TextStyle(
                    font: padaukRegular,
                    fontSize: 9,
                  ),
                ),
              ],
            ),
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                pw.SizedBox(height: 20),
                pw.Text(
                  'စာမျက်နှာ $pageNum / $totalPages',
                  style: pw.TextStyle(
                    font: padaukRegular,
                    fontSize: 9,
                  ),
                ),
              ],
            ),
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                pw.SizedBox(height: 20),
                pw.Text(
                  'ကုန်သည် လက်မှတ်',
                  style: pw.TextStyle(
                    font: padaukRegular,
                    fontSize: 9,
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }
}
