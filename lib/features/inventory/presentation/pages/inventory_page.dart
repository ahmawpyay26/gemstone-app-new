import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../../core/local/local_db.dart';
import '../../../core/local/models.dart';
import '../../../shared/theme.dart';
import '../../../shared/widgets/gemstone_breakdown_widget.dart';
import '../../../shared/widgets/photo_attachment_widget.dart';
import 'package:wouter/wouter.dart';

class InventoryPage extends StatefulWidget {
  const InventoryPage({Key? key}) : super(key: key);

  @override
  State<InventoryPage> createState() => _InventoryPageState();
}

class _InventoryPageState extends State<InventoryPage> {
  late List<Gemstone> _gemstones;
  String _period = 'all';
  final Map<int, bool> _expandedBreakdown = {};

  @override
  void initState() {
    super.initState();
    _loadGemstones();
  }

  void _loadGemstones() {
    final box = LocalDb.gemstones();
    setState(() {
      _gemstones = box.values.toList().cast<Gemstone>();
      _gemstones.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    });
  }

  void _deleteGemstone(int hiveKey) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ဖျက်မည်လား'),
        content: const Text('ဤကျောက်မျက်ကို ဖျက်လိုက်ပါက ပြန်မရနိုင်ပါ။'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ပယ်ဖျက်'),
          ),
          TextButton(
            onPressed: () {
              LocalDb.gemstones().delete(hiveKey);
              _loadGemstones();
              Navigator.pop(context);
            },
            child: const Text('ဖျက်'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryDark,
      appBar: AppBar(
        title: const Text('ကျောက်စာရင်း'),
        backgroundColor: AppTheme.primaryDark,
      ),
      body: _gemstones.isEmpty
          ? const Center(
              child: Text('ကျောက်မျက်မရှိသေးပါ',
                  style: TextStyle(color: Colors.grey)))
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: _gemstones.length,
              itemBuilder: (context, index) {
                final gemstone = _gemstones[index];
                final hiveKey = LocalDb.gemstones().toMap().entries
                    .firstWhere((e) => e.value == gemstone)
                    .key;
                return _buildGemstoneCard(gemstone, hiveKey, index);
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          builder: (context) => _GemstoneForm(
            onSaved: _loadGemstones,
          ),
        ),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildGemstoneCard(Gemstone gemstone, int hiveKey, int index) {
    final isExpanded = _expandedBreakdown[index] ?? false;
    final hasBreakdown = gemstone.breakdownItems.isNotEmpty;
    final breakdownSummary = _buildBreakdownSummary(gemstone.breakdownItems);

    return Card(
      color: AppTheme.surfaceLight,
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        gemstone.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      if (gemstone.type.isNotEmpty)
                        Text(
                          gemstone.type,
                          style: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 12,
                          ),
                        ),
                    ],
                  ),
                ),
                PopupMenuButton(
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      child: const Text('ပြင်ဆင်'),
                      onTap: () => showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        builder: (context) => _GemstoneForm(
                          existing: gemstone,
                          hiveKey: hiveKey,
                          onSaved: _loadGemstones,
                        ),
                      ),
                    ),
                    PopupMenuItem(
                      child: const Text('ဖျက်'),
                      onTap: () => _deleteGemstone(hiveKey),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'အရေအတွက်: ${gemstone.quantity}',
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                ),
                Text(
                  'ကျန်: ${gemstone.remainingQuantity}',
                  style: TextStyle(
                    color: AppTheme.primaryAccent,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'ဝယ်ဈေး: ${gemstone.costPrice.toStringAsFixed(2)}',
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                ),
                Text(
                  'အမြတ်: ${gemstone.totalProfit?.toStringAsFixed(2) ?? '0.00'}',
                  style: TextStyle(
                    color: gemstone.totalProfit != null && gemstone.totalProfit! > 0
                        ? Colors.green
                        : Colors.grey,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            if (hasBreakdown) ...[
              const SizedBox(height: 12),
              _buildBreakdownSummarySection(gemstone, index, isExpanded),
            ],
          ],
        ),
      ),
    );
  }

  String _buildBreakdownSummary(Map<String, int> items) {
    if (items.isEmpty) return '';
    final filtered = items.entries.where((e) => e.value > 0).toList();
    if (filtered.isEmpty) return '';
    return filtered.map((e) => '${e.key} ${e.value}').join(' • ');
  }

  Widget _buildBreakdownSummarySection(Gemstone gemstone, int index, bool isExpanded) {
    final summary = _buildBreakdownSummary(gemstone.breakdownItems);
    if (summary.isEmpty) return const SizedBox.shrink();

    return GestureDetector(
      onTap: () => setState(() => _expandedBreakdown[index] = !isExpanded),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.3),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: AppTheme.primaryAccent.withOpacity(0.3)),
        ),
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'ကျောက်အစိတ်စိတ်ပိုင်းများ:',
                  style: TextStyle(
                    color: AppTheme.primaryAccent,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Icon(
                  isExpanded ? Icons.expand_less : Icons.expand_more,
                  color: AppTheme.primaryAccent,
                  size: 18,
                ),
              ],
            ),
            if (!isExpanded)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  summary,
                  style: const TextStyle(color: Colors.white70, fontSize: 11),
                ),
              )
            else ...[
              const SizedBox(height: 8),
              Column(
                children: gemstone.breakdownItems.entries
                    .where((e) => e.value > 0)
                    .map((e) => Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                e.key,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                ),
                              ),
                              Text(
                                '${e.value}',
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ))
                    .toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _buildPeriodButton(String period, String label) {
    setState(() => _period = period);
  }
}

class _GemstoneForm extends StatefulWidget {
  final Gemstone? existing;
  final int? hiveKey;
  final VoidCallback onSaved;

  const _GemstoneForm({
    this.existing,
    this.hiveKey,
    required this.onSaved,
  });

  @override
  State<_GemstoneForm> createState() => _GemstoneFormState();
}

class _GemstoneFormState extends State<_GemstoneForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _type;
  late final TextEditingController _weight;
  late final TextEditingController _cost;
  late final TextEditingController _commission;
  late final TextEditingController _processingFee;
  late final TextEditingController _repairFee;
  late final TextEditingController _breakageFee;
  late final TextEditingController _bloodFee;
  late final TextEditingController _laborFee;
  late final TextEditingController _miscFee;
  late final TextEditingController _qty;
  late final TextEditingController _color;
  late final TextEditingController _origin;
  late final TextEditingController _note;
  String _weightUnit = 'kg';
  late List<String> _photoPaths;
  late Map<String, int> _breakdownItems;
  late List<String> _breakdownItemNames;
  String? _customItemName;
  bool _breakdownExpanded = false;
  late TextEditingController _breakdownNameCtrl;
  late TextEditingController _breakdownQtyCtrl;
  late FocusNode _breakdownNameFocus;
  late FocusNode _breakdownQtyFocus;
  String? _breakdownError;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _photoPaths = List.from(e?.photoPaths ?? []);
    if (e?.breakdownItems != null && e!.breakdownItems.isNotEmpty) {
      _breakdownItems = Map.from(e.breakdownItems);
      _breakdownItemNames = List.from(e.breakdownItems.keys);
    } else {
      _breakdownItems = {};
      _breakdownItemNames = [];
    }
    _customItemName = null;
    _name = TextEditingController(text: e?.name ?? '');
    _type = TextEditingController(text: e?.type ?? '');
    _weight = TextEditingController(text: e?.weightCarat.toString() ?? '');
    _weightUnit = e?.weightUnit ?? 'kg';
    _cost = TextEditingController(text: e?.costPrice.toString() ?? '');
    _commission = TextEditingController(
        text: (e != null && e.commissionFee > 0)
            ? e.commissionFee.toString()
            : '');
    _processingFee = TextEditingController(
        text: (e != null && e.processingFee > 0)
            ? e.processingFee.toString()
            : '');
    _repairFee = TextEditingController(
        text: (e != null && e.repairFee > 0) ? e.repairFee.toString() : '');
    _breakageFee = TextEditingController(
        text: (e != null && e.breakageFee > 0) ? e.breakageFee.toString() : '');
    _bloodFee = TextEditingController(
        text: (e != null && e.bloodFee > 0) ? e.bloodFee.toString() : '');
    _laborFee = TextEditingController(
        text: (e != null && e.laborFee > 0) ? e.laborFee.toString() : '');
    _miscFee = TextEditingController(
        text: (e != null && e.miscFee > 0) ? e.miscFee.toString() : '');
    _qty = TextEditingController(text: e?.quantity.toString() ?? '1');
    _color = TextEditingController(text: e?.color ?? '');
    _origin = TextEditingController(text: e?.origin ?? '');
    _note = TextEditingController(text: e?.note ?? '');
    _breakdownNameCtrl = TextEditingController();
    _breakdownQtyCtrl = TextEditingController();
    _breakdownNameFocus = FocusNode();
    _breakdownQtyFocus = FocusNode();
    _breakdownError = null;
  }

  @override
  void dispose() {
    for (final c in [
      _name,
      _type,
      _weight,
      _cost,
      _commission,
      _processingFee,
      _repairFee,
      _breakageFee,
      _bloodFee,
      _laborFee,
      _miscFee,
      _qty,
      _color,
      _origin,
      _note,
      _breakdownNameCtrl,
      _breakdownQtyCtrl,
    ]) {
      c.dispose();
    }
    _breakdownNameFocus.dispose();
    _breakdownQtyFocus.dispose();
    super.dispose();
  }

  double _d(String s) => double.tryParse(s.trim()) ?? 0;
  int _i(String s) => int.tryParse(s.trim()) ?? 0;

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final box = LocalDb.gemstones();
    if (widget.existing != null && widget.hiveKey != null) {
      final g = widget.existing!;
      g.name = _name.text.trim();
      g.type = _type.text.trim();
      g.weightCarat = _d(_weight.text);
      g.weightUnit = _weightUnit;
      g.costPrice = _d(_cost.text);
      g.commissionFee = _d(_commission.text);
      g.processingFee = _d(_processingFee.text);
      g.repairFee = _d(_repairFee.text);
      g.breakageFee = _d(_breakageFee.text);
      g.bloodFee = _d(_bloodFee.text);
      g.laborFee = _d(_laborFee.text);
      g.miscFee = _d(_miscFee.text);
      g.quantity = _i(_qty.text);
      g.color = _color.text.trim();
      g.origin = _origin.text.trim();
      g.note = _note.text.trim();
      g.photoPaths = _photoPaths;
      g.breakdownItems = _breakdownItems;
      await box.put(widget.hiveKey, g);
    } else {
      await box.add(Gemstone(
        id: LocalDb.genId(),
        name: _name.text.trim(),
        type: _type.text.trim(),
        weightCarat: _d(_weight.text),
        weightUnit: _weightUnit,
        costPrice: _d(_cost.text),
        commissionFee: _d(_commission.text),
        processingFee: _d(_processingFee.text),
        repairFee: _d(_repairFee.text),
        breakageFee: _d(_breakageFee.text),
        bloodFee: _d(_bloodFee.text),
        laborFee: _d(_laborFee.text),
        miscFee: _d(_miscFee.text),
        quantity: _i(_qty.text),
        color: _color.text.trim(),
        origin: _origin.text.trim(),
        status: 'in_stock',
        note: _note.text.trim(),
        createdAt: DateTime.now().millisecondsSinceEpoch,
        photoPaths: _photoPaths,
        breakdownItems: _breakdownItems,
      ));
    }
    if (mounted) Navigator.pop(context);
    widget.onSaved();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existing != null;
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
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(isEdit ? 'ကျောက်မျက် ပြင်ဆင်ရန်' : 'ကျောက်မျက်အသစ်',
                    style: const TextStyle(
                        color: AppTheme.primaryAccent,
                        fontSize: 18,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                _field(_name, 'အမည်', required: true),
                _field(_type, 'အမျိုးအစား (ဥပမာ - ပတ္တမြား)'),
                Row(children: [
                  Expanded(
                      flex: 2,
                      child: _field(_weight, 'အလေးချိန်', number: true)),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: DropdownButtonFormField<String>(
                        value: _weightUnit,
                        isExpanded: true,
                        dropdownColor: AppTheme.surfaceLight,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(labelText: 'ယူနစ်'),
                        items: LocalDb.weightUnits.entries
                            .map((e) => DropdownMenuItem(
                                  value: e.key,
                                  child: Text(e.value),
                                ))
                            .toList(),
                        onChanged: (v) =>
                            setState(() => _weightUnit = v ?? 'kg'),
                      ),
                    ),
                  ),
                ]),
                _field(_qty, 'အရေအတွက်', number: true),
                _field(_cost, 'ဝယ်ဈေး', number: true),
                const Divider(color: Colors.grey),
                const SizedBox(height: 8),
                Text('ကုန်ကျစရိတ်များ',
                    style: TextStyle(
                        color: Colors.grey[300],
                        fontSize: 12,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                _field(_commission, 'ဝယ်ယူစဉ် ပွဲခ', number: true),
                _field(_processingFee, 'ဆီဖိုး', number: true),
                _field(_repairFee, 'ပြုပြင်ခ', number: true),
                _field(_breakageFee, 'ဖျက်ခ', number: true),
                _field(_bloodFee, 'သွေးခ', number: true),
                _field(_laborFee, 'အလုပ်သမားခ', number: true),
                _field(_miscFee, 'အထွေထွေ', number: true),
                const SizedBox(height: 12),
                Row(children: [
                  Expanded(child: _field(_color, 'အရောင်')),
                  const SizedBox(width: 12),
                  Expanded(child: _field(_origin, 'မူရင်းနေရာ')),
                ]),
                _field(_note, 'မှတ်ချက်'),
                const SizedBox(height: 20),
                _buildBreakdownSection(),
                const SizedBox(height: 20),
                PhotoAttachmentWidget(
                  photoPaths: _photoPaths,
                  onPhotosChanged: (photos) {
                    setState(() => _photoPaths = photos);
                  },
                  recordType: 'purchase',
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _save,
                    child: Text(isEdit ? 'သိမ်းဆည်းမည်' : 'ထည့်သွင်းမည်',
                        style: const TextStyle(
                            color: Colors.black, fontWeight: FontWeight.bold)),
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

  Widget _buildBreakdownSection() {
    return GestureDetector(
      onTap: () => setState(() => _breakdownExpanded = !_breakdownExpanded),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.3),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppTheme.primaryAccent.withOpacity(0.3)),
        ),
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'ကျောက်အစိတ်စိတ်ပိုင်းများ',
                  style: TextStyle(
                    color: AppTheme.primaryAccent,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Icon(
                  _breakdownExpanded ? Icons.expand_less : Icons.expand_more,
                  color: AppTheme.primaryAccent,
                  size: 20,
                ),
              ],
            ),
            if (_breakdownExpanded) ...[const SizedBox(height: 12), _buildBreakdownItemsSection()],
          ],
        ),
      ),
    );
  }

  Widget _buildBreakdownItemsSection() {
    return Column(
      children: [
        if (_breakdownItemNames.isNotEmpty)
          Column(
            children: _breakdownItemNames.map((itemName) {
              final qty = _breakdownItems[itemName] ?? 0;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      itemName,
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                    ),
                    Row(
                      children: [
                        Text(
                          '— $qty',
                          style: TextStyle(
                            color: AppTheme.primaryAccent,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: () => _removeBreakdownItem(itemName),
                          child: const Icon(
                            Icons.close,
                            color: Colors.red,
                            size: 18,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        if (_breakdownItemNames.isNotEmpty) const SizedBox(height: 12),
        _buildAddBreakdownItemForm(),
      ],
    );
  }

  Widget _buildAddBreakdownItemForm() {
    return StatefulBuilder(
      builder: (context, setState) {
        return Column(
          children: [
            if (_breakdownError != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: Colors.red, width: 0.5),
                  ),
                  child: Text(
                    _breakdownError!,
                    style: const TextStyle(color: Colors.red, fontSize: 12),
                  ),
                ),
              ),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _breakdownNameCtrl,
                    focusNode: _breakdownNameFocus,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: 'အမည် ရေးရန်',
                      hintText: 'ဥပမာ - ဖျက်စ',
                    ),
                    onChanged: (_) {
                      if (_breakdownError != null) {
                        setState(() => _breakdownError = null);
                      }
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextFormField(
                    controller: _breakdownQtyCtrl,
                    focusNode: _breakdownQtyFocus,
                    keyboardType: const TextInputType.numberWithOptions(decimal: false),
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: 'အရေအတွက်',
                      hintText: '0',
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                    ],
                    onChanged: (_) {
                      if (_breakdownError != null) {
                        setState(() => _breakdownError = null);
                      }
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  final itemName = _breakdownNameCtrl.text.trim();
                  final qtyStr = _breakdownQtyCtrl.text.trim();
                  final qty = int.tryParse(qtyStr) ?? 0;

                  if (itemName.isEmpty) {
                    setState(() => _breakdownError = 'အမည်ကို ဖြည့်ပါ။');
                    _breakdownNameFocus.requestFocus();
                    return;
                  }

                  if (qtyStr.isEmpty) {
                    setState(() => _breakdownError = 'အရေအတွက်ကို ဖြည့်ပါ။');
                    _breakdownQtyFocus.requestFocus();
                    return;
                  }

                  if (qty <= 0) {
                    setState(() => _breakdownError = 'အရေအတွက်သည် 0 ထက်ကြီးရမည်ဖြစ်ပါသည်။');
                    _breakdownQtyFocus.requestFocus();
                    return;
                  }

                  if (_breakdownItems.containsKey(itemName)) {
                    setState(() => _breakdownError = 'ဤအမည်ဖြင့် အစိတ်အပိုင်း ရှိပြီးသားဖြစ်ပါသည်။');
                    _breakdownNameFocus.requestFocus();
                    return;
                  }

                  _addBreakdownItem(itemName, qty);
                  _breakdownNameCtrl.clear();
                  _breakdownQtyCtrl.clear();
                  setState(() => _breakdownError = null);
                  _breakdownNameFocus.requestFocus();
                },
                child: const Text(
                  'ထည့်ရန်',
                  style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _addBreakdownItem(String itemName, int quantity) {
    if (itemName.isEmpty || quantity <= 0) return;
    setState(() {
      if (!_breakdownItems.containsKey(itemName)) {
        _breakdownItemNames.add(itemName);
      }
      _breakdownItems[itemName] = quantity;
      _customItemName = null;
    });
  }

  void _removeBreakdownItem(String itemName) {
    setState(() {
      _breakdownItems.remove(itemName);
      _breakdownItemNames.remove(itemName);
    });
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
