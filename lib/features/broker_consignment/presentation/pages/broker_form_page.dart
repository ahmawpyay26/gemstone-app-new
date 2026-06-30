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
  late TextEditingController _gemstoneName Ctrl;
  late TextEditingController _quantityCtrl;
  late TextEditingController _weightCtrl;
  late TextEditingController _notesCtrl;
  
  String? _selectedPurchaseId;
  String? _selectedBreakdownItem;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _brokerNameCtrl = TextEditingController(text: widget.existing?.brokerName ?? '');
    _gemstoneNameCtrl = TextEditingController(text: widget.existing?.gemstoneName ?? '');
    _quantityCtrl = TextEditingController(text: widget.existing?.consignedQuantity?.toString() ?? '');
    _weightCtrl = TextEditingController(text: widget.existing?.weight?.toString() ?? '');
    _notesCtrl = TextEditingController(text: widget.existing?.notes ?? '');
    _selectedPurchaseId = widget.existing?.purchaseId;
    _selectedBreakdownItem = widget.existing?.historicalData.breakdownItemName;
  }

  @override
  void dispose() {
    _brokerNameCtrl.dispose();
    _gemstoneNameCtrl.dispose();
    _quantityCtrl.dispose();
    _weightCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_brokerNameCtrl.text.isEmpty ||
        _gemstoneNameCtrl.text.isEmpty ||
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
      final quantity = int.parse(_quantityCtrl.text);
      final weight = double.tryParse(_weightCtrl.text) ?? 0.0;

      if (widget.existing != null) {
        // Update existing
        final updated = widget.existing!.copyWith(
          brokerName: _brokerNameCtrl.text,
          gemstoneName: _gemstoneNameCtrl.text,
          consignedQuantity: quantity,
          weight: weight,
          notes: _notesCtrl.text,
          updatedDate: DateTime.now().millisecondsSinceEpoch,
        );
        await LocalDb.brokerConsignments().put(widget.hiveKey, updated);
      } else {
        // Create new
        final purchase = LocalDb.gemstones().get(_selectedPurchaseId);
        if (purchase == null) throw Exception('ဝယ်ယူမှု မတွေ့ရှိ');

        final consignment = BrokerConsignment(
          id: LocalDb.genId(),
          brokerName: _brokerNameCtrl.text,
          gemstoneName: _gemstoneNameCtrl.text,
          purchaseId: _selectedPurchaseId!,
          consignedQuantity: quantity,
          weight: weight,
          soldQuantity: 0,
          returnedQuantity: 0,
          remainingQuantity: quantity,
          notes: _notesCtrl.text,
          createdDate: DateTime.now().millisecondsSinceEpoch,
          updatedDate: DateTime.now().millisecondsSinceEpoch,
          isActive: true,
          photoPaths: [],
          historicalData: BrokerHistoricalData(
            originalSeller: '',
            gemstoneType: purchase.type,
            originalWeight: purchase.weightCarat,
            sourceType: 'purchase',
            purchaseId: _selectedPurchaseId,
            breakdownItemName: _selectedBreakdownItem,
          ),
        );

        await LocalDb.createBrokerConsignment(
          brokerName: consignment.brokerName,
          gemstoneName: consignment.gemstoneName,
          purchaseId: consignment.purchaseId,
          consignedQuantity: consignment.consignedQuantity,
          weight: consignment.weight,
          notes: consignment.notes,
          sourceType: 'purchase',
          breakdownItemName: _selectedBreakdownItem,
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
              controller: _gemstoneNameCtrl,
              decoration: InputDecoration(
                labelText: 'ကျောက်မျ ိုးအမည်',
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
                labelText: 'အရေအတွက်',
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
              controller: _weightCtrl,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'ကြေးချိန် (ကာရက်)',
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
