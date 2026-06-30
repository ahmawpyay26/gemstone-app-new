import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/local/local_db.dart';
import '../../../../core/local/models.dart';

class BrokerFormPage extends StatefulWidget {
  final String? brokerId;

  const BrokerFormPage({Key? key, this.brokerId}) : super(key: key);

  @override
  State<BrokerFormPage> createState() => _BrokerFormPageState();
}

class _BrokerFormPageState extends State<BrokerFormPage> {
  late TextEditingController _brokerNameCtrl;
  late TextEditingController _brokerPhoneCtrl;
  late TextEditingController _brokerAddressCtrl;
  late TextEditingController _brokerSocialCtrl;
  late TextEditingController _notesCtrl;
  late TextEditingController _consignedQtyCtrl;

  String? _selectedPurchaseId;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _brokerNameCtrl = TextEditingController();
    _brokerPhoneCtrl = TextEditingController();
    _brokerAddressCtrl = TextEditingController();
    _brokerSocialCtrl = TextEditingController();
    _notesCtrl = TextEditingController();
    _consignedQtyCtrl = TextEditingController();

    // Load existing data if editing
    if (widget.brokerId != null) {
      final existing = LocalDb.getBrokerConsignment(widget.brokerId!);
      if (existing != null) {
        _brokerNameCtrl.text = existing.brokerName;
        _brokerPhoneCtrl.text = existing.brokerPhone;
        _brokerAddressCtrl.text = existing.brokerAddress;
        _brokerSocialCtrl.text = existing.brokerSocialAccount ?? '';
        _notesCtrl.text = existing.notes;
        _consignedQtyCtrl.text = existing.consignedQuantity.toString();
        _selectedPurchaseId = existing.purchaseId;
      }
    }
  }

  @override
  void dispose() {
    _brokerNameCtrl.dispose();
    _brokerPhoneCtrl.dispose();
    _brokerAddressCtrl.dispose();
    _brokerSocialCtrl.dispose();
    _notesCtrl.dispose();
    _consignedQtyCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryDark,
      appBar: AppBar(
        title: Text(widget.brokerId == null ? 'အသစ်ထည့်သွင်းရန်' : 'ပြုပြင်ရန်'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Purchase Selection (Disabled when editing)
            if (widget.brokerId == null)
              _buildPurchaseSelector()
            else
              _buildPurchaseDisplay(),

            const SizedBox(height: 16),

            // Broker Information
            TextField(
              controller: _brokerNameCtrl,
              decoration: InputDecoration(
                labelText: 'ပွဲစားအမည် *',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                filled: true,
                fillColor: AppTheme.surfaceDark,
              ),
              style: const TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 12),

            TextField(
              controller: _brokerPhoneCtrl,
              decoration: InputDecoration(
                labelText: 'ဖုန်းနံပါတ် *',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                filled: true,
                fillColor: AppTheme.surfaceDark,
              ),
              style: const TextStyle(color: Colors.white),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 12),

            TextField(
              controller: _brokerAddressCtrl,
              decoration: InputDecoration(
                labelText: 'လိပ်စာ *',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                filled: true,
                fillColor: AppTheme.surfaceDark,
              ),
              style: const TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 12),

            TextField(
              controller: _brokerSocialCtrl,
              decoration: InputDecoration(
                labelText: 'အချက်အလက် (လူမှုကွန်ယက်)',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                filled: true,
                fillColor: AppTheme.surfaceDark,
              ),
              style: const TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 12),

            // Consigned Quantity
            if (widget.brokerId == null)
              TextField(
                controller: _consignedQtyCtrl,
                decoration: InputDecoration(
                  labelText: 'အပ်ထားသောအရေအတွက် *',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  filled: true,
                  fillColor: AppTheme.surfaceDark,
                ),
                style: const TextStyle(color: Colors.white),
                keyboardType: TextInputType.number,
              ),
            const SizedBox(height: 12),

            TextField(
              controller: _notesCtrl,
              decoration: InputDecoration(
                labelText: 'မှတ်ချက်များ',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                filled: true,
                fillColor: AppTheme.surfaceDark,
              ),
              style: const TextStyle(color: Colors.white),
              maxLines: 3,
            ),
            const SizedBox(height: 24),

            // Save Button
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryAccent,
                  foregroundColor: Colors.black,
                ),
                onPressed: _isLoading ? null : _handleSave,
                child: _isLoading
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('သိမ်းဆည်းရန်'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPurchaseSelector() {
    return ValueListenableBuilder(
      valueListenable: LocalDb.gemstones().listenable(),
      builder: (context, Box<Gemstone> box, _) {
        final purchases = box.values.toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'ကျောက်အပ်စာရင်းရွေးချယ်ရန် *',
              style: TextStyle(color: Colors.grey[300], fontSize: 14),
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[600]!),
                borderRadius: BorderRadius.circular(8),
              ),
              child: DropdownButton<String>(
                value: _selectedPurchaseId,
                isExpanded: true,
                underline: const SizedBox(),
                hint: const Padding(
                  padding: EdgeInsets.all(12.0),
                  child: Text('ကျောက်အပ်စာရင်းရွေးချယ်ရန်'),
                ),
                items: purchases.map((purchase) {
                  final key = box.keyAt(box.values.toList().indexOf(purchase));
                  return DropdownMenuItem<String>(
                    value: key.toString(),
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Text(
                        '${purchase.name} (${purchase.type}) - ${purchase.quantity} ခု',
                        style: const TextStyle(color: Colors.black),
                      ),
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedPurchaseId = value;
                  });
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildPurchaseDisplay() {
    if (_selectedPurchaseId == null) return const SizedBox();

    final purchase = LocalDb.getGemstone(_selectedPurchaseId!);
    if (purchase == null) return const SizedBox();

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.primaryAccent),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'ကျောက်အပ်စာရင်း',
            style: TextStyle(color: Colors.grey[400], fontSize: 12),
          ),
          const SizedBox(height: 8),
          Text(
            '${purchase.name} (${purchase.type})',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 4),
          Text(
            'ကျန်အရေအတွက်: ${purchase.quantity}',
            style: TextStyle(color: Colors.grey[300]),
          ),
        ],
      ),
    );
  }

  Future<void> _handleSave() async {
    // Validation
    if (_brokerNameCtrl.text.isEmpty ||
        _brokerPhoneCtrl.text.isEmpty ||
        _brokerAddressCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('လိုအပ်သောအချက်အလက်များ ဖြည့်သွင်းပါ')),
      );
      return;
    }

    if (widget.brokerId == null) {
      // Creating new
      if (_selectedPurchaseId == null || _consignedQtyCtrl.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('ကျောက်အပ်စာရင်းနှင့် အရေအတွက်ရွေးချယ်ပါ')),
        );
        return;
      }
    }

    setState(() => _isLoading = true);

    try {
      if (widget.brokerId == null) {
        // Create new broker consignment
        final consignedQty = double.tryParse(_consignedQtyCtrl.text) ?? 0;

        await LocalDb.createBrokerConsignment(
          purchaseId: _selectedPurchaseId!,
          consignedQuantity: consignedQty,
          brokerName: _brokerNameCtrl.text,
          brokerPhone: _brokerPhoneCtrl.text,
          brokerAddress: _brokerAddressCtrl.text,
          brokerSocialAccount: _brokerSocialCtrl.text.isEmpty ? null : _brokerSocialCtrl.text,
          notes: _notesCtrl.text,
          sourceType: 'whole_stone',
        );

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('အပ်စာရင်းထည့်သွင်းအောင်မြင်ပါသည်')),
        );
      } else {
        // Update existing
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('အပ်စာရင်းအဆင့်မြှင့်တင်အောင်မြင်ပါသည်')),
        );
      }

      if (mounted) {
        context.pop();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('အမှားအယွင်း: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}
