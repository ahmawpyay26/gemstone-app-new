import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/local/local_db.dart';
import '../../../../core/local/models.dart';

class SalesPage extends StatefulWidget {
  const SalesPage({Key? key}) : super(key: key);

  @override
  State<SalesPage> createState() => _SalesPageState();
}

class _SalesPageState extends State<SalesPage> {
  final _money = NumberFormat('#,##0', 'en_US');
  final _date = DateFormat('yyyy-MM-dd');

  void _openForm({Sale? existing, dynamic key}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _SaleForm(existing: existing, hiveKey: key),
    );
  }

  Future<void> _delete(dynamic key) async {
    final sale = LocalDb.sales().get(key);
    final ok = await showDialog<bool>(
          context: context,
          builder: (c) => AlertDialog(
            backgroundColor: AppTheme.surfaceDark,
            title: const Text('အတည်ပြုရန်'),
            content: const Text(
                'ဤအရောင်းမှတ်တမ်းကို ဖျက်မှာလား။ ပစ္စည်းစာရင်းသို့ stock ပြန်ပေါင်းပေးပါမည်။'),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(c, false),
                  child: const Text('မလုပ်တော့ပါ')),
              TextButton(
                  onPressed: () => Navigator.pop(c, true),
                  child: const Text('ဖျက်မည်',
                      style: TextStyle(color: AppTheme.errorColor))),
            ],
          ),
        ) ??
        false;
    if (ok) {
      // Restore stock that was deducted by this sale.
      if (sale != null && sale.gemstoneId.isNotEmpty) {
        await LocalDb.adjustStock(
            sale.gemstoneId, -sale.quantity, -sale.weightCarat);
      }
      await LocalDb.sales().delete(key);
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
            onPressed: () => context.go('/dashboard')),
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
          final total = LocalDb.totalSales();
          return Column(
            children: [
              Container(
                width: double.infinity,
                margin: const EdgeInsets.all(12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.successColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: AppTheme.successColor.withOpacity(0.4)),
                ),
                child: Column(
                  children: [
                    Text('စုစုပေါင်း အရောင်း',
                        style: TextStyle(color: Colors.grey[300])),
                    const SizedBox(height: 4),
                    Text('${_money.format(total)} ကျပ်',
                        style: const TextStyle(
                            color: AppTheme.successColor,
                            fontSize: 24,
                            fontWeight: FontWeight.bold)),
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
                          final key = box.keys.toList()[i];
                          final s = box.get(key)!;
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
                                  InkWell(
                                    onTap: () => _delete(key),
                                    child: const Icon(Icons.delete_outline,
                                        color: AppTheme.errorColor, size: 20),
                                  ),
                                ],
                              ),
                              onTap: () => _openForm(existing: s, key: key),
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
  String _payment = 'cash';
  late DateTime _saleDate;

  String? _selectedGemId; // null => manual entry
  bool _autoDeduct = true;

  bool get _isEdit => widget.existing != null && widget.hiveKey != null;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _customer = TextEditingController(text: e?.customerName ?? '');
    _amount =
        TextEditingController(text: e != null ? _trim(e.amount) : '');
    _qty = TextEditingController(text: e?.quantity.toString() ?? '1');
    _weight =
        TextEditingController(text: e != null && e.weightCarat > 0 ? _trim(e.weightCarat) : '');
    _note = TextEditingController(text: e?.note ?? '');
    _manualName = TextEditingController(text: e?.gemstoneName ?? '');
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
    for (final c in [_customer, _amount, _qty, _weight, _note, _manualName]) {
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
        }
      }
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final qty = int.tryParse(_qty.text.trim()) ?? 1;
    final weight = double.tryParse(_weight.text.trim()) ?? 0;
    final amount = double.tryParse(_amount.text.trim()) ?? 0;

    final gemId = _selectedGemId ?? '';
    final name = gemId.isNotEmpty
        ? (LocalDb.gemstoneById(gemId)?.name ?? _manualName.text.trim())
        : _manualName.text.trim();

    // Stock validation when linked to an inventory item and auto-deduct is on.
    if (gemId.isNotEmpty && _autoDeduct) {
      final g = LocalDb.gemstoneById(gemId)!;
      // Account for what this sale previously held (edit case).
      final prevQty = (_isEdit && widget.existing!.gemstoneId == gemId)
          ? widget.existing!.quantity
          : 0;
      final prevWeight = (_isEdit && widget.existing!.gemstoneId == gemId)
          ? widget.existing!.weightCarat
          : 0;
      final availableQty = g.quantity + prevQty;
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

    // --- First, undo the previous sale's stock impact (edit case) ---
    if (_isEdit) {
      final old = widget.existing!;
      if (old.gemstoneId.isNotEmpty) {
        await LocalDb.adjustStock(
            old.gemstoneId, -old.quantity, -old.weightCarat);
      }
    }

    // --- Apply the new sale's stock deduction ---
    if (gemId.isNotEmpty && _autoDeduct) {
      await LocalDb.adjustStock(gemId, qty, weight);
    }

    if (_isEdit) {
      final s = widget.existing!;
      s.gemstoneId = gemId;
      s.gemstoneName = name;
      s.customerName = _customer.text.trim();
      s.amount = amount;
      s.quantity = qty;
      s.weightCarat = weight;
      s.paymentMethod = _payment;
      s.note = _note.text.trim();
      s.saleDate = _saleDate.millisecondsSinceEpoch;
      await box.put(widget.hiveKey, s);
    } else {
      await box.add(Sale(
        id: LocalDb.genId(),
        gemstoneId: gemId,
        gemstoneName: name,
        customerName: _customer.text.trim(),
        amount: amount,
        quantity: qty,
        weightCarat: weight,
        paymentMethod: _payment,
        note: _note.text.trim(),
        saleDate: _saleDate.millisecondsSinceEpoch,
      ));
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
    final gems = LocalDb.gemstones().values.toList();
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
                              '${g.name} (ကျန် ${g.quantity}'
                              '${g.weightCarat > 0 ? ' • ${_trim(g.weightCarat)} ${LocalDb.unitLabel(g.weightUnit)}' : ''})',
                              overflow: TextOverflow.ellipsis,
                            ),
                          )),
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
                              'လက်ကျန်: ${selectedGem.quantity} ခု'
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
                _field(_note, 'မှတ်ချက်'),
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
        validator: required
            ? (v) => (v == null || v.trim().isEmpty) ? 'ဖြည့်ပါ' : null
            : null,
      ),
    );
  }
}
