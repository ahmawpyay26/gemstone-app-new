import 'dart:io';
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
                              style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text('တန်ဖိုး',
                              style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
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
                pw.Center(
                  child: pw.Text(
                    'ရောင်းချခြင်းလက်ခြင်း',
                    style: pw.TextStyle(
                      fontSize: 24,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ),
                pw.SizedBox(height: 20),
                pw.Table(
                  border: pw.TableBorder.all(),
                  children: [
                    pw.TableRow(
                      decoration: const pw.BoxDecoration(
                        color: PdfColors.grey300,
                      ),
                      children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text('အချက်အလက်',
                              style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text('တန်ဖိုး',
                              style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                        ),
                      ],
                    ),
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

  String _paymentMethodLabel(String method) {
    switch (method) {
      case 'cash':
        return 'ငွေသည်း';
      case 'bank':
        return 'ဘဏ်';
      case 'credit':
        return 'အကြေးခံ';
      default:
        return method;
    }
  }

  String _trim(double v) =>
      v == v.roundToDouble() ? v.toInt().toString() : v.toString();

  /// Generate PDF invoice for multiple sales (grouped by invoice number)
  /// Generate PDF invoice for multiple sales (grouped by invoice number)
  /// Generate invoice as PDF (matching Broker Voucher design)
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
      
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(20),
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Header - matching Broker Voucher design
                pw.Center(
                  child: pw.Column(
                    children: [
                      pw.Text(
                        'ပွဲစားထံမှ ရောင်းချမှု',
                        style: pw.TextStyle(
                          font: padaukBold,
                          fontSize: 18,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.Text(
                        'ပွဲစားထံမှ ရောင်းချမှု',
                        style: pw.TextStyle(
                          font: padaukBold,
                          fontSize: 14,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                pw.SizedBox(height: 12),
                
                // Invoice number and date row - matching Broker Voucher
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      'ဘောင်ချာ အုပ်စုံ: ${firstSale.invoiceNumber}',
                      style: pw.TextStyle(font: padaukRegular, fontSize: 11),
                    ),
                    pw.Text(
                      'မပ်စွဲ: $createdDate',
                      style: pw.TextStyle(font: padaukRegular, fontSize: 11),
                    ),
                  ],
                ),
                pw.SizedBox(height: 12),
                
                // Customer details box - matching Broker Info Box style
                pw.Container(
                  padding: const pw.EdgeInsets.all(8),
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
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        'ကျောက်အမျိုးအစား: ${sales.map((s) => s.gemstoneType).toSet().join(", ")}',
                        style: pw.TextStyle(font: padaukRegular, fontSize: 10),
                      ),
                      pw.Text(
                        'အရေအတွက်: $totalQty',
                        style: pw.TextStyle(font: padaukRegular, fontSize: 10),
                      ),
                      pw.Text(
                        'ယူနစ်: kg',
                        style: pw.TextStyle(font: padaukRegular, fontSize: 10),
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
                                style: pw.TextStyle(font: padaukRegular, fontSize: 9),
                              ),
                              pw.Text(
                                '${moneyFormat.format(totalAmount)} ကျပ်',
                                style: pw.TextStyle(font: padaukBold, fontSize: 9, fontWeight: pw.FontWeight.bold),
                              ),
                            ],
                          ),
                          pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.Text(
                                'စုစုပေါင်းကော်မရှင်',
                                style: pw.TextStyle(font: padaukRegular, fontSize: 9),
                              ),
                              pw.Text(
                                '${moneyFormat.format(totalCommission)} ကျပ်',
                                style: pw.TextStyle(font: padaukRegular, fontSize: 9),
                              ),
                            ],
                          ),
                          pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.Text(
                                'စုစုပေါင်းကျန်ရှိ',
                                style: pw.TextStyle(font: padaukRegular, fontSize: 9),
                              ),
                              pw.Text(
                                '${moneyFormat.format(totalNet)} ကျပ်',
                                style: pw.TextStyle(font: padaukBold, fontSize: 9, fontWeight: pw.FontWeight.bold),
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
                    0: pw.FixedColumnWidth(25),
                    1: pw.FixedColumnWidth(80),
                    2: pw.FixedColumnWidth(50),
                    3: pw.FixedColumnWidth(40),
                    4: pw.FixedColumnWidth(45),
                    5: pw.FixedColumnWidth(40),
                    6: pw.FixedColumnWidth(40),
                    7: pw.FixedColumnWidth(40),
                  },
                  children: [
                    // Header row
                    pw.TableRow(
                      decoration: pw.BoxDecoration(color: PdfColors.grey300),
                      children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(4),
                          child: pw.Text('ល.ដ', style: pw.TextStyle(font: padaukBold, fontSize: 9, fontWeight: pw.FontWeight.bold)),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(4),
                          child: pw.Text('ပစ္စည်းအမည်', style: pw.TextStyle(font: padaukBold, fontSize: 9, fontWeight: pw.FontWeight.bold)),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(4),
                          child: pw.Text('အမျိုးအစား', style: pw.TextStyle(font: padaukBold, fontSize: 9, fontWeight: pw.FontWeight.bold)),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(4),
                          child: pw.Text('အလေးချိန်', style: pw.TextStyle(font: padaukBold, fontSize: 9, fontWeight: pw.FontWeight.bold)),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(4),
                          child: pw.Text('အရေအတွက်', style: pw.TextStyle(font: padaukBold, fontSize: 9, fontWeight: pw.FontWeight.bold)),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(4),
                          child: pw.Text('ယူနစ်ဈေး', style: pw.TextStyle(font: padaukBold, fontSize: 9, fontWeight: pw.FontWeight.bold)),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(4),
                          child: pw.Text('ကော်မရှင်', style: pw.TextStyle(font: padaukBold, fontSize: 9, fontWeight: pw.FontWeight.bold)),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(4),
                          child: pw.Text('စုစုပေါင်း', style: pw.TextStyle(font: padaukBold, fontSize: 9, fontWeight: pw.FontWeight.bold)),
                        ),
                      ],
                    ),
                    // Data rows
                    ...List<pw.TableRow>.generate(
                      sales.length,
                      (index) {
                        final sale = sales[index];
                        return pw.TableRow(
                          children: [
                            pw.Padding(
                              padding: const pw.EdgeInsets.all(4),
                              child: pw.Text('${index + 1}', style: pw.TextStyle(font: padaukRegular, fontSize: 9)),
                            ),
                            pw.Padding(
                              padding: const pw.EdgeInsets.all(4),
                              child: pw.Text(sale.gemstoneType, style: pw.TextStyle(font: padaukRegular, fontSize: 9)),
                            ),
                            pw.Padding(
                              padding: const pw.EdgeInsets.all(4),
                              child: pw.Text(sale.stoneType, style: pw.TextStyle(font: padaukRegular, fontSize: 9)),
                            ),
                            pw.Padding(
                              padding: const pw.EdgeInsets.all(4),
                              child: pw.Text('${sale.weightCarat} ${sale.weightUnit ?? 'kg'}', style: pw.TextStyle(font: padaukRegular, fontSize: 9)),
                            ),
                            pw.Padding(
                              padding: const pw.EdgeInsets.all(4),
                              child: pw.Text('${sale.quantity}', style: pw.TextStyle(font: padaukRegular, fontSize: 9)),
                            ),
                            pw.Padding(
                              padding: const pw.EdgeInsets.all(4),
                              child: pw.Text('${moneyFormat.format(sale.quantity > 0 ? sale.amount / sale.quantity : 0)}', style: pw.TextStyle(font: padaukRegular, fontSize: 9)),
                            ),
                            pw.Padding(
                              padding: const pw.EdgeInsets.all(4),
                              child: pw.Text('${moneyFormat.format(sale.commissionFee)}', style: pw.TextStyle(font: padaukRegular, fontSize: 9)),
                            ),
                            pw.Padding(
                              padding: const pw.EdgeInsets.all(4),
                              child: pw.Text('${moneyFormat.format(sale.amount)}', style: pw.TextStyle(font: padaukRegular, fontSize: 9)),
                            ),
                          ],
                        );
                      },
                    ),
                    // Totals row
                    pw.TableRow(
                      decoration: pw.BoxDecoration(color: PdfColors.grey200),
                      children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(4),
                          child: pw.Text('', style: pw.TextStyle(font: padaukBold, fontSize: 9)),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(4),
                          child: pw.Text('စုစုပေါင်း', style: pw.TextStyle(font: padaukBold, fontSize: 9, fontWeight: pw.FontWeight.bold)),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(4),
                          child: pw.Text('', style: pw.TextStyle(font: padaukRegular, fontSize: 9)),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(4),
                          child: pw.Text('', style: pw.TextStyle(font: padaukRegular, fontSize: 9)),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(4),
                          child: pw.Text('$totalQty', style: pw.TextStyle(font: padaukBold, fontSize: 9, fontWeight: pw.FontWeight.bold)),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(4),
                          child: pw.Text('', style: pw.TextStyle(font: padaukRegular, fontSize: 9)),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(4),
                          child: pw.Text('${moneyFormat.format(totalCommission)}', style: pw.TextStyle(font: padaukBold, fontSize: 9, fontWeight: pw.FontWeight.bold)),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(4),
                          child: pw.Text('${moneyFormat.format(totalAmount)}', style: pw.TextStyle(font: padaukBold, fontSize: 9, fontWeight: pw.FontWeight.bold)),
                        ),
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
                    pw.Text('နေ့စွဲ: __________', style: pw.TextStyle(font: padaukRegular, fontSize: 9)),
                  ],
                ),
                pw.SizedBox(height: 5),
                pw.Center(
                  child: pw.Text('စာမျက်နှာ 1 / 1', style: pw.TextStyle(font: padaukRegular, fontSize: 9)),
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


  /// Generate invoice as PNG image
  Future<File?> generateInvoiceImage(List<Sale> sales) async {
    if (sales.isEmpty) return null;
    
    try {
      // First generate the PDF
      final pdfFile = await generatePdfInvoice(sales);
      if (pdfFile == null) return null;
      
      // Convert PDF to image using printing package
      final pdfBytes = await pdfFile.readAsBytes();
      final firstSale = sales.first;
      
      // Use printing package to render PDF to image
      // Printing.raster() returns a Stream<PdfRaster>
      final rasterPages = await Printing.raster(
        pdfBytes,
        pages: const [0], // First page only
        dpi: 200,
      ).toList();
      
      if (rasterPages.isEmpty) {
        throw Exception('Invoice image generation failed');
      }
      
      // Get the first page and convert to PNG bytes
      final pngBytes = await rasterPages.first.toPng();
      
      // Create safe filename (replace special characters)
      final safeInvoiceNo = firstSale.invoiceNumber
          .replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
      
      // Save as PNG
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/invoice_$safeInvoiceNo.png');
      await file.writeAsBytes(pngBytes, flush: true);
      
      return file;
    } catch (e) {
      print('Error generating invoice image: $e');
      return null;
    }
  }
}
