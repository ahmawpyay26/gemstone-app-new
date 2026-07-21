import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../local/models.dart';
import '../local/local_db.dart';

class VoucherExportService {
  static final VoucherExportService _instance = VoucherExportService._internal();

  VoucherExportService._internal();

  factory VoucherExportService() {
    return _instance;
  }

  static const double _margin = 20;

  /// Generate PDF voucher for a sale record
  Future<File?> generatePdfVoucher(Sale sale) async {
    try {
      // Load Padauk fonts
      final padaukRegular = await _loadPadaukFont('Regular');
      final padaukBold = await _loadPadaukFont('Bold');
      
      final pdf = pw.Document(
        theme: pw.ThemeData.withFont(
          base: padaukRegular,
          bold: padaukBold,
        ),
      );
      final moneyFormat = NumberFormat('#,##0', 'en_US');
      final dateFormat = DateFormat('yyyy-MM-dd HH:mm');

      final saleDate = DateTime.fromMillisecondsSinceEpoch(sale.saleDate);
      final createdDate = dateFormat.format(saleDate);

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(20),
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Header
                pw.Center(
                  child: pw.Text(
                    'ရောင်းချခြင်းလက်ခြင်း',
                    style: pw.TextStyle(
                      fontSize: 24,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.black,
                    ),
                  ),
                ),
                pw.SizedBox(height: 20),

                // Sale details table
                pw.Table(
                  border: pw.TableBorder.all(),
                  children: [
                    // Header row
                    pw.TableRow(
                      decoration: const pw.BoxDecoration(
                        color: PdfColors.grey300,
                      ),
                      children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text('အချက်အလက်',
                              style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.black)),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text('တန်ဖိုး',
                              style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.black)),
                        ),
                      ],
                    ),
                    // Data rows
                    pw.TableRow(
                      children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text('လက်ခြင်းနံပါတ်'),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text(sale.id),
                        ),
                      ],
                    ),
                    pw.TableRow(
                      children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text('ကျောက်အမည်'),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text(sale.gemstoneName),
                        ),
                      ],
                    ),
                    pw.TableRow(
                      children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text('ဝယ်သူအမည်'),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text(sale.customerName),
                        ),
                      ],
                    ),
                    pw.TableRow(
                      children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text('အရေအတွက်'),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text('${sale.quantity} ခု'),
                        ),
                      ],
                    ),
                    if (sale.weightCarat > 0)
                      pw.TableRow(
                        children: [
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(8),
                            child: pw.Text('အလေးချိန်'),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(8),
                            child: pw.Text(
                                '${_trim(sale.weightCarat)} ${_getWeightUnit(sale)}'),
                          ),
                        ],
                      ),
                    pw.TableRow(
                      children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text('ရောင်းရငွေ (စုစုပေါင်း)'),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text(
                              '${moneyFormat.format(sale.amount)} ကျပ်'),
                        ),
                      ],
                    ),
                    pw.TableRow(
                      children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text('ပွဲခ'),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text(
                              '${moneyFormat.format(sale.commissionFee)} ကျပ်'),
                        ),
                      ],
                    ),
                    pw.TableRow(
                      children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text('အသားတင်ငွေ'),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text(
                              '${moneyFormat.format(sale.netSale)} ကျပ်'),
                        ),
                      ],
                    ),
                    pw.TableRow(
                      children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text('ငွေပေးချေမှုနည်း'),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text(_paymentMethodLabel(sale.paymentMethod)),
                        ),
                      ],
                    ),
                    pw.TableRow(
                      children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text('ရက်စွဲ'),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text(createdDate),
                        ),
                      ],
                    ),
                  ],
                ),

                pw.SizedBox(height: 20),

                // Notes
                if (sale.note.isNotEmpty) ...[
                  pw.Text(
                    'မှတ်ချက်:',
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                  ),
                  pw.Text(sale.note),
                  pw.SizedBox(height: 20),
                ],

                // Footer
                pw.Divider(),
                pw.SizedBox(height: 10),
                pw.Center(
                  child: pw.Text(
                    'ဤလက်ခြင်းသည် အရောင်းအဆိုင်ကွန်ပျူတာစနစ်မှ ထုတ်ပြန်သည်။',
                    style: const pw.TextStyle(fontSize: 10),
                  ),
                ),
              ],
            );
          },
        ),
      );

      // Save PDF to file
      final Directory appDir = await getApplicationDocumentsDirectory();
      final String voucherDir = '${appDir.path}/vouchers';
      final Directory voucherDirObj = Directory(voucherDir);

      if (!await voucherDirObj.exists()) {
        await voucherDirObj.create(recursive: true);
      }

      final String fileName =
          'voucher_${sale.id}_${DateTime.now().millisecondsSinceEpoch}.pdf';
      final String filePath = '$voucherDir/$fileName';
      final File file = File(filePath);

      await file.writeAsBytes(await pdf.save());
      return file;
    } catch (e) {
      print('Error generating PDF voucher: $e');
      return null;
    }
  }

  /// Load Padauk font from assets
  /// [variant] can be 'Regular' or 'Bold'
  static Future<pw.Font> _loadPadaukFont(String variant) async {
    final fontPath = 'assets/fonts/Padauk-$variant.ttf';
    final fontData = await rootBundle.load(fontPath);
    return pw.Font.ttf(fontData);
  }

  String _getWeightUnit(Sale sale) {
    // Use Sale's weightUnit if available (whole-stone sales)
    if (sale.weightUnit != null && sale.weightUnit!.isNotEmpty) {
      return LocalDb.unitLabel(sale.weightUnit!);
    }
    // Fallback to fragment weight unit
    if (sale.fragmentWeightUnit != null && sale.fragmentWeightUnit!.isNotEmpty) {
      return LocalDb.unitLabel(sale.fragmentWeightUnit!);
    }
    // Default to kg
    return 'kg';
  }

  /// Print voucher
  Future<void> printVoucher(Sale sale) async {
    try {
      // Load Padauk fonts
      final padaukRegular = await _loadPadaukFont('Regular');
      final padaukBold = await _loadPadaukFont('Bold');
      
      final pdf = pw.Document(
        theme: pw.ThemeData.withFont(
          base: padaukRegular,
          bold: padaukBold,
        ),
      );
      final moneyFormat = NumberFormat('#,##0', 'en_US');
      final dateFormat = DateFormat('yyyy-MM-dd HH:mm');

      final saleDate = DateTime.fromMillisecondsSinceEpoch(sale.saleDate);
      final createdDate = dateFormat.format(saleDate);

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(20),
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Header
                pw.Center(
                  child: pw.Text(
                    'ရောင်းချခြင်းလက်ခြင်း',
                    style: pw.TextStyle(
                      fontSize: 24,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.black,
                    ),
                  ),
                ),
                pw.SizedBox(height: 20),

                // Sale details table
                pw.Table(
                  border: pw.TableBorder.all(),
                  children: [
                    // Header row
                    pw.TableRow(
                      decoration: const pw.BoxDecoration(
                        color: PdfColors.grey300,
                      ),
                      children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text('အချက်အလက်',
                              style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.black)),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text('တန်ဖိုး',
                              style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.black)),
                        ),
                      ],
                    ),
                    // Data rows
                    pw.TableRow(
                      children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text('လက်ခြင်းနံပါတ်'),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text(sale.id),
                        ),
                      ],
                    ),
                    pw.TableRow(
                      children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text('ကျောက်အမည်'),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text(sale.gemstoneName),
                        ),
                      ],
                    ),
                    pw.TableRow(
                      children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text('ဝယ်သူအမည်'),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text(sale.customerName),
                        ),
                      ],
                    ),
                    pw.TableRow(
                      children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text('အရေအတွက်'),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text('${sale.quantity} ခု'),
                        ),
                      ],
                    ),
                    if (sale.weightCarat > 0)
                      pw.TableRow(
                        children: [
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(8),
                            child: pw.Text('အလေးချိန်'),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(8),
                            child: pw.Text(
                                '${_trim(sale.weightCarat)} ${_getWeightUnit(sale)}'),
                          ),
                        ],
                      ),
                    pw.TableRow(
                      children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text('ရောင်းရငွေ (စုစုပေါင်း)'),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text(
                              '${moneyFormat.format(sale.amount)} ကျပ်'),
                        ),
                      ],
                    ),
                    pw.TableRow(
                      children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text('ပွဲခ'),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text(
                              '${moneyFormat.format(sale.commissionFee)} ကျပ်'),
                        ),
                      ],
                    ),
                    pw.TableRow(
                      children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text('အသားတင်ငွေ'),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text(
                              '${moneyFormat.format(sale.netSale)} ကျပ်'),
                        ),
                      ],
                    ),
                    pw.TableRow(
                      children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text('ငွေပေးချေမှုနည်း'),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text(_paymentMethodLabel(sale.paymentMethod)),
                        ),
                      ],
                    ),
                    pw.TableRow(
                      children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text('ရက်စွဲ'),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text(createdDate),
                        ),
                      ],
                    ),
                  ],
                ),

                pw.SizedBox(height: 20),

                // Notes
                if (sale.note.isNotEmpty) ...[
                  pw.Text(
                    'မှတ်ချက်:',
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                  ),
                  pw.Text(sale.note),
                  pw.SizedBox(height: 20),
                ],

                // Footer
                pw.Divider(),
                pw.SizedBox(height: 10),
                pw.Center(
                  child: pw.Text(
                    'ဤလက်ခြင်းသည် အရောင်းအဆိုင်ကွန်ပျူတာစနစ်မှ ထုတ်ပြန်သည်။',
                    style: const pw.TextStyle(fontSize: 10),
                  ),
                ),
              ],
            );
          },
        ),
      );

      await Printing.layoutPdf(
        onLayout: (_) => pdf.save(),
      );
    } catch (e) {
      print('Error printing voucher: $e');
    }
  }

  /// Generate PDF invoice for multiple sales (matching Broker Voucher design 1:1)
  Future<File?> generatePdfInvoice(List<Sale> sales) async {
    if (sales.isEmpty) return null;
    
    try {
      // Load Padauk fonts
      final padaukRegular = await _loadPadaukFont('Regular');
      final padaukBold = await _loadPadaukFont('Bold');
      
      final pdf = pw.Document(
        theme: pw.ThemeData.withFont(
          base: padaukRegular,
          bold: padaukBold,
        ),
      );
      
      final moneyFormat = NumberFormat('#,##0', 'en_US');
      final dateFormat = DateFormat('yyyy-MM-dd');
      
      // Get invoice details from first sale
      final firstSale = sales.first;
      final invoiceDate = DateTime.fromMillisecondsSinceEpoch(firstSale.saleDate);
      final createdDate = dateFormat.format(invoiceDate);
      
      // Calculate totals
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
      
      // Load business profile for logo
      final profile = LocalDb.getBusinessProfile();
      Uint8List? logoBytes;
      try {
        final rawPath = profile.logoPath;
        if (rawPath != null && rawPath.trim().isNotEmpty) {
          final logoFile = File(rawPath.trim());
          if (logoFile.existsSync()) {
            final bytes = await logoFile.readAsBytes();
            if (bytes.isNotEmpty) {
              logoBytes = bytes;
            }
          }
        }
      } catch (_) {
        logoBytes = null;
      }
      
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: pw.EdgeInsets.all(_margin),
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Header - matching Broker Voucher design
                _buildInvoiceHeader(
                  profile,
                  logoBytes,
                  padaukRegular,
                  padaukBold,
                ),
                pw.SizedBox(height: 12),
                
                // Invoice number and date row - matching Broker Voucher
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      'ဘောင်ချာ နံပါတ်: ${firstSale.invoiceNumber}',
                      style: pw.TextStyle(font: padaukRegular, fontSize: 11),
                    ),
                    pw.Text(
                      'ရက်စွဲ: $createdDate',
                      style: pw.TextStyle(font: padaukRegular, fontSize: 11),
                    ),
                  ],
                ),
                pw.SizedBox(height: 12),
                
                // Customer details box - matching Broker Info Box style
                pw.Container(
                  padding: pw.EdgeInsets.all(8),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.grey400),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'ဖောက်သည်အချက်အလက်',
                        style: pw.TextStyle(
                          font: padaukBold,
                          fontSize: 11,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.black,
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        'ကျောက်အမျိုးအစား: ${sales.map((s) => s.gemstoneName).toSet().join(", ")}',
                        style: pw.TextStyle(font: padaukRegular, fontSize: 10, color: PdfColors.black),
                      ),
                      pw.Text(
                        'အရေအတွက်: $totalQty',
                        style: pw.TextStyle(font: padaukRegular, fontSize: 10, color: PdfColors.black),
                      ),
                      pw.Text(
                        'ယူနစ်: kg',
                        style: pw.TextStyle(font: padaukRegular, fontSize: 10, color: PdfColors.black),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.Text(
                                'စုစုပေါင်းရောင်းချမှု',
                                style: pw.TextStyle(font: padaukRegular, fontSize: 9, color: PdfColors.black),
                              ),
                              pw.Text(
                                '${moneyFormat.format(totalAmount)} ကျပ်',
                                style: pw.TextStyle(font: padaukBold, fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColors.black),
                              ),
                            ],
                          ),
                          pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.Text(
                                'စုစုပေါင်းကော်မရှင်',
                                style: pw.TextStyle(font: padaukRegular, fontSize: 9, color: PdfColors.black),
                              ),
                              pw.Text(
                                '${moneyFormat.format(totalCommission)} ကျပ်',
                                style: pw.TextStyle(font: padaukRegular, fontSize: 9, color: PdfColors.black),
                              ),
                            ],
                          ),
                          pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.Text(
                                'စုစုပေါင်းကျန်ရှိ',
                                style: pw.TextStyle(font: padaukRegular, fontSize: 9, color: PdfColors.black),
                              ),
                              pw.Text(
                                '${moneyFormat.format(totalNet)} ကျပ်',
                                style: pw.TextStyle(font: padaukBold, fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColors.black),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                pw.SizedBox(height: 15),
                
                // Items table - matching Broker Voucher table design
                pw.Table(
                  border: pw.TableBorder.all(color: PdfColors.grey400),
                  columnWidths: {
                    0: pw.FixedColumnWidth(40),
                    1: pw.FixedColumnWidth(100),
                    2: pw.FixedColumnWidth(60),
                    3: pw.FixedColumnWidth(50),
                    4: pw.FixedColumnWidth(50),
                    5: pw.FixedColumnWidth(50),
                    6: pw.FixedColumnWidth(50),
                    7: pw.FixedColumnWidth(50),
                  },
                  children: [
                    // Header row
                    pw.TableRow(
                      decoration: pw.BoxDecoration(color: PdfColors.grey300),
                      children: [
                        _buildInvoiceTableCell('ល.ដ', padaukBold, isHeader: true),
                        _buildInvoiceTableCell('ပစ္စည်းအမည်', padaukBold, isHeader: true),
                        _buildInvoiceTableCell('အမျိုးအစား', padaukBold, isHeader: true),
                        _buildInvoiceTableCell('အလေးချိန်', padaukBold, isHeader: true),
                        _buildInvoiceTableCell('အရေအတွက်', padaukBold, isHeader: true),
                        _buildInvoiceTableCell('ယူနစ်ဈေး', padaukBold, isHeader: true),
                        _buildInvoiceTableCell('ကော်မရှင်', padaukBold, isHeader: true),
                        _buildInvoiceTableCell('စုစုပေါင်း', padaukBold, isHeader: true),
                      ],
                    ),
                    // Data rows
                    ...List<pw.TableRow>.generate(
                      sales.length,
                      (index) {
                        final sale = sales[index];
                        return pw.TableRow(
                          children: [
                            _buildInvoiceTableCell('${index + 1}', padaukRegular),
                            _buildInvoiceTableCell(sale.gemstoneName, padaukRegular),
                            _buildInvoiceTableCell('ကျောက်လုံး', padaukRegular),
                            _buildInvoiceTableCell('${sale.weightCarat} ${sale.weightUnit ?? 'kg'}', padaukRegular),
                            _buildInvoiceTableCell('${sale.quantity}', padaukRegular),
                            _buildInvoiceTableCell('${moneyFormat.format(sale.quantity > 0 ? sale.amount / sale.quantity : 0)}', padaukRegular),
                            _buildInvoiceTableCell('${moneyFormat.format(sale.commissionFee)}', padaukRegular),
                            _buildInvoiceTableCell('${moneyFormat.format(sale.amount)}', padaukRegular),
                          ],
                        );
                      },
                    ),
                    // Totals row
                    pw.TableRow(
                      decoration: pw.BoxDecoration(color: PdfColors.grey200),
                      children: [
                        _buildInvoiceTableCell('', padaukBold, isHeader: true),
                        _buildInvoiceTableCell('စုစုပေါင်း', padaukBold, isHeader: true),
                        _buildInvoiceTableCell('', padaukBold, isHeader: true),
                        _buildInvoiceTableCell('', padaukBold, isHeader: true),
                        _buildInvoiceTableCell('$totalQty', padaukBold, isHeader: true),
                        _buildInvoiceTableCell('', padaukBold, isHeader: true),
                        _buildInvoiceTableCell('${moneyFormat.format(totalCommission)}', padaukBold, isHeader: true),
                        _buildInvoiceTableCell('${moneyFormat.format(totalAmount)}', padaukBold, isHeader: true),
                      ],
                    ),
                  ],
                ),
                
                pw.SizedBox(height: 15),
                
                // Footer
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('ရေးထိုးသူ: __________', style: pw.TextStyle(font: padaukRegular, fontSize: 9)),
                    pw.Text('စာမျက်နှာ 1 / 1', style: pw.TextStyle(font: padaukRegular, fontSize: 9)),
                    pw.Text('ကုန်သည် လက်မှတ်: __________', style: pw.TextStyle(font: padaukRegular, fontSize: 9)),
                  ],
                ),
              ],
            );
          },
        ),
      );
      
      final tempDir = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final file = File('${tempDir.path}/invoice_${firstSale.invoiceNumber}_$timestamp.pdf');
      await file.writeAsBytes(await pdf.save());
      return file;
    } catch (e) {
      print('Error generating PDF invoice: $e');
      return null;
    }
  }

  /// Build invoice header section (matching Broker Voucher)
  static pw.Widget _buildInvoiceHeader(
    dynamic profile,
    Uint8List? logoBytes,
    pw.Font padaukRegular,
    pw.Font padaukBold,
  ) {
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
        logoWidget = null;
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
          'ရောင်းချမှုဘောင်ချာ',
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
      ],
    );

    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        if (logoWidget != null) ...[logoWidget, pw.SizedBox(width: 10)],
        pw.Expanded(child: infoColumn),
      ],
    );
  }

  /// Build a single invoice table cell (matching Broker Voucher)
  static pw.Widget _buildInvoiceTableCell(
    String text,
    pw.Font font, {
    bool isHeader = false,
  }) {
    return pw.Padding(
      padding: pw.EdgeInsets.all(4),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          font: font,
          fontSize: isHeader ? 9 : 8,
          fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
          color: PdfColors.black,
        ),
        textAlign: pw.TextAlign.center,
      ),
    );
  }

  String _trim(double value) {
    final trimmed = value.toStringAsFixed(2);
    return trimmed.replaceAll(RegExp(r'\.?0+$'), '');
  }

  String _paymentMethodLabel(String method) {
    switch (method) {
      case 'cash':
        return 'ငွေသည်း';
      case 'bank_transfer':
        return 'ဘဏ်လွှဲပြောင်း';
      case 'check':
        return 'ချက်';
      default:
        return method;
    }
  }
}
