import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/local/local_db.dart';
import '../../../../core/local/models.dart';

class InventoryPage extends StatefulWidget {
  const InventoryPage({Key? key}) : super(key: key);

  @override
  State<InventoryPage> createState() => _InventoryPageState();
}

class _InventoryPageState extends State<InventoryPage> {
  final _money = NumberFormat('#,##0', 'en_US');

  void _openForm({Gemstone? existing, dynamic key}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _GemstoneForm(existing: existing, hiveKey: key),
    );
  }

  Future<void> _delete(dynamic key) async {
    final ok = await _confirm('ဤကျောက်မျက်ကို ဖျက်မှာ သေချာပါသလား။');
    if (ok) await LocalDb.gemstones().delete(key);
  }

  Future<bool> _confirm(String msg) async {
    return await showDialog<bool>(
          context: context,
          builder: (c) => AlertDialog(
            backgroundColor: AppTheme.surfaceDark,
            title: const Text('အတည်ပြုရန်'),
            content: Text(msg),
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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryDark,
      appBar: AppBar(
        title: const Text('ပစ္စည်းစာရင်း'),
        leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.go('/dashboard')),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppTheme.primaryAccent,
        foregroundColor: Colors.black,
        icon: const Icon(Icons.add),
        label: const Text('အသစ်ထည့်ရန်'),
        onPressed: () => _openForm(),
      ),
      body: ValueListenableBuilder(
        valueListenable: LocalDb.gemstones().listenable(),
        builder: (context, Box<Gemstone> box, _) {
          if (box.isEmpty) {
            return _empty();
          }
          final keys = box.keys.toList();
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 90),
            itemCount: keys.length,
            itemBuilder: (context, i) {
              final key = keys[i];
              final g = box.get(key)!;
              return Card(
                color: AppTheme.surfaceDark,
                margin: const EdgeInsets.only(bottom: 10),
                child: ListTile(
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  leading: CircleAvatar(
                    backgroundColor: AppTheme.primaryAccent.withOpacity(0.2),
                    child: const Icon(Icons.diamond,
                        color: AppTheme.primaryAccent),
                  ),
                  title: Text(g.name,
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${g.type} • ${g.weightCarat} ကာရက်',
                          style: TextStyle(color: Colors.grey[400])),
                      Text(
                          'ရောင်းဈေး: ${_money.format(g.sellPrice)} ကျပ် • အရေအတွက်: ${g.quantity}',
                          style: const TextStyle(
                              color: AppTheme.primaryAccent, fontSize: 12)),
                    ],
                  ),
                  trailing: PopupMenuButton<String>(
                    color: AppTheme.surfaceLight,
                    icon: const Icon(Icons.more_vert, color: Colors.white),
                    onSelected: (v) {
                      if (v == 'edit') _openForm(existing: g, key: key);
                      if (v == 'delete') _delete(key);
                    },
                    itemBuilder: (_) => const [
                      PopupMenuItem(value: 'edit', child: Text('ပြင်ဆင်ရန်')),
                      PopupMenuItem(value: 'delete', child: Text('ဖျက်ရန်')),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _empty() => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.diamond, size: 70, color: Colors.grey[700]),
            const SizedBox(height: 12),
            Text('ကျောက်မျက်စာရင်း မရှိသေးပါ',
                style: TextStyle(color: Colors.grey[500])),
            const SizedBox(height: 4),
            Text('အောက်က ခလုတ်ဖြင့် ထည့်ပါ',
                style: TextStyle(color: Colors.grey[600], fontSize: 12)),
          ],
        ),
      );
}

class _GemstoneForm extends StatefulWidget {
  final Gemstone? existing;
  final dynamic hiveKey;
  const _GemstoneForm({this.existing, this.hiveKey});

  @override
  State<_GemstoneForm> createState() => _GemstoneFormState();
}

class _GemstoneFormState extends State<_GemstoneForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _type;
  late final TextEditingController _weight;
  late final TextEditingController _cost;
  late final TextEditingController _sell;
  late final TextEditingController _qty;
  late final TextEditingController _color;
  late final TextEditingController _origin;
  late final TextEditingController _note;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _name = TextEditingController(text: e?.name ?? '');
    _type = TextEditingController(text: e?.type ?? '');
    _weight = TextEditingController(text: e?.weightCarat.toString() ?? '');
    _cost = TextEditingController(text: e?.costPrice.toString() ?? '');
    _sell = TextEditingController(text: e?.sellPrice.toString() ?? '');
    _qty = TextEditingController(text: e?.quantity.toString() ?? '1');
    _color = TextEditingController(text: e?.color ?? '');
    _origin = TextEditingController(text: e?.origin ?? '');
    _note = TextEditingController(text: e?.note ?? '');
  }

  @override
  void dispose() {
    for (final c in [
      _name,
      _type,
      _weight,
      _cost,
      _sell,
      _qty,
      _color,
      _origin,
      _note
    ]) {
      c.dispose();
    }
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
      g.costPrice = _d(_cost.text);
      g.sellPrice = _d(_sell.text);
      g.quantity = _i(_qty.text);
      g.color = _color.text.trim();
      g.origin = _origin.text.trim();
      g.note = _note.text.trim();
      await box.put(widget.hiveKey, g);
    } else {
      await box.add(Gemstone(
        id: LocalDb.genId(),
        name: _name.text.trim(),
        type: _type.text.trim(),
        weightCarat: _d(_weight.text),
        costPrice: _d(_cost.text),
        sellPrice: _d(_sell.text),
        quantity: _i(_qty.text),
        color: _color.text.trim(),
        origin: _origin.text.trim(),
        status: 'in_stock',
        note: _note.text.trim(),
        createdAt: DateTime.now().millisecondsSinceEpoch,
      ));
    }
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existing != null;
    return Padding(
      padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom),
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
                      child: _field(_weight, 'အလေးချိန် (ကာရက်)',
                          number: true)),
                  const SizedBox(width: 12),
                  Expanded(child: _field(_qty, 'အရေအတွက်', number: true)),
                ]),
                Row(children: [
                  Expanded(child: _field(_cost, 'ဝယ်ဈေး', number: true)),
                  const SizedBox(width: 12),
                  Expanded(child: _field(_sell, 'ရောင်းဈေး', number: true)),
                ]),
                Row(children: [
                  Expanded(child: _field(_color, 'အရောင်')),
                  const SizedBox(width: 12),
                  Expanded(child: _field(_origin, 'မူရင်းနေရာ')),
                ]),
                _field(_note, 'မှတ်ချက်'),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _save,
                    child: Text(isEdit ? 'သိမ်းဆည်းမည်' : 'ထည့်သွင်းမည်',
                        style: const TextStyle(
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
