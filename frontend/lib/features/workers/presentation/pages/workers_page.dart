import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/local/local_db.dart';
import '../../../../core/local/models.dart';

class WorkersPage extends StatefulWidget {
  const WorkersPage({Key? key}) : super(key: key);

  @override
  State<WorkersPage> createState() => _WorkersPageState();
}

class _WorkersPageState extends State<WorkersPage> {
  final _money = NumberFormat('#,##0', 'en_US');

  void _openForm({Worker? existing, dynamic key}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _WorkerForm(existing: existing, hiveKey: key),
    );
  }

  Future<void> _delete(dynamic key) async {
    final ok = await showDialog<bool>(
          context: context,
          builder: (c) => AlertDialog(
            backgroundColor: AppTheme.surfaceDark,
            title: const Text('အတည်ပြုရန်'),
            content: const Text('ဤအလုပ်သမားကို ဖျက်မှာလား။'),
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
    if (ok) await LocalDb.workers().delete(key);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryDark,
      appBar: AppBar(
        title: const Text('အလုပ်သမားများ'),
        leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.go('/dashboard')),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppTheme.primaryAccent,
        foregroundColor: Colors.black,
        icon: const Icon(Icons.add),
        label: const Text('ဝန်ထမ်းအသစ်'),
        onPressed: () => _openForm(),
      ),
      body: ValueListenableBuilder(
        valueListenable: LocalDb.workers().listenable(),
        builder: (context, Box<Worker> box, _) {
          if (box.isEmpty) return _empty();
          final keys = box.keys.toList();
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 90),
            itemCount: keys.length,
            itemBuilder: (context, i) {
              final key = keys[i];
              final w = box.get(key)!;
              final active = w.status == 'active';
              return Card(
                color: AppTheme.surfaceDark,
                margin: const EdgeInsets.only(bottom: 10),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: AppTheme.primaryAccent.withOpacity(0.2),
                    child: Text(
                      w.name.isNotEmpty ? w.name[0].toUpperCase() : '?',
                      style: const TextStyle(
                          color: AppTheme.primaryAccent,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                  title: Text(w.name,
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${w.role} • ${w.phone}',
                          style: TextStyle(color: Colors.grey[400])),
                      Text('လစာ: ${_money.format(w.salary)} ကျပ်',
                          style: const TextStyle(
                              color: AppTheme.primaryAccent, fontSize: 12)),
                    ],
                  ),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: (active
                                  ? AppTheme.successColor
                                  : Colors.grey)
                              .withOpacity(0.2),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(active ? 'အလုပ်ဆင်း' : 'ရပ်နား',
                            style: TextStyle(
                                color: active
                                    ? AppTheme.successColor
                                    : Colors.grey,
                                fontSize: 11)),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          InkWell(
                            onTap: () => _openForm(existing: w, key: key),
                            child: const Icon(Icons.edit,
                                color: AppTheme.primaryAccent, size: 18),
                          ),
                          const SizedBox(width: 12),
                          InkWell(
                            onTap: () => _delete(key),
                            child: const Icon(Icons.delete_outline,
                                color: AppTheme.errorColor, size: 18),
                          ),
                        ],
                      ),
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
            Icon(Icons.people, size: 70, color: Colors.grey[700]),
            const SizedBox(height: 12),
            Text('အလုပ်သမား မရှိသေးပါ',
                style: TextStyle(color: Colors.grey[500])),
          ],
        ),
      );
}

class _WorkerForm extends StatefulWidget {
  final Worker? existing;
  final dynamic hiveKey;
  const _WorkerForm({this.existing, this.hiveKey});

  @override
  State<_WorkerForm> createState() => _WorkerFormState();
}

class _WorkerFormState extends State<_WorkerForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _role;
  late final TextEditingController _phone;
  late final TextEditingController _salary;
  late final TextEditingController _note;
  bool _active = true;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _name = TextEditingController(text: e?.name ?? '');
    _role = TextEditingController(text: e?.role ?? '');
    _phone = TextEditingController(text: e?.phone ?? '');
    _salary = TextEditingController(text: e?.salary.toString() ?? '');
    _note = TextEditingController(text: e?.note ?? '');
    _active = (e?.status ?? 'active') == 'active';
  }

  @override
  void dispose() {
    for (final c in [_name, _role, _phone, _salary, _note]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final box = LocalDb.workers();
    if (widget.existing != null && widget.hiveKey != null) {
      final w = widget.existing!;
      w.name = _name.text.trim();
      w.role = _role.text.trim();
      w.phone = _phone.text.trim();
      w.salary = double.tryParse(_salary.text.trim()) ?? 0;
      w.status = _active ? 'active' : 'inactive';
      w.note = _note.text.trim();
      await box.put(widget.hiveKey, w);
    } else {
      await box.add(Worker(
        id: LocalDb.genId(),
        name: _name.text.trim(),
        role: _role.text.trim(),
        phone: _phone.text.trim(),
        salary: double.tryParse(_salary.text.trim()) ?? 0,
        status: _active ? 'active' : 'inactive',
        note: _note.text.trim(),
        createdAt: DateTime.now().millisecondsSinceEpoch,
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
                const Text('ဝန်ထမ်း မှတ်တမ်း',
                    style: TextStyle(
                        color: AppTheme.primaryAccent,
                        fontSize: 18,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                _field(_name, 'အမည်', required: true),
                _field(_role, 'ရာထူး/တာဝန်'),
                _field(_phone, 'ဖုန်းနံပါတ်'),
                _field(_salary, 'လစာ', number: true),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  activeColor: AppTheme.primaryAccent,
                  title: const Text('အလုပ်ဆင်းနေသည်',
                      style: TextStyle(color: Colors.white)),
                  value: _active,
                  onChanged: (v) => setState(() => _active = v),
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
