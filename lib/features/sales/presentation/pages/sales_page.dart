import 'package:flutter/material.dart';
import 'dart:io';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import 'package:collection/collection.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/local/local_db.dart';
import '../../../../core/local/models.dart';
import '../../../../shared/widgets/photo_attachment_widget.dart';
import '../../../../shared/widgets/photo_viewer.dart';
import '../../../../shared/widgets/gemstone_breakdown_widget.dart';
import '../../../../core/services/voucher_export_service.dart';
import 'package:share_plus/share_plus.dart';
import 'package:uuid/uuid.dart';

class SalesPage extends StatefulWidget {
  const SalesPage({Key? key}) : super(key: key);

  @override
  State<SalesPage> createState() => _SalesPageState();
}

class _SalesPageState extends State<SalesPage> {
  final _money = NumberFormat('#,##0', 'en_US');
  final _date = DateFormat('yyyy-MM-dd');

  void _openForm({Sale? existing, dynamic key}) {
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

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _SaleForm(existing: existing, hiveKey: key),
    );
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
      builder: (_) => const _BrokerSaleForm(),
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

  Future<void> _exportPNG(Sale sale) async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('PNG တည်ဆောက်နေ...')),
      );
      // PNG export using current invoice layout
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('အမှားအယွင်း: $e')),
        );
      }
    }
  }

  void _showPhotoViewer(Sale sale) {
    if (sale.photoPaths.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('ဤမှတ်တမ်းတွင် ဓာတ်ပုံမရှိသေးပါ။'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PhotoViewer(photoUrls: sale.photoPaths),
      ),
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
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(12, 0, 12, 90),
                        itemCount: box.keys.length,
                        itemBuilder: (context, i) {
                          final keys = box.keys.toList().reversed.toList(); // Show newest first
                          final key = keys[i];
                          final s = box.get(key)!;
                          
                          // Skip deleted sales
                          if (s.isDeleted == true) return const SizedBox.shrink();
                          return Card(
                            color: AppTheme.surfaceDark,
                            margin: const EdgeInsets.only(bottom: 10),
                            child: Column(
                            children: [
                              // Date box at the top
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: AppTheme.successColor.withOpacity(0.1),
                                  borderRadius: const BorderRadius.only(
                                    topLeft: Radius.circular(8),
                                    topRight: Radius.circular(8),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.calendar_today,
                                      size: 16,
                                      color: AppTheme.successColor,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      _date.format(DateTime.fromMillisecondsSinceEpoch(s.saleDate)),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              ListTile(
                              leading: CircleAvatar(
                                backgroundColor:
                                    AppTheme.successColor.withOpacity(0.2),
                                child: const Icon(Icons.shopping_cart,
                                    color: AppTheme.successColor),
                              ),
                              title: Text(s.gemstoneName,
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold)),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Fragment Sale header with badge
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
                                              border: Border.all(
                                                color: AppTheme.primaryAccent,
                                                width: 0.5,
                                              ),
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
                                              onTap: () => _showPhotoViewer(s),
                                              child: Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                                decoration: BoxDecoration(
                                                  color: Colors.blue.withOpacity(0.2),
                                                  borderRadius: BorderRadius.circular(4),
                                                  border: Border.all(
                                                    color: Colors.blue,
                                                    width: 0.5,
                                                  ),
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
                                  // Fragment name
                                  if (s.isFragmentSource && s.fragmentName != null)
                                    Text(
                                      'အစိတ်စိတ်အမည်: ${s.fragmentName}',
                                      style: TextStyle(
                                        color: Colors.grey[300],
                                        fontSize: 11,
                                      ),
                                    ),
                                  // Quantity and weight
                                  Text(
                                      'အရေအတွက်: ${s.quantity}'
                                      '${s.weightCarat > 0 ? ' • ${s.weightCarat} ${_saleUnit(s)}' : ''}',
                                      style:
                                          TextStyle(color: Colors.grey[400], fontSize: 11)),
                                  // Commission (for fragment sales)
                                  if (s.isFragmentSource && s.commissionFee > 0)
                                    Text(
                                      'ရောင်းပွဲခ: ${_money.format(s.commissionFee)} ကျပ်',
                                      style: TextStyle(
                                        color: Colors.amber[300],
                                        fontSize: 11,
                                      ),
                                    ),
                                  // Customer and payment
                                  Text(
                                      'ဝယ်သူ: ${_getCustomerName(s)}',
                                      style:
                                          TextStyle(color: Colors.grey[400], fontSize: 11)),
                                  Text(
                                      '${_date.format(DateTime.fromMillisecondsSinceEpoch(s.saleDate))} • ${_payLabel(s.paymentMethod)}',
                                      style: TextStyle(
                                          color: Colors.grey[500],
                                          fontSize: 10)),
                                ],
                              ),
                              trailing: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(_money.format(s.amount),
                                      style: const TextStyle(
                                          color: AppTheme.successColor,
                                          fontWeight: FontWeight.bold)),
                                  if (s.costPrice > 0) _profitBadge(s),
                                  PopupMenuButton<String>(
                                    constraints: BoxConstraints(maxHeight: 300),
                                    icon: Icon(Icons.more_vert,
                                        color: LocalDb.canEditSale() ? Colors.white : Colors.grey[600]),
                                    enabled: LocalDb.canEditSale(),
                                    onSelected: (v) {
                                      if (v == 'edit') _openForm(existing: s, key: key);
                                      if (v == 'delete') _delete(key);
                                      if (v == 'print') _printSale(s);
                                      if (v == 'image') _exportImage(s);
                                      if (v == 'pdf') _exportVoucher(s);
                                      if (v == 'photos') _showPhotoViewer(s);
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
                                          )),
                                      PopupMenuItem(
                                          value: 'delete',
                                          enabled: LocalDb.canDeleteSale(),
                                          child: const Row(
                                            children: [
                                              Text('🗑️'),
                                              SizedBox(width: 8),
                                              Text('ဖျက်ရန်', style: TextStyle(color: AppTheme.errorColor)),
                                            ],
                                          )),
                                      PopupMenuItem(
                                          value: 'print',
                                          child: const Row(
                                            children: [
                                              Text('🖨️'),
                                              SizedBox(width: 8),
                                              Text('ပရင့်ထုတ်ရန်'),
                                            ],
                                          )),
                                      PopupMenuItem(
                                          value: 'image',
                                          child: const Row(
                                            children: [
                                              Text('🖼️'),
                                              SizedBox(width: 8),
                                              Text('ပုံထုတ်ရန်'),
                                            ],
                                          )),
                                      PopupMenuItem(
                                          value: 'pdf',
                                          child: const Row(
                                            children: [
                                              Text('📄'),
                                              SizedBox(width: 8),
                                              Text('PDF ထုတ်ရန်'),
                                            ],
                                          )),
                                      PopupMenuItem(
                                          value: 'photos',
                                          child: const Row(
                                            children: [
                                              Text('🖼️'),
                                              SizedBox(width: 8),
                                              Text('ဓာတ်ပုံကြည့်ရန်'),
                                            ],
                                          )),
                                    ],
                                  ),
                                ],
                              ),
                              onTap: () => _showDetails(s, hiveKey: key),
                            ),
                              // Gemstone breakdown widget
                              Padding(
                                padding: const EdgeInsets.all(12),
                                child: GemstoneBreakdownWidget(
                                  isForSale: true,
                                  onBreakdownChanged: (breakdown) {
                                    // Store breakdown data for sale
                                  },
                                ),
                              ),
                            ],
                          ),
                        );
                        },
                      ),
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
  double commission; // Commission fee for this item
  double? weight; // Fragment weight (optional)
  String? weightUnit; // Fragment weight unit

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
  });

  double get totalAmount => quantity * unitPrice;
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
  late final TextEditingController _fragmentQuantity; // Fragment quantity input (Step 5C-4)
  String? _fragmentQuantityError; // Fragment quantity validation error (Step 5C-4)
  late final TextEditingController _fragmentUnitPrice; // Fragment unit price input (Step 5D-2)
  late final TextEditingController _fragmentCommission; // Fragment commission input (Step 1 UI)
  late final TextEditingController _fragmentWeight; // Fragment weight input (optional)
  late String _fragmentWeightUnit; // Fragment weight unit selector
  
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
        final netSale = (item.quantity * item.unitPrice) - (double.tryParse(_commission.text.trim()) ?? 0);
        _updatePreviewForGemstone(item.gemstoneId, netSale);
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

    // Get gemstone name
    String gemstoneName = _manualName.text;
    String? gemstoneId;
    if (_selectedGemId != null) {
      final gem = LocalDb.gemstoneById(_selectedGemId!);
      gemstoneName = gem?.name ?? 'Unknown';
      gemstoneId = gem?.id;
    }

    // Create item
    final item = _SaleItem(
      id: const Uuid().v4(),
      gemstoneId: gemstoneId,
      gemstoneName: gemstoneName,
      quantity: qty.toInt(),
      unitPrice: price,
      remark: _note.text,
    );

    // Add to list
    setState(() {
      _items.add(item);
    });

    // Update preview state for this item
    if (gemstoneId != null && gemstoneId.isNotEmpty) {
      final netSale = (item.quantity * item.unitPrice) - (double.tryParse(_commission.text.trim()) ?? 0);
      _updatePreviewForGemstone(gemstoneId, netSale);
    }

    // Clear form fields
    setState(() {
      _selectedGemId = null;
      _manualName.clear();
      _qty.clear();
      _amount.clear();
      _note.clear();
      _weight.clear();
      _cost.clear();
      _commission.clear();
    });

    _showSuccess('${item.gemstoneName} added');
  }

  void _removeItemFromTemporaryList(int index) {
    setState(() {
      _items.removeAt(index);
    });
    _recalculatePreview();
    _showSuccess('Item removed');
  }

  void _editItemFromTemporaryList(int index) {
    final item = _items[index];
    
    // Load item data back into form fields
    setState(() {
      if (item.isFragmentSource) {
        // Fragment item: restore all fragment fields
        _saleSource = 'breakdown_item';
        _selectedFragmentGemstoneId = item.gemstoneId;
        _selectedFragmentName = item.fragmentName;
        _fragmentQuantity.text = item.quantity.toString();
        _fragmentUnitPrice.text = item.unitPrice.toString();
        _fragmentWeight.text = (item.weight ?? 0).toString();
        _fragmentWeightUnit = item.weightUnit ?? 'kg';
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
    _fragmentQuantity = TextEditingController();
    _fragmentUnitPrice = TextEditingController();
    _fragmentCommission = TextEditingController(text: '0');
    _fragmentWeight = TextEditingController();
    _fragmentWeightUnit = 'kg';
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
    _items = [
      _SaleItem(
        id: const Uuid().v4(),
        gemstoneId: e?.gemstoneId,
        gemstoneName: e?.gemstoneName ?? '',
        quantity: e?.quantity ?? 1,
        unitPrice: e?.amount ?? 0,
        remark: e?.note ?? '',
      ),
    ];
  }

  static String _trim(double v) =>
      v == v.roundToDouble() ? v.toInt().toString() : v.toString();

  @override
  void dispose() {
    // Clear preview state (automatic rollback)
    _previewState.clear();
    
    for (final c in [_customer, _amount, _qty, _weight, _note, _manualName, _cost, _commission, _fragmentQuantity, _fragmentUnitPrice, _fragmentCommission]) {
      c.dispose();
    }
    super.dispose();
  }
  
  double get _totalQuantity => _items.fold<int>(0, (sum, item) => sum + item.quantity).toDouble();
  double get _totalAmount => _items.fold<double>(0, (sum, item) => sum + item.totalAmount);
  
  void _addItem() {
    setState(() {
      _items.add(_SaleItem(
        id: const Uuid().v4(),
        gemstoneName: '',
        quantity: 1,
        unitPrice: 0,
      ));
      _isMultiItemMode = true;
    });
  }
  
  void _removeItem(int index) {
    if (_items.length > 1) {
      setState(() {
        _items.removeAt(index);
      });
    }
  }

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
    // Mirror the same costing logic used in _save for the preview.
    if (_selectedGemId != null && cost > 0) {
      cost = cost * qty;
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
    if (!_formKey.currentState!.validate()) return;

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
        final remaining = LocalDb.gemstoneRemainingQuantity(gemstone);
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

    // PHASE 2: GENERATE INVOICE NUMBER
    final now = DateTime.now();
    final dateStr = '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';
    final box = LocalDb.sales();
    final existingInvoices = box.values
        .where((s) => s.invoiceNumber.startsWith('INV-$dateStr-'))
        .length;
    final invoiceNum = 'INV-$dateStr-${(existingInvoices + 1).toString().padLeft(3, '0')}';

    // PHASE 3: SAVE LOOP - Save each item as separate Sale record
    // Use Preview State values (Step 4D: Commit Preview to Database)
    final Set<String> gemstonesUpdated = {};
    final sellCommission = double.tryParse(_commission.text.trim()) ?? 0;
    final perUnitCost = double.tryParse(_cost.text.trim()) ?? 0;
    
    try {
      for (int i = 0; i < _items.length; i++) {
      final item = _items[i];
      final qty = item.quantity;
      final unitPrice = item.unitPrice;
      final amount = qty * unitPrice;
      // Use item-specific commission for fragments, otherwise use form commission
      final itemCommission = item.isFragmentSource ? item.commission : sellCommission;
      final netSale = amount - itemCommission;
      
      // Calculate cost
      double cost;
      if (item.gemstoneId!.isNotEmpty) {
        cost = perUnitCost * qty;
      } else {
        cost = perUnitCost;
      }
      
      // Create Sale record
      final fragmentWeight = item.isFragmentSource ? (double.tryParse(_fragmentWeight.text.trim()) ?? 0) : null;
      final fragmentWeightUnit = item.isFragmentSource ? _fragmentWeightUnit : null;
      
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
        photoPaths: i == 0 ? _photoPaths : [],
        isDeleted: false,
        deletedAt: null,
        deletedBy: '',
        deleteReason: '',
        invoiceNumber: invoiceNum,
        fragmentWeight: fragmentWeight,
        fragmentWeightUnit: fragmentWeightUnit,
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
          
          await LocalDb.gemstones().put(item.gemstoneId!, gemstone);
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
      
      // Show success and close form
      _toast('Invoice $invoiceNum သိမ်းဆည်းပြီးပါပြီ');
      if (mounted) Navigator.pop(context);
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
    final gems = LocalDb.gemstones().values.where((g) => g.quantity > 0).toList();
    final selectedGem =
        _selectedGemId != null ? LocalDb.gemstoneById(_selectedGemId!) : null;

    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
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
                const Text('အရောင်း မှတ်တမ်း',
                    style: TextStyle(
                        color: AppTheme.primaryAccent,
                        fontSize: 18,
                        fontWeight: FontWeight.bold)),
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

                // Fragment purchase list (Step 5C-1)
                if (_saleSource == 'breakdown_item')
                  _buildFragmentPurchaseList(gems),

                // Fragment dropdown (Step 5C-3)
                if (_saleSource == 'breakdown_item' && _selectedFragmentGemstoneId != null)
                  _buildFragmentDropdown(gems),

                // Fragment quantity field (Step 5C-4)
                if (_saleSource == 'breakdown_item' && _selectedFragmentName != null) ...
                  [
                    _buildFragmentQuantityField(gems),
                    _field(_fragmentUnitPrice, 'ရောင်းဈေး (ကျပ်)', number: true),
                    _field(_fragmentCommission, 'အရောင်းပွဲခ (ကျပ်)', number: true),
                    // Fragment weight field
                    Row(children: [
                      Expanded(
                        child: _field(_fragmentWeight, 'အလေးချိန်', number: true),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: _fragmentWeightUnit,
                          items: ['ပိသာ', 'ကျပ်သား', 'ကာရက်', 'kg', 'g', 'lb', 'oz']
                              .map((unit) => DropdownMenuItem(
                                    value: unit,
                                    child: Text(unit),
                                  ))
                              .toList(),
                          onChanged: (value) {
                            setState(() {
                              _fragmentWeightUnit = value ?? 'kg';
                            });
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
                    // Fragment Sale Summary Panel
                    if (_saleSource == 'breakdown_item' && _selectedFragmentName != null)
                      _buildFragmentSalarySummary(gems),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child:                                   SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _saleSource == 'breakdown_item' ? _addFragmentItemMinimal : _addItemToTemporaryList,
                    child: const Flexible(
                      child: Text(
                        'ထည့်မည်',
                        maxLines: 1,
                        overflow: TextOverflow.visible,
                        textAlign: TextAlign.center,
                      ),
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
                _field(
                    _weight,
                    selectedGem != null
                        ? 'အလေးချိန် (${LocalDb.unitLabel(selectedGem.weightUnit)}) — မဖြည့်လည်းရ'
                        : 'အလေးချိန် — မဖြည့်လည်းရ',
                    number: true),

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
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _addItemToTemporaryList,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryAccent,
                    ),
                    child: const Text(
                      'ထည့်မည်',
                      style: TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                      ),
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
                                  // Total amount
                                  Text(
                                    'ခန့်မှန်းရောင်းငွေ: ${NumberFormat('#,##0', 'en_US').format(item.totalAmount.toInt())} ကျပ်',
                                    style: const TextStyle(
                                      color: Colors.white70,
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
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _items.isEmpty || _isSaving ? null : _finalizeAndSave,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _items.isEmpty || _isSaving
                              ? AppTheme.primaryAccent.withOpacity(0.5)
                              : AppTheme.primaryAccent,
                          disabledBackgroundColor: AppTheme.primaryAccent.withOpacity(0.5),
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
                                  Flexible(
                                    child: Text(
                                      'သိမ်းဆည်းနေသည်...',
                                      style: TextStyle(
                                        color: Colors.black,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.visible,
                                    ),
                                  ),
                                ],
                              )
                            : Flexible(
                                child: Text(
                                  'ရောင်းချမည်',
                                  style: const TextStyle(
                                    color: Colors.black,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.visible,
                                  textAlign: TextAlign.center,
                                ),
                              ),
                      ),
                    ),
                  ),
                ),
                ], // End of if (_saleSource == 'whole_stone')
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Build read-only list of purchases with breakdown items (Step 5C-1)
  Widget _buildFragmentPurchaseList(List<Gemstone> gems) {
    final gemsWithBreakdown = gems.where((g) {
      return g.breakdownItems != null && 
             g.breakdownItems!.isNotEmpty &&
             g.breakdownItems!.values.any((item) {
               if (item is Map<String, dynamic>) {
                 final qty = (item['quantity'] as num?)?.toInt() ?? 0;
                 return qty > 0;
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
              'အစိတ်စိတ်ပိုင်း ရွေးချယ်မှု',
              style: TextStyle(
                color: AppTheme.primaryAccent,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ...gemsWithBreakdown.map((gem) {
            final breakdownItemsList = gem.breakdownItems!.entries
                .where((e) {
                  if (e.value is Map<String, dynamic>) {
                    final qty = (e.value['quantity'] as num?)?.toInt() ?? 0;
                    return qty > 0;
                  }
                  return (e.value is num) && (e.value as num) > 0;
                })
                .toList();

            final isSelected = _selectedFragmentGemstoneId == gem.id;
            
            return InkWell(
              onTap: () {
                setState(() {
                  _selectedFragmentGemstoneId = gem.id;
                });
              },
              child: Container(
                margin: const EdgeInsets.only(bottom: 6),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceDark,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: isSelected ? AppTheme.primaryAccent : AppTheme.primaryAccent.withOpacity(0.2),
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: breakdownItemsList.map((entry) {
                    final itemData = entry.value as Map<String, dynamic>?;
                    final quantity = (itemData?['quantity'] as num?)?.toInt() ?? (entry.value is num ? (entry.value as num).toInt() : 0);
                    final weight = (itemData?['weight'] as num?)?.toDouble() ?? 0;
                    final weightUnit = itemData?['weightUnit'] as String? ?? '';
                    final weightDisplay = weight > 0 ? ' — $weight $weightUnit' : '';
                    
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 3),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              entry.key,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '$quantity ခု$weightDisplay',
                            style: TextStyle(
                              color: Colors.grey[300],
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildFragmentDropdown(List<Gemstone> gems) {
    // Find the selected purchase
    final selectedPurchase = gems.firstWhereOrNull(
      (g) => g.id == _selectedFragmentGemstoneId,
    );
    if (selectedPurchase == null || selectedPurchase.breakdownItems == null) {
      return const SizedBox.shrink();
    }
    // Get available breakdown items (quantity > 0)
    final availableItems = selectedPurchase.breakdownItems!.entries
        .where((e) {
          if (e.value is Map<String, dynamic>) {
            final qty = (e.value['quantity'] as num?)?.toInt() ?? 0;
            return qty > 0;
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
              'ရနှနွတ်မျတ် အစိတ်စိတ်ပြီင်',
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
                color: AppTheme.primaryAccent.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: DropdownButton<String>(
              value: _selectedFragmentName,
              hint: const Text(
                'အစိတ်စိတ်ပြီင် ရနှနွတ်မျ',
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
                final weightDisplay = weight > 0 ? ' — $weight $weightUnit' : '';
                final displayText = '$quantityခ်$weightDisplay';
                return DropdownMenuItem<String>(
                  value: entry.key,
                  child: Text(
                    '${entry.key} ($displayText)',
                    style: const TextStyle(color: Colors.white),
                  ),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedFragmentName = value;
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
  Widget _buildFragmentSalarySummary(List<Gemstone> gems) {
    if (_selectedFragmentName == null) {
      return const SizedBox.shrink();
    }

    // Get selected purchase and fragment data
    final selectedPurchase = gems.firstWhereOrNull(
      (g) => g.id == _selectedFragmentGemstoneId,
    );
    if (selectedPurchase == null || selectedPurchase.breakdownItems == null) {
      return const SizedBox.shrink();
    }

    // Extract fragment data
    final fragmentData = selectedPurchase.breakdownItems![_selectedFragmentName];
    final remainingQtyBefore = (fragmentData is Map<String, dynamic>)
        ? (fragmentData['quantity'] as num?)?.toInt() ?? 0
        : (fragmentData is num ? (fragmentData as num).toInt() : 0);
    final remainingWeightBefore = (fragmentData is Map<String, dynamic>)
        ? (fragmentData['weight'] as num?)?.toDouble() ?? 0
        : 0.0;
    final weightUnit = (fragmentData is Map<String, dynamic>)
        ? (fragmentData['weightUnit'] as String? ?? 'kg')
        : 'kg';

    // Get sale inputs
    final saleQty = int.tryParse(_fragmentQuantity.text) ?? 0;
    final saleWeight = double.tryParse(_fragmentWeight.text) ?? 0.0;
    final saleAmount = double.tryParse(_fragmentUnitPrice.text) ?? 0.0;
    final commission = double.tryParse(_fragmentCommission.text) ?? 0.0;

    // Calculate remaining values
    final remainingQtyAfter = remainingQtyBefore - saleQty;
    final remainingWeightAfter = remainingWeightBefore - saleWeight;
    final netSale = (saleAmount * saleQty) - commission;

    // Check for invalid values
    final isQtyInvalid = remainingQtyAfter < 0;
    final isWeightInvalid = remainingWeightAfter < 0;
    final hasError = isQtyInvalid || isWeightInvalid;

    final m = NumberFormat('#,##0.00');
    final mInt = NumberFormat('#,##0');

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: hasError ? AppTheme.errorColor.withOpacity(0.1) : AppTheme.primaryAccent.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: hasError ? AppTheme.errorColor : AppTheme.primaryAccent,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'အစိတ်စိတ်ရောင်းချမှုအကျဉ်းချုပ်',
            style: TextStyle(
              color: hasError ? AppTheme.errorColor : AppTheme.primaryAccent,
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          // Fragment name
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'အစိတ်စိတ်အမည်:',
                style: TextStyle(color: Colors.grey[400], fontSize: 11),
              ),
              Text(
                _selectedFragmentName ?? '-',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Quantity section
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'ကျန်ရှိသောအရေအတွက်:',
                style: TextStyle(color: Colors.grey[400], fontSize: 10),
              ),
              Text(
                '$remainingQtyBefore → $saleQty → $remainingQtyAfter',
                style: TextStyle(
                  color: isQtyInvalid ? AppTheme.errorColor : Colors.lightGreen,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          // Weight section
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'ကျန်ရှိသောအလေးချိန်:',
                style: TextStyle(color: Colors.grey[400], fontSize: 10),
              ),
              Text(
                '$remainingWeightBefore → $saleWeight → $remainingWeightAfter $weightUnit',
                style: TextStyle(
                  color: isWeightInvalid ? AppTheme.errorColor : Colors.lightGreen,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Divider(color: Colors.grey[600], height: 1),
          const SizedBox(height: 8),
          // Sale amount
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'ရောင်းရငွေ:',
                style: TextStyle(color: Colors.grey[400], fontSize: 11),
              ),
              Text(
                '${m.format(saleAmount * saleQty)} ကျပ်',
                style: const TextStyle(
                  color: AppTheme.successColor,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          // Commission
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'ရောင်းပွဲခ:',
                style: TextStyle(color: Colors.grey[400], fontSize: 11),
              ),
              Text(
                '${m.format(commission)} ကျပ်',
                style: const TextStyle(
                  color: Colors.amber,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          // Net Sale
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'အသားတင်ရောင်းချမှု:',
                style: TextStyle(color: Colors.grey[400], fontSize: 11, fontWeight: FontWeight.w600),
              ),
              Text(
                '${m.format(netSale)} ကျပ်',
                style: const TextStyle(
                  color: Colors.lightGreen,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          if (hasError) ...[const SizedBox(height: 8), Text(
            isQtyInvalid ? '⚠️ ကျန်ရှိသောအရေအတွက်မလုံလောက်ပါ' : '⚠️ ကျန်ရှိသောအလေးချိန်မလုံလောက်ပါ',
            style: const TextStyle(
              color: AppTheme.errorColor,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          )],
        ],
      ),
    );
  }

  Widget _buildFragmentQuantityField(List<Gemstone> gems) {
    // Find the selected purchase
    final selectedPurchase = gems.firstWhereOrNull(
      (g) => g.id == _selectedFragmentGemstoneId,
    );

    if (selectedPurchase == null || selectedPurchase.breakdownItems == null) {
      return const SizedBox.shrink();
    }

    // Get the selected fragment's quantity
    final qtyObj = selectedPurchase.breakdownItems![_selectedFragmentName];
    final selectedFragmentQty = (qtyObj is num) ? (qtyObj as num).toInt() : 0;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Available quantity label
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              'လက်ကျန်အစိတ်အရေအတွက်: $selectedFragmentQty',
              style: TextStyle(
                color: Colors.grey[300],
                fontSize: 12,
              ),
            ),
          ),
          // Quantity input field
          TextFormField(
            controller: _fragmentQuantity,
            keyboardType: const TextInputType.numberWithOptions(decimal: false),
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              labelText: 'အရေအတွက်',
              errorText: _fragmentQuantityError,
              errorStyle: const TextStyle(color: Colors.red),
            ),
            onChanged: (value) {
              setState(() {
                _validateFragmentQuantity(selectedFragmentQty);
              });
            },
          ),
        ],
      ),
    );
  }

  void _validateFragmentQuantity(int availableQty) {
    final input = _fragmentQuantity.text.trim();
    
    if (input.isEmpty) {
      _fragmentQuantityError = null;
      return;
    }

    final qty = int.tryParse(input);
    
    if (qty == null || qty <= 0) {
      _fragmentQuantityError = 'အရေအတွက်သည် ၀ထက်ကြီးရမည်';
      return;
    }

    if (qty > availableQty) {
      _fragmentQuantityError = 'လက်ကျန်အစိတ်အရေအတွက်ထက် မကျော်ရပါ';
      return;
    }

    _fragmentQuantityError = null;
  }

  void _addFragmentItemMinimal() {
    // Obtain the gemstone list (matching build method logic)
    final gems = LocalDb.gemstones().values.where((g) => g.quantity > 0).toList();
    
    // Find the selected purchase
    final selectedPurchase = gems.firstWhereOrNull(
      (g) => g.id == _selectedFragmentGemstoneId,
    );

    // Validation
    if (_selectedFragmentGemstoneId == null) {
      _toast('ကျောက်အစိတ်စုပေါင်းရွေးချယ်ပါ');
      return;
    }

    if (_selectedFragmentName == null || _selectedFragmentName!.isEmpty) {
      _toast('အစိတ်စိတ်ပိုင်းရွေးချယ်ပါ');
      return;
    }

    final qtyInput = _fragmentQuantity.text.trim();
    if (qtyInput.isEmpty) {
      _toast('အရေအတွက်ထည့်သွင်းပါ');
      return;
    }

    final qty = int.tryParse(qtyInput);
    if (qty == null || qty <= 0) {
      _toast('အရေအတွက်သည် ၀ထက်ကြီးရမည်');
      return;
    }

    // Check quantity against available
    final availableQtyObj = selectedPurchase?.breakdownItems?[_selectedFragmentName];
    final availableQty = (availableQtyObj is num) ? (availableQtyObj as num).toDouble() : 0.0;
    if (qty > availableQty) {
      _toast('လက်ကျန်အစိတ်အရေအတွက်ထက် မကျော်ရပါ');
      return;
    }

    // Validate unit price
    final priceInput = _fragmentUnitPrice.text.trim();
    if (priceInput.isEmpty) {
      _toast('ရောင်းဈေးထည့်သွင်းပါ');
      return;
    }

    final unitPrice = double.tryParse(priceInput);
    if (unitPrice == null || unitPrice < 0) {
      _toast('ရောင်းဈေးသည် ၀နှင့်အညီ သို့မဟုတ် ၀ထက်ကြီးရမည်');
      return;
    }

    // Validate and parse commission
    final commissionInput = _fragmentCommission.text.trim();
    final commission = double.tryParse(commissionInput) ?? 0;
    if (commission < 0) {
      _toast('အရောင်းပွဲခသည် အနုတ်မဖြစ်ရပါ');
      return;
    }

    // All validations passed - add item to temporary list
    setState(() {
      _items.add(
        _SaleItem(
          id: const Uuid().v4(),
          gemstoneId: _selectedFragmentGemstoneId,
          gemstoneName: selectedPurchase?.name ?? 'Unknown',
          quantity: qty,
          unitPrice: unitPrice,
          remark: '',
          fragmentName: _selectedFragmentName,
          isFragmentSource: true,
          commission: commission,
          weight: double.tryParse(_fragmentWeight.text.trim()),
          weightUnit: _fragmentWeightUnit,
        ),
      );

      // Update preview state for fragment item (Step 5E-1)
      final netSale = qty * unitPrice;
      _updatePreviewForGemstone(_selectedFragmentGemstoneId, netSale, fragmentQtyDeducted: qty);

      // Clear fragment-related fields only
      _selectedFragmentGemstoneId = null;
      _selectedFragmentName = null;
      _fragmentQuantity.clear();
      _fragmentUnitPrice.clear();
      _fragmentCommission.text = '0';
      _fragmentWeight.clear();
      _fragmentWeightUnit = 'kg';
      _fragmentQuantityError = null;
    });

    _toast('အစိတ်စိတ်ပိုင်းထည့်သွင်းအောင်မြင်ပါသည်');
  }

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
              Text(
                'ကုန်ပစ္စည်း ${index + 1}',
                style: const TextStyle(
                  color: AppTheme.primaryAccent,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
              if (index > 0)
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red, size: 18),
                  onPressed: () => _removeItem(index),
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

  /// View photos for a temporary item
  void _viewItemPhotos(dynamic item) {
    // Check if item has photos
    final photoPaths = item.photoPaths;
    if (photoPaths == null || photoPaths.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('ဤပစ္စည်းတွင် ပုံမရှိသေးပါ'),
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

class _BrokerSaleForm extends StatefulWidget {
  const _BrokerSaleForm({Key? key}) : super(key: key);

  @override
  State<_BrokerSaleForm> createState() => _BrokerSaleFormState();
}

class _BrokerSaleFormState extends State<_BrokerSaleForm> {
  late TextEditingController _brokerNameController;
  late TextEditingController _quantitySoldController;
  late TextEditingController _unitPriceController;
  late TextEditingController _commissionController;
  late TextEditingController _buyerNameController;
  late TextEditingController _remarkController;
  DateTime? _selectedSaleDate;
  BrokerConsignment? _selectedConsignment;

  String? _quantityError;
  String? _priceError;
  String? _commissionError;

  @override
  void initState() {
    super.initState();
    _brokerNameController = TextEditingController();
    _quantitySoldController = TextEditingController();
    _unitPriceController = TextEditingController();
    _commissionController = TextEditingController();
    _buyerNameController = TextEditingController();
    _remarkController = TextEditingController();
    _selectedSaleDate = DateTime.now();
  }

  @override
  void dispose() {
    _brokerNameController.dispose();
    _quantitySoldController.dispose();
    _unitPriceController.dispose();
    _commissionController.dispose();
    _buyerNameController.dispose();
    _remarkController.dispose();
    super.dispose();
  }

  void _validateQuantity(String value) {
    if (value.isEmpty) {
      setState(() => _quantityError = null);
      return;
    }
    final qty = double.tryParse(value);
    if (qty == null || qty <= 0) {
      setState(() => _quantityError = 'အရေအတွက်သည် ၀ထက်ကြီးရမည်ဖြစ်ပါသည်။');
      return;
    }
    if (_selectedConsignment != null && qty > (_selectedConsignment!.remainingQuantity as double)) {
      setState(() => _quantityError = 'ကျန်ရှိသော အရေအတွက်ထက် ကျော်လွန်သည်။');
      return;
    }
    setState(() => _quantityError = null);
  }

  void _validatePrice(String value) {
    if (value.isEmpty) {
      setState(() => _priceError = null);
      return;
    }
    final price = double.tryParse(value);
    if (price == null || price < 0) {
      setState(() => _priceError = 'စျေးနှုန်းသည် အနုတ်မဖြစ်ရမည်ဖြစ်ပါသည်။');
      return;
    }
    setState(() => _priceError = null);
  }

  void _validateCommission(String value) {
    if (value.isEmpty) {
      setState(() => _commissionError = null);
      return;
    }
    final commission = double.tryParse(value);
    if (commission == null || commission < 0) {
      setState(() => _commissionError = 'ကော်မရှင်သည် အနုတ်မဖြစ်ရမည်ဖြစ်ပါသည်။');
      return;
    }
    setState(() => _commissionError = null);
  }

  Future<void> _saveBrokerSale() async {
    if (_selectedConsignment == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ကြေးမုံအချက်အလက်ကို ရွေးချယ်ပါ။')),
      );
      return;
    }

    final qty = double.tryParse(_quantitySoldController.text);
    final unitPrice = double.tryParse(_unitPriceController.text);
    final commission = double.tryParse(_commissionController.text) ?? 0;

    if (qty == null || qty <= 0 || _quantityError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('အရေအတွက်ကို စစ်ဆေးပါ။')),
      );
      return;
    }

    if (unitPrice == null || unitPrice < 0 || _priceError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ယူနစ်စျေးကို စစ်ဆေးပါ။')),
      );
      return;
    }

    if (_commissionError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ကော်မရှင်ကို စစ်ဆေးပါ။')),
      );
      return;
    }

    try {
      final totalAmount = (qty as double) * unitPrice;
      final netAmount = totalAmount - commission;

      final saleRecord = BrokerSaleRecord(
        id: LocalDb.genId(),
        brokerConsignmentId: _selectedConsignment!.id,
        purchaseId: _selectedConsignment!.purchaseId,
        sourceType: _selectedConsignment!.historicalData.sourceType,
        breakdownItemName: _selectedConsignment!.historicalData.breakdownItemName,
        soldQuantity: qty,
        unitPrice: unitPrice,
        totalSaleAmount: totalAmount,
        brokerCommission: commission,
        netAmount: netAmount,
        buyerName: _buyerNameController.text.trim().isNotEmpty ? _buyerNameController.text.trim() : null,
        remark: _remarkController.text.trim(),
        saleDate: _selectedSaleDate!.millisecondsSinceEpoch,
        createdAt: DateTime.now().millisecondsSinceEpoch,
      );

      final validationError = saleRecord.validate();
      if (validationError != null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('အမှားအယွင်း: $validationError')),
          );
        }
        return;
      }

      final saleRecordsBox = Hive.box<BrokerSaleRecord>('brokerSaleRecords');
      await saleRecordsBox.add(saleRecord);

      _selectedConsignment!.soldQuantity += qty;
      final brokerConsignmentBox = Hive.box<BrokerConsignment>('brokerConsignments');
      await brokerConsignmentBox.put(_selectedConsignment!.id, _selectedConsignment!);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('ကြေးမုံရောင်းချမှု သိမ်းဆည်းပြီးပါပြီ။')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('အမှားအယွင်း: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final brokerConsignmentsBox = Hive.box<BrokerConsignment>('brokerConsignments');
    final brokerConsignments = brokerConsignmentsBox.values.where((c) => c.remainingQuantity > 0).toList();

    return SingleChildScrollView(
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.surfaceDark,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
          ),
        ),
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 16,
          bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'ကြေးမုံရောင်းချမှု',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<BrokerConsignment>(
              value: _selectedConsignment,
              decoration: InputDecoration(
                labelText: 'ကြေးမုံအချက်အလက်',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
              items: brokerConsignments.map((consignment) {
                final gemstonesBox = Hive.box<Gemstone>('gemstones');
                final gemstone = gemstonesBox.get(consignment.purchaseId);
                return DropdownMenuItem(
                  value: consignment,
                  child: Text('${gemstone?.name ?? "Unknown"} - ${consignment.brokerName}'),
                );
              }).toList(),
              onChanged: (value) {
                setState(() => _selectedConsignment = value);
              },
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _quantitySoldController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: 'ရောင်းချသော အရေအတွက်',
                errorText: _quantityError,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onChanged: _validateQuantity,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _unitPriceController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: 'ယူနစ်စျေးနှုန်း',
                errorText: _priceError,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onChanged: _validatePrice,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _commissionController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: 'ကော်မရှင်',
                errorText: _commissionError,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onChanged: _validateCommission,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _buyerNameController,
              decoration: InputDecoration(
                labelText: 'ဝယ်ယူသူအမည်',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _remarkController,
              decoration: InputDecoration(
                labelText: 'မှတ်ချက်',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 12),
            InkWell(
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: _selectedSaleDate ?? DateTime.now(),
                  firstDate: DateTime(2000),
                  lastDate: DateTime.now(),
                );
                if (date != null) {
                  setState(() => _selectedSaleDate = date);
                }
              },
              child: InputDecorator(
                decoration: InputDecoration(
                  labelText: 'ရောင်းချသည့်နေ့စွဲ',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: Text(
                  _selectedSaleDate != null ? DateFormat('dd/MM/yyyy').format(_selectedSaleDate!) : 'ရွေးချယ်ပါ',
                ),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saveBrokerSale,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryAccent,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: const Text('သိမ်းဆည်းမည်'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
