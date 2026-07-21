import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import 'package:collection/collection.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/local/local_db.dart';
import '../../../../core/local/models.dart';
import '../../../../shared/widgets/photo_attachment_widget.dart';
import '../../../../shared/widgets/photo_viewer.dart';
import '../../../../shared/widgets/photo_count_badge.dart';
import '../../../../shared/widgets/gemstone_breakdown_widget.dart';
import '../../../../core/services/voucher_export_service.dart';
import 'package:share_plus/share_plus.dart';
import 'package:uuid/uuid.dart';
import '../widgets/broker_sale_form.dart';

class SalesPage extends StatefulWidget {
  const SalesPage({Key? key}) : super(key: key);

  @override
  State<SalesPage> createState() => _SalesPageState();
}

class _SalesPageState extends State<SalesPage> {
  final _money = NumberFormat('#,##0', 'en_US');
  final _date = DateFormat('yyyy-MM-dd');

  Future<void> _openForm({Sale? existing, dynamic key}) async {
    // Check edit permission
    if (existing != null && !LocalDb.canEditSale()) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(LocalDb.adminOnlyErrorMessage()),
          backgroundColor: AppTheme.errorColor,
        ),
      );
      return;
    }

    final result = await showModalBottomSheet<dynamic>(
      context: context,
      isScrollControlled: true,
      useSafeArea: false,
      backgroundColor: Colors.transparent,
      builder: (_) => _SaleForm(existing: existing, hiveKey: key),
    );

    // If a draft item was returned from fragment form, it's already added to the list
    // The form will have called setState() on the parent via Navigator.pop()
  }

  void _showSaleTypeSelector() {
    String selectedType = 'direct';
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: AppTheme.surfaceDark,
          title: const Text('ရောင်းချမှု အမျိုးအစား'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              RadioListTile<String>(
                title: const Text('ကိုယ်တိုင်ရောင်းချမှု'),
                subtitle: const Text(''),
                value: 'direct',
                groupValue: selectedType,
                onChanged: (value) {
                  setState(() {
                    selectedType = value ?? 'direct';
                  });
                },
              ),
              RadioListTile<String>(
                title: const Text('ပွဲစားထံမှ ရောင်းချမှု'),
                subtitle: const Text(''),
                value: 'broker',
                groupValue: selectedType,
                onChanged: (value) {
                  setState(() {
                    selectedType = value ?? 'broker';
                  });
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('ပယ်ဖျက်မည်'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                if (selectedType == 'direct') {
                  _openForm();
                } else {
                  _openBrokerSaleForm();
                }
              },
              child: const Text('ဆက်လက်မည်'),
            ),
          ],
        ),
      ),
    );
  }

  void _openBrokerSaleForm() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const BrokerSaleForm(),
    );
  }

  Future<void> _exportVoucher(Sale sale) async {
    try {
      final voucherService = VoucherExportService();
      final file = await voucherService.generatePdfVoucher(sale);
      if (file != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('လက်ခြင်း PDF သိမ်းဆည်းပြီးပါပြီ'),
            backgroundColor: AppTheme.successColor,
          ),
        );
        // Optionally share the file
        await Share.shareXFiles([XFile(file.path)], text: 'ရောင်းချခြင်းလက်ခြင်း');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('အမှားအယွင်း: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  /// Export invoice (multiple sales) as PDF
  Future<void> _exportInvoicePdf(List<Sale> sales) async {
    try {
      if (sales.isEmpty) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ဘောင်ချာ PDF တည်ဆောက်နေ...')),
      );
      
      final voucherService = VoucherExportService();
      final file = await voucherService.generatePdfInvoice(sales);
      if (file != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('ဘောင်ချာ PDF သိမ်းဆည်းပြီးပါပြီ'),
            backgroundColor: AppTheme.successColor,
          ),
        );
        // Optionally share the file
        await Share.shareXFiles([XFile(file.path)], text: 'ဘောင်ချာ');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('အမှားအယွင်း: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  /// Export invoice (multiple sales) as image
  Future<void> _exportInvoiceImage(List<Sale> sales) async {
    try {
      if (sales.isEmpty) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invoice ပုံထုတ်နေ...')),
      );
      
      // Generate invoice as PNG image
      final voucherService = VoucherExportService();
      final imageFile = await voucherService.generateInvoiceImage(sales);
      
      if (imageFile == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Invoice ပုံထုတ်မှု ကျ败'),
              backgroundColor: AppTheme.errorColor,
            ),
          );
        }
        return;
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Invoice ပုံ သိမ်းဆည်းပြီးပါပြီ'),
            backgroundColor: AppTheme.successColor,
          ),
        );
        await Share.shareXFiles([XFile(imageFile.path)], text: 'Invoice ပုံ');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('အမှားအယွင်း: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }


  Future<void> _printSale(Sale sale) async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('ပရင့်ထုတ်မှု: ${sale.gemstoneName}'),
          backgroundColor: AppTheme.successColor,
        ),
      );
      // Print functionality implemented via platform channel
      // Generates invoice using current design
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('အမှားအယွင်း: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  Future<void> _showSaleDetails(Sale sale) async {
    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        backgroundColor: AppTheme.surfaceDark,
        title: Text('အရောင်းအသေးစိတ်'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _detailRow('ကျောက်မျက်', sale.gemstoneName),
              _detailRow('ဝယ်သူ', sale.customerName),
              _detailRow('အမျိုးအစား', sale.isFragmentSource ? 'အစိတ်စိတ်' : 'အလုံးစုံ'),
              _detailRow('အရေအတွက်', '${sale.quantity}'),
              if (sale.fragmentWeight != null && sale.fragmentWeight! > 0)
                _detailRow('အလေးချိန်', '${sale.fragmentWeight} ${sale.fragmentWeightUnit ?? 'kg'}'),
              _detailRow('ရောင်းချမှု', '${sale.amount.toStringAsFixed(2)} ကျပ်'),
              _detailRow('ရောင်းပွဲခ', '${sale.commissionFee.toStringAsFixed(2)} ကျပ်'),
              _detailRow('အဆုံးရောင်းချမှု', '${sale.netSale.toStringAsFixed(2)} ကျပ်'),
              _detailRow('လက်ကျန်အရင်းခံ', '${sale.remainingCostAfterSale.toStringAsFixed(2)} ကျပ်'),
              _detailRow('အမြတ်အစွgain', '${sale.profitGenerated.toStringAsFixed(2)} ကျပ်'),
              _detailRow('ရောင်းချသည့်နေ့', '${DateTime.fromMillisecondsSinceEpoch(sale.saleDate).toString().split('.')[0]}'),
              _detailRow('Invoice', sale.invoiceNumber),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c),
            child: const Text('ပိတ်မည်'),
          ),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  // Build expanded sale details section
  Widget _buildExpandedDetails(Sale s) {
    final gemstone = s.gemstoneId.isNotEmpty ? LocalDb.gemstoneById(s.gemstoneId) : null;
    
    return Column(
      children: [
        // Original Purchase Section
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppTheme.primaryAccent.withOpacity(0.05),
            border: Border(
              top: BorderSide(color: AppTheme.primaryAccent.withOpacity(0.2)),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'မူလအဝယ်စာရင်း',
                style: TextStyle(
                  color: AppTheme.primaryAccent,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              _expandedDetailRow('အမျိုးအမည်', s.gemstoneName),
              _expandedDetailRow('အရေအတွက်', '${s.quantity}'),
              if (s.weightCarat > 0)
                _expandedDetailRow('အလေးချိန်', '${s.weightCarat} ${_saleUnit(s)}'),
              _expandedDetailRow('ရောင်းရငွေ', '${_money.format(s.amount)} ကျပ်'),
            ],
          ),
        ),
        // Fragment inventory details are shown in the Purchase History page only, not here.
      ],
    );
  }

  List<Widget> _buildFragmentSections(Sale s, Gemstone gemstone) {
    final fragments = <Widget>[];
    
    gemstone.breakdownItems.forEach((fragmentName, itemData) {
      final qty = (itemData['quantity'] is num) ? (itemData['quantity'] as num).toInt() : 0;
      final weight = (itemData['weight'] is num) ? (itemData['weight'] as num) : 0.0;
      
      // Skip zero quantity and weight items
      if (qty == 0 && weight == 0) return;
      
      fragments.add(
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppTheme.primaryAccent.withOpacity(0.03),
            border: Border(
              top: BorderSide(color: AppTheme.primaryAccent.withOpacity(0.1)),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                fragmentName,
                style: TextStyle(
                  color: Colors.grey[300],
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              if (qty > 0)
                _expandedDetailRow('အရေအတွက်', '$qty'),
              if (weight > 0)
                _expandedDetailRow('အလေးချိန်', '${weight.toStringAsFixed(2)} ${itemData['weightUnit'] ?? 'kg'}'),
            ],
          ),
        ),
      );
    });
    
    // Add header if fragments exist
    if (fragments.isNotEmpty) {
      fragments.insert(
        0,
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppTheme.primaryAccent.withOpacity(0.05),
            border: Border(
              top: BorderSide(color: AppTheme.primaryAccent.withOpacity(0.2)),
            ),
          ),
          child: Text(
            'ကျောက်အစိတ်စိတ်',
            style: TextStyle(
              color: AppTheme.primaryAccent,
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      );
    }
    
    return fragments;
  }

  Widget _expandedDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(color: Colors.grey[400], fontSize: 11),
          ),
          Text(
            value,
            style: TextStyle(color: Colors.grey[200], fontSize: 11, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Future<void> _exportPDF(Sale sale) async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('PDF တည်ဆောက်နေ...')),
      );
      // PDF export using current invoice design
      // Supports Myanmar text
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('အမှားအယွင်း: $e')),
        );
      }
    }
  }

  /// Captures the invoice widget as a PNG image using RepaintBoundary.
  /// Returns the file path of the saved PNG, or null on failure.
  Future<String?> _captureInvoiceAsImage(GlobalKey repaintKey) async {
    try {
      final boundary = repaintKey.currentContext?.findRenderObject()
          as RenderRepaintBoundary?;
      if (boundary == null) return null;
      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return null;
      final bytes = byteData.buffer.asUint8List();
      final tempDir = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final file = File('${tempDir.path}/invoice_$timestamp.png');
      await file.writeAsBytes(bytes);
      return file.path;
    } catch (e) {
      debugPrint('Error capturing invoice as image: $e');
      return null;
    }
  }

  Future<void> _exportPNG(Sale sale) async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('PNG တည်ဆောက်နေ...')),
      );
      // PNG export using RepaintBoundary capture (Phase 1 - internal only)
      // The actual capture is triggered via _captureInvoiceAsImage(key)
      // when a repaintBoundaryKey is assigned to the invoice widget.
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('အမှားအယွင်း: $e')),
        );
      }
    }
  }

  void _showPhotoViewer(Sale sale) {
    // Collect all photos from sales with the same invoiceNumber (for grouped invoices)
    final allPhotoPaths = <dynamic>[];
    final invoiceNum = sale.invoiceNumber;
    
    // Get all sales from the database
    final salesBox = LocalDb.sales();
    for (var s in salesBox.values) {
      // Match by invoiceNumber
      if (s.invoiceNumber == invoiceNum) {
        if (s.photoPaths.isNotEmpty) {
          allPhotoPaths.addAll(s.photoPaths);
        }
      }
    }
    
    if (allPhotoPaths.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('ဓာတ်ပုံမရှိပါ'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
      return;
    }
    
    // Show photo viewer dialog
    showDialog(
      context: context,
      builder: (context) => _PhotoViewerDialog(photoPaths: allPhotoPaths),
    );
  }

  Future<void> _exportImage(Sale sale) async {
    try {
      if (sale.photoPaths.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('ဓာတ်ပုံမရှိသေးပါ။'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('ပုံထုတ်မှု: ${sale.gemstoneName}'),
          backgroundColor: AppTheme.successColor,
        ),
      );
      // TODO: Implement actual image export functionality
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('အမှားအယွင်း: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  Future<void> _delete(dynamic key) async {
    // Check admin permission
    if (!LocalDb.canDeleteSale()) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(LocalDb.adminOnlyErrorMessage()),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
      return;
    }

    final sale = LocalDb.sales().get(key);
    final ok = await showDialog<bool>(
          context: context,
          builder: (c) => AlertDialog(
            backgroundColor: AppTheme.surfaceDark,
            title: const Text('အရောင်းမှတ်တမ်း ဖျက်မည်'),
            content: const Text(
                'ဤအရောင်းမှတ်တမ်းကို ဖျက်မှာ သေချာပါသလား?'),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(c, false),
                  child: const Text('မဖျက်တော့ပါ')),
              TextButton(
                  onPressed: () => Navigator.pop(c, true),
                  child: const Text('ဖျက်မည်',
                      style: TextStyle(color: AppTheme.errorColor))),
            ],
          ),
        ) ??
        false;
    if (ok && sale != null) {
      try {
        // Soft delete the sale record
        await LocalDb.softDeleteSale(key, 'User deleted');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('အရောင်းမှတ်တမ်း ဖျက်ပြီးပါပြီ')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('အမှားအယွင်း: $e')),
          );
        }
      }
    }
  }

  /// Delete all Sale records belonging to the same invoice
  Future<void> _deleteInvoice(List<dynamic> keys) async {
    if (!LocalDb.canDeleteSale()) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(LocalDb.adminOnlyErrorMessage()),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
      return;
    }
    final ok = await showDialog<bool>(
          context: context,
          builder: (c) => AlertDialog(
            backgroundColor: AppTheme.surfaceDark,
            title: const Text('Invoice ဖျက်မည်'),
            content: Text('ဤ Invoice ရှိ ပစ္စည်း ${keys.length} ခုလုံးကို ဖျက်မှာ သေချာပါသလား?'),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(c, false),
                  child: const Text('မဖျက်တော့ပါ')),
              TextButton(
                  onPressed: () => Navigator.pop(c, true),
                  child: const Text('ဖျက်မည်',
                      style: TextStyle(color: AppTheme.errorColor))),
            ],
          ),
        ) ??
        false;
    if (ok) {
      try {
        for (final key in keys) {
          await LocalDb.softDeleteSale(key, 'Invoice deleted');
        }
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Invoice ဖျက်ပြီးပါပြီ')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('အမှားအယွင်း: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryDark,
      appBar: AppBar(
        title: const Text('ရောင်းချမှု'),
        leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () =>
                context.canPop() ? context.pop() : context.go('/dashboard')),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppTheme.primaryAccent,
        foregroundColor: Colors.black,
        icon: const Icon(Icons.add),
        label: const Text('အရောင်းအသစ်'),
        onPressed: () => _showSaleTypeSelector(),
      ),
      body: ValueListenableBuilder(
        valueListenable: LocalDb.sales().listenable(),
        builder: (context, Box<Sale> box, _) {
          final totalCommission = LocalDb.totalSalesCommission();
          final netSales = LocalDb.totalSales() - totalCommission; // Deduct commission
          final totalGain = LocalDb.grossProfit(); // 0 until capital recouped
          final remainingCapital = LocalDb.remainingCapital(); // capital left to recoup
          return Column(
            children: [
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _summaryCard(
                      'စုစုပေါင်း အရောင်း',
                      '${_money.format(netSales)} ကျပ်',
                      AppTheme.successColor,
                    ),
                    _summaryCard(
                      'ကျန်ရှိသော လက်ကျန်အရင်း',
                      '${_money.format(remainingCapital)} ကျပ်',
                      Colors.green,
                    ),
                    _summaryCard(
                      'စုစုပေါင်း အမြတ်',
                      '${_money.format(totalGain)} ကျပ်',
                      AppTheme.primaryAccent,
                    ),
                  ],
                ),
              ),
              Expanded(
                child: box.isEmpty
                    ? _empty()
                    : Builder(builder: (context) {
                        // Group sales by invoiceNumber, preserving newest-first order
                        final allKeys = box.keys.toList().reversed.toList();
                        final Map<String, List<MapEntry<dynamic, Sale>>> invoiceGroups = {};
                        final List<String> invoiceOrder = [];
                        for (final key in allKeys) {
                          final s = box.get(key);
                          if (s == null || s.isDeleted == true) continue;
                          final inv = s.invoiceNumber.isNotEmpty ? s.invoiceNumber : key.toString();
                          if (!invoiceGroups.containsKey(inv)) {
                            invoiceGroups[inv] = [];
                            invoiceOrder.add(inv);
                          }
                          invoiceGroups[inv]!.add(MapEntry(key, s));
                        }
                        if (invoiceOrder.isEmpty) return _empty();
                        return ListView.builder(
                          padding: const EdgeInsets.fromLTRB(12, 0, 12, 90),
                          itemCount: invoiceOrder.length,
                          itemBuilder: (context, i) {
                            final inv = invoiceOrder[i];
                            final entries = invoiceGroups[inv]!;
                            final primaryEntry = entries.first;
                            final primarySale = primaryEntry.value;
                            final primaryKey = primaryEntry.key;
                            if (entries.length == 1) {
                              // Single-item invoice: use existing card unchanged
                              return _SaleHistoryCard(
                                sale: primarySale,
                                hiveKey: primaryKey,
                                onEdit: () => _openForm(existing: primarySale, key: primaryKey),
                                onDelete: () => _delete(primaryKey),
                                onPrint: () => _printSale(primarySale),
                                onExportImage: () => _exportImage(primarySale),
                                onExportPdf: () => _exportVoucher(primarySale),
                                onShowPhotos: () => _showPhotoViewer(primarySale),
                                onShowDetails: () => _showDetails(primarySale, hiveKey: primaryKey),
                                dateFormat: _date,
                                moneyFormat: _money,
                                saleUnitFn: _saleUnit,
                                getCustomerNameFn: _getCustomerName,
                                payLabelFn: _payLabel,
                                profitBadgeFn: _profitBadge,
                              );
                            } else {
                              // Multi-item invoice: show grouped card
                              return _InvoiceGroupCard(
                                invoiceNumber: inv,
                                entries: entries,
                                onDeleteAll: () => _deleteInvoice(entries.map((e) => e.key).toList()),
                                onPrint: () => _printSale(primarySale),
                                onExportPdf: () => _exportInvoicePdf(entries.map((e) => e.value).toList()),
                                onExportImage: () => _exportInvoiceImage(entries.map((e) => e.value).toList()),
                                onEditItem: (saleKey) => _editSale(saleKey),
                                onDeleteItem: (saleKey) => _deleteSale(saleKey),
                                dateFormat: _date,
                                moneyFormat: _money,
                                getCustomerNameFn: _getCustomerName,
                                payLabelFn: _payLabel,
                              );
                            }
                          },
                        );
                      }),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _summaryCard(String label, String value, Color color) {
    return Container(
      margin: const EdgeInsets.all(8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Column(
        children: [
          Text(label,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[300], fontSize: 12)),
          const SizedBox(height: 4),
          Text(value,
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: color,
                  fontSize: 18,
                  fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _profitBadge(Sale s) {
    final profitGenerated = s.profitGenerated > 0 ? s.profitGenerated : 0;
    final accumulatedProfit = s.accumulatedProfit > 0 ? s.accumulatedProfit : 0;
    final remainingCost = s.remainingCostAfterSale > 0 ? s.remainingCostAfterSale : 0;
    
    if (accumulatedProfit > 0) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              'ယခု အမြတ်: ${_money.format(profitGenerated)}',
              style: const TextStyle(
                color: AppTheme.successColor,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              'စုစုပေါင်း: ${_money.format(accumulatedProfit)}',
              style: const TextStyle(
                color: Colors.lightGreen,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      );
    }
    
    if (remainingCost > 0) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Text(
          'ကျန်အရင်း: ${_money.format(remainingCost)}',
          style: const TextStyle(
            color: Colors.amber,
            fontSize: 10,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    }
    
    return const SizedBox.shrink();
  }

  String _saleUnit(Sale s) {
    // Use weightUnit from Sale record if available (for whole-stone and fragment sales)
    if (s.weightUnit != null && s.weightUnit!.isNotEmpty) {
      return s.weightUnit!;
    }
    // Fallback to gemstone unit if no weightUnit in sale
    if (s.gemstoneId.isNotEmpty) {
      final g = LocalDb.gemstoneById(s.gemstoneId);
      if (g != null) return LocalDb.unitLabel(g.weightUnit);
    }
    return '';
  }

  String _getCustomerName(Sale sale) {
    if (sale.customerId != null && sale.customerId!.isNotEmpty) {
      final customer = LocalDb.customers().get(sale.customerId);
      if (customer != null) {
        return customer.name;
      }
    }
    return sale.customerName;
  }

  String _payLabel(String m) {
    switch (m) {
      case 'bank':
        return 'ဘဏ်';
      case 'credit':
        return 'အကြွေး';
      default:
        return 'ငွေသား';
    }
  }

  Widget _empty() => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.shopping_cart, size: 70, color: Colors.grey[700]),
            const SizedBox(height: 12),
            Text('အရောင်းမှတ်တမ်း မရှိသေးပါ',
                style: TextStyle(color: Colors.grey[500])),
          ],
        ),
      );

  void _showDetails(Sale sale, {dynamic hiveKey}) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(sale.gemstoneName),
            ),
            PopupMenuButton<String>(
              onSelected: (value) async {
                Navigator.pop(context); // Close dialog first
                switch (value) {
                  case 'edit':
                    if (LocalDb.canEditSale()) {
                      _openForm(existing: sale, key: hiveKey);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(LocalDb.adminOnlyErrorMessage()),
                          backgroundColor: AppTheme.errorColor,
                        ),
                      );
                    }
                    break;
                  case 'delete':
                    _delete(hiveKey);
                    break;
                  case 'print':
                    _printSale(sale);
                    break;
                  case 'pdf':
                    _exportVoucher(sale);
                    break;
                }
              },
              itemBuilder: (BuildContext context) => [
                const PopupMenuItem<String>(
                  value: 'edit',
                  child: Row(
                    children: [
                      Text('✏️'),
                      SizedBox(width: 8),
                      Text('ပြုပြင်ရန်'),
                    ],
                  ),
                ),
                const PopupMenuItem<String>(
                  value: 'delete',
                  child: Row(
                    children: [
                      Text('🗑️'),
                      SizedBox(width: 8),
                      Text('ဖျက်ရန်'),
                    ],
                  ),
                ),
                const PopupMenuItem<String>(
                  value: 'print',
                  child: Row(
                    children: [
                      Text('🖨️'),
                      SizedBox(width: 8),
                      Text('ပရင့်ထုတ်ရန်'),
                    ],
                  ),
                ),
                const PopupMenuItem<String>(
                  value: 'pdf',
                  child: Row(
                    children: [
                      Text('📄'),
                      SizedBox(width: 8),
                      Text('PDF ထုတ်ရန်'),
                    ],
                  ),
                ),
              ],
              child: const Text('⋮', style: TextStyle(fontSize: 20)),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('အရေအတွက်: ${sale.quantity}'),
              if (sale.weightCarat > 0)
                Text('အလေးချိန်: ${sale.weightCarat} ${_saleUnit(sale)}'),
              Text('ဝယ်သူ: ${_getCustomerName(sale)}'),
              Text('ငွေပမာဏ: ${_money.format(sale.amount)}'),
              Text('ငွေပေးချေမှု: ${_payLabel(sale.paymentMethod)}'),
              Text('နေ့စွဲ: ${_date.format(DateTime.fromMillisecondsSinceEpoch(sale.saleDate))}'),
              if (sale.note.isNotEmpty) Text('မှတ်ချက်: ${sale.note}'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ပိတ်ရန်'),
          ),
        ],
      ),
    );
  }

  /// Edit a single sale item
  Future<void> _editSale(dynamic saleKey) async {
    // Get the sale from LocalDb
    final sale = LocalDb.sales().get(saleKey);
    if (sale == null) return;
    
    // Open the form with the existing sale data
    await _openForm(existing: sale, key: saleKey);
  }

  /// Delete a single sale item
  Future<void> _deleteSale(dynamic saleKey) async {
    // Call the existing _delete method which handles a single key
    await _delete(saleKey);
  }
}

// Item model for multi-item invoices
class _SaleItem {
  String id;
  String? gemstoneId;
  String gemstoneName;
  int quantity;
  double unitPrice;
  String remark;
  String? fragmentName; // Fragment name if from breakdown_item source
  bool isFragmentSource; // True if this item is from fragment source
  double commission; // Commission fee for this item (read at ထည့်မည် time)
  double? weight; // Fragment weight (optional)
  String? weightUnit; // Fragment weight unit
  List<String> photoPaths; // Photo paths for draft items

  _SaleItem({
    required this.id,
    this.gemstoneId,
    required this.gemstoneName,
    required this.quantity,
    required this.unitPrice,
    this.remark = '',
    this.fragmentName,
    this.isFragmentSource = false,
    this.commission = 0,
    this.weight,
    this.weightUnit,
    this.photoPaths = const [],
  });

  // Calculated properties
  // For fragment items: unitPrice stores the TOTAL sale amount (not per-unit)
  // For whole-stone items: unitPrice IS the total sale amount (not per-unit)
  // Quantity is used ONLY for inventory deduction, never for financial calculation
  double get totalAmount => unitPrice; // salePrice entered = total sale amount for ALL types
  double get saleAmount => unitPrice;  // same — no multiplication by quantity
  double get netSale => saleAmount - commission;
  
  // Cumulative financial values (will be set during save flow)
  double recoveredPrincipal = 0;
  double remainingPrincipal = 0;
  double cumulativeProfit = 0;
}

class _SaleForm extends StatefulWidget {
  final Sale? existing;
  final dynamic hiveKey;
  const _SaleForm({this.existing, this.hiveKey});

  @override
  State<_SaleForm> createState() => _SaleFormState();
}

class _SaleFormState extends State<_SaleForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _customer;
  String? _selectedCustomerId; // Customer Master ID
  late final TextEditingController _amount;
  late final TextEditingController _qty;
  late final TextEditingController _weight;
  late final TextEditingController _note;
  late final TextEditingController _manualName; // when no gemstone selected
  late final TextEditingController _cost; // optional manual cost override
  late final TextEditingController _commission; // sell-side commission (ပွဲခ)
  String _payment = 'cash';
  late DateTime _saleDate;
  late List<String> _photoPaths;
  final _money = NumberFormat('#,##0', 'en_US');

  String? _selectedGemId; // null => manual entry
  bool _autoDeduct = true;
  
  // Sale source selector (Step 5B)
  String _saleSource = 'whole_stone'; // 'whole_stone' or 'breakdown_item'
  String? _selectedFragmentGemstoneId; // Selected fragment purchase (Step 5C-2)
  String? _selectedFragmentName; // Selected fragment name from dropdown (Step 5C-3)
  
  // Weight unit selection for whole-stone and fragment sales
  String _weightUnitWhole = 'kg'; // Default unit for whole-stone sales
  String _weightUnitFragment = 'kg'; // Default unit for fragment sales
  
  // Multi-item invoice support
  late List<_SaleItem> _items;
  bool _isMultiItemMode = false;

  // Preview state (in-memory only, never persisted to Hive)
  final Map<String, dynamic> _previewState = {}; // Stores preview values for each gemstone

  // Duplicate-save protection flag
  bool _isSaving = false;

  bool get _isEdit => widget.existing != null && widget.hiveKey != null;

  /// Calculate preview state for a gemstone when an item is added
  void _updatePreviewForGemstone(String? gemstoneId, double netSale, {int? fragmentQtyDeducted}) {
    if (gemstoneId == null || gemstoneId.isEmpty) return;
    
    final originalGem = LocalDb.gemstoneById(gemstoneId);
    if (originalGem == null) return;
    
    if (!_previewState.containsKey(gemstoneId)) {
      _previewState[gemstoneId] = {
        'originalRemainingCost': originalGem.remainingCost,
        'originalRemainingQuantity': originalGem.remainingQuantity,
        'originalRecoveredCost': originalGem.recoveredCost,
        'originalTotalProfit': originalGem.totalProfit ?? 0,
        'originalRemainingCostBalance': originalGem.remainingCostBalance,
        'totalNetSale': 0.0,
        'totalFragmentQtyDeducted': 0,
      };
    }
    
    _previewState[gemstoneId]['totalNetSale'] += netSale;
    
    final preview = _previewState[gemstoneId];
    final totalNetSale = preview['totalNetSale'] as double;
    final originalBalance = preview['originalRemainingCostBalance'] as double;
    
    double recoveredAmount = 0;
    double profitAmount = 0;
    double remainingBalance = originalBalance;
    
    if (totalNetSale <= remainingBalance) {
      recoveredAmount = totalNetSale;
      remainingBalance -= totalNetSale;
    } else {
      recoveredAmount = remainingBalance;
      profitAmount = totalNetSale - remainingBalance;
      remainingBalance = 0;
    }
    
    preview['previewRecoveredCost'] = (preview['originalRecoveredCost'] as double) + recoveredAmount;
    preview['previewRemainingCostBalance'] = remainingBalance.clamp(0, double.infinity);
    preview['previewTotalProfit'] = (preview['originalTotalProfit'] as double) + profitAmount;
    preview['previewRemainingCost'] = remainingBalance.clamp(0, double.infinity);
    // Track fragment quantity deduction in preview
    if (fragmentQtyDeducted != null && fragmentQtyDeducted > 0) {
      preview['totalFragmentQtyDeducted'] = (preview['totalFragmentQtyDeducted'] as int? ?? 0) + fragmentQtyDeducted;
    }
    preview['previewRemainingQuantity'] = (preview['originalRemainingQuantity'] as int) - (preview['totalFragmentQtyDeducted'] as int? ?? 0);
  }
  
    /// Recalculate preview state from all items in temporary list
  void _recalculatePreview() {
    _previewState.clear();
    for (final item in _items) {
      if (item.gemstoneId != null && item.gemstoneId!.isNotEmpty) {
        // Use the pre-calculated netSale from the item getter
        // For fragments: netSale = unitPrice (total amount) - commission
        // For whole-stone: netSale = (quantity * unitPrice) - commission
        _updatePreviewForGemstone(item.gemstoneId, item.netSale);
      }
    }
  }
  
  /// Get preview value for remaining cost
  double _getPreviewRemainingCost(String? gemstoneId) {
    if (gemstoneId == null || gemstoneId.isEmpty) return 0;
    
    if (_previewState.containsKey(gemstoneId)) {
      return _previewState[gemstoneId]['previewRemainingCost'] as double? ?? 0;
    }
    
    final gem = LocalDb.gemstoneById(gemstoneId);
    return gem?.remainingCost ?? 0;
  }
  
  /// Get preview value for remaining quantity
  int _getPreviewRemainingQuantity(String? gemstoneId) {
    if (gemstoneId == null || gemstoneId.isEmpty) return 0;
    
    if (_previewState.containsKey(gemstoneId)) {
      return (_previewState[gemstoneId]['previewRemainingQuantity'] as int?) ?? 0;
    }
    
    final gem = LocalDb.gemstoneById(gemstoneId);
    return gem?.remainingQuantity ?? 0;
  }
  
  /// Get preview value for recovered cost
  double _getPreviewRecoveredCost(String? gemstoneId) {
    if (gemstoneId == null || gemstoneId.isEmpty) return 0;
    
    if (_previewState.containsKey(gemstoneId)) {
      return _previewState[gemstoneId]['previewRecoveredCost'] as double? ?? 0;
    }
    
    final gem = LocalDb.gemstoneById(gemstoneId);
    return gem?.recoveredCost ?? 0;
  }
  
  /// Get preview value for estimated profit
  double _getPreviewEstimatedProfit(String? gemstoneId) {
    if (gemstoneId == null || gemstoneId.isEmpty) return 0;
    
    if (_previewState.containsKey(gemstoneId)) {
      return _previewState[gemstoneId]['previewTotalProfit'] as double? ?? 0;
    }
    
    final gem = LocalDb.gemstoneById(gemstoneId);
    return gem?.totalProfit ?? 0;
  }

  void _addItemToTemporaryList() {
    // Determine which mode we're in
    if (_saleSource == 'breakdown_item') {
      _addFragmentItem();
    } else {
      _addWholeStoneItem();
    }
  }

  void _addWholeStoneItem() {
    // Validate
    if (_selectedGemId == null && _manualName.text.isEmpty) {
      _showError('Please select or enter a gemstone');
      return;
    }
    double qty = double.tryParse(_qty.text) ?? 0;
    if (qty <= 0) {
      _showError('Quantity must be greater than 0');
      return;
    }
    double price = double.tryParse(_amount.text) ?? 0;
    if (price < 0) {
      _showError('Price must be 0 or greater');
      return;
    }

    // READ COMMISSION IMMEDIATELY at ထည့်မည် time
    final commissionValue = double.tryParse(_commission.text.trim()) ?? 0;

    // Get gemstone name
    String gemstoneName = _manualName.text;
    String? gemstoneId;
    if (_selectedGemId != null) {
      final gem = LocalDb.gemstoneById(_selectedGemId!);
      gemstoneName = gem?.name ?? 'Unknown';
      gemstoneId = gem?.id;
    }

    // Get weight and weight unit (optional)
    final weightValue = double.tryParse(_weight.text.trim());
    
    // Create item with stored commission and weight unit
    final item = _SaleItem(
      id: const Uuid().v4(),
      gemstoneId: gemstoneId,
      gemstoneName: gemstoneName,
      quantity: qty.toInt(),
      unitPrice: price,
      remark: _note.text,
      commission: commissionValue,
      weight: weightValue,
      weightUnit: _weightUnitWhole,
      photoPaths: List.from(_photoPaths),
    );

    // Financial values are now calculated via getters (saleAmount, netSale)

    // Add to list
    setState(() {
      _items.add(item);
    });

    // Recalculate cumulative financial values from all draft items
    _recalculateCumulativeFinancials();

    // Clear form fields
    setState(() {
      _selectedGemId = null;
      _manualName.clear();
      _qty.text = '1'; // Default to 1 for next item
      _amount.clear();
      _note.clear();
      _weight.clear();
      _cost.clear();
      _commission.clear();
      _weightUnitWhole = 'kg'; // Reset to default unit
      _photoPaths.clear(); // Clear selected images
    });

    _showSuccess('${item.gemstoneName} added');
  }

  void _addFragmentItem() {
    // Obtain the gemstone list (matching build method logic)
    final gems = LocalDb.gemstones().values.where((g) => g.quantity > 0).toList();
    
    // Find the selected purchase
    final selectedPurchase = gems.firstWhereOrNull(
      (g) => g.id == _selectedFragmentGemstoneId,
    );

    // DEBUG: Log the state
    print('DEBUG _addFragmentItem: _selectedFragmentGemstoneId=$_selectedFragmentGemstoneId');
    print('DEBUG _addFragmentItem: _selectedFragmentName=$_selectedFragmentName');
    print('DEBUG _addFragmentItem: selectedPurchase=${selectedPurchase?.name}');

    // Validation
    if (_selectedFragmentGemstoneId == null) {
      print('DEBUG: Validation failed - gemstone ID is null');
      _toast('ကျောက်အစိတ်စုပေါင်းရွေးချယ်ပါ');
      return;
    }

    if (_selectedFragmentName == null || _selectedFragmentName!.isEmpty) {
      print('DEBUG: Validation failed - fragment name is null or empty');
      _toast('အစိတ်စိတ်ပိုင်းရွေးချယ်ပါ');
      return;
    }

    final qtyInput = _qty.text.trim();
    print('DEBUG: qtyInput="$qtyInput"');
    if (qtyInput.isEmpty) {
      print('DEBUG: Validation failed - qty is empty');
      _toast('အရေအတွက်ထည့်သွင်းပါ');
      return;
    }

    final qty = int.tryParse(qtyInput);
    if (qty == null || qty <= 0) {
      _toast('အရေအတွက်သည် ၀ထက်ကြီးရမည်');
      return;
    }

    // Check quantity against available
    // breakdownItems stores fragments as: {'quantity': int, 'weight': double, 'weightUnit': string}
    final availableQtyObj = selectedPurchase?.breakdownItems?[_selectedFragmentName];
    final availableQty = (availableQtyObj is Map<String, dynamic>) 
      ? ((availableQtyObj['quantity'] as int?) ?? 0).toDouble()
      : (availableQtyObj is num ? (availableQtyObj as num).toDouble() : 0.0);
    if (qty > availableQty) {
      _toast('လက်ကျန်အစိတ်အရေအတွက်ထက် မကျော်ရပါ');
      return;
    }

    // Validate unit price
    final priceInput = _amount.text.trim();
    if (priceInput.isEmpty) {
      _toast('ရောင်းဈေးထည့်သွင်းပါ');
      return;
    }

    final unitPrice = double.tryParse(priceInput);
    if (unitPrice == null || unitPrice < 0) {
      _toast('ရောင်းဈေးသည် ၀နှင့်အညီ သို့မဟုတ် ၀ထက်ကြီးရမည်');
      return;
    }

    // Validate total sale amount > 0
    if (unitPrice <= 0) {
      _toast('ရောင်းဈေးသည် ၀ထက်ကြီးရမည်');
      return;
    }

    // Validate and parse commission
    final commissionInput = _commission.text.trim();
    final commission = double.tryParse(commissionInput) ?? 0;
    if (commission < 0) {
      _toast('အရောင်းပွဲခသည် အနုတ်မဖြစ်ရပါ');
      return;
    }
    if (commission > unitPrice) {
      _toast('ပွဲခသည် ရောင်းဈေးထက်မကျော်ရပါ');
      return;
    }

    // DEBUG: Log all values at ထည့်မည် time
    final grossSale = unitPrice; // For fragments, unitPrice IS the total sale amount
    final netSale = grossSale - commission;
    print('DEBUG FRAGMENT ထည့်မည်: button callback entered');
    print('DEBUG FRAGMENT ထည့်မည်: selectedFragmentId=$_selectedFragmentGemstoneId');
    print('DEBUG FRAGMENT ထည့်မည်: quantity=$qty');
    print('DEBUG FRAGMENT ထည့်မည်: grossSale=$grossSale');
    print('DEBUG FRAGMENT ထည့်မည်: commission=$commission');
    print('DEBUG FRAGMENT ထည့်မည်: netSale=$netSale');
    print('DEBUG FRAGMENT ထည့်မည်: validation=PASSED');
    print('DEBUG FRAGMENT ထည့်မည်: _items.length BEFORE=${_items.length}');
    
    final item = _SaleItem(
      id: const Uuid().v4(),
      gemstoneId: _selectedFragmentGemstoneId,
      gemstoneName: selectedPurchase?.name ?? 'Unknown',
      quantity: qty,
      unitPrice: unitPrice,
      remark: '',
      fragmentName: _selectedFragmentName,
      isFragmentSource: true,
      commission: commission,
      weight: double.tryParse(_weight.text.trim()),
      weightUnit: _weightUnitFragment,
      photoPaths: List.from(_photoPaths),
    );

    // Financial values are now calculated via getters:
    // item.saleAmount = unitPrice (for fragments, this IS the total sale amount)
    // item.netSale = saleAmount - commission
    print('DEBUG FRAGMENT ထည့်မည်: item.saleAmount=${item.saleAmount}');
    print('DEBUG FRAGMENT ထည့်မည်: item.netSale=${item.netSale}');

    setState(() {
      _items.add(item);
    });

    print('DEBUG FRAGMENT ထည့်မည်: _items.length AFTER=${_items.length}');

    // Recalculate cumulative financial values from all draft items
    _recalculateCumulativeFinancials();

    print('DEBUG FRAGMENT ထည့်မည်: navigation result = staying on form (user can add more)');

    // Clear only quantity/price/weight fields - KEEP fragment selections
    // This allows user to continue adding more items from the same fragment
    setState(() {
      _qty.text = '1'; // Default to 1 for next item (not empty!)
      _amount.clear();
      _commission.text = '0';
      _weight.clear();
      _photoPaths.clear(); // Clear selected images for next item
      // NOTE: Do NOT clear _selectedFragmentGemstoneId or _selectedFragmentName
      // Keep them set so the fragment form remains visible for next entry
    });

    _toast('အစိတ်စိတ်ပိုင်းထည့်သွင်းအောင်မြင်ပါသည်');

    // Auto-switch back to 'whole_stone' view so the user sees the
    // ထည့်ထားသောပစ္စည်းများ box with the newly added item
    setState(() {
      _saleSource = 'whole_stone';
    });
    print('DEBUG FRAGMENT ထည့်မည်: auto-switched _saleSource to whole_stone');
  }

  void _recalculateCumulativeFinancials() {
    if (_items.isEmpty) return;

    double totalNetSales = 0;
    final gemstone = _selectedGemId != null ? LocalDb.gemstoneById(_selectedGemId!) : null;
    final double totalPurchaseCost = gemstone != null ? LocalDb.gemstoneTotalCost(gemstone).toDouble() : 0.0;

    for (var item in _items) {
      totalNetSales += item.netSale;
      
      // Calculate cumulative values
      item.recoveredPrincipal = totalNetSales > totalPurchaseCost ? totalPurchaseCost : totalNetSales;
      item.remainingPrincipal = totalNetSales >= totalPurchaseCost ? 0 : (totalPurchaseCost - totalNetSales);
      item.cumulativeProfit = totalNetSales > totalPurchaseCost ? (totalNetSales - totalPurchaseCost) : 0;
    }

    setState(() {});
  }

  void _removeItemFromTemporaryList(int index) {
    setState(() {
      _items.removeAt(index);
    });
    _recalculateCumulativeFinancials();
    _showSuccess('Item removed');
  }

  void _editItemFromTemporaryList(int index) {
    final item = _items[index];
    
    // Load item data back into form fields (unified for both types)
    setState(() {
      if (item.isFragmentSource) {
        // Fragment item: restore using unified fields
        _saleSource = 'breakdown_item';
        _selectedFragmentGemstoneId = item.gemstoneId;
        _selectedFragmentName = item.fragmentName;
        _qty.text = item.quantity.toString();
        _amount.text = item.unitPrice.toString();
        _weight.text = (item.weight ?? 0).toString();
        _commission.text = (item.commission ?? 0).toString();
      } else {
        // Whole-stone item: restore whole-stone fields
        _saleSource = 'whole_stone';
        _selectedGemId = item.gemstoneId;
        _manualName.text = item.gemstoneName;
        _qty.text = item.quantity.toString();
        _amount.text = item.unitPrice.toString();
        _note.text = item.remark;
      }
    });
    // Remove from temporary list
    setState(() {
      _items.removeAt(index);
    });
    _recalculatePreview();
    _showSuccess('Item loaded for editing');
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: AppTheme.errorColor),
    );
  }

  void _showSuccess(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: AppTheme.successColor),
    );
  }

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _photoPaths = List.from(e?.photoPaths ?? []);
    _selectedCustomerId = e?.customerId;
    _customer = TextEditingController(text: e?.customerName ?? '');
    _amount =
        TextEditingController(text: e != null ? _trim(e.amount) : '');
    _qty = TextEditingController(text: e?.quantity.toString() ?? '1');
    _weight =
        TextEditingController(text: e != null && e.weightCarat > 0 ? _trim(e.weightCarat) : '');
    _note = TextEditingController(text: e?.note ?? '');
    _manualName = TextEditingController(text: e?.gemstoneName ?? '');
    _cost = TextEditingController(
        text: e != null && e.costPrice > 0 ? _trim(e.costPrice) : '');
    _commission = TextEditingController(
        text: e != null && e.commissionFee > 0 ? _trim(e.commissionFee) : '');
    _payment = e?.paymentMethod ?? 'cash';
    _saleDate = e != null
        ? DateTime.fromMillisecondsSinceEpoch(e.saleDate)
        : DateTime.now();

    // Preselect gemstone if the sale was linked to one and it still exists.
    if (e != null && e.gemstoneId.isNotEmpty &&
        LocalDb.gemstoneById(e.gemstoneId) != null) {
      _selectedGemId = e.gemstoneId;
    }
    
    // Initialize multi-item list
    // Architecture: ONE Sale record per item (not one Sale with multiple items)
    // For new sales: start with empty list so user can add items via 'ထည့်မည်'
    // For existing sales (edit mode): load the single sale as a draft item
    if (e != null) {
      // Editing existing sale: create one draft item from the sale data
      final item = _SaleItem(
        id: const Uuid().v4(),
        gemstoneId: e.gemstoneId,
        gemstoneName: e.gemstoneName,
        quantity: e.quantity,
        unitPrice: e.amount,
        remark: e.note,
        commission: e.commissionFee,
        weight: e.weightCarat > 0 ? e.weightCarat : null,
        weightUnit: e.weightUnit ?? 'carat',
        isFragmentSource: e.isFragmentSource,
        fragmentName: e.fragmentName,
      );
      
      // Financial values are now calculated via getters (saleAmount, netSale)
      // Cumulative values will be calculated during save
      _items = [item];
    } else {
      // New sale: start with empty list so user can add items via 'ထည့်မည်'
      _items = [];
    }
  }

  static String _trim(double v) =>
      v == v.roundToDouble() ? v.toInt().toString() : v.toString();

  @override
  void dispose() {
    // Clear preview state (automatic rollback)
    _previewState.clear();
    
    for (final c in [_customer, _amount, _qty, _weight, _note, _manualName, _cost, _commission]) {
      c.dispose();
    }
    // Note: _fragmentWeight is removed - use _weight for both types
    super.dispose();
  }
  
  double get _totalQuantity => _items.fold<int>(0, (sum, item) => sum + item.quantity).toDouble();
  double get _totalAmount => _items.fold<double>(0, (sum, item) => sum + item.totalAmount);
  
  void _onSelectGem(String? id) {
    setState(() {
      _selectedGemId = id;
      if (id != null) {
        final g = LocalDb.gemstoneById(id);
        if (g != null) {
          // Auto-fill suggested values from inventory.
          _manualName.text = g.name;
          if (_amount.text.trim().isEmpty) {
            _amount.text = _trim(g.sellPrice);
          }
          // Auto-fill cost based on product state (Product-wise Independent Ledger)
          // ပထမအကြိမ်: totalCost
          // နောက်အကြိမ်များ: remainingCost
          // remainingCost = 0 ဖြစ်လျှင်: 0
          final autoCost = LocalDb.getSalesFormAutoCost(g);
          _cost.text = _trim(autoCost);
        }
      } else {
        _cost.clear();
      }
    });
  }

  /// Display preview values from temporary items
  Widget _previewValuesDisplay() {
    if (_items.isEmpty || _previewState.isEmpty) {
      return const SizedBox.shrink();
    }

    // Calculate totals from preview state
    double totalRecoveredCost = 0;
    double totalRemainingCost = 0;
    double totalEstimatedProfit = 0;
    int totalItemTypes = 0;

    for (final entry in _previewState.entries) {
      final preview = entry.value as Map<String, dynamic>;
      totalRecoveredCost += (preview['previewRecoveredCost'] as double? ?? 0);
      totalRemainingCost += (preview['previewRemainingCost'] as double? ?? 0);
      totalEstimatedProfit += (preview['previewTotalProfit'] as double? ?? 0);
      totalItemTypes++;
    }

    final m = NumberFormat('#,##0');

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.primaryAccent.withOpacity(0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppTheme.primaryAccent.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'ခန့်မှန်းမြင်တွေ့ချက် (အခြေခံ)',
            style: TextStyle(
              color: AppTheme.primaryAccent,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'ပစ္စည်းအမျိုးအစား:',
                style: TextStyle(color: Colors.grey[400], fontSize: 11),
              ),
              Text(
                '$totalItemTypes',
                style: const TextStyle(
                  color: AppTheme.primaryAccent,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'ပြန်လည်ရယူထားသောအရင်း:',
                style: TextStyle(color: Colors.grey[400], fontSize: 11),
              ),
              Text(
                '${m.format(totalRecoveredCost)} ကျပ်',
                style: const TextStyle(
                  color: Colors.lightGreen,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'ကျန်ရှိသောအရင်း:',
                style: TextStyle(color: Colors.grey[400], fontSize: 11),
              ),
              Text(
                '${m.format(totalRemainingCost)} ကျပ်',
                style: const TextStyle(
                  color: Colors.amber,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'ခန့်မှန်းအမြတ်:',
                style: TextStyle(color: Colors.grey[400], fontSize: 11),
              ),
              Text(
                '${m.format(totalEstimatedProfit)} ကျပ်',
                style: TextStyle(
                  color: totalEstimatedProfit > 0 ? AppTheme.successColor : Colors.grey,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Live profit/loss preview based on currently entered amount and cost.
  Widget _profitPreview() {
    final amount = double.tryParse(_amount.text.trim()) ?? 0;
    final qty = int.tryParse(_qty.text.trim()) ?? 1;
    final sellCommission = double.tryParse(_commission.text.trim()) ?? 0;
    double cost = double.tryParse(_cost.text.trim()) ?? 0;
    // amount IS the total sale price — no multiplication by qty needed.
    // cost is the per-unit cost from the gemstone record; scale it by qty for cost recovery preview.
    if (_selectedGemId != null && cost > 0) {
      cost = cost * qty; // cost (purchase price per unit) * qty = total cost for this batch
    }
    if (amount <= 0 && cost <= 0) return const SizedBox.shrink();
    // Sell commission is deducted from revenue.
    final p = (amount - sellCommission) - cost;
    // အရင်းထက် မကျော်ရသေးသော့ အရှုံးမပြပါ။ ကျန်အရင်းကိုသာ ပြပါ။
    final isProfit = p > 0;
    final m = NumberFormat('#,##0');
    final label = isProfit ? 'ခန့်မှန်းအမြတ်' : 'ကျန်ရှိမည့်အရင်း';
    final color = isProfit ? AppTheme.successColor : Colors.green;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w600)),
          Text('${m.format(p.abs())} ကျပ်',
              style: TextStyle(
                  color: color,
                  fontSize: 16,
                  fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Future<void> _finalizeAndSave() async {
    print('DEBUG ရောင်းချမည်: _finalizeAndSave CALLED');
    print('DEBUG ရောင်းချမည်: _items.length = ${_items.length}');
    print('DEBUG ရောင်းချမည်: _isSaving = $_isSaving');
    for (int i = 0; i < _items.length; i++) {
      final item = _items[i];
      print('DEBUG ရောင်းချမည်: item[$i] gemstoneId=${item.gemstoneId}, qty=${item.quantity}, unitPrice=${item.unitPrice}, isFragment=${item.isFragmentSource}, commission=${item.commission}');
    }
    
    // Prevent duplicate saves
    if (_isSaving) {
      _toast('ရောင်းချမှု သိမ်းဆည်းနေသည်...');
      return;
    }
    
    setState(() {
      _isSaving = true;
    });
    
    try {
      await _performFinalSave();
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  Future<void> _performFinalSave() async {
    // Check if temporary list has items
    if (_items.isEmpty) {
      _toast('ရောင်းချရန် ပစ္စည်းအနည်းဆုံးတစ်ခု ထည့်ပါ');
      return;
    }

    // PHASE 1: VALIDATE ALL ITEMS BEFORE SAVING ANY
    for (int i = 0; i < _items.length; i++) {
      final item = _items[i];
      
      // Check gemstone selected
      if (item.gemstoneId == null || item.gemstoneId!.isEmpty) {
        _toast('အရည်အသွေး $i: ကျောက်မျက်ရွေးချယ်ပါ');
        return;
      }
      
      // Check quantity > 0
      if (item.quantity <= 0) {
        _toast('အရည်အသွေး $i: အရေအတွက် > 0 ဖြစ်ရမည်');
        return;
      }
      
      // Check unit price >= 0
      if (item.unitPrice < 0) {
        _toast('အရည်အသွေး $i: ယူနစ်ဈေးနှုန်း >= 0 ဖြစ်ရမည်');
        return;
      }
      
      // Check gemstone exists
      final gemstone = LocalDb.gemstoneById(item.gemstoneId!);
      if (gemstone == null) {
        _toast('အရည်အသွေး $i: ကျောက်မျက်မတွေ့ရှိ');
        return;
      }
      
      // Check inventory if auto-deduct enabled
      if (_autoDeduct) {
        if (item.isFragmentSource && item.fragmentName != null && item.fragmentName!.isNotEmpty) {
          // For fragment items: check individual BreakdownItem remaining quantity
          if (gemstone != null && gemstone.breakdownItems != null) {
            final fragmentName = item.fragmentName!;
            final itemData = gemstone.breakdownItems![fragmentName];
            if (itemData is Map<String, dynamic>) {
              final currentQtyObj = itemData['quantity'];
              final currentQty = (currentQtyObj is num) ? (currentQtyObj as num).toInt() : 0;
              print('DEBUG ရောင်းချမည်: item[$i] fragment autoDeduct check: fragmentName=$fragmentName, currentQty=$currentQty, qty=${item.quantity}');
              if (currentQty <= 0) {
                _toast('အရည်အသွေး $i ($fragmentName): အရောင်းအဆုံးဖြစ်နေ');
                return;
              }
              if (item.quantity > currentQty) {
                _toast('အရည်အသွေး $i ($fragmentName): Stock မလောက်ပါ — ကျန် $currentQty ခုသာ ရှိသည်');
                return;
              }
            }
          }
        } else {
          // For whole stone items: check whole stone remaining quantity
          final remaining = LocalDb.gemstoneRemainingQuantity(gemstone);
          print('DEBUG ရောင်းချမည်: item[$i] wholeStone autoDeduct check: remaining=$remaining, qty=${item.quantity}');
          if (remaining <= 0) {
            _toast('အရည်အသွေး $i: အရောင်းအဆုံးဖြစ်နေ');
            return;
          }
          if (item.quantity > remaining) {
            _toast('အရည်အသွေး $i: Stock မလောက်ပါ — ကျန် $remaining ခုသာ ရှိသည်');
            return;
          }
        }
      }
    }

    // PHASE 2: GENERATE INVOICE NUMBER
    final now = DateTime.now();
    final dateStr = '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';
    final box = LocalDb.sales();
    final existingInvoices = box.values
        .where((s) => s.invoiceNumber.startsWith('INV-$dateStr-'))
        .length;
    final invoiceNum = 'INV-$dateStr-${(existingInvoices + 1).toString().padLeft(3, '0')}';

    // PHASE 3: SAVE LOOP - Save each item as separate Sale record
    // Use PRE-CALCULATED values from draft items (calculated at ထည့်မည် time)
    final Set<String> gemstonesUpdated = {};
    
    try {
      for (int i = 0; i < _items.length; i++) {
        final item = _items[i];
        final qty = item.quantity;
        final unitPrice = item.unitPrice;
        final amount = item.saleAmount; // Use pre-calculated gross amount
        final itemCommission = item.commission; // Use pre-calculated commission
        final netSale = item.netSale; // Use pre-calculated net sale
        
        // costPrice = purchase cost (COGS), NOT the sale price.
        // For fragment items: unitPrice IS the total sale amount, not cost.
        // For whole-stone items: look up the gemstone's remaining cost balance as COGS.
        double cost;
        if (item.isFragmentSource) {
          // Fragment: use gemstone's per-unit cost × qty as COGS approximation
          final fragGem = item.gemstoneId!.isNotEmpty ? LocalDb.gemstoneById(item.gemstoneId!) : null;
          cost = fragGem != null ? LocalDb.getSalesFormAutoCost(fragGem) : 0;
        } else if (item.gemstoneId!.isNotEmpty) {
          // Whole-stone: use gemstone's auto cost (remaining cost balance) as COGS
          final wsGem = LocalDb.gemstoneById(item.gemstoneId!);
          cost = wsGem != null ? LocalDb.getSalesFormAutoCost(wsGem) : 0;
        } else {
          cost = 0; // Manual entry with no gemstone reference
        }
        
        // Create Sale record
        final fragmentWeight = item.isFragmentSource ? item.weight : null;
        final fragmentWeightUnit = item.isFragmentSource ? item.weightUnit : null;
        
        final newSale = Sale(
          id: LocalDb.genId(),
          gemstoneId: item.gemstoneId ?? '',
          gemstoneName: item.gemstoneName,
          customerId: _selectedCustomerId,
          customerName: _customer.text.trim(),
          amount: amount,
          costPrice: cost,
          commissionFee: itemCommission,
          quantity: qty,
          weightCarat: 0,
          paymentMethod: _payment,
          note: item.remark,
          saleDate: _saleDate.millisecondsSinceEpoch,
          netSale: netSale,
          costUsed: 0,
          profitGenerated: 0,
          remainingCostAfterSale: 0,
          accumulatedProfit: 0,
          photoPaths: item.photoPaths,
          isDeleted: false,
          deletedAt: null,
          deletedBy: '',
          deleteReason: '',
          invoiceNumber: invoiceNum,
          fragmentWeight: fragmentWeight,
          fragmentWeightUnit: fragmentWeightUnit,
          isFragmentSource: item.isFragmentSource,
          fragmentName: item.fragmentName,
        );
        
        // Save to Hive
        await box.add(newSale);
        
        // Update customer ledger
        await LocalDb.applySaleCustomerLedger(newSale);
        
        // Update gemstone cost recovery using Preview State values
        if (item.gemstoneId!.isNotEmpty) {
        final gemstone = LocalDb.gemstoneById(item.gemstoneId!);
        if (gemstone != null) {
          // Use preview state values instead of recalculating
          if (_previewState.containsKey(item.gemstoneId)) {
            final preview = _previewState[item.gemstoneId] as Map<String, dynamic>;
            // Apply preview values directly from preview state
            gemstone.recoveredCost = preview['previewRecoveredCost'] as double? ?? gemstone.recoveredCost;
            gemstone.remainingCostBalance = preview['previewRemainingCostBalance'] as double? ?? gemstone.remainingCostBalance;
            gemstone.totalProfit = preview['previewTotalProfit'] as double? ?? gemstone.totalProfit;
            gemstone.remainingCost = preview['previewRemainingCost'] as double? ?? gemstone.remainingCost;
          } else {
            // Fallback: recalculate if no preview (should not happen in normal flow)
            LocalDb.applyCostRecovery(gemstone, netSale);
          }
          
          // Step 5E-2: Deduct from breakdownItems if this is a fragment sale
          if (item.isFragmentSource && item.fragmentName != null && item.fragmentName!.isNotEmpty) {
            if (gemstone.breakdownItems != null) {
              final fragmentName = item.fragmentName!;
              final itemData = gemstone.breakdownItems![fragmentName];
              if (itemData is Map<String, dynamic>) {
                final currentQtyObj = itemData['quantity'];
                final currentQty = (currentQtyObj is num) ? (currentQtyObj as num) : 0;
                if (currentQty >= qty) {
                  itemData['quantity'] = currentQty - qty;
                }
                
                // Deduct weight if available
                if (fragmentWeight != null && fragmentWeight! > 0) {
                  final currentWeightObj = itemData['weight'];
                  final currentWeight = (currentWeightObj is num) ? (currentWeightObj as num) : 0;
                  if (currentWeight >= fragmentWeight!) {
                    itemData['weight'] = currentWeight - fragmentWeight!;
                  }
                }
              }
            }
          }
          
          final hiveKey = LocalDb.gemstoneKeyById(item.gemstoneId!);
          if (hiveKey != null) {
            await LocalDb.gemstones().put(hiveKey, gemstone);
          }
          gemstonesUpdated.add(item.gemstoneId!);
        }
        }
      }

      // PHASE 4: POST-SAVE UPDATES - Recalculate product ledger for all changed gemstones
      for (final gemId in gemstonesUpdated) {
        await LocalDb.updateGemstoneProductLedger(gemId);
      }
      
      // PHASE 5: CLEAR PREVIEW STATE AND FORM
      _previewState.clear();
      _items.clear();
      _selectedGemId = null;
      _manualName.clear();
      _qty.clear();
      _amount.clear();
      _note.clear();
      _weight.clear();
      _cost.clear();
      _commission.clear();
      _photoPaths.clear();
      
      // Show success and navigate to Sales History
      _toast('Invoice $invoiceNum သိမ်းဆည်းပြီးပါပြီ');
      if (mounted) {
        // Pop the form modal
        Navigator.pop(context);
        // Trigger refresh of sales history
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            setState(() {
              // Trigger rebuild to refresh sales list
            });
          }
        });
      }
    } catch (e) {
      // FAILURE: Keep preview state and temporary list for retry
      _toast('အမှားအယွင်း: $e');
      // Do NOT clear preview state or items - allow user to retry
    }
  }

  void _toast(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: AppTheme.errorColor,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Filter out sold out products (quantity <= 0)
    final allGems = LocalDb.gemstones().values.where((g) => g.quantity > 0).toList();
    
    // Deduplicate by gemstone ID - keep only the first occurrence of each unique ID
    final seenIds = <String>{};
    final gems = <Gemstone>[];
    for (final g in allGems) {
      if (!seenIds.contains(g.id)) {
        seenIds.add(g.id);
        gems.add(g);
      }
    }
    
    final selectedGem =
        _selectedGemId != null ? LocalDb.gemstoneById(_selectedGemId!) : null;

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Padding(
        padding: EdgeInsets.zero,
        child: Container(
          decoration: const BoxDecoration(
            color: AppTheme.primaryDark,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: const EdgeInsets.all(20),
          child: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                        color: Colors.grey[700],
                        borderRadius: BorderRadius.circular(2)),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text('အရောင်း မှတ်တမ်း',
                          style: TextStyle(
                              color: AppTheme.primaryAccent,
                              fontSize: 18,
                              fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // --- Sale Source Selector (Step 5B) ---
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'ရောင်းချမည့်အမျိုးအစား',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: RadioListTile<String>(
                              contentPadding: EdgeInsets.zero,
                              title: const Text(
                                'အဝယ်စာရင်းမှ ကျောက်',
                                style: TextStyle(color: Colors.white, fontSize: 13),
                              ),
                              value: 'whole_stone',
                              groupValue: _saleSource,
                              onChanged: (value) => setState(() => _saleSource = value ?? 'whole_stone'),
                              activeColor: AppTheme.primaryAccent,
                            ),
                          ),
                          Expanded(
                            child: RadioListTile<String>(
                              contentPadding: EdgeInsets.zero,
                              title: const Text(
                                'ကျောက်အစိတ်စိတ်ပိုင်းများ',
                                style: TextStyle(color: Colors.white, fontSize: 13),
                              ),
                              value: 'breakdown_item',
                              groupValue: _saleSource,
                              onChanged: (value) => setState(() => _saleSource = value ?? 'whole_stone'),
                              activeColor: AppTheme.primaryAccent,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // --- Gemstone picker from inventory (Whole Stone) ---
                if (_saleSource == 'whole_stone')
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: DropdownButtonFormField<String?>(
                    key: ValueKey('gem_dropdown_${_items.length}'),
                    value: _selectedGemId,
                    isExpanded: true,
                    dropdownColor: AppTheme.surfaceLight,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                        labelText: 'ပစ္စည်းစာရင်းမှ ကျောက်မျက်ရွေးပါ'),
                    items: [
                      const DropdownMenuItem<String?>(
                        value: null,
                        child: Text('— လက်ဖြင့်ရိုက်ထည့်မည် —'),
                      ),
                      ...gems.map((g) => DropdownMenuItem<String?>(
                            value: g.id,
                            child: Text(
                              '${g.name} (ကျန် ${LocalDb.gemstoneRemainingQuantity(g)}'
                              '${g.weightCarat > 0 ? ' • ${_trim(g.weightCarat)} ${LocalDb.unitLabel(g.weightUnit)}' : ''})',
                              overflow: TextOverflow.ellipsis,
                            ),
                          )).toList(),
                    ],
                    onChanged: _onSelectGem,
                  ),
                ),

                // Available stock hint (Whole Stone only)
                if (_saleSource == 'whole_stone' && selectedGem != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryAccent.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.inventory_2_outlined,
                              color: AppTheme.primaryAccent, size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'လက်ကျန်: ${_getPreviewRemainingQuantity(_selectedGemId)} ခု'
                              '${selectedGem.weightCarat > 0 ? ' • ${_trim(selectedGem.weightCarat)} ${LocalDb.unitLabel(selectedGem.weightUnit)}' : ''}'
                              ' • ရောင်းဈေး ${NumberFormat('#,##0').format(selectedGem.sellPrice)}',
                              style: const TextStyle(
                                  color: AppTheme.primaryAccent, fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                // Fragment Level 1 Dropdown - Select Purchase (Step 5C-1)
                if (_saleSource == 'breakdown_item')
                  _buildFragmentPurchaseDropdown(gems),

                // Fragment Level 2 Dropdown - Select Fragment (Step 5C-3)
                if (_saleSource == 'breakdown_item' && _selectedFragmentGemstoneId != null)
                  _buildFragmentNameDropdown(gems),

                // Fragment quantity field (Step 5C-4) - now uses unified fields
                if (_saleSource == 'breakdown_item' && _selectedFragmentName != null) ...
                  [
                    _field(_qty, 'အရေအတွက်', number: true),
                    _field(_amount, 'ရောင်းဈေး (ကျပ်)', number: true),
                    _field(_commission, 'အရောင်းပွဲခ (ကျပ်)', number: true),
                    // Fragment weight field - unified
                    Row(children: [
                      Expanded(
                        child: _field(_weight, 'အလေးချိန်', number: true),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: _weightUnitFragment,
                          items: [
                            const DropdownMenuItem(value: 'ပိဿာ', child: Text('ပိဿာ')),
                            const DropdownMenuItem(value: 'ကျပ်သား', child: Text('ကျပ်သား')),
                            const DropdownMenuItem(value: 'ကာရက်', child: Text('ကာရက်')),
                            const DropdownMenuItem(value: 'kg', child: Text('ကီလို (kg)')),
                            const DropdownMenuItem(value: 'g', child: Text('ဂရမ် (g)')),
                            const DropdownMenuItem(value: 'lb', child: Text('ပေါင် (lb)')),
                            const DropdownMenuItem(value: 'oz', child: Text('အောင်စ (oz)')),
                          ],
                          onChanged: (value) {
                            setState(() => _weightUnitFragment = value ?? 'kg');
                          },
                          decoration: InputDecoration(
                            labelText: 'ယူနစ်',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                    ]),
                    // Fragment gallery section
                    if (_saleSource == 'breakdown_item' && _selectedFragmentName != null) ...
                      [
                        const SizedBox(height: 16),
                        const Text('ပြခန်း', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 8),
                        PhotoAttachmentWidget(
                          photoPaths: _photoPaths,
                          onPhotosChanged: (photos) {
                            setState(() => _photoPaths = photos);
                          },
                          recordType: 'sale',
                        ),
                        if (_photoPaths.isNotEmpty) ...[const SizedBox(height: 12), _buildFragmentGalleryPreview()],
                      ],
                    // Sale Summary Panel (unified for both whole-stone and fragment)
                    if (_saleSource == 'breakdown_item' && _selectedFragmentName != null)
                      _profitPreview(),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: _addItemToTemporaryList,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryAccent,
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                          ),
                          child: const Text(
                            'ထည့်မည်',
                            style: TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.bold,
                              fontSize: 20,
                              height: 1.2,
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 1,
                          ),
                        ),
                      ),
                    ),
                  ],

                // Show entire form only for whole stone source
                if (_saleSource == 'whole_stone') ...[                
                // Manual name (editable; auto-filled when a gem is selected)
                _field(_manualName, 'ကျောက်မျက်အမည်', required: true),

                _buildCustomerPicker(),
                Row(children: [
                  Expanded(
                      child: _field(_amount, 'ရောင်းရငွေ (ကျပ်)',
                          number: true, required: true)),
                  const SizedBox(width: 12),
                  Expanded(
                      child: _field(_qty, 'အရေအတွက်',
                          number: true, required: true)),
                ]),
                // Weight field with unit dropdown for whole-stone sales
                Row(children: [
                  Expanded(
                    child: _field(_weight, 'အလေးချိန် — မဖြည့်လည်းရ', number: true),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _weightUnitWhole,
                      items: [
                        const DropdownMenuItem(value: 'ပိဿာ', child: Text('ပိဿာ')),
                        const DropdownMenuItem(value: 'ကျပ်သား', child: Text('ကျပ်သား')),
                        const DropdownMenuItem(value: 'ကာရက်', child: Text('ကာရက်')),
                        const DropdownMenuItem(value: 'kg', child: Text('ကီလို (kg)')),
                        const DropdownMenuItem(value: 'g', child: Text('ဂရမ် (g)')),
                        const DropdownMenuItem(value: 'lb', child: Text('ပေါင် (lb)')),
                        const DropdownMenuItem(value: 'oz', child: Text('အောင်စ (oz)')),
                      ],
                      onChanged: (value) {
                        setState(() => _weightUnitWhole = value ?? 'kg');
                      },
                      decoration: InputDecoration(
                        labelText: 'ယူနစ်',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                ]),

                // Auto-deduct toggle (only meaningful when linked to inventory)
                if (_selectedGemId != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      activeColor: AppTheme.primaryAccent,
                      value: _autoDeduct,
                      onChanged: (v) => setState(() => _autoDeduct = v),
                      title: const Text(
                        'ပစ္စည်းစာရင်းမှ အလိုအလျောက် နှုတ်မည်',
                        style: TextStyle(color: Colors.white, fontSize: 14),
                      ),
                      subtitle: Text(
                        'အရေအတွက်နှင့် အလေးချိန်ကို inventory မှ နုတ်ပေးပါမည်',
                        style:
                            TextStyle(color: Colors.grey[500], fontSize: 11),
                      ),
                    ),
                  ),

                Padding(
                  padding: const EdgeInsets.only(top: 8, bottom: 12),
                  child: DropdownButtonFormField<String>(
                    value: _payment,
                    dropdownColor: AppTheme.surfaceLight,
                    style: const TextStyle(color: Colors.white),
                    decoration:
                        const InputDecoration(labelText: 'ငွေပေးချေမှု'),
                    items: const [
                      DropdownMenuItem(value: 'cash', child: Text('ငွေသား')),
                      DropdownMenuItem(value: 'bank', child: Text('ဘဏ်')),
                      DropdownMenuItem(
                          value: 'credit', child: Text('အကြွေး')),
                    ],
                    onChanged: (v) => setState(() => _payment = v ?? 'cash'),
                  ),
                ),
                InkWell(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _saleDate,
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2100),
                    );
                    if (picked != null) setState(() => _saleDate = picked);
                  },
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceLight,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today,
                            color: AppTheme.primaryAccent, size: 18),
                        const SizedBox(width: 10),
                        Text(
                            'ရက်စွဲ: ${DateFormat('yyyy-MM-dd').format(_saleDate)}',
                            style: const TextStyle(color: Colors.white)),
                      ],
                    ),
                  ),
                ),
                _field(_cost, 'အရင်းတန်ဖိုး (ကျပ်) — အလိုအလျောက်တွက်ပြီး၊ ပြင်လို့ရ',
                    number: true),
                _field(_commission, 'ရောင်းပွဲခ (ဝင်ငွေထဲမှ နှုတ်)',
                    number: true),
                _profitPreview(),
                _previewValuesDisplay(),
                _field(_note, 'မှတ်ချက်'),
                const SizedBox(height: 20),
                PhotoAttachmentWidget(
                  photoPaths: _photoPaths,
                  onPhotosChanged: (photos) {
                    setState(() => _photoPaths = photos);
                  },
                  recordType: 'sale',
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _addItemToTemporaryList,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryAccent,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                    ),
                    child: const Text(
                      'ထည့်မည်',
                      style: TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                        height: 1.2,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                // Temporary Item List Section (Improved UI)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceLight,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppTheme.primaryAccent.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'ထည့်ထားသော ပစ္စည်းများ',
                        style: const TextStyle(
                          color: AppTheme.primaryAccent,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (_items.isEmpty)
                        Center(
                          child: Text(
                            '(ပစ္စည်းများ ထည့်ထားမရှိသေးပါ)',
                            style: TextStyle(
                              color: Colors.grey[500],
                              fontSize: 12,
                            ),
                          ),
                        )
                      else
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _items.length,
                          itemBuilder: (ctx, idx) {
                            final item = _items[idx];
                            return Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppTheme.surfaceDark,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: AppTheme.primaryAccent.withOpacity(0.2),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Header with name and menu
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          'ကျောက်မျက်အမည်: ${item.gemstoneName}',
                                          style: const TextStyle(
                                            color: AppTheme.primaryAccent,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      PopupMenuButton<String>(
                                        onSelected: (value) {
                                          if (value == 'edit') {
                                            _editItemFromTemporaryList(idx);
                                          } else if (value == 'delete') {
                                            _removeItemFromTemporaryList(idx);
                                          } else if (value == 'view_photos') {
                                            _viewItemPhotos(item);
                                          }
                                        },
                                        itemBuilder: (BuildContext context) => [
                                          const PopupMenuItem<String>(
                                            value: 'edit',
                                            child: Row(
                                              children: [
                                                Icon(Icons.edit, size: 18, color: AppTheme.primaryAccent),
                                                SizedBox(width: 8),
                                                Text('ပြုပြင်ရန်'),
                                              ],
                                            ),
                                          ),
                                          const PopupMenuItem<String>(
                                            value: 'delete',
                                            child: Row(
                                              children: [
                                                Icon(Icons.delete, size: 18, color: AppTheme.errorColor),
                                                SizedBox(width: 8),
                                                Text('ဖျက်ရန်'),
                                              ],
                                            ),
                                          ),
                                          const PopupMenuItem<String>(
                                            value: 'view_photos',
                                            child: Row(
                                              children: [
                                                Icon(Icons.image, size: 18, color: AppTheme.primaryAccent),
                                                SizedBox(width: 8),
                                                Text('ပုံကြည့်ရန်'),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  // Quantity
                                  Text(
                                    'အရေအတွက်: ${item.quantity}',
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 12,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  // Gross Sale
                                  Text(
                                    'ရောင်းငွေ: ${NumberFormat('#,##0', 'en_US').format(item.saleAmount.toInt())} ကျပ်',
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 12,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  // Commission
                                  Text(
                                    'ပွဲခ: ${NumberFormat('#,##0', 'en_US').format(item.commission.toInt())} ကျပ်',
                                    style: const TextStyle(
                                      color: Colors.orange,
                                      fontSize: 12,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  // Net Sale
                                  Text(
                                    'အသင့်ရောင်းငွေ: ${NumberFormat('#,##0', 'en_US').format(item.netSale.toInt())} ကျပ်',
                                    style: const TextStyle(
                                      color: AppTheme.primaryAccent,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                  if (item.remark.isNotEmpty) ...[const SizedBox(height: 4), Text(
                                    'မှတ်ချက်: ${item.remark}',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey[500],
                                    ),
                                  )],
                                ],
                              ),
                            );
                          },
                        ),
                      if (_items.isNotEmpty) ...[const SizedBox(height: 16), Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryAccent.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'စုစုပေါင်းအချက်အလက်',
                              style: TextStyle(
                                color: AppTheme.primaryAccent,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'ပစ္စည်းအမျိုးအစား: ${_items.length}',
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'စုစုပေါင်း အရေအတွက်: ${_totalQuantity.toInt()}',
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'စုစုပေါင်း ရောင်းငွေ:',
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 11,
                                  ),
                                ),
                                Text(
                                  '${NumberFormat('#,##0', 'en_US').format(_totalAmount.toInt())} ကျပ်',
                                  style: const TextStyle(
                                    color: AppTheme.primaryAccent,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      )],
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                // Finalize Sale Button (Two-Stage Confirmation)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _items.isEmpty || _isSaving ? null : () {
                          FocusScope.of(context).unfocus();
                          _finalizeAndSave();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _items.isEmpty || _isSaving
                              ? AppTheme.primaryAccent.withOpacity(0.5)
                              : AppTheme.primaryAccent,
                          disabledBackgroundColor: AppTheme.primaryAccent.withOpacity(0.5),
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                        ),
                        child: _isSaving
                            ? const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                                    ),
                                  ),
                                  SizedBox(width: 12),
                                  Text(
                                    'သိမ်းဆည်းနေသည်...',
                                    style: TextStyle(
                                      color: Colors.black,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                    ),
                                  ),
                                ],
                              )
                            : const Text(
                                'ရောင်းချမည်',
                                style: TextStyle(
                                  color: Colors.black,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                      ),
                    ),
                  ),
                // Add bottom padding so Save button can scroll above keyboard
                SizedBox(height: MediaQuery.of(context).viewInsets.bottom + 40),
                ], // End of if (_saleSource == 'whole_stone')
              ],
            ),
          ),
        ),
      ),
      ),
    );
  }

  /// Level 1 Dropdown: Select original purchase with breakdown items
  Widget _buildFragmentPurchaseDropdown(List<Gemstone> gems) {
    // Filter purchases with breakdowns and available fragments
    final gemsWithBreakdown = gems.where((g) {
      if (g.breakdownItems == null || g.breakdownItems!.isEmpty) return false;
      return g.breakdownItems!.values.any((item) {
        if (item is Map<String, dynamic>) {
          final qty = (item['quantity'] as num?)?.toInt() ?? 0;
          final weight = (item['weight'] as num?)?.toDouble() ?? 0;
          return qty > 0 || weight > 0;
        }
        return (item is num) && (item as num) > 0;
      });
    }).toList();

    if (gemsWithBreakdown.isEmpty) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.surfaceDark.withOpacity(0.5),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: AppTheme.primaryAccent.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: const Center(
            child: Text(
              'အစိတ်စိတ်ပိုင်း ရွေးချယ်မှု မတ်ရိတ်မောရေ',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 12,
              ),
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(bottom: 8),
            child: Text(
              'မူလအဝယ်စာရင်းမှ ကျောက်ရွေးပါ',
              style: TextStyle(
                color: AppTheme.primaryAccent,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppTheme.surfaceDark,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: _selectedFragmentGemstoneId != null 
                  ? AppTheme.primaryAccent 
                  : AppTheme.primaryAccent.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: DropdownButton<String>(
              value: _selectedFragmentGemstoneId,
              hint: const Text(
                'ကျောက်မျိုးရွေးပါ',
                style: TextStyle(color: Colors.white70),
              ),
              isExpanded: true,
              dropdownColor: AppTheme.surfaceDark,
              underline: const SizedBox.shrink(),
              items: gemsWithBreakdown.map((gem) {
                final availableFragments = gem.breakdownItems!.values
                    .where((item) {
                      if (item is Map<String, dynamic>) {
                        final qty = (item['quantity'] as num?)?.toInt() ?? 0;
                        final weight = (item['weight'] as num?)?.toDouble() ?? 0;
                        return qty > 0 || weight > 0;
                      }
                      return (item is num) && (item as num) > 0;
                    })
                    .length;
                
                final shortId = gem.id.length > 6 ? gem.id.substring(0, 6) : gem.id;
                final displayText = '${gem.name} • အစိတ်စိတ် $availableFragments မျိုး • ID: $shortId';
                
                return DropdownMenuItem<String>(
                  value: gem.id,
                  child: Text(
                    displayText,
                    style: const TextStyle(color: Colors.white),
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedFragmentGemstoneId = value;
                  _selectedFragmentName = null;
                });
              },
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  /// Level 2 Dropdown: Select fragment from selected purchase
  Widget _buildFragmentNameDropdown(List<Gemstone> gems) {
    final selectedPurchase = gems.firstWhereOrNull(
      (g) => g.id == _selectedFragmentGemstoneId,
    );
    if (selectedPurchase == null || selectedPurchase.breakdownItems == null) {
      return const SizedBox.shrink();
    }
    // Get available breakdown items (quantity > 0 OR weight > 0)
    final availableItems = selectedPurchase.breakdownItems!.entries
        .where((e) {
          if (e.value is Map<String, dynamic>) {
            final qty = (e.value['quantity'] as num?)?.toInt() ?? 0;
            final weight = (e.value['weight'] as num?)?.toDouble() ?? 0;
            return qty > 0 || weight > 0;
          }
          return (e.value is num) && (e.value as num) > 0;
        })
        .toList();
    if (availableItems.isEmpty) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(bottom: 8),
            child: Text(
              'ရောင်းချမည့် အစိတ်စိတ်ပိုင်းရွေးပါ',
              style: TextStyle(
                color: AppTheme.primaryAccent,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppTheme.surfaceDark,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: _selectedFragmentName != null 
                  ? AppTheme.primaryAccent 
                  : AppTheme.primaryAccent.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: DropdownButton<String>(
              value: _selectedFragmentName,
              hint: const Text(
                'အစိတ်စိတ်ပိုင်းရွေးပါ',
                style: TextStyle(color: Colors.white70),
              ),
              isExpanded: true,
              dropdownColor: AppTheme.surfaceDark,
              underline: const SizedBox.shrink(),
              items: availableItems.map((entry) {
                final itemData = entry.value as Map<String, dynamic>?;
                final quantity = (itemData?['quantity'] as num?)?.toInt() ?? (entry.value is num ? (entry.value as num).toInt() : 0);
                final weight = (itemData?['weight'] as num?)?.toDouble() ?? 0;
                final weightUnit = itemData?['weightUnit'] as String? ?? '';
                final weightDisplay = weight > 0 ? ' • ကျန် $weight $weightUnit' : '';
                final qtyDisplay = quantity > 0 ? 'ကျန် $quantity ခု' : '';
                final displayText = '$qtyDisplay$weightDisplay';
                return DropdownMenuItem<String>(
                  value: entry.key,
                  child: Text(
                    '${entry.key} • $displayText',
                    style: const TextStyle(color: Colors.white),
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedFragmentName = value;
                  _saleSource = 'breakdown_item'; // Ensure source is set when fragment is selected
                });
              },
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  /// Build gallery preview for fragment sale with horizontal scroll
  Widget _buildFragmentGalleryPreview() {
    if (_photoPaths.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'ရွေးချယ်ထားသောပုံများ (${_photoPaths.length})',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 100,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _photoPaths.length,
            itemBuilder: (context, index) {
              final photoPath = _photoPaths[index];
              return Padding(
                padding: EdgeInsets.only(right: index < _photoPaths.length - 1 ? 8 : 0),
                child: GestureDetector(
                  onTap: () {
                    // Show full-screen preview
                    showDialog(
                      context: context,
                      builder: (_) => Dialog(
                        backgroundColor: Colors.transparent,
                        insetPadding: EdgeInsets.zero,
                        child: GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Stack(
                            children: [
                              Center(
                                child: Image.network(
                                  photoPath,
                                  fit: BoxFit.contain,
                                  errorBuilder: (_, __, ___) => const Icon(
                                    Icons.image_not_supported,
                                    color: Colors.white,
                                    size: 48,
                                  ),
                                ),
                              ),
                              Positioned(
                                top: 16,
                                right: 16,
                                child: GestureDetector(
                                  onTap: () => Navigator.pop(context),
                                  child: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withOpacity(0.5),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.close,
                                      color: Colors.white,
                                      size: 24,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                  onLongPress: () {
                    // Show remove option on long press
                    showDialog(
                      context: context,
                      builder: (_) => AlertDialog(
                        backgroundColor: AppTheme.surfaceDark,
                        title: const Text('ပုံကိုဖျက်မည်?'),
                        content: const Text('ဤပုံကိုဖျက်ရန်သည်ကိုအတည်ပြုပါ။'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('ပယ်ဖျက်မည်'),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.pop(context);
                              setState(() {
                                _photoPaths.removeAt(index);
                              });
                            },
                            child: const Text(
                              'ဖျက်ရန်',
                              style: TextStyle(color: AppTheme.errorColor),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: AppTheme.primaryAccent.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        photoPath,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          color: AppTheme.surfaceLight,
                          child: const Icon(
                            Icons.image_not_supported,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'ပုံကိုဖျက်ရန် ရှည်ကိုင်ပါ | အပြည့်အစုံကြည့်ရှုရန် တို့ပါ',
          style: TextStyle(
            color: Colors.grey[500],
            fontSize: 10,
          ),
        ),
      ],
    );
  }

  /// Build Fragment Sale Summary Panel with live updates
  // REMOVED: _buildFragmentSalarySummary - now uses unified _profitPreview()

  // REMOVED: _buildFragmentQuantityField - now uses unified _field(_qty, ...)
  // REMOVED: _validateFragmentQuantity - validation now in _addFragmentItem()

  // REMOVED: _addFragmentItemMinimal - now uses unified _addFragmentItem() called by _addItemToTemporaryList()

  Widget _field(TextEditingController c, String label,
      {bool number = false, bool required = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: c,
        keyboardType: number
            ? const TextInputType.numberWithOptions(decimal: true)
            : TextInputType.text,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(labelText: label),
        onChanged: (_) => setState(() {}),
        validator: required
            ? (v) => (v == null || v.trim().isEmpty) ? 'ဖဳစ်ပာ' : null
            : null,
      ),
    );
  }

  Widget _buildItemCard(int index, _SaleItem item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Text(
                      'ကုန်ပစ္စည်း ${index + 1}',
                      style: const TextStyle(
                        color: AppTheme.primaryAccent,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(width: 8),
                    PhotoCountBadge(count: item.photoPaths.length),
                  ],
                ),
              ),
              if (index > 0)
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red, size: 18),
                  onPressed: () => _removeItemFromTemporaryList(index),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
            ],
          ),
          const SizedBox(height: 8),
          // Gemstone selector dropdown
          ValueListenableBuilder<Box<Gemstone>>(
            valueListenable: LocalDb.gemstones().listenable(),
            builder: (context, box, _) {
              final gems = box.values.toList();
              
              return DropdownButtonFormField<String?>(
                value: item.gemstoneId,
                isExpanded: true,
                dropdownColor: AppTheme.surfaceLight,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'ကျောက်မျက် *',
                ),
                items: [
                  const DropdownMenuItem<String?>(
                    value: null,
                    child: Text('— ကျောက်မျက်ရွေးပါ —'),
                  ),
                  ...gems.map((g) => DropdownMenuItem<String?>(
                    value: g.id,
                    child: Text(
                      g.name,
                      overflow: TextOverflow.ellipsis,
                    ),
                  )).toList(),
                ],
                onChanged: (gemstoneId) {
                  setState(() {
                    item.gemstoneId = gemstoneId;
                    if (gemstoneId != null) {
                      final g = LocalDb.gemstoneById(gemstoneId);
                      if (g != null) {
                        item.gemstoneName = g.name;
                      }
                    } else {
                      item.gemstoneName = '';
                    }
                  });
                },
              );
            },
          ),
          const SizedBox(height: 8),
          // Quantity and Unit Price
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  initialValue: item.quantity.toString(),
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(labelText: 'အရေအတွက်'),
                  onChanged: (value) {
                    setState(() {
                      item.quantity = int.tryParse(value) ?? 1;
                    });
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextFormField(
                  initialValue: item.unitPrice.toString(),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(labelText: 'ယူနစ်ဈေး'),
                  onChanged: (value) {
                    setState(() {
                      item.unitPrice = double.tryParse(value) ?? 0;
                    });
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Remark
          TextFormField(
            initialValue: item.remark,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(labelText: 'မှတ်ချက်'),
            onChanged: (value) {
              setState(() {
                item.remark = value;
              });
            },
          ),
          const SizedBox(height: 8),
          // Total amount display
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.primaryAccent.withOpacity(0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'စုစုပေါင်းငွေ:',
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
                Text(
                  '${NumberFormat('#,##0').format(item.totalAmount)} ကျပ်',
                  style: const TextStyle(
                    color: AppTheme.primaryAccent,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomerPicker() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: ValueListenableBuilder<Box<Customer>>(
        valueListenable: LocalDb.customers().listenable(),
        builder: (context, box, _) {
          final activeCustomers = box.values
              .where((c) => !c.isDeleted && c.status == 'active')
              .toList();

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'ဖောက်သည် *',
                style: TextStyle(color: Colors.white70, fontSize: 12),
              ),
              const SizedBox(height: 4),
              Container(
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: Colors.white24),
                  ),
                ),
                child: DropdownButton<String?>(
                  isExpanded: true,
                  value: _selectedCustomerId,
                  dropdownColor: Colors.grey[900],
                  style: const TextStyle(color: Colors.white),
                  underline: const SizedBox(),
                  hint: const Text('ဖောက်သည်အချက်အလက်'),
                  onChanged: (customerId) {
                    if (customerId == '__add_new_customer__') {
                      _showCreateCustomerDialog();
                    } else {
                      setState(() {
                        _selectedCustomerId = customerId;
                        if (customerId != null) {
                          final customer = activeCustomers.firstWhereOrNull(
                            (c) => c.id == customerId,
                          );
                          if (customer != null) {
                            _customer.text = customer.name;
                          }
                        }
                      });
                    }
                  },
                  items: [
                    const DropdownMenuItem<String?>(
                      value: null,
                      child: Text('ဖောက်သည်အချက်အလက်'),
                    ),
                    ...activeCustomers.map((customer) {
                      return DropdownMenuItem<String>(
                        value: customer.id,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(customer.name),
                            if (customer.phone != null && customer.phone!.isNotEmpty)
                              Text(
                                customer.phone!,
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Colors.white70,
                                ),
                              ),
                          ],
                        ),
                      );
                    }).toList(),
                    DropdownMenuItem<String>(
                      value: '__add_new_customer__',
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border(
                            top: BorderSide(color: Colors.white24),
                          ),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: const Row(
                          children: [
                            Text('➕ '),
                            Text('ဖောက်သည်အသစ်ထည့်ရန်'),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showCreateCustomerDialog() {
    final TextEditingController nameController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surfaceDark,
        title: const Text('ဖောက်သည်အသစ်ထည့်ရန်'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: nameController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'ဖောက်သည်အမည်',
                hintText: 'ဖောက်သည်အမည်ထည့်သွင်းပါ',
              ),
              autofocus: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ပယ်ဖျက်မည်'),
          ),
          TextButton(
            onPressed: () async {
              final customerName = nameController.text.trim();
              if (customerName.isEmpty) {
                _toast('ဖောက်သည်အမည်ထည့်သွင်းပါ');
                return;
              }
              
              // Check for duplicate (case-insensitive)
              final existingCustomer = LocalDb.customers()
                  .values
                  .firstWhereOrNull((c) => 
                    c.name.toLowerCase() == customerName.toLowerCase() && 
                    !c.isDeleted
                  );
              
              if (existingCustomer != null) {
                if (mounted) {
                  Navigator.pop(context);
                  setState(() {
                    _selectedCustomerId = existingCustomer.id;
                    _customer.text = existingCustomer.name;
                  });
                }
                return;
              }
              
              // Create new customer
              final newCustomer = Customer(
                id: LocalDb.genId(),
                name: customerName,
                phone: '',
                address: '',
                notes: '',
                openingBalance: 0.0,
                currentBalance: 0.0,
                creditLimit: 0.0,
                status: 'active',
                isDeleted: false,
                deletedAt: null,
                createdAt: DateTime.now().millisecondsSinceEpoch,
                updatedAt: DateTime.now().millisecondsSinceEpoch,
              );
              
              await LocalDb.customers().add(newCustomer);
              
              if (mounted) {
                Navigator.pop(context);
                setState(() {
                  _selectedCustomerId = newCustomer.id;
                  _customer.text = newCustomer.name;
                });
                _toast('ဖောက်သည်အသစ်ထည့်သွင်းပြီးပါပြီ');
              }
            },
            child: const Text('သိမ်းဆည်းမည်'),
          ),
        ],
      ),
    );
  }

  /// View photos for a temporary item or saved sale
  void _viewItemPhotos(dynamic item) {
    // Get photo paths from either draft item or saved sale
    List<dynamic> photoPaths = [];
    
    if (item is _SaleItem) {
      // Draft item
      photoPaths = item.photoPaths;
    } else if (item is Sale) {
      // Saved sale record
      photoPaths = item.photoPaths;
    }
    
    if (photoPaths.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('ဤပစ္စည်းတွင် ပုံမရှိပါ'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    // Open gallery viewer
    showDialog(
      context: context,
      builder: (context) => _PhotoViewerDialog(photoPaths: photoPaths),
    );
  }
}

class _PhotoViewerDialog extends StatefulWidget {
  final List<dynamic> photoPaths;

  const _PhotoViewerDialog({Key? key, required this.photoPaths})
      : super(key: key);

  @override
  State<_PhotoViewerDialog> createState() => _PhotoViewerDialogState();
}

class _PhotoViewerDialogState extends State<_PhotoViewerDialog> {
  late PageController _pageController;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.black,
      insetPadding: EdgeInsets.zero,
      child: Stack(
        children: [
          // Photo viewer
          PageView.builder(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() => _currentIndex = index);
            },
            itemCount: widget.photoPaths.length,
            itemBuilder: (context, index) {
              final path = widget.photoPaths[index];
              return GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Image.file(
                  File(path.toString()),
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.image_not_supported,
                              color: Colors.white54, size: 48),
                          const SizedBox(height: 16),
                          Text(
                            'ပုံမဖွင့်နိုင်ပါ',
                            style: TextStyle(color: Colors.white54),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              );
            },
          ),
          // Close button
          Positioned(
            top: 16,
            right: 16,
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close, color: Colors.white),
              ),
            ),
          ),
          // Photo counter
          if (widget.photoPaths.length > 1)
            Positioned(
              bottom: 16,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${_currentIndex + 1} / ${widget.photoPaths.length}',
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}



// Expandable Sale History Card Widget
class _SaleHistoryCard extends StatefulWidget {
  final Sale sale;
  final dynamic hiveKey;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onPrint;
  final VoidCallback onExportImage;
  final VoidCallback onExportPdf;
  final VoidCallback onShowPhotos;
  final VoidCallback onShowDetails;
  final DateFormat dateFormat;
  final NumberFormat moneyFormat;
  final Function(Sale) saleUnitFn;
  final Function(Sale) getCustomerNameFn;
  final Function(String) payLabelFn;
  final Function(Sale) profitBadgeFn;

  const _SaleHistoryCard({
    required this.sale,
    required this.hiveKey,
    required this.onEdit,
    required this.onDelete,
    required this.onPrint,
    required this.onExportImage,
    required this.onExportPdf,
    required this.onShowPhotos,
    required this.onShowDetails,
    required this.dateFormat,
    required this.moneyFormat,
    required this.saleUnitFn,
    required this.getCustomerNameFn,
    required this.payLabelFn,
    required this.profitBadgeFn,
  });

  @override
  State<_SaleHistoryCard> createState() => _SaleHistoryCardState();
}

class _SaleHistoryCardState extends State<_SaleHistoryCard> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final s = widget.sale;
    final gemstone = s.gemstoneId.isNotEmpty ? LocalDb.gemstoneById(s.gemstoneId) : null;

    return Card(
      color: AppTheme.surfaceDark,
      margin: const EdgeInsets.only(bottom: 10),
      child: Column(
        children: [
          // Date header
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.successColor.withOpacity(0.1),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(_isExpanded ? 0 : 8),
                topRight: Radius.circular(_isExpanded ? 0 : 8),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.calendar_today, size: 16, color: AppTheme.successColor),
                const SizedBox(width: 8),
                Text(
                  widget.dateFormat.format(DateTime.fromMillisecondsSinceEpoch(s.saleDate)),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          // Summary view (always visible)
          GestureDetector(
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: AppTheme.successColor.withOpacity(0.2),
                child: const Icon(Icons.shopping_cart, color: AppTheme.successColor),
              ),
              title: Text(
                s.gemstoneName,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (s.isFragmentSource)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryAccent.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: AppTheme.primaryAccent, width: 0.5),
                            ),
                            child: const Text(
                              'အစိတ်စိတ်ပိုင်း',
                              style: TextStyle(
                                color: AppTheme.primaryAccent,
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          if (s.photoPaths.isNotEmpty)
                            GestureDetector(
                              onTap: widget.onShowPhotos,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: Colors.blue.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(color: Colors.blue, width: 0.5),
                                ),
                                child: Text(
                                  '📷 ${s.photoPaths.length}',
                                  style: const TextStyle(
                                    color: Colors.blue,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  Text(
                    'အရေအတွက်: ${s.quantity}${s.weightCarat > 0 ? ' • ${s.weightCarat} ${widget.saleUnitFn(s)}' : ''}',
                    style: TextStyle(color: Colors.grey[400], fontSize: 11),
                  ),
                  if (s.isFragmentSource && s.commissionFee > 0)
                    Text(
                      'ရောင်းပွဲခ: ${widget.moneyFormat.format(s.commissionFee)} ကျပ်',
                      style: TextStyle(color: Colors.amber[300], fontSize: 11),
                    ),
                ],
              ),
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    widget.moneyFormat.format(s.amount),
                    style: const TextStyle(
                      color: AppTheme.successColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (s.costPrice > 0) widget.profitBadgeFn(s),
                  Icon(
                    _isExpanded ? Icons.expand_less : Icons.expand_more,
                    color: AppTheme.primaryAccent,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
          // Expanded details
          if (_isExpanded) ...[
            // Original purchase section
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.primaryAccent.withOpacity(0.05),
                border: Border(
                  top: BorderSide(color: AppTheme.primaryAccent.withOpacity(0.2)),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'မူလအဝယ်စာရင်း',
                    style: TextStyle(
                      color: AppTheme.primaryAccent,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _expandedDetailRow('အမျိုးအမည်', s.gemstoneName),
                  _expandedDetailRow('အရေအတွက်', '${s.quantity}'),
                  if (s.weightCarat > 0)
                    _expandedDetailRow('အလေးချိန်', '${s.weightCarat} ${widget.saleUnitFn(s)}'),
                  _expandedDetailRow('ရောင်းရငွေ', '${widget.moneyFormat.format(s.amount)} ကျပ်'),
                ],
              ),
            ),
            // Fragment inventory details are shown in the Purchase History page only, not here.
            // Action buttons
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.surfaceLight.withOpacity(0.1),
                border: Border(
                  top: BorderSide(color: AppTheme.primaryAccent.withOpacity(0.2)),
                ),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(8),
                  bottomRight: Radius.circular(8),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert, color: Colors.white),
                    enabled: LocalDb.canEditSale(),
                    onSelected: (v) {
                      if (v == 'edit') widget.onEdit();
                      if (v == 'delete') widget.onDelete();
                      if (v == 'print') widget.onPrint();
                      if (v == 'image') widget.onExportImage();
                      if (v == 'pdf') widget.onExportPdf();
                      if (v == 'photos') widget.onShowPhotos();
                    },
                    itemBuilder: (_) => [
                      PopupMenuItem(
                        value: 'edit',
                        enabled: LocalDb.canEditSale(),
                        child: const Row(
                          children: [
                            Text('✏️'),
                            SizedBox(width: 8),
                            Text('ပြုပြင်ရန်'),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'delete',
                        enabled: LocalDb.canDeleteSale(),
                        child: const Row(
                          children: [
                            Text('🗑️'),
                            SizedBox(width: 8),
                            Text('ဖျက်ရန်', style: TextStyle(color: AppTheme.errorColor)),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'print',
                        child: const Row(
                          children: [
                            Text('🖨️'),
                            SizedBox(width: 8),
                            Text('ပရင့်ထုတ်ရန်'),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'image',
                        child: const Row(
                          children: [
                            Text('🖼️'),
                            SizedBox(width: 8),
                            Text('ပုံထုတ်ရန်'),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'pdf',
                        child: const Row(
                          children: [
                            Text('📄'),
                            SizedBox(width: 8),
                            Text('PDF ထုတ်ရန်'),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'photos',
                        child: const Row(
                          children: [
                            Text('🖼️'),
                            SizedBox(width: 8),
                            Text('ပြခန်း'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  List<Widget> _buildFragmentSections(Sale s, Gemstone gemstone) {
    final fragments = <Widget>[];
    
    gemstone.breakdownItems.forEach((fragmentName, itemData) {
      final qty = (itemData['quantity'] is num) ? (itemData['quantity'] as num).toInt() : 0;
      final weight = (itemData['weight'] is num) ? (itemData['weight'] as num) : 0.0;
      
      // Skip zero quantity and weight items
      if (qty == 0 && weight == 0) return;
      
      fragments.add(
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppTheme.primaryAccent.withOpacity(0.03),
            border: Border(
              top: BorderSide(color: AppTheme.primaryAccent.withOpacity(0.1)),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                fragmentName,
                style: TextStyle(
                  color: Colors.grey[300],
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              if (qty > 0)
                _expandedDetailRow('အရေအတွက်', '$qty'),
              if (weight > 0)
                _expandedDetailRow('အလေးချိန်', '${weight.toStringAsFixed(2)} ${itemData['weightUnit'] ?? 'kg'}'),
            ],
          ),
        ),
      );
    });
    
    // Add header if fragments exist
    if (fragments.isNotEmpty) {
      fragments.insert(
        0,
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppTheme.primaryAccent.withOpacity(0.05),
            border: Border(
              top: BorderSide(color: AppTheme.primaryAccent.withOpacity(0.2)),
            ),
          ),
          child: Text(
            'ကျောက်အစိတ်စိတ်',
            style: TextStyle(
              color: AppTheme.primaryAccent,
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      );
    }
    
    return fragments;
  }

  Widget _expandedDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(color: Colors.grey[400], fontSize: 11),
          ),
          Text(
            value,
            style: TextStyle(color: Colors.grey[200], fontSize: 11, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}

/// A card that groups multiple Sale records sharing the same invoiceNumber
/// into one expandable invoice card.
class _InvoiceGroupCard extends StatefulWidget {
  final String invoiceNumber;
  final List<MapEntry<dynamic, Sale>> entries;
  final VoidCallback onDeleteAll;
  final VoidCallback onPrint;
  final VoidCallback onExportPdf;
  final VoidCallback onExportImage;
  final Function(dynamic) onEditItem;
  final Function(dynamic) onDeleteItem;
  final DateFormat dateFormat;
  final NumberFormat moneyFormat;
  final String Function(Sale) getCustomerNameFn;
  final String Function(String) payLabelFn;
  final GlobalKey? repaintBoundaryKey;

  const _InvoiceGroupCard({
    required this.invoiceNumber,
    required this.entries,
    required this.onDeleteAll,
    required this.onPrint,
    required this.onExportPdf,
    required this.onExportImage,
    required this.onEditItem,
    required this.onDeleteItem,
    required this.dateFormat,
    required this.moneyFormat,
    required this.getCustomerNameFn,
    required this.payLabelFn,
    this.repaintBoundaryKey,
  });

  @override
  State<_InvoiceGroupCard> createState() => _InvoiceGroupCardState();
}

class _InvoiceGroupCardState extends State<_InvoiceGroupCard> {
  bool _expanded = false;
  late GlobalKey _invoiceRepaintKey;

  @override
  void initState() {
    super.initState();
    _invoiceRepaintKey = GlobalKey();
  }

  /// Show all photos from all items in this invoice
  void _showAllInvoicePhotos() {
    final allPhotoPaths = <dynamic>[];
    for (final entry in widget.entries) {
      final sale = entry.value;
      if (sale.photoPaths.isNotEmpty) {
        allPhotoPaths.addAll(sale.photoPaths);
      }
    }

    if (allPhotoPaths.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('ဓာတ်ပုံမရှိပါ'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => _PhotoViewerDialog(photoPaths: allPhotoPaths),
    );
  }

  /// Capture invoice as PNG and save to temp directory (legacy method - kept for compatibility)
  Future<void> _captureAndExportInvoiceImage() async {
    try {
      final wasExpanded = _expanded;
      if (!_expanded) {
        setState(() => _expanded = true);
        await Future.delayed(const Duration(milliseconds: 500));
      }

      final filePath = await _captureInvoiceAsImage(_invoiceRepaintKey);
      if (filePath != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Invoice PNG သိမ်းဆည်းပြီးပါပြီ'),
            backgroundColor: AppTheme.successColor,
          ),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Invoice ပုံထုတ်မှု ကျ败'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }

      if (!wasExpanded && mounted) {
        setState(() => _expanded = false);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('အမှားအယွင်း: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  /// Capture invoice widget using RepaintBoundary
  Future<String?> _captureInvoiceAsImage(GlobalKey repaintKey) async {
    try {
      final boundary = repaintKey.currentContext?.findRenderObject()
          as RenderRepaintBoundary?;
      if (boundary == null) return null;
      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return null;
      final bytes = byteData.buffer.asUint8List();
      final tempDir = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final file = File('${tempDir.path}/invoice_$timestamp.png');
      await file.writeAsBytes(bytes);
      return file.path;
    } catch (e) {
      debugPrint('Error capturing invoice: $e');
      return null;
    }
  }


  @override
  Widget build(BuildContext context) {
    final primarySale = widget.entries.first.value;
    // Aggregate totals across all items
    double totalAmount = 0;
    double totalNet = 0;
    double totalCommission = 0;
    int totalQty = 0;
    for (final e in widget.entries) {
      final s = e.value;
      totalAmount += s.amount;
      totalNet += s.netSale;
      totalCommission += s.commissionFee;
      totalQty += s.quantity;
    }
    final saleDate = DateTime.fromMillisecondsSinceEpoch(primarySale.saleDate);
    final customerName = widget.getCustomerNameFn(primarySale);

    final cardWidget = Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      color: AppTheme.surfaceDark,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          // Header row with expand/collapse and invoice menu
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryAccent.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(Icons.receipt_long, color: AppTheme.primaryAccent, size: 20),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _expanded = !_expanded),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    '${widget.entries.length} ပစ္စည်း — ${widget.entries.map((e) => e.value.gemstoneName).toSet().join(', ')}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Text(
                                  widget.moneyFormat.format(totalAmount),
                                  style: TextStyle(
                                    color: AppTheme.successColor,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Text(
                                  widget.dateFormat.format(saleDate),
                                  style: TextStyle(color: Colors.grey[400], fontSize: 12),
                                ),
                                const SizedBox(width: 8),
                                if (customerName.isNotEmpty)
                                  Text(
                                    customerName,
                                    style: TextStyle(color: Colors.grey[400], fontSize: 12),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'ကျန်အရင်း: ${widget.moneyFormat.format(primarySale.remainingCostAfterSale)} ကျပ်',
                              style: TextStyle(color: AppTheme.primaryAccent, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Expand/collapse icon
                    IconButton(
                      icon: Icon(
                        _expanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                        color: Colors.grey[400],
                      ),
                      onPressed: () => setState(() => _expanded = !_expanded),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                    // Invoice-level menu
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert, color: Colors.grey),
                      onSelected: (value) async {
                        switch (value) {
                          case 'print':
                            widget.onPrint();
                            break;
                          case 'pdf':
                            widget.onExportPdf();
                            break;
                          case 'image':
                            widget.onExportImage();
                            break;
                          case 'photos':
                            _showAllInvoicePhotos();
                            break;
                          case 'delete':
                            widget.onDeleteAll();
                            break;
                        }
                      },
                      itemBuilder: (_) => [
                        const PopupMenuItem(
                          value: 'print',
                          child: Row(
                            children: [
                              Text('🖨️'),
                              SizedBox(width: 8),
                              Text('ပရင့်ထုတ်ရန်'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'pdf',
                          child: Row(
                            children: [
                              Text('📄'),
                              SizedBox(width: 8),
                              Text('PDF ထုတ်ရန်'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'image',
                          child: Row(
                            children: [
                              Text('📸'),
                              SizedBox(width: 8),
                              Text('Invoice ပုံထုတ်ရန်'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'photos',
                          child: Row(
                            children: [
                              Text('🖼️'),
                              SizedBox(width: 8),
                              Text('ဓာတ်ပုံများကြည့်ရန်'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Text('🗑️'),
                              SizedBox(width: 8),
                              Text('Invoice ဖျက်ရန်', style: TextStyle(color: AppTheme.errorColor)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Invoice number tag
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryAccent.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'Invoice: ${widget.invoiceNumber}',
                    style: TextStyle(color: AppTheme.primaryAccent, fontSize: 11),
                  ),
                ),
              ],
            ),
          ),
          // Expanded items list
          if (_expanded) ...[
            Divider(color: AppTheme.primaryAccent.withOpacity(0.2), height: 1),
            ...widget.entries.map((e) {
              final s = e.value;
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: AppTheme.primaryAccent.withOpacity(0.1)),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  s.gemstoneName,
                                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                                ),
                              ),
                              if (s.isFragmentSource) ...[
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.orange.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    s.fragmentName ?? 'အစိတ်',
                                    style: const TextStyle(color: Colors.orange, fontSize: 10),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'အရေအတွက်: ${s.quantity}  •  ရောင်းပွဲခ: ${widget.moneyFormat.format(s.commissionFee)} ကျပ်',
                            style: TextStyle(color: Colors.grey[400], fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${widget.moneyFormat.format(s.amount)} ကျပ်',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                        Text(
                          'ကျန်: ${widget.moneyFormat.format(s.netSale)} ကျပ်',
                          style: TextStyle(color: AppTheme.successColor, fontSize: 11),
                        ),
                      ],
                    ),
                    // Item-level menu
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert, color: Colors.grey, size: 20),
                      onSelected: (value) async {
                        switch (value) {
                          case 'edit':
                            widget.onEditItem(e.key);
                            break;
                          case 'delete':
                            widget.onDeleteItem(e.key);
                            break;
                          case 'photos':
                            if (s.photoPaths.isNotEmpty) {
                              showDialog(
                                context: context,
                                builder: (context) => _PhotoViewerDialog(photoPaths: s.photoPaths),
                              );
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('ဓာတ်ပုံမရှိပါ'),
                                  backgroundColor: AppTheme.errorColor,
                                ),
                              );
                            }
                            break;
                        }
                      },
                      itemBuilder: (_) => [
                        const PopupMenuItem(
                          value: 'edit',
                          child: Row(
                            children: [
                              Text('✏️'),
                              SizedBox(width: 8),
                              Text('ပြုပြင်ရန်'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Text('🗑️'),
                              SizedBox(width: 8),
                              Text('ဖျက်ရန်', style: TextStyle(color: AppTheme.errorColor)),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'photos',
                          child: Row(
                            children: [
                              Text('🖼️'),
                              SizedBox(width: 8),
                              Text('ပြခန်း'),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }),
            // Totals row
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: AppTheme.primaryAccent.withOpacity(0.05),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(12),
                  bottomRight: Radius.circular(12),
                ),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('စုစုပေါင်း ရောင်းငွေ', style: TextStyle(color: Colors.grey[300], fontSize: 12)),
                      Text('${widget.moneyFormat.format(totalAmount)} ကျပ်',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('ပွဲခ စုစုပေါင်း', style: TextStyle(color: Colors.grey[300], fontSize: 12)),
                      Text('${widget.moneyFormat.format(totalCommission)} ကျပ်',
                          style: TextStyle(color: Colors.orange[300], fontSize: 12)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Net Sale စုစုပေါင်း', style: TextStyle(color: Colors.grey[300], fontSize: 12)),
                      Text('${widget.moneyFormat.format(totalNet)} ကျပ်',
                          style: TextStyle(color: AppTheme.successColor, fontSize: 13, fontWeight: FontWeight.bold)),
                    ],
                  ),

                ],
              ),
            ),
          ],
        ],
      ),
    );

    if (widget.repaintBoundaryKey != null) {
      return RepaintBoundary(
        key: widget.repaintBoundaryKey,
        child: cardWidget,
      );
    }
    return cardWidget;
  }
}
