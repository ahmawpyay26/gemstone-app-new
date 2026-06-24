import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/local/local_db.dart';
import '../../../../core/local/models.dart';

class ExpensesPage extends StatefulWidget {
  const ExpensesPage({Key? key}) : super(key: key);

  @override
  State<ExpensesPage> createState() => _ExpensesPageState();
}

class _ExpensesPageState extends State<ExpensesPage> {
  final _money = NumberFormat('#,##0', 'en_US');
  final _date = DateFormat('yyyy-MM-dd');

  void _openForm({Expense? existing, dynamic key}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ExpenseForm(existing: existing, hiveKey: key),
    );
  }

  Future<void> _delete(dynamic key) async {
    final ok = await showDialog<bool>(
          context: context,
          builder: (c) => AlertDialog(
            backgroundColor: AppTheme.surfaceDark,
            title: const Text('အတည်ပြုရန်'),
            content: const Text('ဤအသုံးစရိတ်ကို ဖျက်မှာလား။'),
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
    if (ok) await LocalDb.expenses().delete(key);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryDark,
      appBar: AppBar(
        title: const Text('အသုံးစရိတ်'),
        leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () =>
                context.canPop() ? context.pop() : context.go('/dashboard')),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppTheme.primaryAccent,
        foregroundColor: Colors.black,
        icon: const Icon(Icons.add),
        label: const Text('စရိတ်အသစ်'),
        onPressed: () => _openForm(),
      ),
      body: ValueListenableBuilder(
        valueListenable: LocalDb.expenses().listenable(),
        builder: (context, Box<Expense> box, _) {
          final total = LocalDb.totalExpenses();
          return Column(
            children: [
              Container(
                width: double.infinity,
                margin: const EdgeInsets.all(12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.errorColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                  border:
                      Border.all(color: AppTheme.errorColor.withOpacity(0.4)),
                ),
                child: Column(
                  children: [
                    Text('စုစုပေါင်း အသုံးစရိတ်',
                        style: TextStyle(color: Colors.grey[300])),
                    const SizedBox(height: 4),
                    Text('${_money.format(total)} ကျပ်',
                        style: const TextStyle(
                            color: AppTheme.errorColor,
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
                          final e = box.get(key)!;
                          return Card(
                            color: AppTheme.surfaceDark,
                            margin: const EdgeInsets.only(bottom: 10),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor:
                                    AppTheme.errorColor.withOpacity(0.2),
                                child: const Icon(Icons.receipt_long,
                                    color: AppTheme.errorColor),
                              ),
                              title: Text(e.title,
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold)),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(e.category,
                                      style:
                                          TextStyle(color: Colors.grey[400])),
                                  Text(
                                      _date.format(
                                          DateTime.fromMillisecondsSinceEpoch(
                                              e.expenseDate)),
                                      style: TextStyle(
                                          color: Colors.grey[500],
                                          fontSize: 12)),
                                ],
                              ),
                              trailing: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(_money.format(e.amount),
                                      style: const TextStyle(
                                          color: AppTheme.errorColor,
                                          fontWeight: FontWeight.bold)),
                                  InkWell(
                                    onTap: () => _delete(key),
                                    child: const Icon(Icons.delete_outline,
                                        color: AppTheme.errorColor, size: 20),
                                  ),
                                ],
                              ),
                              onTap: () => _openForm(existing: e, key: key),
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

  Widget _empty() => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.receipt_long, size: 70, color: Colors.grey[700]),
            const SizedBox(height: 12),
            Text('အသုံးစရိတ် မရှိသေးပါ',
                style: TextStyle(color: Colors.grey[500])),
          ],
        ),
      );
}

class _ExpenseForm extends StatefulWidget {
  final Expense? existing;
  final dynamic hiveKey;
  const _ExpenseForm({this.existing, this.hiveKey});

  @override
  State<_ExpenseForm> createState() => _ExpenseFormState();
}

class _ExpenseFormState extends State<_ExpenseForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _title;
  late final TextEditingController _amount;
  late final TextEditingController _note;
  String _category = 'အထွေထွေ';
  late DateTime _expenseDate;

  final _categories = const [
    'အထွေထွေ',
    'လစာ',
    'သယ်ယူပို့ဆောင်',
    'အငှား',
    'လျှပ်စစ်',
    'ဝယ်ယူမှု',
    'အခြား',
  ];

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _title = TextEditingController(text: e?.title ?? '');
    _amount = TextEditingController(text: e?.amount.toString() ?? '');
    _note = TextEditingController(text: e?.note ?? '');
    _category = e?.category ?? 'အထွေထွေ';
    if (!_categories.contains(_category)) _category = 'အထွေထွေ';
    _expenseDate = e != null
        ? DateTime.fromMillisecondsSinceEpoch(e.expenseDate)
        : DateTime.now();
  }

  @override
  void dispose() {
    _title.dispose();
    _amount.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final box = LocalDb.expenses();
    if (widget.existing != null && widget.hiveKey != null) {
      final e = widget.existing!;
      e.title = _title.text.trim();
      e.category = _category;
      e.amount = double.tryParse(_amount.text.trim()) ?? 0;
      e.note = _note.text.trim();
      e.expenseDate = _expenseDate.millisecondsSinceEpoch;
      await box.put(widget.hiveKey, e);
    } else {
      await box.add(Expense(
        id: LocalDb.genId(),
        title: _title.text.trim(),
        category: _category,
        amount: double.tryParse(_amount.text.trim()) ?? 0,
        note: _note.text.trim(),
        expenseDate: _expenseDate.millisecondsSinceEpoch,
      ));
    }
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
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
                const Text('အသုံးစရိတ် မှတ်တမ်း',
                    style: TextStyle(
                        color: AppTheme.primaryAccent,
                        fontSize: 18,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                _field(_title, 'အကြောင်းအရာ', required: true),
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: DropdownButtonFormField<String>(
                    value: _category,
                    dropdownColor: AppTheme.surfaceLight,
                    style: const TextStyle(color: Colors.white),
                    decoration:
                        const InputDecoration(labelText: 'အမျိုးအစား'),
                    items: _categories
                        .map((c) =>
                            DropdownMenuItem(value: c, child: Text(c)))
                        .toList(),
                    onChanged: (v) =>
                        setState(() => _category = v ?? 'အထွေထွေ'),
                  ),
                ),
                _field(_amount, 'ပမာဏ', number: true, required: true),
                InkWell(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _expenseDate,
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2100),
                    );
                    if (picked != null) setState(() => _expenseDate = picked);
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
                            'ရက်စွဲ: ${DateFormat('yyyy-MM-dd').format(_expenseDate)}',
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
