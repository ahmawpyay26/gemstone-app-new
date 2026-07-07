import 'package:flutter/material.dart';
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
import 'dart:developer' as developer;
import '../widgets/bottom_sheet_dropdown.dart';
import '../widgets/inline_selector.dart';
import '../widgets/fragment_gemstone_selector.dart';
import '../widgets/fragment_item_selector.dart';

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
      builder: (_) => _SaleForm(existing: existing, hiveKey: key, parentContext: context),
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
      // TODO: Implement actual print functionality
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
                                  Text(
                                      '${s.isFragmentSource ? "အစိတ်စိတ်ပိုင်း" : "အဝယ်စာရင်း"}${s.fragmentName != null ? " (${s.fragmentName})" : ""}',
                                      style: TextStyle(
                                        color: s.isFragmentSource ? AppTheme.primaryAccent : Colors.grey[400],
                                        fontSize: 11,
                                        fontWeight: s.isFragmentSource ? FontWeight.w600 : FontWeight.normal,
                                      )),
                                  Text(
                                      'အရေအတွက်: ${s.quantity}'
                                      '${s.weightCarat > 0 ? ' • ${s.weightCarat} ${_saleUnit(s)}' : ''}'
                                      '${s.isFragmentSource && s.fragmentWeight != null ? ' • ${s.fragmentWeight!.toStringAsFixed(2)} ${s.fragmentWeightUnit ?? "kg"}' : ''}',
                                      style:
                                          TextStyle(color: Colors.grey[400])),
                                  Text(
                                      'ဝယ်သူ: ${_getCustomerName(s)}',
                                      style:
                                          TextStyle(color: Colors.grey[400])),
                                  Text(
                                      '${_date.format(DateTime.fromMillisecondsSinceEpoch(s.saleDate))} • ${_payLabel(s.paymentMethod)}',
                                      style: TextStyle(
                                          color: Colors.grey[500],
                                          fontSize: 12)),
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
    // Use Sale's weightUnit if available (whole-stone sales with selected unit)
    if (s.weightUnit != null && s.weightUnit!.isNotEmpty) {
      return LocalDb.unitLabel(s.weightUnit!);
    }
    // Fallback to gemstone's weight unit
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
  double? weight; // Weight in kg for fragment items
  String? weightUnit; // Weight unit for fragment items (ပိသာ|ကျပ်သား|ကာရက်|kg|g|lb|oz)
  List<String> photoPaths; // Photo attachment paths for fragment items (Step 6C-1)

  _SaleItem({
    required this.id,
    this.gemstoneId,
    required this.gemstoneName,
    required this.quantity,
    required this.unitPrice,
    this.remark = '',
    this.fragmentName,
    this.isFragmentSource = false,
    this.weight,
    this.weightUnit,
    this.photoPaths = const [],
  });

  double get totalAmount => quantity * unitPrice;
}

class _SaleForm extends StatefulWidget {
  final Sale? existing;
  final dynamic hiveKey;
  final BuildContext? parentContext;
  const _SaleForm({this.existing, this.hiveKey, this.parentContext});

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
  
  // Parent context for SnackBar visibility
  late BuildContext _parentContext;

  String? _selectedGemId; // null => manual entry
  bool _autoDeduct = true;
  
  // Debug state for button tap verification
  String _saveDebugStatus = '';
  
  // Sale source selector (Step 5B)
  String _saleSource = 'whole_stone'; // 'whole_stone' or 'breakdown_item'
  String? _selectedFragmentGemstoneId; // Selected fragment purchase (Step 5C-2)
  String? _selectedFragmentName; // Selected fragment name from dropdown (Step 5C-3)
  late final TextEditingController _fragmentQuantity; // Fragment quantity input (Step 5C-4)
  String? _fragmentQuantityError; // Fragment quantity validation error (Step 5C-4)
  late final TextEditingController _fragmentWeight; // Fragment weight input in kg (Step 6B-1)
  String? _fragmentWeightError; // Fragment weight validation error (Step 6B-1)
  String _fragmentWeightUnit = 'kg'; // Fragment weight unit (Step 6B-2)
  String _weightUnit = 'kg'; // Whole-stone weight unit (Step 6T)
  late final TextEditingController _fragmentUnitPrice; // Fragment unit price input (Step 5D-2)
  List<String> _fragmentPhotoPaths = []; // Fragment photo attachment paths (Step 6C-2)
  
  // Multi-item invoice support
  late List<_SaleItem> _items;
  late List<_SaleItem> _fragmentItems; // Separate temporary list for fragment sales (Step 6G)
  bool _isMultiItemMode = false;

  // Preview state (in-memory only, never persisted to Hive)
  final Map<String, dynamic> _previewState = {}; // Stores preview values for each gemstone

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
    if (price <= 0) {
      _showError('Price must be greater than 0');
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
      weight: double.tryParse(_weight.text.trim()),
      weightUnit: _weightUnit,
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
      _weightUnit = 'kg';
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

  // Fragment temporary list handlers (Step 6G-UI)
  void _editFragmentItemFromList(int index) {
    final item = _fragmentItems[index];
    setState(() {
      _selectedFragmentGemstoneId = item.gemstoneId;
      _selectedFragmentName = item.fragmentName;
      _fragmentQuantity.text = item.quantity.toString();
      _fragmentWeight.text = item.weight?.toString() ?? '';
      _fragmentWeightUnit = item.weightUnit ?? 'kg';
      _fragmentUnitPrice.text = item.unitPrice.toString();
      _photoPaths = item.photoPaths ?? [];
      _fragmentItems.removeAt(index);
    });
    _recalculatePreview();
    _showSuccess('Fragment item restored for editing');
  }

  void _removeFragmentItemFromList(int index) {
    setState(() {
      _fragmentItems.removeAt(index);
    });
    _recalculatePreview();
    _showSuccess('Fragment item removed');
  }

  // Transfer fragment items to main list (Step 6K)
  void _transferFragmentItemsToMainList() {
    developer.log('[Fragment] _transferFragmentItemsToMainList called');
    developer.log('[Fragment] _fragmentItems.length: ${_fragmentItems.length}');
    developer.log('[Fragment] _items.length before transfer: ${_items.length}');
    
    if (_fragmentItems.isEmpty) {
      developer.log('[Fragment] ERROR: _fragmentItems is empty, cannot transfer');
      _showError('No fragment items to transfer');
      return;
    }

    setState(() {
      developer.log('[Fragment] Transferring ${_fragmentItems.length} items to main list');
      
      // Move all fragment items to main temporary list
      _items.addAll(_fragmentItems);
      _fragmentItems.clear();

      developer.log('[Fragment] Transfer complete. _items.length after transfer: ${_items.length}');
      developer.log('[Fragment] Switching to whole_stone mode');
      
      // Switch back to whole-stone source
      _saleSource = 'whole_stone';

      // Clear fragment form fields
      _selectedFragmentGemstoneId = null;
      _selectedFragmentName = null;
      _fragmentQuantity.clear();
      _fragmentWeight.clear();
      _fragmentWeightUnit = 'kg';
      _fragmentUnitPrice.clear();
      _photoPaths.clear();
      
      // Clear whole-stone form fields (Step 6M)
      _selectedGemId = null;
      _selectedCustomerId = null;
      _qty.clear();
      _weight.clear();
      _weightUnit = 'kg';
      _amount.clear();
      _note.clear();
    });

    _recalculatePreview();
    developer.log('[Fragment] Preview recalculated');
    _showSuccess('Fragment items transferred to temporary list');
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
        if (item.weight != null) {
          _fragmentWeight.text = item.weight.toString();
        }
        _fragmentUnitPrice.text = item.unitPrice.toString();
        _fragmentPhotoPaths = List.from(item.photoPaths);
      } else {
        // Whole-stone item: restore whole-stone fields
        _saleSource = 'whole_stone';
        _selectedGemId = item.gemstoneId;
        _manualName.text = item.gemstoneName;
        _qty.text = item.quantity.toString();
        _amount.text = item.unitPrice.toString();
        _note.text = item.remark;
        if (item.weight != null) {
          _weight.text = item.weight.toString();
        }
        _weightUnit = item.weightUnit ?? 'kg';
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
    // Try to use current context first, fall back to parent context
    final messenger = ScaffoldMessenger.maybeOf(context) ?? ScaffoldMessenger.maybeOf(_parentContext);
    if (messenger != null) {
      messenger.showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: AppTheme.errorColor),
      );
    } else {
      developer.log('[ERROR] ScaffoldMessenger not available: $msg');
    }
  }

  void _showSuccess(String msg) {
    // Try to use current context first, fall back to parent context
    final messenger = ScaffoldMessenger.maybeOf(context) ?? ScaffoldMessenger.maybeOf(_parentContext);
    if (messenger != null) {
      messenger.showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: AppTheme.successColor),
      );
    } else {
      developer.log('[SUCCESS] ScaffoldMessenger not available: $msg');
    }
  }

  @override
  void initState() {
    super.initState();
    _parentContext = widget.parentContext ?? context;
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
    _fragmentWeight = TextEditingController();
    _fragmentUnitPrice = TextEditingController();
    _payment = e?.paymentMethod ?? 'cash';
    _saleDate = e != null
        ? DateTime.fromMillisecondsSinceEpoch(e.saleDate)
        : DateTime.now();
    _weightUnit = e?.weightUnit ?? 'kg';
    _fragmentWeightUnit = e?.fragmentWeightUnit ?? 'kg';

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
        weight: e?.weightCarat,
        weightUnit: _weightUnit,
      ),
    ];
    
    // Initialize fragment temporary list (Step 6G)
    _fragmentItems = [];
  }

  static String _trim(double v) =>
      v == v.roundToDouble() ? v.toInt().toString() : v.toString();

  @override
  void dispose() {
    // Clear preview state (automatic rollback)
    _previewState.clear();
    
    for (final c in [_customer, _amount, _qty, _weight, _note, _manualName, _cost, _commission, _fragmentQuantity, _fragmentWeight, _fragmentUnitPrice]) {
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

  Future<void> _save() async {
    developer.log('ENTERED_SAVE - _save() method called');
    developer.log('[Sale] _save() called - Final save button tapped');
    developer.log('[Sale] _items.length: ${_items.length}');
    developer.log('[Sale] _fragmentItems.length: ${_fragmentItems.length}');
    
    // Check if temporary sale list is empty
    if (_items.isEmpty && _fragmentItems.isEmpty) {
      developer.log('[Sale] No items to save - both lists are empty');
      _toast('ရောင်းချမည့်ပစ္စည်း မရှိသေးပါ');
      return;
    }

    // PHASE A: MERGE TEMPORARY LISTS (Step 6G)
    // Merge fragment items into main items list before processing
    try {
      developer.log('[PHASE_A_START] Merging fragment items into main list');
      _items.addAll(_fragmentItems);
      developer.log('[PHASE_A_SUCCESS] After merge: _items.length = ${_items.length}');
    } catch (e) {
      developer.log('[PHASE_A_FAILED] Exception: $e');
      _toast('Phase A Error: $e');
      return;
    }

    // PHASE B: VALIDATE ALL ITEMS BEFORE SAVING ANY
    try {
      developer.log('[PHASE_B_START] Starting validation of ${_items.length} items');
      for (int i = 0; i < _items.length; i++) {
      final item = _items[i];
      
      // Check gemstone selected
      if (item.gemstoneId == null || item.gemstoneId!.isEmpty) {
        developer.log('[Sale] Validation failed at item $i: gemstone not selected');
        _toast('အရည်အသွေး $i: ကျောက်မျက်ရွေးချယ်ပါ');
        return;
      }
      
      // Check quantity > 0
      if (item.quantity <= 0) {
        developer.log('[Sale] Validation failed at item $i: quantity <= 0 (qty=${item.quantity})');
        _toast('အရည်အသွေး $i: အရေအတွက် > 0 ဖြစ်ရမည်');
        return;
      }
      
      // Check unit price > 0
      if (item.unitPrice <= 0) {
        developer.log('[Sale] Validation failed at item $i: unitPrice <= 0 (price=${item.unitPrice})');
        _showError('ပစ္စည်း $i: ရောင်းရငွေ > 0 ဖြစ်ရမည်');
        return;
      }
      
      // Check gemstone name not blank
      if (item.gemstoneName.isEmpty) {
        developer.log('[Sale] Validation failed at item $i: gemstoneName is blank');
        _showError('ပစ္စည်း $i: ကျောက်မျက်အမည် မည်သည့်မျှ မဖြည့်စွက်ရသေးပါ');
        return;
      }
      
      // Check gemstone exists
      final gemstone = LocalDb.gemstoneById(item.gemstoneId!);
      if (gemstone == null) {
        developer.log('[Sale] Validation failed at item $i: gemstone not found (id=${item.gemstoneId})');
        _toast('အရည်အသွေး $i: ကျောက်မျက်မတ်တေးချယ်ပါ');
        return;
      }
      
      // Check inventory if auto-deduct enabled
      if (_autoDeduct) {
        final remaining = LocalDb.gemstoneRemainingQuantity(gemstone);
        developer.log('[Sale] Auto-deduct enabled. Remaining qty: $remaining');
        if (remaining <= 0) {
          developer.log('[Sale] Validation failed at item $i: no remaining inventory');
          _toast('အရည်အသွေး $i: အရောင်းအဆုံးဖြစ်နေ');
          return;
        }
        if (item.quantity > remaining) {
          developer.log('[Sale] Validation failed at item $i: qty ${item.quantity} > remaining $remaining');
          _toast('အရည်အသွေး $i: Stock မတ်တေးတင်ပါ — ကျောတ် $remaining ခ်ပါ ရိးတေးချယ်ပါ');
          return;
        }
      }
      }
      developer.log('[PHASE_B_SUCCESS] All validations passed');
    } catch (e) {
      developer.log('[PHASE_B_FAILED] Exception: $e');
      _toast('Phase B Error: $e');
      return;
    }

    // PHASE C: GENERATE INVOICE NUMBER
    final now = DateTime.now();
    final dateStr = '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';
    final box = LocalDb.sales();
    final existingInvoices = box.values
        .where((s) => s.invoiceNumber.startsWith('INV-$dateStr-'))
        .length;
    final invoiceNum = 'INV-$dateStr-${(existingInvoices + 1).toString().padLeft(3, '0')}';

    // PHASE C-D-E-F-G: SAVE LOOP - Save each item as separate Sale record
    // Use Preview State values (Step 4D: Commit Preview to Database)
    final Set<String> gemstonesUpdated = {};
    final sellCommission = double.tryParse(_commission.text.trim()) ?? 0;
    final perUnitCost = double.tryParse(_cost.text.trim()) ?? 0;
    
    try {
      developer.log('[PHASE_C_START] Creating and saving Sale objects');
      for (int i = 0; i < _items.length; i++) {
      final item = _items[i];
      final qty = item.quantity;
      final unitPrice = item.unitPrice;
      final amount = qty * unitPrice;
      final netSale = amount - sellCommission;
      
      // Calculate cost
      double cost;
      if (item.gemstoneId!.isNotEmpty) {
        cost = perUnitCost * qty;
      } else {
        cost = perUnitCost;
      }
      
      // PHASE C: Create Sale record
      developer.log('[PHASE_C_ITEM_${i}_START] Creating Sale object for item $i');
      final newSale = Sale(
        id: LocalDb.genId(),
        gemstoneId: item.gemstoneId ?? '',
        gemstoneName: item.gemstoneName,
        customerId: _selectedCustomerId,
        customerName: _customer.text.trim(),
        amount: amount,
        costPrice: cost,
        commissionFee: sellCommission,
        quantity: qty,
        weightCarat: item.weight ?? 0,
        paymentMethod: _payment,
        note: item.remark,
        saleDate: _saleDate.millisecondsSinceEpoch,
        netSale: netSale,
        costUsed: 0,
        profitGenerated: 0,
        remainingCostAfterSale: 0,
        accumulatedProfit: 0,
        photoPaths: i == 0 ? _photoPaths : (item.isFragmentSource ? item.photoPaths : []),
        isDeleted: false,
        deletedAt: null,
        deletedBy: '',
        deleteReason: '',
        invoiceNumber: invoiceNum,
        fragmentName: item.fragmentName,
        isFragmentSource: item.isFragmentSource,
        fragmentWeight: item.weight,
        fragmentWeightUnit: item.weightUnit,
        weightUnit: item.isFragmentSource ? null : item.weightUnit,
      );
      developer.log('[PHASE_C_ITEM_${i}_SUCCESS] Sale object created: ${newSale.id}');
      
      // PHASE D: Save to Hive
      developer.log('[PHASE_D_ITEM_${i}_START] Saving to Hive box');
      await box.add(newSale);
      developer.log('[PHASE_D_ITEM_${i}_SUCCESS] Saved to Hive');
      
      // PHASE E: Update customer ledger - DISABLED FOR ISOLATION TEST
      developer.log('[PHASE_E_ITEM_${i}_START] Updating customer ledger - SKIPPED FOR TEST');
      // await LocalDb.applySaleCustomerLedger(newSale);
      developer.log('[PHASE_E_ITEM_${i}_SUCCESS] Customer ledger update skipped');
      
      // PHASE F: Update gemstone cost recovery using Preview State values
      developer.log('[PHASE_F_ITEM_${i}_START] Updating gemstone inventory');
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
              if (itemData == null) continue;
              final itemMap = itemData as Map<String, dynamic>;
              final currentQty = (itemMap['quantity'] as num?)?.toInt() ?? 0;
              if (currentQty >= qty) {
                gemstone.breakdownItems![fragmentName] = {
                  'quantity': currentQty - qty,
                  'weight': itemMap['weight'],
                  'weightUnit': itemMap['weightUnit']
                };
              }
            }
          }
          
          await LocalDb.gemstones().put(item.gemstoneId!, gemstone);
          gemstonesUpdated.add(item.gemstoneId!);
          developer.log('[PHASE_F_ITEM_${i}_SUCCESS] Gemstone inventory updated');
        }
      }
      }

      // PHASE G: POST-SAVE UPDATES - DISABLED FOR ISOLATION TEST
      developer.log('[PHASE_G_START] Updating product ledger - SKIPPED FOR TEST');
      // for (final gemId in gemstonesUpdated) {
      //   await LocalDb.updateGemstoneProductLedger(gemId);
      // }
      developer.log('[PHASE_G_SUCCESS] Product ledger update skipped');
      
      developer.log('[PHASE_H_START] Clearing preview state and form');
      _previewState.clear();
      _items.clear();
      _fragmentItems.clear(); // Clear fragment temporary list after successful save
      _selectedGemId = null;
      _manualName.clear();
      _qty.clear();
      _amount.clear();
      _note.clear();
      _weight.clear();
      _weightUnit = 'kg';
      _cost.clear();
      _commission.clear();
      _photoPaths.clear();
      developer.log('[PHASE_H_SUCCESS] Preview state and form cleared');
      
      // Show success and close form - IMMEDIATE CLOSE FOR ISOLATION TEST
      developer.log('[PHASE_I_START] Closing sale form');
      _showSuccess('အရောင်းစာရင်း အောင်မြင်စွာ သိမ်းပြီးပါပြီ');
      if (mounted) {
        developer.log('[PHASE_I_SUCCESS] Navigating back to Sales History');
        // Pop the sale form bottom sheet
        Navigator.pop(context, true);
        // The Sales History page will automatically refresh when we return
      }
    } catch (e) {
      // FAILURE: Keep preview state and temporary list for retry
      developer.log('[SAVE_EXCEPTION] ERROR during save: $e');
      developer.log('[SAVE_EXCEPTION] Stack trace: ${StackTrace.current}');
      developer.log('[SAVE_EXCEPTION] Exception type: ${e.runtimeType}');
      _toast('Error: $e');
      // Do NOT clear preview state or items - allow user to retry
    }
  }

  void _toast(String msg) {
    // Try to use current context first, fall back to parent context
    final messenger = ScaffoldMessenger.maybeOf(context) ?? ScaffoldMessenger.maybeOf(_parentContext);
    if (messenger != null) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(msg),
          backgroundColor: AppTheme.errorColor,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      developer.log('[TOAST] ScaffoldMessenger not available: $msg');
    }
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
                    _buildFragmentDetailsDisplay(gems),
                    _field(_fragmentQuantity, 'ရောင်းမည့် အရေအတွက်', number: true),
                    _field(_fragmentWeight, 'ရောင်းမည့် အလေးချိန်', number: true),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: DropdownButtonFormField<String>(
                        value: _fragmentWeightUnit,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          labelText: 'အလေးချိန် ယူနစ်',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'ပိသာ', child: Text('ပိသာ')),
                          DropdownMenuItem(value: 'ကျပ်သား', child: Text('ကျပ်သား')),
                          DropdownMenuItem(value: 'ကာရက်', child: Text('ကာရက်')),
                          DropdownMenuItem(value: 'kg', child: Text('kg')),
                          DropdownMenuItem(value: 'g', child: Text('g')),
                          DropdownMenuItem(value: 'lb', child: Text('lb')),
                          DropdownMenuItem(value: 'oz', child: Text('oz')),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _fragmentWeightUnit = value ?? 'kg';
                          });
                        },
                      ),
                    ),
                    _field(_fragmentUnitPrice, 'ရောင်းဈေး (ကျပ်)', number: true),
                    _buildFragmentPhotoAttachmentSection(),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: SizedBox(
                        width: double.infinity,
                        height: 60,
                        child: ElevatedButton(
                          onPressed: _addFragmentItemMinimal,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: const Text(
                            'ထည့်မည်',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],

                // Fragment temporary list (Step 6G-UI: Display only in Fragment Dialog)
                if (_saleSource == 'breakdown_item') ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceDark.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: AppTheme.primaryAccent.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'ထည့်ထားသော ကျောက်အစိတ်စိတ်ပိုင်းများ',
                          style: const TextStyle(
                            color: AppTheme.primaryAccent,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        if (_fragmentItems.isEmpty)
                          Center(
                            child: Text(
                              '(အစိတ်စိတ်ပိုင်းများ ထည့်ထားမရှိသေးပါ)',
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
                            itemCount: _fragmentItems.length,
                            itemBuilder: (ctx, idx) {
                              final item = _fragmentItems[idx];
                              return Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                padding: const EdgeInsets.all(10),
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
                                    // Header: Title + Badge + Menu
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                item.gemstoneName,
                                                style: const TextStyle(
                                                  color: AppTheme.primaryAccent,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 13,
                                                ),
                                              ),
                                              const SizedBox(height: 2),
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: AppTheme.primaryAccent.withOpacity(0.2),
                                                  borderRadius: BorderRadius.circular(4),
                                                ),
                                                child: const Text(
                                                  'အစိတ်စိတ်ပိုင်း',
                                                  style: TextStyle(
                                                    color: AppTheme.primaryAccent,
                                                    fontSize: 10,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        PopupMenuButton<String>(
                                          onSelected: (value) {
                                            if (value == 'edit') {
                                              _editFragmentItemFromList(idx);
                                            } else if (value == 'delete') {
                                              _removeFragmentItemFromList(idx);
                                            }
                                          },
                                          itemBuilder: (BuildContext context) => [
                                            const PopupMenuItem<String>(
                                              value: 'edit',
                                              child: Row(
                                                children: [
                                                  Icon(Icons.edit, size: 18),
                                                  SizedBox(width: 8),
                                                  Text('ပြုပြင်ရန်'),
                                                ],
                                              ),
                                            ),
                                            const PopupMenuItem<String>(
                                              value: 'delete',
                                              child: Row(
                                                children: [
                                                  Icon(Icons.delete, size: 18),
                                                  SizedBox(width: 8),
                                                  Text('ဖျက်ရန်'),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    // Row 1: Quantity + Weight
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          'အရေအတွက်: ${item.quantity}',
                                          style: const TextStyle(color: Colors.white70, fontSize: 12),
                                        ),
                                        if (item.weight != null && item.weight! > 0)
                                          Text(
                                            'အလေးချိန်: ${item.weight} ${item.weightUnit ?? "kg"}',
                                            style: const TextStyle(color: Colors.white70, fontSize: 12),
                                          ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    // Row 2: Unit Price + Total
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          'ယူနစ်ဈေး: ${item.unitPrice}',
                                          style: const TextStyle(color: Colors.white70, fontSize: 12),
                                        ),
                                        Text(
                                          'စုစုပေါင်း: ${item.totalAmount}',
                                          style: const TextStyle(color: AppTheme.primaryAccent, fontWeight: FontWeight.bold, fontSize: 12),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    // Row 3: Photos
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          item.photoPaths != null && item.photoPaths!.isNotEmpty
                                              ? '📷 ${item.photoPaths!.length} ပုံ'
                                              : '📷 --',
                                          style: const TextStyle(color: Colors.white70, fontSize: 12),
                                        ),
                                        if (item.remark != null && item.remark!.isNotEmpty)
                                          Expanded(
                                            child: Text(
                                              'မှတ်ချက်: ${item.remark}',
                                              style: const TextStyle(color: Colors.white70, fontSize: 11),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                      ],
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Save button for Fragment Sales (Step 6J)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _fragmentItems.isNotEmpty ? _transferFragmentItemsToMainList : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryAccent,
                        disabledBackgroundColor: Colors.grey[700],
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text(
                        'သိမ်းမည်',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
                // Weight and unit fields
                Row(children: [
                  Expanded(
                    flex: 2,
                    child: _field(
                        _weight,
                        'အလေးချိန်ဖြည့်ရန်',
                        number: true),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: DropdownButtonFormField<String>(
                        value: _weightUnit,
                        dropdownColor: AppTheme.surfaceLight,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(
                          labelText: 'ယူနစ်',
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        ),
                        items: LocalDb.weightUnits.keys.map((unit) =>
                          DropdownMenuItem(
                            value: unit,
                            child: Text(LocalDb.weightUnits[unit] ?? unit),
                          ),
                        ).toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() => _weightUnit = value);
                          }
                        },
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
                  height: 60,
                  child: ElevatedButton(
                    onPressed: _addItemToTemporaryList,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryAccent,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text(
                      'ထည့်မည်',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
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
                              padding: const EdgeInsets.all(10),
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
                                  // Header: Title + Badge + Menu
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              item.gemstoneName,
                                              style: const TextStyle(
                                                color: AppTheme.primaryAccent,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 13,
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: item.isFragmentSource ? AppTheme.primaryAccent.withOpacity(0.2) : Colors.grey[700],
                                                borderRadius: BorderRadius.circular(4),
                                              ),
                                              child: Text(
                                                item.isFragmentSource ? 'အစိတ်စိတ်ပိုင်း' : 'အဝယ်စာရင်း',
                                                style: TextStyle(
                                                  color: item.isFragmentSource ? AppTheme.primaryAccent : Colors.grey[300],
                                                  fontSize: 10,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      PopupMenuButton<String>(
                                        onSelected: (value) {
                                          if (value == 'edit') {
                                            _editItemFromTemporaryList(idx);
                                          } else if (value == 'delete') {
                                            _removeItemFromTemporaryList(idx);
                                          }
                                        },
                                        itemBuilder: (BuildContext context) => [
                                          const PopupMenuItem<String>(
                                            value: 'edit',
                                            child: Row(
                                              children: [
                                                Icon(Icons.edit, size: 18),
                                                SizedBox(width: 8),
                                                Text('ပြုပြင်ရန်'),
                                              ],
                                            ),
                                          ),
                                          PopupMenuItem<String>(
                                            value: 'delete',
                                            child: Row(
                                              children: [
                                                Icon(Icons.delete, size: 18, color: AppTheme.errorColor),
                                                SizedBox(width: 8),
                                                Text('ဖျက်ရန်', style: TextStyle(color: AppTheme.errorColor)),
                                              ],
                                            ),
                                          ),
                                        ],
                                        child: Icon(Icons.more_vert, size: 20, color: AppTheme.primaryAccent),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  // Row 1: Quantity + Weight
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'အရေအတွက်: ${item.quantity}',
                                        style: const TextStyle(color: Colors.white70, fontSize: 11),
                                      ),
                                      if (item.isFragmentSource && item.weight != null)
                                        Text(
                                          'အလေးချိန်: ${item.weight!.toStringAsFixed(2)} ${item.weightUnit ?? "kg"}',
                                          style: const TextStyle(color: Colors.white70, fontSize: 11),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  // Row 2: Unit Price + Total Amount
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'ယူနစ်: ${NumberFormat('#,##0', 'en_US').format(item.unitPrice.toInt())} ကျပ်',
                                        style: const TextStyle(color: Colors.white70, fontSize: 11),
                                      ),
                                      Text(
                                        'စုစုပေါင်း: ${NumberFormat('#,##0', 'en_US').format(item.totalAmount.toInt())} ကျပ်',
                                        style: const TextStyle(color: AppTheme.primaryAccent, fontSize: 11, fontWeight: FontWeight.w500),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  // Row 3: Photos + Remark
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        item.photoPaths.isNotEmpty ? '📷 ${item.photoPaths.length} ပုံ' : '📷 --',
                                        style: const TextStyle(color: Colors.white70, fontSize: 11),
                                      ),
                                      if (item.remark.isNotEmpty)
                                        Expanded(
                                          child: Text(
                                            'မှတ်ချက်: ${item.remark}',
                                            style: TextStyle(fontSize: 10, color: Colors.grey[500]),
                                            overflow: TextOverflow.ellipsis,
                                            textAlign: TextAlign.end,
                                          ),
                                        ),
                                    ],
                                  ),
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
                // Debug status display
                if (_saveDebugStatus.isNotEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: _saveDebugStatus == 'BUTTON_TAPPED' ? Colors.yellow[700] : Colors.red[700],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'DEBUG: $_saveDebugStatus',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                // Main final save button (Step 6L)
                if (_items.isNotEmpty)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _items.isNotEmpty ? () {
                        developer.log('[SaleFinalButton] tapped - _items.length: ${_items.length}');
                        setState(() {
                          _saveDebugStatus = 'BUTTON_TAPPED';
                        });
                        _save();
                      } : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryAccent,
                        disabledBackgroundColor: Colors.grey[700],
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: Text(
                        _saveDebugStatus == 'BUTTON_TAPPED' ? 'နှိပ်ပြီးပါပြီ' : 'ရောင်းချမည်',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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

  /// Build compact dropdown for gemstone selection with breakdown items (Step 5C-1)
  Widget _buildFragmentPurchaseList(List<Gemstone> gems) {
    return FragmentGemstoneSelector(
      selectedGemstoneId: _selectedFragmentGemstoneId,
      onChanged: (value) {
        setState(() {
          _selectedFragmentGemstoneId = value;
          _selectedFragmentName = null; // Reset fragment name when gemstone changes
          developer.log('[Fragment] Gemstone selected: $value');
        });
      },
    );
  }

  Widget _buildFragmentDropdown(List<Gemstone> gems) {
    return FragmentItemSelector(
      selectedGemstoneId: _selectedFragmentGemstoneId,
      selectedFragmentName: _selectedFragmentName,
      onChanged: (value) {
        setState(() {
          _selectedFragmentName = value;
          developer.log('[Fragment] Item selected: $value');
          
          // Auto-populate form fields from selected fragment
          if (value != null && _selectedFragmentGemstoneId != null) {
            _populateFragmentFormFields(value);
          }
        });
      },
    );
  }
  
  /// Auto-populate form fields when a fragment item is selected
  void _populateFragmentFormFields(String fragmentName) {
    final gem = LocalDb.gemstoneById(_selectedFragmentGemstoneId!);
    if (gem == null || gem.breakdownItems == null) return;
    
    final itemData = gem.breakdownItems![fragmentName] as Map<String, dynamic>?;
    if (itemData == null) return;
    
    // Extract values from the nested map (NEVER cast directly to int)
    final quantity = (itemData['quantity'] as num?)?.toInt() ?? 0;
    final weight = (itemData['weight'] as num?)?.toDouble();
    final weightUnit = itemData['weightUnit'] as String? ?? 'kg';
    
    // Pre-fill the form with fragment details
    _fragmentQuantity.text = quantity.toString();
    _fragmentWeight.text = weight?.toString() ?? '';
    _fragmentWeightUnit = weightUnit;
    
    developer.log('[Fragment] Form populated: qty=$quantity, weight=$weight, unit=$weightUnit');
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
    final itemData = selectedPurchase.breakdownItems![_selectedFragmentName];
    if (itemData == null) return const SizedBox.shrink();
    final itemMap = itemData as Map<String, dynamic>;
    final selectedFragmentQty = (itemMap['quantity'] as num?)?.toInt() ?? 0;

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
          const SizedBox(height: 12),
          // Weight input field with unit dropdown (Step 6B-1 & 6B-2)
          Row(
            children: [
              Expanded(
                flex: 3,
                child: TextFormField(
                  controller: _fragmentWeight,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'အလေးချိန်',
                    hintText: 'ဥပမာ - 2.35',
                    errorText: _fragmentWeightError,
                    errorStyle: const TextStyle(color: Colors.red),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _validateFragmentWeight();
                    });
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: DropdownButtonFormField<String>(
                  value: _fragmentWeightUnit,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'ယူနစ်',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'ပိသာ', child: Text('ပိသာ')),
                    DropdownMenuItem(value: 'ကျပ်သား', child: Text('ကျပ်သား')),
                    DropdownMenuItem(value: 'ကာရက်', child: Text('ကာရက်')),
                    DropdownMenuItem(value: 'kg', child: Text('kg')),
                    DropdownMenuItem(value: 'g', child: Text('g')),
                    DropdownMenuItem(value: 'lb', child: Text('lb')),
                    DropdownMenuItem(value: 'oz', child: Text('oz')),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _fragmentWeightUnit = value ?? 'kg';
                    });
                  },
                ),
              ),
            ],
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

  void _validateFragmentWeight() {
    final input = _fragmentWeight.text.trim();
    
    if (input.isEmpty) {
      _fragmentWeightError = null;
      return;
    }

    final weight = double.tryParse(input);
    
    if (weight == null || weight <= 0) {
      _fragmentWeightError = 'အလေးချိန်သည် ၀ထက်ကြီးရမည်';
      return;
    }

    _fragmentWeightError = null;
  }

  Widget _buildFragmentPhotoAttachmentSection() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: PhotoAttachmentWidget(
        photoPaths: _fragmentPhotoPaths,
        onPhotosChanged: (photos) {
          setState(() => _fragmentPhotoPaths = photos);
        },
        recordType: 'sale',
      ),
    );
  }

  void _addFragmentItemMinimal() {
    developer.log('[Fragment] _addFragmentItemMinimal called');
    // Obtain the gemstone list (matching build method logic)
    final gems = LocalDb.gemstones().values.where((g) => g.quantity > 0).toList();
    
    // Find the selected purchase
    final selectedPurchase = gems.firstWhereOrNull(
      (g) => g.id == _selectedFragmentGemstoneId,
    );

    // Validation
    if (_selectedFragmentGemstoneId == null) {
      developer.log('[Fragment] Validation failed: gemstone not selected');
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
    final itemData = selectedPurchase?.breakdownItems?[_selectedFragmentName];
    if (itemData == null) {
      _toast('အစိတ်အပိုင်းအချက်အလက် မတွေ့ရှိ');
      return;
    }
    final itemMap = itemData as Map<String, dynamic>;
    final availableQty = (itemMap['quantity'] as num?)?.toInt() ?? 0;
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

    // All validations passed - add item to fragment temporary list (Step 6G)
    developer.log('[Fragment] All validations passed. Adding to _fragmentItems. Current count: ${_fragmentItems.length}');
    setState(() {
      _fragmentItems.add(
        _SaleItem(
          id: const Uuid().v4(),
          gemstoneId: _selectedFragmentGemstoneId,
          gemstoneName: selectedPurchase?.name ?? 'Unknown',
          quantity: qty,
          unitPrice: unitPrice,
          remark: '',
          fragmentName: _selectedFragmentName,
          weight: double.tryParse(_fragmentWeight.text.trim()),
          isFragmentSource: true,
          weightUnit: _fragmentWeightUnit,
          photoPaths: List.from(_fragmentPhotoPaths),
        ),
      );

      developer.log('[Fragment] Item added. New _fragmentItems.length: ${_fragmentItems.length}');
      
      // Update preview state for fragment item (Step 5E-1)
      final netSale = qty * unitPrice;
      _updatePreviewForGemstone(_selectedFragmentGemstoneId, netSale, fragmentQtyDeducted: qty);

      // Clear fragment-related fields only
      _selectedFragmentGemstoneId = null;
      _selectedFragmentName = null;
      _fragmentQuantity.clear();
      _fragmentWeight.clear();
      _fragmentWeightUnit = 'kg';
      _fragmentPhotoPaths.clear();
      _fragmentUnitPrice.clear();
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

  /// Display selected fragment details as read-only information
  Widget _buildFragmentDetailsDisplay(List<Gemstone> gems) {
    final selectedGemstone = gems.firstWhereOrNull(
      (g) => g.id == _selectedFragmentGemstoneId,
    );

    if (selectedGemstone == null || selectedGemstone.breakdownItems == null) {
      return const SizedBox.shrink();
    }

    final itemData = selectedGemstone.breakdownItems![_selectedFragmentName];
    if (itemData == null) return const SizedBox.shrink();

    final itemMap = itemData as Map<String, dynamic>;
    final remainingQty = (itemMap['quantity'] as num?)?.toInt() ?? 0;
    final remainingWeight = (itemMap['weight'] as num?)?.toDouble() ?? 0.0;
    final weightUnit = itemMap['weightUnit'] as String? ?? 'kg';

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppTheme.surfaceDark.withOpacity(0.5),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: AppTheme.primaryAccent.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Gemstone name
            Text(
              'ကျောက်အစိတ်စုပေါင်း: ${selectedGemstone.name}',
              style: const TextStyle(
                color: AppTheme.primaryAccent,
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            // Fragment name
            Text(
              'အစိတ်စိတ်ပိုင်း: $_selectedFragmentName',
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 8),
            // Remaining quantity
            Text(
              'လက်ကျန် အရေအတွက်: $remainingQty ခု',
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 4),
            // Remaining weight
            Text(
              'လက်ကျန် အလေးချိန်: ${remainingWeight.toStringAsFixed(2)} $weightUnit',
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 12,
              ),
            ),
          ],
        ),
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
