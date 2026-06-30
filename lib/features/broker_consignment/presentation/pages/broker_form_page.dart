import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/local/local_db.dart';
import '../../../../core/local/models.dart';

class BrokerFormPage extends StatefulWidget {
  final BrokerConsignment? existing;
  final dynamic hiveKey;

  const BrokerFormPage({
    Key? key,
    this.existing,
    this.hiveKey,
  }) : super(key: key);

  @override
  State<BrokerFormPage> createState() => _BrokerFormPageState();
}

class _BrokerFormPageState extends State<BrokerFormPage> {
  late TextEditingController _brokerNameCtrl;
  late TextEditingController _brokerPhoneCtrl;
  late TextEditingController _brokerAddressCtrl;
  late TextEditingController _brokerSocialCtrl;
  late TextEditingController _quantityCtrl;
  late TextEditingController _notesCtrl;
  
  String? _selectedPurchaseId;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _brokerNameCtrl = TextEditingController(text: widget.existing?.brokerName ?? '');
    _brokerPhoneCtrl = TextEditingController(text: widget.existing?.brokerPhone ?? '');
    _brokerAddressCtrl = TextEditingController(text: widget.existing?.brokerAddress ?? '');
    _brokerSocialCtrl = TextEditingController(text: widget.existing?.brokerSocialAccount ?? '');
    _quantityCtrl = TextEditingController(text: widget.existing?.consignedQuantity?.toString() ?? '');
    _notesCtrl = TextEditingController(text: widget.existing?.notes ?? '');
    _selectedPurchaseId = widget.existing?.purchaseId;
  }

  @override
  void dispose() {
    _brokerNameCtrl.dispose();
    _brokerPhoneCtrl.dispose();
    _brokerAddressCtrl.dispose();
    _brokerSocialCtrl.dispose();
    _quantityCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_brokerNameCtrl.text.isEmpty ||
        _brokerPhoneCtrl.text.isEmpty ||
        _brokerAddressCtrl.text.isEmpty ||
        _quantityCtrl.text.isEmpty ||
        _selectedPurchaseId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('အားလုံးဖြည့်စွက်ပါ'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final quantity = double.parse(_quantityCtrl.text);

      if (widget.existing != null) {
        // Update existing
        final updated = widget.existing!;
        updated.brokerName = _brokerNameCtrl.text;
        updated.brokerPhone = _brokerPhoneCtrl.text;
        updated.brokerAddress = _brokerAddressCtrl.text;
        updated.brokerSocialAccount = _brokerSocialCtrl.text;
        updated.consignedQuantity = quantity;
        updated.notes = _notesCtrl.text;
        updated.updatedAt = DateTime.now().millisecondsSinceEpoch;
        
        await LocalDb.brokerConsignments().put(widget.hiveKey, updated);
      } else {
        // Create new
        final purchase = LocalDb.gemstones().get(_selectedPurchaseId);
        if (purchase == null) throw Exception('ဝယ်ယူမှု မတွေ့ရှိ');

        await LocalDb.createBrokerConsignment(
          brokerName: _brokerNameCtrl.text,
          brokerPhone: _brokerPhoneCtrl.text,
          brokerAddress: _brokerAddressCtrl.text,
          brokerSocialAccount: _brokerSocialCtrl.text,
          purchaseId: _selectedPurchaseId!,
          consignedQuantity: quantity,
          notes: _notesCtrl.text,
          sourceType: 'whole_stone',
          breakdownItemName: null,
        );
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.existing != null
                ? 'ပွဲစားအပ်စာရင်း အဆင့်မြှင့်တင်ပြီးပါပြီ'
                : 'ပွဲစားအပ်စာရင်း ဖန်တီးပြီးပါပြီ'),
            backgroundColor: AppTheme.successColor,
          ),
        );
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
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryDark,
      appBar: AppBar(
        title: Text(widget.existing != null
            ? 'ပွဲစားအပ်စာရင်း အဆင့်မြှင့်တင်ရန်'
            : 'ပွဲစားအပ်စာရင်း အသစ်'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _brokerNameCtrl,
              decoration: InputDecoration(
                labelText: 'ပွဲစားအမည်',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                filled: true,
                fillColor: AppTheme.surfaceDark,
              ),
              style: const TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _brokerPhoneCtrl,
              decoration: InputDecoration(
                labelText: 'ဖုန်းနံပါတ်',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                filled: true,
                fillColor: AppTheme.surfaceDark,
              ),
              style: const TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _brokerAddressCtrl,
              decoration: InputDecoration(
                labelText: 'လိပ်စာ',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                filled: true,
                fillColor: AppTheme.surfaceDark,
              ),
              style: const TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _brokerSocialCtrl,
              decoration: InputDecoration(
                labelText: 'လူမှုကွန်ယက်အကောင့်',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                filled: true,
                fillColor: AppTheme.surfaceDark,
              ),
              style: const TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _quantityCtrl,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'အပ်ထားသောအရေအတွက်',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                filled: true,
                fillColor: AppTheme.surfaceDark,
              ),
              style: const TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _notesCtrl,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: 'မှတ်ချက်များ',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                filled: true,
                fillColor: AppTheme.surfaceDark,
              ),
              style: const TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryAccent,
                  foregroundColor: Colors.black,
                ),
                onPressed: _isLoading ? null : _save,
                child: _isLoading
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.black),
                        ),
                      )
                    : const Text('သိမ်းဆည်းရန်'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
