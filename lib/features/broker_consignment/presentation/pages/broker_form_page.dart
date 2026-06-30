import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
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
  
  // Purchase Record reference
  Gemstone? _selectedPurchase;

  // Step 6.4: list of purchase records loaded from LocalDb
  List<Gemstone> _purchaseRecords = [];

  @override
  void initState() {
    super.initState();
    _brokerNameCtrl = TextEditingController();
    _brokerPhoneCtrl = TextEditingController();
    _brokerAddressCtrl = TextEditingController();
    _purchaseRecords = LocalDb.gemstones().values.toList();
  }

  @override
  void dispose() {
    _brokerNameCtrl.dispose();
    _brokerPhoneCtrl.dispose();
    _brokerAddressCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.brokerId != null ? 'ပွဲစားအပ်စာရင်းပြင်ဆင်ရန်' : 'ပွဲစားအပ်စာရင်းထည့်သွင်းရန်'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('ပွဲစားအချက်အလက်', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            DropdownButtonFormField<Gemstone>(
              value: _selectedPurchase,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'ဝယ်ယူမှုမှတ်တမ်း',
                border: OutlineInputBorder(),
              ),
              items: _purchaseRecords.map((g) {
                return DropdownMenuItem<Gemstone>(
                  value: g,
                  child: Text(
                    '${g.name} (${g.type}) - အရေအတွက် ${g.quantity}',
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              }).toList(),
              onChanged: (g) {
                setState(() {
                  _selectedPurchase = g;
                });
              },
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _brokerNameCtrl,
              decoration: const InputDecoration(
                labelText: 'ပွဲစားအမည်',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _brokerPhoneCtrl,
              decoration: const InputDecoration(
                labelText: 'ဖုန်းနံပါတ်',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _brokerAddressCtrl,
              decoration: const InputDecoration(
                labelText: 'လိပ်စာ',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  // TODO: Implement save logic
                  context.pop(true);
                },
                child: const Text('သိမ်းဆည်းရန်'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
