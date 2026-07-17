import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../models/broker_voucher_document.dart';

/// Generates multi-page PDF bytes for broker vouchers with Myanmar text support
class BrokerVoucherPdfGenerator {
  static const String _fontFamily = 'Padauk';
  static const double _pageWidth = PdfPageFormat.a4.width;
  static const double _pageHeight = PdfPageFormat.a4.height;
  static const double _margin = 20;
  static const double _contentWidth = _pageWidth - (2 * _margin);
  static const double _itemsPerPage = 15;

  /// Generate PDF bytes from voucher document data
  static Future<Uint8List> generatePdf(
    BrokerVoucherDocumentData data,
  ) async {
    final pdf = pw.Document();

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
                _buildHeader(data),
                pw.SizedBox(height: 12),

                // Broker Information
                _buildBrokerInfo(data),
                pw.SizedBox(height: 12),

                // Items Table
                _buildItemsTable(pageItems, data.totals),

                // Page break space
                pw.Spacer(),

                // Footer with page number
                _buildFooter(pageNum + 1, totalPages),
              ],
            );
          },
        ),
      );
    }

    return pdf.save();
  }

  /// Build header section with app name and voucher title
  static pw.Widget _buildHeader(BrokerVoucherDocumentData data) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        // App/Business name
        pw.Text(
          'အတ္တကြ မြန်မာ ကျောက်မျ',
          style: pw.TextStyle(
            font: pw.Font.helvetica(),
            fontSize: 18,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        pw.SizedBox(height: 4),

        // Voucher title
        pw.Text(
          'ပွဲစားအပ်နှံဘောင်ချာ',
          style: pw.TextStyle(
            fontFamily: _fontFamily,
            fontSize: 16,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        pw.SizedBox(height: 8),

        // Voucher number and date
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              'ဘောင်ချာ နံပါတ်: ${data.voucherNumber}',
              style: pw.TextStyle(
                fontFamily: _fontFamily,
                fontSize: 11,
              ),
            ),
            pw.Text(
              'ရက်စွဲ: ${data.formattedDate}',
              style: pw.TextStyle(
                fontFamily: _fontFamily,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Build broker information section
  static pw.Widget _buildBrokerInfo(BrokerVoucherDocumentData data) {
    return pw.Container(
      padding: pw.EdgeInsets.all(8),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey400),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'ပွဲစားအချက်အလက်',
            style: pw.TextStyle(
              fontFamily: _fontFamily,
              fontSize: 11,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            'နာမည်: ${data.brokerName}',
            style: pw.TextStyle(
              fontFamily: _fontFamily,
              fontSize: 10,
            ),
          ),
          pw.Text(
            'ဖုန်း: ${data.brokerPhone}',
            style: pw.TextStyle(
              fontFamily: _fontFamily,
              fontSize: 10,
            ),
          ),
          if (data.brokerAddress != null && data.brokerAddress!.isNotEmpty)
            pw.Text(
              'လိပ်စာ: ${data.brokerAddress}',
              style: pw.TextStyle(
                fontFamily: _fontFamily,
                fontSize: 10,
              ),
            ),
          if (data.notes != null && data.notes!.isNotEmpty)
            pw.Text(
              'မှတ်ချက်: ${data.notes}',
              style: pw.TextStyle(
                fontFamily: _fontFamily,
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
            _buildTableCell('စဉ်', isHeader: true),
            _buildTableCell('ပစ္စည်းအမည်', isHeader: true),
            _buildTableCell('အမျိုးအစား', isHeader: true),
            _buildTableCell('အလေးချိန်', isHeader: true),
            _buildTableCell('အပ်ထားသည့်\nခုနှုန်း', isHeader: true),
            _buildTableCell('ရောင်းချ', isHeader: true),
            _buildTableCell('ပြန်လည်\nရယူ', isHeader: true),
            _buildTableCell('ကျန်ရှိ', isHeader: true),
          ],
        ),

        // Item rows
        ...items.map((item) {
          return pw.TableRow(
            children: [
              _buildTableCell('${item.itemNumber}'),
              _buildTableCell(item.itemName),
              _buildTableCell(item.sourceType),
              _buildTableCell('${item.weight} ${item.weightUnit}'),
              _buildTableCell('${item.consignedQuantity.toStringAsFixed(2)}'),
              _buildTableCell('${item.soldQuantity.toStringAsFixed(2)}'),
              _buildTableCell('${item.returnedQuantity.toStringAsFixed(2)}'),
              _buildTableCell('${item.remainingQuantity.toStringAsFixed(2)}'),
            ],
          );
        }),

        // Totals row
        pw.TableRow(
          decoration: pw.BoxDecoration(color: PdfColors.grey200),
          children: [
            _buildTableCell('စုစုပေါင်း', isHeader: true),
            _buildTableCell('${totals.distinctItemCount} ပစ္စည်း', isHeader: true),
            _buildTableCell('', isHeader: true),
            _buildTableCell('', isHeader: true),
            _buildTableCell('${totals.totalConsignedQuantity.toStringAsFixed(2)}', isHeader: true),
            _buildTableCell('${totals.totalSoldQuantity.toStringAsFixed(2)}', isHeader: true),
            _buildTableCell('${totals.totalReturnedQuantity.toStringAsFixed(2)}', isHeader: true),
            _buildTableCell('${totals.totalRemainingQuantity.toStringAsFixed(2)}', isHeader: true),
          ],
        ),
      ],
    );
  }

  /// Build a single table cell
  static pw.Widget _buildTableCell(
    String text, {
    bool isHeader = false,
  }) {
    return pw.Padding(
      padding: pw.EdgeInsets.all(4),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontFamily: _fontFamily,
          fontSize: isHeader ? 9 : 8,
          fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
        textAlign: isHeader ? pw.TextAlign.center : pw.TextAlign.center,
      ),
    );
  }

  /// Build footer with signatures and page number
  static pw.Widget _buildFooter(int pageNum, int totalPages) {
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
                    fontFamily: _fontFamily,
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
                    fontFamily: _fontFamily,
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
                    fontFamily: _fontFamily,
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
