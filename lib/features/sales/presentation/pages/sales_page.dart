import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/local/local_db.dart';
import '../../../../core/local/models.dart';
import '../../../../shared/widgets/photo_attachment_widget.dart';
import '../../../../core/services/voucher_export_service.dart';
import 'package:share_plus/share_plus.dart';

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
        onPressed: () => _openForm(),
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
                            child: ListTile(
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
                                      'အရေအတွက်: ${s.quantity}'
                                      '${s.weightCarat > 0 ? ' • ${s.weightCarat} ${_saleUnit(s)}' : ''}',
                                      style:
                                          TextStyle(color: Colors.grey[400])),
                                  Text('ဝယ်သူ: ${s.customerName}',
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
                                    icon: Icon(Icons.more_vert,
                                        color: LocalDb.canEditSale() ? Colors.white : Colors.grey[600]),
                                    enabled: LocalDb.canEditSale(),
                                    onSelected: (v) {
                                      if (v == 'edit') _openForm(existing: s, key: key);
                                      if (v == 'delete') _delete(key);
                                      if (v == 'print') _printSale(s);
                                      if (v == 'pdf') _exportVoucher(s);
                                    },
                                    itemBuilder: (_) => [
                                      PopupMenuItem(
                                          value: 'edit',
                                          enabled: LocalDb.canEditSale(),
                                          child: const Row(
                                            children: [
                                              Icon(Icons.edit, size: 18, color: Colors.white),
                                              SizedBox(width: 8),
                                              Text('ပြုပြင်ရန်'),
                                            ],
                                          )),
                                      PopupMenuItem(
                                          value: 'delete',
                                          enabled: LocalDb.canDeleteSale(),
                                          child: const Row(
                                            children: [
                                              Icon(Icons.delete, size: 18, color: AppTheme.errorColor),
                                              SizedBox(width: 8),
                                              Text('ဖျက်ရန်', style: TextStyle(color: AppTheme.errorColor)),
                                            ],
                                          )),
                                      PopupMenuItem(
                                          value: 'print',
                                          child: const Row(
                                            children: [
                                              Icon(Icons.print, size: 18, color: Colors.white),
                                              SizedBox(width: 8),
                                              Text('ပရင့်ထုတ်ရန်'),
                                            ],
                                          )),
                                      PopupMenuItem(
                                          value: 'pdf',
                                          child: const Row(
                                            children: [
                                              Icon(Icons.picture_as_pdf, size: 18, color: Colors.white),
                                              SizedBox(width: 8),
                                              Text('PDF ထုတ်ရန်'),
                                            ],
                                          )),
                                    ],
                                  ),
                                ],
                              ),
                              onTap: () => _showDetails(s),
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

  void _showDetails(Sale sale) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(sale.gemstoneName),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('အရေအတွက်: ${sale.quantity}'),
              if (sale.weightCarat > 0)
                Text('အလေးချိန်: ${sale.weightCarat} ${_saleUnit(sale)}'),
              Text('ဝယ်သူ: ${sale.customerName}'),
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

  String? _selectedGemId; // null => manual entry
  bool _autoDeduct = true;

  bool get _isEdit => widget.existing != null && widget.hiveKey != null;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _photoPaths = List.from(e?.photoPaths ?? []);
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
  }

  static String _trim(double v) =>
      v == v.roundToDouble() ? v.toInt().toString() : v.toString();

  @override
  void dispose() {
    for (final c in [_customer, _amount, _qty, _weight, _note, _manualName, _cost, _commission]) {
      c.dispose();
    }
    super.dispose();
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
    if (!_formKey.currentState!.validate()) return;

    final qty = int.tryParse(_qty.text.trim()) ?? 1;
    final weight = double.tryParse(_weight.text.trim()) ?? 0;
    final amount = double.tryParse(_amount.text.trim()) ?? 0;
    final sellCommission = double.tryParse(_commission.text.trim()) ?? 0;

    final gemId = _selectedGemId ?? '';
    final name = gemId.isNotEmpty
        ? (LocalDb.gemstoneById(gemId)?.name ?? _manualName.text.trim())
        : _manualName.text.trim();

    // --- Compute cost of goods sold (COGS) for this sale ---
    // The cost field holds the per-unit cost (auto-filled from the linked
    // gemstone, but the user may override it). Total COGS = per-unit × qty.
    // For manual entries (no linked gemstone) the field is taken as the total
    // cost as typed.
    final perUnitCost = double.tryParse(_cost.text.trim()) ?? 0;
    double cost;
    if (gemId.isNotEmpty) {
      cost = perUnitCost * qty;
    } else {
      cost = perUnitCost;
    }

    // Stock validation when linked to an inventory item and auto-deduct is on.
    if (gemId.isNotEmpty && _autoDeduct) {
      final g = LocalDb.gemstoneById(gemId)!;
      
                      // Sold out check is already done in dropdown filter
                      // This is a safety check
      // Check remaining quantity (not purchase quantity)
      final remaining = LocalDb.gemstoneRemainingQuantity(g);
      if (remaining <= 0) {
        _toast('ဤပစ္စည်းသည် အရောင်းအဆုံးဖြစ်နေပါသည်။');
        return;
      }
      
      // For edit: account for the previous sale quantity being re-released
      final prevQty = (_isEdit && widget.existing!.gemstoneId == gemId)
          ? widget.existing!.quantity
          : 0;
      final prevWeight = (_isEdit && widget.existing!.gemstoneId == gemId)
          ? widget.existing!.weightCarat
          : 0;
      final availableQty = remaining + prevQty;
      final availableWeight = g.weightCarat + prevWeight;
      if (qty > availableQty) {
        _toast('Stock မလောက်ပါ — ကျန် $availableQty ခုသာ ရှိသည်');
        return;
      }
      if (weight > 0 && weight > availableWeight) {
        _toast(
            'အလေးချိန် မလောက်ပါ — ကျန် ${_trim(availableWeight.toDouble())} ${LocalDb.unitLabel(g.weightUnit)}သာ ရှိသည်');
        return;
      }
    }

    final box = LocalDb.sales();

    // NOTE: Stock is NO LONGER deducted from g.quantity
    // Purchase quantity (g.quantity) remains immutable
    // Sales only affect soldQuantity and remainingQuantity (derived fields)
    // Cost tracking is handled via updateGemstoneProductLedger()

    // --- Calculate transaction history fields for Product-wise Independent Ledger ---
    final netSale = amount - sellCommission;
    
    // These will be recalculated from sales records after save
    double costUsed = 0;
    double profitGenerated = 0;
    double remainingCostAfterSale = 0;
    double accumulatedProfit = 0;

    if (_isEdit) {
      final s = widget.existing!;
      s.gemstoneId = gemId;
      s.gemstoneName = name;
      s.customerName = _customer.text.trim();
      s.amount = amount;
      s.costPrice = cost;
      s.commissionFee = sellCommission;
      s.quantity = qty;
      s.weightCarat = weight;
      s.paymentMethod = _payment;
      s.note = _note.text.trim();
      s.saleDate = _saleDate.millisecondsSinceEpoch;
      s.netSale = netSale;
      s.costUsed = costUsed;
      s.remainingCostAfterSale = remainingCostAfterSale;
      s.profitGenerated = profitGenerated;
      s.accumulatedProfit = accumulatedProfit;
      s.photoPaths = _photoPaths;
      await box.put(widget.hiveKey, s);
    } else {
      await box.add(Sale(
        id: LocalDb.genId(),
        gemstoneId: gemId,
        gemstoneName: name,
        customerName: _customer.text.trim(),
        amount: amount,
        costPrice: cost,
        commissionFee: sellCommission,
        quantity: qty,
        weightCarat: weight,
        paymentMethod: _payment,
        note: _note.text.trim(),
        saleDate: _saleDate.millisecondsSinceEpoch,
        netSale: netSale,
        costUsed: costUsed,
        remainingCostAfterSale: remainingCostAfterSale,
        profitGenerated: profitGenerated,
        accumulatedProfit: accumulatedProfit,
        photoPaths: _photoPaths,
      ));
    }
    
    // Recalculate profit from all sales records for this gemstone
    if (gemId.isNotEmpty) {
      await LocalDb.updateGemstoneProductLedger(gemId);
    }
    
    if (mounted) Navigator.pop(context);
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

                // --- Gemstone picker from inventory ---
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

                // Available stock hint
                if (selectedGem != null)
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
                              'လက်ကျန်: ${LocalDb.gemstoneRemainingQuantity(selectedGem)} ခု'
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

                // Manual name (editable; auto-filled when a gem is selected)
                _field(_manualName, 'ကျောက်မျက်အမည်', required: true),

                _field(_customer, 'ဝယ်သူအမည်'),
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
                    onPressed: _save,
                    child: const Text('သိမ်းဆည်းမည်',
                        style: TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    );
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
            ? (v) => (v == null || v.trim().isEmpty) ? 'ဖြည့်ပါ' : null
            : null,
      ),
    );
  }
}
